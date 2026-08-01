#!/usr/bin/env python3
"""Create a word-level tracked-changes DOCX from an original and revised DOCX.

The revised DOCX is used as the base document so page setup, images, and final
formatting are preserved. Text paragraphs are aligned against the original, then
WordprocessingML revision elements are injected at token granularity.
"""

from __future__ import annotations

import argparse
import copy
import datetime as dt
import re
import shutil
import tempfile
import zipfile
from dataclasses import dataclass
from difflib import SequenceMatcher
from pathlib import Path

from lxml import etree


W_NS = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
XML_NS = "http://www.w3.org/XML/1998/namespace"
NS = {"w": W_NS}


def w(tag: str) -> str:
    return f"{{{W_NS}}}{tag}"


TOKEN_RE = re.compile(r"\s+|[\w]+(?:[-'’][\w]+)*|[^\w\s]", re.UNICODE)


@dataclass
class Token:
    text: str
    rpr: etree._Element | None = None


@dataclass
class ParagraphInfo:
    index: int
    element: etree._Element
    text: str
    tokens: list[Token]
    has_drawing: bool


@dataclass
class AlignStep:
    kind: str  # match, insert, delete
    old_index: int | None
    new_index: int | None
    score: float = 0.0


class RevisionId:
    def __init__(self) -> None:
        self.value = 1

    def next(self) -> str:
        out = str(self.value)
        self.value += 1
        return out


def normalize(text: str) -> str:
    return re.sub(r"\s+", " ", text).strip().lower()


def paragraph_text(p: etree._Element) -> str:
    parts: list[str] = []
    for node in p.xpath(".//w:t | .//w:delText | .//w:tab | .//w:br", namespaces=NS):
        if node.tag == w("tab"):
            parts.append("\t")
        elif node.tag == w("br"):
            parts.append("\n")
        elif node.text:
            parts.append(node.text)
    return "".join(parts)


def tokenize_text(text: str, rpr: etree._Element | None = None) -> list[Token]:
    return [Token(m.group(0), copy.deepcopy(rpr) if rpr is not None else None) for m in TOKEN_RE.finditer(text)]


def paragraph_tokens(p: etree._Element) -> list[Token]:
    tokens: list[Token] = []
    for run in p.xpath(".//w:r", namespaces=NS):
        # Skip drawing/object runs; image changes are better handled by the final
        # document itself than by synthetic revision markup.
        if run.xpath(".//w:drawing | .//w:pict | .//w:object", namespaces=NS):
            continue
        rpr = run.find(w("rPr"))
        for child in run:
            if child.tag == w("t") and child.text:
                tokens.extend(tokenize_text(child.text, rpr))
            elif child.tag == w("tab"):
                tokens.append(Token("\t", copy.deepcopy(rpr) if rpr is not None else None))
            elif child.tag == w("br"):
                tokens.append(Token("\n", copy.deepcopy(rpr) if rpr is not None else None))
    if not tokens:
        text = paragraph_text(p)
        if text:
            tokens = tokenize_text(text)
    return tokens


def parse_docx_xml(docx_path: Path) -> tuple[etree._ElementTree, list[ParagraphInfo]]:
    with zipfile.ZipFile(docx_path) as zf:
        document_xml = zf.read("word/document.xml")
    tree = etree.fromstring(document_xml)
    paras: list[ParagraphInfo] = []
    for idx, p in enumerate(tree.xpath("//w:body/w:p", namespaces=NS)):
        text = paragraph_text(p)
        paras.append(
            ParagraphInfo(
                index=idx,
                element=p,
                text=text,
                tokens=paragraph_tokens(p),
                has_drawing=bool(p.xpath(".//w:drawing | .//w:pict | .//w:object", namespaces=NS)),
            )
        )
    return etree.ElementTree(tree), paras


def paragraph_similarity(old_text: str, new_text: str) -> float:
    a = normalize(old_text)
    b = normalize(new_text)
    if not a and not b:
        return 1.0
    if not a or not b:
        return 0.0
    if a == b:
        return 1.0
    word_a = set(re.findall(r"\w+", a, flags=re.UNICODE))
    word_b = set(re.findall(r"\w+", b, flags=re.UNICODE))
    jaccard = len(word_a & word_b) / max(1, len(word_a | word_b))
    seq = SequenceMatcher(None, a, b, autojunk=False).ratio()
    return 0.6 * seq + 0.4 * jaccard


def align_nonempty_paragraphs(old: list[ParagraphInfo], new: list[ParagraphInfo]) -> list[AlignStep]:
    old_nonempty = [p for p in old if normalize(p.text)]
    new_nonempty = [p for p in new if normalize(p.text)]

    old_norm = [normalize(p.text) for p in old_nonempty]
    new_norm = [normalize(p.text) for p in new_nonempty]
    sm = SequenceMatcher(None, old_norm, new_norm, autojunk=False)
    steps: list[AlignStep] = []

    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            for oi, nj in zip(range(i1, i2), range(j1, j2)):
                steps.append(AlignStep("match", old_nonempty[oi].index, new_nonempty[nj].index, 1.0))
        elif tag == "delete":
            for oi in range(i1, i2):
                steps.append(AlignStep("delete", old_nonempty[oi].index, None, 0.0))
        elif tag == "insert":
            for nj in range(j1, j2):
                steps.append(AlignStep("insert", None, new_nonempty[nj].index, 0.0))
        else:
            steps.extend(align_replace_block(old_nonempty[i1:i2], new_nonempty[j1:j2]))

    return steps


def align_replace_block(old_block: list[ParagraphInfo], new_block: list[ParagraphInfo]) -> list[AlignStep]:
    m, n = len(old_block), len(new_block)
    gap = -0.42
    dp = [[0.0] * (n + 1) for _ in range(m + 1)]
    back: list[list[str | None]] = [[None] * (n + 1) for _ in range(m + 1)]

    for i in range(1, m + 1):
        dp[i][0] = dp[i - 1][0] + gap
        back[i][0] = "delete"
    for j in range(1, n + 1):
        dp[0][j] = dp[0][j - 1] + gap
        back[0][j] = "insert"

    for i in range(1, m + 1):
        for j in range(1, n + 1):
            sim = paragraph_similarity(old_block[i - 1].text, new_block[j - 1].text)
            match_score = dp[i - 1][j - 1] + (2.2 * sim - 0.74)
            delete_score = dp[i - 1][j] + gap
            insert_score = dp[i][j - 1] + gap
            best = max(match_score, delete_score, insert_score)
            dp[i][j] = best
            if best == match_score:
                back[i][j] = "match"
            elif best == delete_score:
                back[i][j] = "delete"
            else:
                back[i][j] = "insert"

    rev: list[AlignStep] = []
    i, j = m, n
    while i or j:
        move = back[i][j]
        if move == "match":
            sim = paragraph_similarity(old_block[i - 1].text, new_block[j - 1].text)
            if sim < 0.18 and m != n:
                # Very weak pairings in uneven blocks are usually unrelated paragraphs.
                rev.append(AlignStep("insert", None, new_block[j - 1].index, 0.0))
                rev.append(AlignStep("delete", old_block[i - 1].index, None, 0.0))
            else:
                rev.append(AlignStep("match", old_block[i - 1].index, new_block[j - 1].index, sim))
            i -= 1
            j -= 1
        elif move == "delete":
            rev.append(AlignStep("delete", old_block[i - 1].index, None, 0.0))
            i -= 1
        elif move == "insert":
            rev.append(AlignStep("insert", None, new_block[j - 1].index, 0.0))
            j -= 1
        else:
            raise RuntimeError("paragraph alignment backtrace failed")
    return list(reversed(rev))


def same_rpr(a: etree._Element | None, b: etree._Element | None) -> bool:
    if a is None and b is None:
        return True
    if a is None or b is None:
        return False
    return etree.tostring(a) == etree.tostring(b)


def make_run(token: Token, deleted: bool = False) -> etree._Element:
    r = etree.Element(w("r"))
    if token.rpr is not None:
        r.append(copy.deepcopy(token.rpr))
    text_tag = w("delText") if deleted else w("t")
    t = etree.Element(text_tag)
    if token.text != token.text.strip() or token.text in {"\t", "\n"}:
        t.set(f"{{{XML_NS}}}space", "preserve")
    if token.text == "\t":
        # Revision-wrapped tabs are more robust as text in this context.
        t.text = "\t"
    elif token.text == "\n":
        t.text = "\n"
    else:
        t.text = token.text
    r.append(t)
    return r


def append_tokens(parent: etree._Element, tokens: list[Token], deleted: bool) -> None:
    for token in tokens:
        if token.text == "":
            continue
        parent.append(make_run(token, deleted=deleted))


def make_change(tag: str, tokens: list[Token], rev_id: RevisionId, author: str, date: str) -> etree._Element:
    elem = etree.Element(w(tag))
    elem.set(w("id"), rev_id.next())
    elem.set(w("author"), author)
    elem.set(w("date"), date)
    append_tokens(elem, tokens, deleted=(tag == "del"))
    return elem


def paragraph_revision_children(
    old_tokens: list[Token],
    new_tokens: list[Token],
    rev_id: RevisionId,
    author: str,
    date: str,
    force_insert: bool = False,
    force_delete: bool = False,
) -> list[etree._Element]:
    if force_insert:
        return [make_change("ins", new_tokens, rev_id, author, date)] if new_tokens else []
    if force_delete:
        return [make_change("del", old_tokens, rev_id, author, date)] if old_tokens else []

    old_vals = [t.text for t in old_tokens]
    new_vals = [t.text for t in new_tokens]
    sm = SequenceMatcher(None, old_vals, new_vals, autojunk=False)
    children: list[etree._Element] = []

    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == "equal":
            children.extend(make_run(tok, deleted=False) for tok in new_tokens[j1:j2])
        elif tag == "delete":
            children.append(make_change("del", old_tokens[i1:i2], rev_id, author, date))
        elif tag == "insert":
            children.append(make_change("ins", new_tokens[j1:j2], rev_id, author, date))
        elif tag == "replace":
            children.append(make_change("del", old_tokens[i1:i2], rev_id, author, date))
            children.append(make_change("ins", new_tokens[j1:j2], rev_id, author, date))
    return children


def replace_paragraph_content(p: etree._Element, children: list[etree._Element]) -> None:
    ppr = p.find(w("pPr"))
    sect = p.find(w("sectPr"))
    keep = [node for node in (ppr, sect) if node is not None]
    for child in list(p):
        p.remove(child)
    if ppr is not None:
        p.append(ppr)
    for child in children:
        p.append(child)
    if sect is not None:
        p.append(sect)


def make_deleted_paragraph(old_para: ParagraphInfo, rev_id: RevisionId, author: str, date: str) -> etree._Element:
    new_p = etree.Element(w("p"))
    old_ppr = old_para.element.find(w("pPr"))
    if old_ppr is not None:
        new_p.append(copy.deepcopy(old_ppr))
    children = paragraph_revision_children(
        old_para.tokens,
        [],
        rev_id,
        author,
        date,
        force_delete=True,
    )
    for child in children:
        new_p.append(child)
    return new_p


def add_track_revisions_setting(zip_dir: Path) -> None:
    settings_path = zip_dir / "word" / "settings.xml"
    if not settings_path.exists():
        return
    tree = etree.parse(str(settings_path))
    root = tree.getroot()
    if root.find(w("trackRevisions")) is None:
        root.insert(0, etree.Element(w("trackRevisions")))
    tree.write(str(settings_path), xml_declaration=True, encoding="UTF-8", standalone="yes")


def write_docx_from_dir(zip_dir: Path, out_path: Path) -> None:
    with zipfile.ZipFile(out_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for file_path in sorted(zip_dir.rglob("*")):
            if file_path.is_file():
                zf.write(file_path, file_path.relative_to(zip_dir).as_posix())


def build_redline(original: Path, revised: Path, out_path: Path, author: str) -> None:
    old_tree, old_paras = parse_docx_xml(original)
    new_tree, new_paras = parse_docx_xml(revised)
    old_by_index = {p.index: p for p in old_paras}
    new_by_index = {p.index: p for p in new_paras}
    steps = align_nonempty_paragraphs(old_paras, new_paras)

    rev_id = RevisionId()
    date = dt.datetime.now(dt.timezone.utc).replace(microsecond=0).isoformat()
    insertions_before_new: dict[int, list[etree._Element]] = {}
    insertions_after_body: list[etree._Element] = []
    matched_new: set[int] = set()
    body = new_tree.getroot().find(".//w:body", namespaces=NS)
    if body is None:
        raise RuntimeError("word/document.xml has no w:body")

    next_new_for_position: int | None = None
    for step in reversed(steps):
        if step.new_index is not None:
            next_new_for_position = step.new_index
        if step.kind == "delete" and step.old_index is not None:
            deleted_p = make_deleted_paragraph(old_by_index[step.old_index], rev_id, author, date)
            if next_new_for_position is None:
                insertions_after_body.append(deleted_p)
            else:
                insertions_before_new.setdefault(next_new_for_position, []).insert(0, deleted_p)

    for step in steps:
        if step.kind == "match" and step.old_index is not None and step.new_index is not None:
            old_p = old_by_index[step.old_index]
            new_p = new_by_index[step.new_index]
            if new_p.has_drawing and not normalize(new_p.text):
                continue
            children = paragraph_revision_children(old_p.tokens, new_p.tokens, rev_id, author, date)
            replace_paragraph_content(new_p.element, children)
            matched_new.add(step.new_index)
        elif step.kind == "insert" and step.new_index is not None:
            new_p = new_by_index[step.new_index]
            if new_p.has_drawing and not normalize(new_p.text):
                continue
            children = paragraph_revision_children(
                [],
                new_p.tokens,
                rev_id,
                author,
                date,
                force_insert=True,
            )
            replace_paragraph_content(new_p.element, children)
            matched_new.add(step.new_index)

    # Apply all deleted-only paragraphs at their ordered positions.
    for new_idx in sorted(insertions_before_new, reverse=True):
        anchor = new_by_index[new_idx].element
        parent = anchor.getparent()
        pos = parent.index(anchor)
        for deleted_p in reversed(insertions_before_new[new_idx]):
            parent.insert(pos, deleted_p)
    for deleted_p in insertions_after_body:
        sect = body.find(w("sectPr"))
        if sect is not None:
            body.insert(body.index(sect), deleted_p)
        else:
            body.append(deleted_p)

    with tempfile.TemporaryDirectory(prefix="word_level_redline_") as td:
        td_path = Path(td)
        with zipfile.ZipFile(revised) as zf:
            zf.extractall(td_path)
        document_path = td_path / "word" / "document.xml"
        new_tree.write(str(document_path), xml_declaration=True, encoding="UTF-8", standalone="yes")
        add_track_revisions_setting(td_path)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        write_docx_from_dir(td_path, out_path)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("original", type=Path)
    parser.add_argument("revised", type=Path)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--author", default="Codex word-level diff")
    args = parser.parse_args()

    build_redline(args.original, args.revised, args.out, args.author)
    print(args.out)


if __name__ == "__main__":
    main()
