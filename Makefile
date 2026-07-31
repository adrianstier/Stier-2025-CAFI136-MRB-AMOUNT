.PHONY: all analysis quick qa validate

all: analysis

analysis:
	./run_all.sh

quick:
	./run_all.sh --quick

qa:
	Rscript scripts/MRB/15.pre_submission_checks.R

validate:
	Rscript scripts/MRB/validate_pipeline.R
