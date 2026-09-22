### Summarize the approved GAZP11 build; no database writes or uploads.

library(dplyr)
library(readr)
library(DBI)
library(RPostgres)
library(digest)

source(file.path("R", "import_framework", "20260915_framework", "build_functions.R"))
build_dir <- file.path("outputs", "import_review", "GAZP11", "build")
summary_dir <- file.path("outputs", "import_review", "GAZP11", "summarize")
dir.create(summary_dir, recursive = TRUE, showWarnings = FALSE)

approved_files <- list.files(build_dir, full.names = TRUE)
approved_files <- approved_files[file.info(approved_files)$isdir %in% FALSE]
approved_files <- approved_files[basename(approved_files) != "build_approval.csv"]
required_build_files <- c(
  "build_summary.csv", "build_validation_issues.csv", "staging_table_inventory.csv",
  "GAZP11_harmonized-SQL_crosswalk.csv", "GAZP11_species_crosswalk.csv"
)
if (!all(required_build_files %in% basename(approved_files))) {
  stop("The reviewed GAZP11 build package is incomplete.", call. = FALSE)
}
build_approval <- tibble(
  file = basename(approved_files),
  sha256 = toupper(vapply(approved_files, digest, character(1), algo = "sha256", file = TRUE)),
  approved = TRUE, reviewed_by = "user", reviewed_date = as.Date("2026-09-21"),
  review_note = "User approved the revised GAZP11 build package in the Codex conversation."
)

password <- read_secret_bom_safe(
  "C:/Users/nshack/OneDrive - University of Victoria/Documents/R/GRP/pword.csv"
)
con <- dbConnect(Postgres(), host = "aws-1-ca-central-1.pooler.supabase.com",
                 port = 6543, dbname = "postgres",
                 user = "postgres.rudybfqutvodkakgctpo", password = password,
                 sslmode = "require")
on.exit(dbDisconnect(con), add = TRUE)
live_state <- dbGetQuery(con, paste(
  "SELECT",
  "(SELECT COALESCE(MAX(areaid),0) FROM grp.area) max_areaid,",
  "(SELECT COALESCE(MAX(treatmentid),0) FROM grp.treatment) max_treatmentid,",
  "(SELECT COALESCE(MAX(locationid),0) FROM grp.location) max_locationid,",
  "(SELECT COALESCE(MAX(paperid),0) FROM grp.paper) max_paperid,",
  "(SELECT COALESCE(MAX(author_contributorid),0) FROM grp.author_contributor) max_authorid,",
  "(SELECT COALESCE(MAX(seed_mixid),0) FROM grp.seed_mix) max_seedmixid,",
  "(SELECT COALESCE(MAX(seedingid),0) FROM grp.seeding) max_seedingid,",
  "(SELECT COUNT(*) FROM grp.project WHERE database='GAZP' AND projectid=11) existing_project"
))
read_stage <- function(name) {
  read_csv(file.path(build_dir, paste0("stg_", name, ".csv")), show_col_types = FALSE)
}
expected_state <- tibble(
  id_type = c("area", "treatment", "location", "paper", "author", "seed_mix", "seeding"),
  expected_current_max = c(
    min(read_stage("area")$areaid) - 1L,
    min(read_stage("treatment")$treatmentid) - 1L,
    min(read_stage("location")$locationid) - 1L,
    min(read_stage("paper")$paperid) - 1L,
    min(read_stage("author_contributor")$author_contributorid) - 1L,
    min(read_stage("seed_mix")$seed_mixid) - 1L,
    min(read_stage("seeding")$seedingid) - 1L
  ),
  live_current_max = vapply(
    live_state[1, c("max_areaid", "max_treatmentid", "max_locationid", "max_paperid",
                    "max_authorid", "max_seedmixid", "max_seedingid")],
    function(x) as.numeric(x[[1]]), numeric(1)
  )
) |>
  mutate(status = if_else(expected_current_max == live_current_max, "pass", "blocker"))

commit_order <- c(
  "project", "project_data_accessibility", "location", "project_location", "site",
  "project_site", "author_contributor", "project_contributor", "project_vegmetric",
  "paper", "project_paper", "paper_author", "site_classification", "site_disturbance",
  "site_ref_ecosystem", "site_soil", "site_invasive", "area", "treatment",
  "area_treatment", "treatment_application", "treatment_cover_crop", "treatment_erosion",
  "treatment_fertilization", "treatment_grazer", "treatment_herbicide",
  "treatment_invasion", "treatment_irrigation", "treatment_material", "treatment_medium",
  "treatment_mowing", "treatment_prep", "seed_mix", "seeding", "seeding_pretreatment",
  "veg_result"
)
inventory <- read_csv(file.path(build_dir, "staging_table_inventory.csv"), show_col_types = FALSE)
if (!setequal(inventory$table, commit_order) || nrow(inventory) != length(commit_order)) {
  stop("Staging inventory does not match the complete GAZP10 commit-order contract.", call. = FALSE)
}
commit_preview <- tibble(table = commit_order, commit_order = seq_along(commit_order)) |>
  left_join(inventory, by = "table") |>
  mutate(rows = coalesce(rows, 0L), action = if_else(rows == 0L, "skip_zero_rows", "insert"))

issue_lines <- readLines(file.path(build_dir, "build_validation_issues.csv"), warn = FALSE)
build_summary <- read_csv(file.path(build_dir, "build_summary.csv"), show_col_types = FALSE)
get_count <- function(key) build_summary$value[match(key, build_summary$check)]
precommit_checks <- bind_rows(
  transmute(expected_state, check = paste0("id_drift_", id_type),
            value = live_current_max, status),
  tibble(check = "existing_GAZP11_project", value = as.numeric(live_state$existing_project[[1]]),
         status = if_else(live_state$existing_project[[1]] == 0L, "pass", "blocker")),
  tibble(check = "build_validation_issue_rows", value = as.numeric(max(length(issue_lines) - 1L, 0L)),
         status = if_else(length(issue_lines) <= 1L, "pass", "blocker")),
  tibble(check = "vegetation_rows_to_insert", value = get_count("veg_result_rows"),
         status = if_else(get_count("veg_result_rows") == 1220L &&
                            get_count("veg_rows_lost") == 0L, "pass", "blocker")),
  tibble(check = "area_treatment_rows_to_insert", value = get_count("area_treatment_rows"),
         status = if_else(get_count("area_treatment_rows") == 1566L, "pass", "blocker")),
  tibble(check = "seeding_rows_to_insert", value = get_count("seeding_rows"),
         status = if_else(get_count("seeding_rows") == 120L, "pass", "blocker"))
)

artifact_preview <- tibble::tribble(
  ~artifact_type, ~file_name, ~workflow_stage, ~notes,
  "raw_data", "NV_seedlings_edit.csv", "input", "Retained row-level seedling data CSV.",
  "raw_data", "NV_seedlings_edit.xlsx", "input", "Retained row-level seedling workbook used for reprocessing.",
  "raw_data", "NV_seedlings_relevant.csv", "input", "Retained relevant-subset seedling CSV.",
  "raw_data", "Rout.csv", "input", "Retained output from legacy processing.",
  "raw_data", "Species.csv", "input", "Retained legacy species table.",
  "transformation_code", "Processing.R", "input", "Legacy processing code retained in the source package.",
  "harmonized_data", "GAZP11.xlsx", "input", "Original harmonized workbook retained unchanged.",
  "harmonized_data", "GAZP11_reprocessed.xlsx", "input", "Reviewed harmonized workbook used for SQL preparation.",
  "transformation_code", "01_reprocess_GAZP11_vegresults.R", "preprocess", "Source-supported corrections and passive-count reversal.",
  "transformation_code", "02_GAZP11_import.R", "prepare", "Prepare-stage driver and project decisions.",
  "transformation_code", "03_GAZP11_build.R", "build", "SQL staging builder and live validation.",
  "transformation_code", "04_GAZP11_summarize.R", "summarize", "Build approval, ID-drift check, and commit preview.",
  "mapping_table", "GAZP11_harmonized-SQL_crosswalk.csv", "output", "Reviewed plot-to-treatment-event SQL mapping.",
  "mapping_table", "GAZP11_species_crosswalk.csv", "output", "Exact-code vegetation species mapping."
) |>
  mutate(
    artifact_subtype = case_when(
      artifact_type == "raw_data" ~ "GAZP11 source data",
      artifact_type == "harmonized_data" ~ "GAZP11 harmonized data",
      artifact_type == "transformation_code" & file_name == "Processing.R" ~
        "GAZP11 legacy source processing code",
      artifact_type == "transformation_code" ~ "GAZP11 import code",
      artifact_type == "mapping_table" ~ "GAZP11 crosswalk"
    ),
    file_extension = tolower(tools::file_ext(file_name)),
    file_path_or_storage_key = case_when(
      artifact_type == "raw_data" | file_name == "Processing.R" ~
        paste0("GAZP/GAZP11/source/", file_name),
      artifact_type == "harmonized_data" ~ paste0("GAZP/GAZP11/harmonized/", file_name),
      artifact_type == "transformation_code" ~ paste0("GAZP/GAZP11/code/", file_name),
      artifact_type == "mapping_table" ~ paste0("GAZP/GAZP11/crosswalks/", file_name)
    ),
    storage_bucket = "grp-import-artifacts",
    source_layer = case_when(
      artifact_type == "raw_data" ~ "retained original source data",
      file_name == "Processing.R" ~ "retained legacy processing code",
      artifact_type == "harmonized_data" ~ "legacy Excel database",
      artifact_type == "transformation_code" ~ "R transformation workflow",
      artifact_type == "mapping_table" ~ "reviewed SQL mapping output"
    ),
    created_by = "Nancy Shackelford", created_date = as.Date("2026-09-21")
  ) |>
  select(artifact_type, artifact_subtype, file_name, file_extension,
         file_path_or_storage_key, storage_bucket, source_layer, workflow_stage,
         created_by, created_date, notes)
if (anyDuplicated(artifact_preview$file_path_or_storage_key)) {
  stop("Duplicate artifact storage key in GAZP11 manifest.", call. = FALSE)
}
artifact_local_path <- function(type, name) {
  if (type == "raw_data" || name == "Processing.R")
    return(file.path("data", "source", "GAZP", "GAZP11", name))
  if (type == "harmonized_data")
    return(file.path("data", "harmonized", "GAZP", "GAZP11", name))
  if (type == "transformation_code") return(file.path("R", "import_code", "GAZP11", name))
  if (type == "mapping_table") return(file.path("crosswalk_tables", "GAZP", "GAZP11", name))
  NA_character_
}
missing_artifacts <- artifact_preview |>
  rowwise() |>
  mutate(local_path = artifact_local_path(artifact_type, file_name),
         exists = file.exists(local_path)) |>
  ungroup() |>
  filter(!exists)
if (nrow(missing_artifacts) > 0L) {
  stop("Missing artifact files: ", paste(missing_artifacts$file_name, collapse = ", "), call. = FALSE)
}

import_batch_preview <- tibble(
  database = "GAZP", projectid = 11L,
  source_folder = "Supabase Storage: grp-import-artifacts/GAZP/GAZP11",
  source_file_list = paste(artifact_preview$file_path_or_storage_key, collapse = ", "),
  workflow_version = "GAZP11_prepare-build-summarize_v1",
  processed_by = "Nancy Shackelford", processed_date = as.Date("2026-09-21"),
  pipeline_stage_start = "GAZP11 retained source and harmonized data",
  pipeline_stage_end = "GAZP11 SQL imported data",
  notes = paste(
    "Initial GAZP11 import with raw seedling counts, year-separated sampling areas,",
    "plot-level treatment-event links, exact-code species mapping, seed pretreatment,",
    "and row-loss auditing. Herbicide information is documented but not mapped to areas."
  )
)
import_project_preview <- tibble(
  database = "GAZP", projectid = 11L, contribution_type = "initial_import",
  contribution_period = "Vegetation monitoring in 2015 and 2016 following 2014 seeding.",
  documentation_tier = "transformation_documented", import_status = "pending_commit",
  is_current_version = TRUE,
  notes = paste(
    "Detailed row-level raw records are absent for 196 passive observations; their",
    "integer counts were recovered by reversing the recorded 16-fold standardization.",
    "The retained files do not identify herbicide-treated sampling areas or distinguish",
    "the two passive groups by herbicide status. The source publication PDF is not",
    "present in the local source package."
  )
)
transformation_steps_preview <- tibble::tribble(
  ~step_order, ~step_name, ~transformation_type, ~notes,
  1L, "Reprocess harmonized seedling results", "data transformation",
  "Reversed per-square-metre standardization to counts; restored active raw spatial and grazing labels; kept years separate because area alignment is uncertain. Passive counts use the reviewed 16-fold inverse without retained row-level raw records.",
  2L, "Prepare and audit harmonized data", "data preparation",
  "Created treatment-event keys and child-plot treatment links only; omitted false applicationmethod=none; retained herbicide mapping gap in project notes.",
  3L, "Build and validate SQL staging", "database staging",
  "Built all 36 applicable or explicitly empty target tables and checked vocabulary, references, exact species codes, and row preservation.",
  4L, "Summarize and approve commit plan", "review and approval",
  "Fingerprinted approved build files and checked current SQL identifier maxima without writing to SQL.",
  5L, "Commit transaction", "database load",
  "Pending separate final authorization; will recheck file hashes and ID drift before live insertion."
)

write_csv(build_approval, file.path(build_dir, "build_approval.csv"), na = "")
write_csv(build_approval, file.path(summary_dir, "build_approval.csv"), na = "")
write_csv(expected_state, file.path(summary_dir, "id_drift_check.csv"), na = "")
write_csv(commit_preview, file.path(summary_dir, "commit_preview.csv"), na = "")
write_csv(precommit_checks, file.path(summary_dir, "precommit_checks.csv"), na = "")
write_csv(import_batch_preview, file.path(summary_dir, "import_batch_preview.csv"), na = "")
write_csv(import_project_preview, file.path(summary_dir, "import_project_preview.csv"), na = "")
write_csv(artifact_preview, file.path(summary_dir, "import_artifact_preview.csv"), na = "")
write_csv(transformation_steps_preview,
          file.path(summary_dir, "transformation_steps_preview.csv"), na = "")

print(precommit_checks, n = Inf)
print(filter(commit_preview, rows > 0L), n = Inf)
if (any(precommit_checks$status == "blocker")) {
  stop("GAZP11 summarize stage found a blocker.", call. = FALSE)
}
message("Summarize review written to: ", summary_dir)
message("No SQL write or artifact upload was performed.")
