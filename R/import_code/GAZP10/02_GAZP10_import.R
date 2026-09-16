### Prepare GAZP10 harmonized data for review before SQL build/commit
###
### This script intentionally stops at reviewable prepare-stage files. It does
### not connect to Supabase, allocate SQL identifiers, or write database rows.

library(dplyr)
library(readr)
library(readxl)
library(stringr)
library(tibble)

framework_version <- "20260915_framework"
framework_dir <- file.path("R", "import_framework", framework_version)
source(file.path(framework_dir, "prepare_functions.R"))

input_workbook <- file.path(
  "data", "harmonized", "GAZP", "GAZP10", "GAZP10_reprocessed.xlsx"
)
output_dir <- file.path("outputs", "import_review", "GAZP10", "prepare")

project_config <- list(
  database = "GAZP",
  projectid = 10L,
  date_received = as.Date("2018-04-12"),
  block_size = 17.6,
  block_units = "m2",
  child_area_type = "plot",
  route_other_treatment_to_notes = TRUE,
  project_note_append = paste(
    "Burn timing review: the associated publication reports controlled burns",
    "on October 19, 2012, after the 2012 peak-flowering vegetation census.",
    "All vegetation results in this import are therefore interpreted as pre-burn.",
    "Source treatment IDs 10_3 and 10_4 are retained as source-design burn groups,",
    "not as evidence that burning preceded an observation. The source workbook",
    "flags 13 plots for burning, while the publication reports 10 plots actually burned."
  )
)

harmonized <- read_harmonized_workbook(input_workbook)
validate_harmonized_identity(
  harmonized,
  expected_database = project_config$database,
  expected_projectid = project_config$projectid
)

prepared_treatments <- prepare_treatments(
  harmonized$treatments,
  route_other_treatment_to_notes = project_config$route_other_treatment_to_notes
)

prepared_areas <- prepare_spatial_areas(
  vegresults = harmonized$vegresults,
  prepared_treatments = prepared_treatments,
  block_size = project_config$block_size,
  block_units = project_config$block_units,
  child_area_type = project_config$child_area_type
)

prepared_area_treatments <- prepare_area_treatment_links(
  vegresults = harmonized$vegresults,
  prepared_treatments = prepared_treatments,
  areas = prepared_areas
)

prepared_vegresults <- prepare_vegresults(
  vegresults = harmonized$vegresults,
  timepoints = harmonized$timepoints,
  prepared_treatments = prepared_treatments,
  areas = prepared_areas
)

species_crosswalk <- read_csv(
  file.path(framework_dir, "sp_crosswalk.csv"),
  show_col_types = FALSE
)
species_inventory <- prepare_species_inventory(
  harmonized$vegresults,
  species_crosswalk
)

prepare_audit <- build_prepare_audit(
  source_vegresults = harmonized$vegresults,
  prepared_vegresults = prepared_vegresults,
  areas = prepared_areas,
  area_treatments = prepared_area_treatments,
  species_inventory = species_inventory
)

project_manifest <- tibble(
  database = project_config$database,
  projectid = project_config$projectid,
  type = str_to_lower(harmonized$study$studytype[[1]]),
  community = str_to_lower(harmonized$study$community[[1]]),
  reference = if_else(
    is.na(harmonized$study$refdata[[1]]),
    NA_character_,
    str_to_lower(as.character(harmonized$study$refdata[[1]]))
  ),
  input_workbook = input_workbook,
  date_received = project_config$date_received,
  source_project_notes = harmonized$study$notes[[1]],
  project_note_append = project_config$project_note_append,
  prepare_completed_at = Sys.time(),
  sql_write_performed = FALSE
)

prepared <- list(
  areas = prepared_areas,
  area_treatments = prepared_area_treatments,
  treatments = prepared_treatments,
  vegresults = prepared_vegresults,
  species = species_inventory,
  audit = prepare_audit
)

written_files <- write_prepare_review(prepared, output_dir)
write_csv(project_manifest, file.path(output_dir, "project_manifest.csv"), na = "")

blockers <- prepare_audit$summary |>
  filter(.data$status == "blocker")

print(prepare_audit$summary)
message("Prepared review files written to: ", output_dir)
message("No SQL connection was opened and no SQL write was performed.")

if (nrow(blockers) > 0L) {
  stop("GAZP10 prepare stage produced blocker audit results.", call. = FALSE)
}
