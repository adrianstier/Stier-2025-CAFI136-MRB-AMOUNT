# ==============================================================================
# silhouettes.R -- PhyloPic taxon silhouettes (vector art)
# Ported from Stier-CAFI-Pocillopora-2026 (paper/R/guilds.R) so the 136 figures
# use the SAME vector silhouettes. Cached Picture objects in
# assets/silhouettes/guild_silhouettes.rds (crab/shrimp/snail/fish/brittlestar).
# PhyloPic UUIDs (attribution CC0/CC-BY, see assets/silhouettes/ATTRIBUTION.txt):
#   crab   = 96523a56-068b-436f-a44f-ebf05605e700 (Carcinus)
#   shrimp = 0ea8e976-df74-4306-8d3d-a81093a287b3 (Caridea)
#   snail  = 06f288ac-a5dc-4404-bba7-02f2d9098b08 (Gastropoda)
#   fish   = 0ac52ecf-5bd5-4bbf-9cf2-35531546d04a (Pomacentridae)
# ==============================================================================

GUILD_SILHOUETTES <- local({
  cache <- here::here("assets", "silhouettes", "guild_silhouettes.rds")
  if (file.exists(cache)) readRDS(cache) else NULL
})

# Map a 136 taxon-group label (Fishes / Shrimps/Crabs / Snails, or singular) to a guild silhouette.
TAXON_TO_GUILD <- c(
  "Fishes" = "fish", "Fish" = "fish",
  "Shrimps/Crabs" = "crab", "Crustacean" = "crab", "Crustaceans" = "crab",
  "Snails" = "snail", "Snail" = "snail"
)

# Return the Picture silhouette for a taxon label (NULL if unavailable).
taxon_silhouette <- function(taxon) {
  if (is.null(GUILD_SILHOUETTES)) return(NULL)
  g <- TAXON_TO_GUILD[[as.character(taxon)]]
  if (is.null(g) || is.na(g)) return(NULL)
  GUILD_SILHOUETTES[[g]]
}

# ---- Robust taxon grouping from taxonomic CLASS (not fragile name-grepl) ----
# Actinopterygii -> Fishes, Malacostraca -> Shrimps/Crabs, Gastropoda -> Snails.
taxon_group_from_class <- function(class) {
  dplyr::case_when(
    class %in% c("Actinopterygii", "Teleostei") ~ "Fishes",
    class == "Malacostraca"                     ~ "Shrimps/Crabs",
    class == "Gastropoda"                       ~ "Snails",
    TRUE ~ NA_character_
  )
}

# Named vector: species -> taxon group, built from the CAFI data's `class` column.
cafi_taxon_lookup <- function(
    cafi_csv = here::here("data", "MRB Amount", "1. mrb_fe_cafi_summer_2021_v4_AP_updated_2024.csv")) {
  d  <- readr::read_csv(cafi_csv, show_col_types = FALSE)
  cc <- grep("^class$",   names(d), ignore.case = TRUE, value = TRUE)[1]
  sc <- grep("^species$", names(d), ignore.case = TRUE, value = TRUE)[1]
  d  <- dplyr::distinct(d, .species = d[[sc]], .class = d[[cc]])
  stats::setNames(taxon_group_from_class(d$.class), d$.species)
}
