# Archive and document the 2026-08-14 GAZP audit corrections in Supabase.
#
# This script is the final provenance step for corrections 01-03. It archives
# the correction code, successful correction evidence, historical taxonomic
# evidence, corrected global species mapping, and the GAZP5 project species
# crosswalk in the `grp-import-artifacts` Storage bucket. The GAZP5 crosswalk
# is stored at its canonical project location; the database-wide global species
# crosswalk before/after copies are stored in a dated species correction folder;
# all other evidence is stored in the dated GAZP correction folder. It then creates one
# dated correction batch, one import_project record for each affected project
# (GAZP1, GAZP2, GAZP3, and GAZP5), import_artifact records, transformation
# steps, and step-artifact links. The run datestamp is part of every Storage
# key and the workflow version so later correction rounds remain distinct.
#
# IMPORTANT: this script does NOT populate grp.project_object_crosswalk. The
# standalone GAZP5 species crosswalk is archived as a mapping artifact only.
#
# Safe operating model:
#   1. Leave `apply_changes <- FALSE` and source the whole file.
#   2. Review the manifest and preview report it writes.
#   3. Set `apply_changes <- TRUE` only after approval, then source it again.
# Storage objects are uploaded without overwrite. Existing objects are accepted
# only when their SHA-256 hashes match the local files. Database documentation
# is committed only after every object is present and verified. A completed
# workflow version is treated as success on rerun, not inserted a second time.

suppressPackageStartupMessages({
  library(tidyverse)
  library(DBI)
  library(RPostgres)
  library(glue)
  library(httr2)
})

# ---- Operator settings ------------------------------------------------------

apply_changes <- TRUE

correction_date <- as.Date("2026-08-14")
correction_datestamp <- format(correction_date, "%Y%m%d")
workflow_version <- paste0("GAZP_audit_corrections_", correction_datestamp, "_v1")
processed_by <- "Nancy Shackelford"

storage_bucket <- "grp-import-artifacts"
storage_root <- paste0("GAZP/corrections/", correction_datestamp)
supabase_url <- "https://rudybfqutvodkakgctpo.supabase.co"

password_path <- paste0(
  "C:/Users/nshack/OneDrive - University of Victoria/",
  "Documents/R/GRP/pword.csv"
)
service_key_path <- paste0(
  "C:/Users/nshack/OneDrive - University of Victoria/",
  "Documents/R/GRP/skey.csv"
)

report_root <- "docs/supabase_correction_reports"
preview_report_dir <- file.path(
  report_root,
  paste0(correction_datestamp, "_correction_artifact_registration_preview")
)

# These are the authoritative successful runs. Do not replace them with preview
# folders or with a newer run without also changing workflow_version.
timepoint_report_dir <- file.path(
  report_root,
  "20260814_112303_GAZP1_GAZP3_timepoint_month_day_apply"
)
taxonomy_report_dir <- file.path(
  report_root,
  "20260814_121118_GAZP5_Art_tri3_subspecies_apply"
)
species_crosswalk_report_dir <- file.path(
  report_root,
  "20260814_131511_GAZP5_species_crosswalk_build"
)

# ---- Small helpers ----------------------------------------------------------

read_secret <- function(path, label) {
  if (!file.exists(path)) {
    stop(label, " file not found: ", path, call. = FALSE)
  }
  value <- trimws(readLines(path, warn = FALSE, n = 1L))
  if (!nzchar(value)) stop(label, " file is empty.", call. = FALSE)
  value
}

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}

file_extension <- function(path) {
  ext <- tools::file_ext(path)
  ifelse(nzchar(ext), ext, NA_character_)
}

connect_to_supabase <- function() {
  DBI::dbConnect(
    RPostgres::Postgres(),
    host = "aws-1-ca-central-1.pooler.supabase.com",
    port = 6543,
    dbname = "postgres",
    user = "postgres.rudybfqutvodkakgctpo",
    password = read_secret(password_path, "Database password"),
    sslmode = "require"
  )
}

storage_endpoint <- function(destination_path) {
  paste0(
    supabase_url, "/storage/v1/object/", storage_bucket, "/",
    paste(vapply(strsplit(destination_path, "/", fixed = TRUE)[[1]],
      URLencode, character(1), reserved = TRUE
    ), collapse = "/")
  )
}

storage_get <- function(destination_path, service_key) {
  response <- httr2::request(storage_endpoint(destination_path)) |>
    httr2::req_url_query(
      correction_verification = paste0(
        format(Sys.time(), "%Y%m%d%H%M%OS6"), "_", sample.int(1e9, 1L)
      )
    ) |>
    httr2::req_headers(
      apikey = service_key,
      Authorization = paste("Bearer", service_key),
      "Cache-Control" = "no-cache, no-store, must-revalidate",
      Pragma = "no-cache"
    ) |>
    httr2::req_error(is_error = function(resp) FALSE) |>
    httr2::req_perform()

  status <- httr2::resp_status(response)
  body_text <- if (status >= 400L) httr2::resp_body_string(response) else ""
  # Supabase Storage currently reports a missing private object as either an
  # HTTP 404 or an HTTP 400 whose JSON body contains NoSuchKey / not_found.
  object_missing <- status == 404L ||
    (status == 400L && grepl(
      '"code"\\s*:\\s*"NoSuchKey"|"error"\\s*:\\s*"not_found"',
      body_text,
      perl = TRUE
    ))
  if (object_missing) return(list(exists = FALSE, hash = NA_character_))
  if (status >= 400L) {
    stop(
      "Could not inspect Storage object `", destination_path, "` (HTTP ",
      status, "): ", body_text, call. = FALSE
    )
  }

  list(
    exists = TRUE,
    hash = digest::digest(
      httr2::resp_body_raw(response),
      algo = "sha256",
      serialize = FALSE
    )
  )
}

storage_upload_immutable <- function(
    local_file,
    destination_path,
    service_key,
    replace_incomplete_registration_code = FALSE
) {
  current <- storage_get(destination_path, service_key)
  local_hash <- sha256_file(local_file)

  if (current$exists) {
    if (identical(tolower(current$hash), tolower(local_hash))) {
      return("ALREADY_PRESENT_AND_VERIFIED")
    }
    if (!replace_incomplete_registration_code) {
      stop(
        "Storage key already exists with different content: ",
        destination_path, call. = FALSE
      )
    }
  }

  response <- httr2::request(storage_endpoint(destination_path)) |>
    httr2::req_method("POST") |>
    httr2::req_headers(
      apikey = service_key,
      Authorization = paste("Bearer", service_key),
      "x-upsert" = ifelse(replace_incomplete_registration_code, "true", "false"),
      "Cache-Control" = "no-cache, no-store, must-revalidate"
    ) |>
    httr2::req_body_file(local_file) |>
    httr2::req_error(is_error = function(resp) FALSE) |>
    httr2::req_perform()

  if (httr2::resp_status(response) >= 400L) {
    stop(
      "Storage upload failed for `", destination_path, "` (HTTP ",
      httr2::resp_status(response), "): ",
      httr2::resp_body_string(response), call. = FALSE
    )
  }

  verified <- NULL
  for (attempt in seq_len(5L)) {
    verified <- storage_get(destination_path, service_key)
    if (
      verified$exists &&
        identical(tolower(verified$hash), tolower(local_hash))
    ) break
    if (attempt < 5L) Sys.sleep(attempt / 2)
  }
  if (!verified$exists || !identical(tolower(verified$hash), tolower(local_hash))) {
    stop("Post-upload hash verification failed: ", destination_path, call. = FALSE)
  }
  "UPLOADED_AND_VERIFIED"
}

# ---- Artifact plan ----------------------------------------------------------

artifact_spec <- tibble::tribble(
  ~artifact_key, ~local_file, ~storage_subdir, ~project_codes,
  ~artifact_type, ~artifact_subtype, ~source_layer, ~workflow_stage, ~notes,

  "correction_01_code",
  "R/supabase_correction_code/01_backfill_GAZP1_GAZP3_timepoint_month_day.R",
  "shared/code", list(c("GAZP1", "GAZP2", "GAZP3")),
  "transformation_code", "timepoint month/day backfill", "R correction workflow",
  "correction", "Preview-first code used to backfill authoritative monitoring month/day values.",

  "correction_01_report",
  file.path(timepoint_report_dir, "correction_report.md"),
  "shared/reports/timepoint_month_day", list(c("GAZP1", "GAZP2", "GAZP3")),
  "notes", "timepoint correction report", "database correction evidence",
  "validation", "Successful apply and verification report for the GAZP1-3 timepoint correction.",

  "correction_01_rows",
  file.path(timepoint_report_dir, "timepoint_month_day_correction_rows.csv"),
  "shared/reports/timepoint_month_day", list(c("GAZP1", "GAZP2", "GAZP3")),
  "processed_output", "timepoint corrected rows", "database correction evidence",
  "validation", "Row-level before/after evidence for the month/day correction.",

  "correction_01_summary",
  file.path(timepoint_report_dir, "timepoint_month_day_correction_summary.csv"),
  "shared/reports/timepoint_month_day", list(c("GAZP1", "GAZP2", "GAZP3")),
  "processed_output", "timepoint correction summary", "database correction evidence",
  "validation", "Project-level counts for the month/day correction.",

  "correction_02_code",
  "R/supabase_correction_code/02_correct_GAZP5_Art_tri3_subspecies.R",
  "GAZP5/code", list("GAZP5"),
  "transformation_code", "Art_tri3 taxonomy correction", "R correction workflow",
  "correction", "Code that created the corrected taxon and reassigned GAZP5 species references.",

  "correction_02_report",
  file.path(taxonomy_report_dir, "correction_report.md"),
  "GAZP5/reports/Art_tri3", list("GAZP5"),
  "notes", "Art_tri3 correction report", "database correction evidence",
  "validation", "Successful apply and verification report for the Art_tri3 correction.",

  "correction_02_summary",
  file.path(taxonomy_report_dir, "Art_tri3_correction_summary.csv"),
  "GAZP5/reports/Art_tri3", list("GAZP5"),
  "processed_output", "Art_tri3 correction summary", "database correction evidence",
  "validation", "Summary counts and identifiers for the Art_tri3 correction.",

  "global_species_crosswalk_before",
  file.path(
    taxonomy_report_dir,
    "20260605_sp_crosswalk_pre_Art_tri3_correction_20260814_121118.csv"
  ),
  "species/corrections/20260814", list("GAZP5"),
  "mapping_table", "global species crosswalk before correction",
  "repository mapping evidence", "input",
  paste(
    "Immutable pre-correction copy of the database-wide global species crosswalk.",
    "Stored in the species correction archive rather than under GAZP because its scope is the full database."
  ),

  "global_species_crosswalk_corrected",
  "crosswalk_tables/20260605_sp_crosswalk.csv",
  "species/corrections/20260814", list("GAZP5"),
  "mapping_table", "corrected global species crosswalk",
  "repository mapping evidence", "output",
  paste(
    "Database-wide global mapping after Art_tri3 was assigned speciesid 7171 / Art_tri_sub_tri.",
    "The repository copy remains the operational import lookup; this dated Storage copy is the discoverable correction record."
  ),

  "historical_species_vocabulary",
  "data/harmonized/GRP_archives/species_long_traits3-2021-October-26.xlsx",
  "GAZP5/evidence/species_crosswalk", list("GAZP5"),
  "metadata", "historical GRP species vocabulary", "GRP Excel archive",
  "input", "Historical taxonomy used to reconstruct project-specific species concepts.",

  "correction_03_code",
  "R/supabase_correction_code/03_reconstruct_GAZP5_species_crosswalk.R",
  "GAZP5/code", list("GAZP5"),
  "transformation_code", "GAZP5 species crosswalk build", "R correction workflow",
  "crosswalk generation", "Code used to reconstruct and validate the standalone project species crosswalk.",

  "GAZP5_species_crosswalk",
  "crosswalk_tables/GAZP/GAZP5/GAZP5_species_crosswalk.csv",
  "GAZP/GAZP5/crosswalks", list("GAZP5"),
  "mapping_table", "GAZP5 species crosswalk", "GAZP5 correction workflow",
  "output", paste(
    "Canonical standalone GAZP5 project species crosswalk preserving historical taxonomy",
    "and contextual reverse-mapping rules. Stored with the project's other crosswalks, not in the correction archive."
  ),

  "correction_03_report",
  file.path(species_crosswalk_report_dir, "GAZP5_species_crosswalk_build_report.md"),
  "GAZP5/reports/species_crosswalk", list("GAZP5"),
  "notes", "GAZP5 species crosswalk build report", "crosswalk build evidence",
  "validation", "Successful local build and verification report.",

  "correction_03_summary",
  file.path(species_crosswalk_report_dir, "GAZP5_species_crosswalk_summary.csv"),
  "GAZP5/reports/species_crosswalk", list("GAZP5"),
  "processed_output", "GAZP5 species crosswalk summary", "crosswalk build evidence",
  "validation", "Counts of source codes and reverse-mapping rules.",

  "correction_03_usage",
  file.path(species_crosswalk_report_dir, "GAZP5_source_species_usage_summary.csv"),
  "GAZP5/reports/species_crosswalk", list("GAZP5"),
  "processed_output", "GAZP5 source species usage", "crosswalk build evidence",
  "validation", "Source-table usage evidence for project species codes.",

  "correction_03_taxonomy_flags",
  file.path(species_crosswalk_report_dir, "GAZP5_species_taxonomy_flags_for_future_review.csv"),
  "GAZP5/reports/species_crosswalk", list("GAZP5"),
  "processed_output", "GAZP5 future taxonomy flags", "crosswalk build evidence",
  "validation", "Automated taxonomy flags; intentionally empty for the verified build.",

  "correction_03_non_taxonomic",
  file.path(species_crosswalk_report_dir, "GAZP5_non_taxonomic_species_placeholders.csv"),
  "GAZP5/reports/species_crosswalk", list("GAZP5"),
  "processed_output", "GAZP5 non-taxonomic placeholders", "crosswalk build evidence",
  "validation", "Documents mix_unknown as a non-taxonomic seed-mix placeholder.",

  "correction_04_code",
  "R/supabase_correction_code/04_archive_and_document_20260814_corrections.R",
  "shared/code", list(c("GAZP1", "GAZP2", "GAZP3", "GAZP5")),
  "transformation_code", "correction artifact registration", "R provenance workflow",
  "documentation", "Code used to archive these artifacts and register their provenance."
)

build_manifest <- function() {
  missing <- artifact_spec$local_file[!file.exists(artifact_spec$local_file)]
  if (length(missing) > 0L) {
    stop("Required artifacts missing:\n- ", paste(missing, collapse = "\n- "), call. = FALSE)
  }

  duplicate_keys <- artifact_spec$artifact_key[duplicated(artifact_spec$artifact_key)]
  if (length(duplicate_keys) > 0L) {
    stop("Duplicate artifact keys: ", paste(duplicate_keys, collapse = ", "), call. = FALSE)
  }

  artifact_spec |>
    mutate(
      # tribble cells use list(...) to hold one or several project codes;
      # unwrap that cell-level list before previewing or joining to projects.
      project_codes = map(.data$project_codes, ~ as.character(.x[[1]])),
      file_name = basename(.data$local_file),
      file_extension = file_extension(.data$local_file),
      storage_key = case_when(
        .data$artifact_key == "GAZP5_species_crosswalk" ~
          paste(.data$storage_subdir, .data$file_name, sep = "/"),
        .data$artifact_key %in% c(
          "global_species_crosswalk_before",
          "global_species_crosswalk_corrected"
        ) ~ paste(.data$storage_subdir, .data$file_name, sep = "/"),
        TRUE ~ paste(storage_root, .data$storage_subdir, .data$file_name, sep = "/")
      ),
      file_hash = map_chr(.data$local_file, sha256_file),
      file_size_bytes = file.info(.data$local_file)$size
    )
}

validate_source_outcomes <- function() {
  required_text <- setNames(
    c(
      "COMMITTED_AND_VERIFIED",
      "DATABASE_COMMITTED_AND_VERIFIED",
      "LOCAL_BUILD_WRITTEN_AND_VERIFIED"
    ),
    c(
      file.path(timepoint_report_dir, "correction_report.md"),
      file.path(taxonomy_report_dir, "correction_report.md"),
      file.path(species_crosswalk_report_dir, "GAZP5_species_crosswalk_build_report.md")
    )
  )

  walk2(names(required_text), required_text, function(path, marker) {
    contents <- paste(readLines(path, warn = FALSE), collapse = "\n")
    if (!grepl(marker, contents, fixed = TRUE)) {
      stop("Required success marker `", marker, "` missing from ", path, call. = FALSE)
    }
  })
}

# ---- Database plan ----------------------------------------------------------

project_plan <- tibble::tribble(
  ~project_code, ~projectid, ~contribution_period, ~notes,
  "GAZP1", 1L, "Post-import audit correction completed 2026-08-14",
  "Backfilled 625 monitoring month values from the authoritative harmonized timepoints sheet.",
  "GAZP2", 2L, "Post-import audit correction completed 2026-08-14",
  "Backfilled 576 monitoring month values from the authoritative harmonized timepoints sheet.",
  "GAZP3", 3L, "Post-import audit correction completed 2026-08-14",
  "Backfilled 81 monitoring month values from the authoritative harmonized timepoints sheet.",
  "GAZP5", 5L, "Post-import audit correction completed 2026-08-14",
  paste(
    "Corrected Art_tri3 to speciesid 7171 / Art_tri_sub_tri and built a",
    "standalone project species crosswalk preserving historical concepts."
  )
)

step_plan <- bind_rows(
  crossing(project_code = c("GAZP1", "GAZP2", "GAZP3"), projectid = c(1L, 2L, 3L)) |>
    filter(substr(.data$project_code, 5, 5) == as.character(.data$projectid)) |>
    crossing(tibble::tribble(
      ~step_order, ~step_name, ~step_description, ~transformation_type,
      ~software_or_language, ~notes,
      1L, "Recover authoritative monitoring dates",
      "Read project timepoints and match them to live vegetation-result records.",
      "data reconciliation", "R/PostgreSQL", "Month and day were assessed independently.",
      2L, "Apply timepoint correction",
      "Update monitoring month/day fields after row-level validation.",
      "database correction", "R/PostgreSQL", "No source day values were available; months were corrected.",
      3L, "Validate corrected records",
      "Re-read corrected rows and verify values and project counts.",
      "data validation", "R/PostgreSQL", "Correction reports retain row-level evidence.",
      4L, "Archive and register correction provenance",
      "Archive dated artifacts and register the correction in import tracking tables.",
      "artifact archival and provenance", "R/Supabase", "No project_object_crosswalk rows are created."
    )),
  tibble::tribble(
    ~project_code, ~projectid, ~step_order, ~step_name, ~step_description,
    ~transformation_type, ~software_or_language, ~notes,
    "GAZP5", 5L, 1L, "Review historical and current taxonomy",
    "Compare historical project codes with harmonized mappings and live Supabase taxonomy.",
    "taxonomy reconciliation", "R/PostgreSQL", "Historical nuance remains project-specific where appropriate.",
    "GAZP5", 5L, 2L, "Apply Art_tri3 taxonomy correction",
    "Create the tridentata subspecies taxon and reassign GAZP5 vegetation and seeding records.",
    "database correction", "R/PostgreSQL", "Canonical code: Art_tri_sub_tri; speciesid: 7171.",
    "GAZP5", 5L, 3L, "Build project species crosswalk",
    "Construct contextual reverse mappings from Supabase records to historical GAZP5 species codes.",
    "crosswalk generation", "R", "Pse_rup/Pse_rup1 use speciesid plus seeding rate and unit.",
    "GAZP5", 5L, 4L, "Validate taxonomy and crosswalk",
    "Verify corrected references, mapping completeness, taxonomy flags, and non-taxonomic placeholders.",
    "data validation", "R/PostgreSQL", "mix_unknown is documented but excluded from taxonomy.",
    "GAZP5", 5L, 5L, "Archive and register correction provenance",
    "Archive dated artifacts and register the correction in import tracking tables.",
    "artifact archival and provenance", "R/Supabase", "No project_object_crosswalk rows are created."
  )
)

artifact_step_plan <- tibble::tribble(
  ~artifact_key, ~project_code, ~step_order, ~artifact_role,
  "correction_01_code", "GAZP1", 2L, "code",
  "correction_01_code", "GAZP2", 2L, "code",
  "correction_01_code", "GAZP3", 2L, "code",
  "correction_01_report", "GAZP1", 3L, "documentation",
  "correction_01_report", "GAZP2", 3L, "documentation",
  "correction_01_report", "GAZP3", 3L, "documentation",
  "correction_01_rows", "GAZP1", 3L, "output",
  "correction_01_rows", "GAZP2", 3L, "output",
  "correction_01_rows", "GAZP3", 3L, "output",
  "correction_01_summary", "GAZP1", 3L, "output",
  "correction_01_summary", "GAZP2", 3L, "output",
  "correction_01_summary", "GAZP3", 3L, "output",
  "correction_02_code", "GAZP5", 2L, "code",
  "correction_02_report", "GAZP5", 4L, "documentation",
  "correction_02_summary", "GAZP5", 4L, "output",
  "global_species_crosswalk_before", "GAZP5", 1L, "input",
  "global_species_crosswalk_corrected", "GAZP5", 2L, "mapping",
  "historical_species_vocabulary", "GAZP5", 1L, "lookup",
  "correction_03_code", "GAZP5", 3L, "code",
  "GAZP5_species_crosswalk", "GAZP5", 3L, "mapping",
  "correction_03_report", "GAZP5", 4L, "documentation",
  "correction_03_summary", "GAZP5", 4L, "output",
  "correction_03_usage", "GAZP5", 4L, "output",
  "correction_03_taxonomy_flags", "GAZP5", 4L, "output",
  "correction_03_non_taxonomic", "GAZP5", 4L, "output",
  "correction_04_code", "GAZP1", 4L, "code",
  "correction_04_code", "GAZP2", 4L, "code",
  "correction_04_code", "GAZP3", 4L, "code",
  "correction_04_code", "GAZP5", 5L, "code"
)

validate_live_schema <- function(con) {
  required_tables <- c(
    "project", "import_batch", "import_project", "import_artifact",
    "import_transformation_step", "import_transformation_step_artifact"
  )
  present <- DBI::dbGetQuery(con, "
    SELECT table_name
    FROM information_schema.tables
    WHERE table_schema = 'grp'
  ")$table_name
  missing <- setdiff(required_tables, present)
  if (length(missing) > 0L) {
    stop("Required grp tables missing: ", paste(missing, collapse = ", "), call. = FALSE)
  }

  projects <- DBI::dbGetQuery(con, "
    SELECT database, projectid
    FROM grp.project
    WHERE database = 'GAZP' AND projectid IN (1, 2, 3, 5)
  ")
  if (!setequal(projects$projectid, project_plan$projectid)) {
    stop("Live grp.project does not contain exactly GAZP project IDs 1, 2, 3, and 5.", call. = FALSE)
  }

  DBI::dbGetQuery(
    con,
    glue::glue_sql(
      "SELECT import_batchid FROM grp.import_batch WHERE workflow_version = {workflow_version}",
      .con = con
    )
  )
}

write_preview_report <- function(manifest, existing_batch) {
  dir.create(preview_report_dir, recursive = TRUE, showWarnings = FALSE)

  readr::write_csv(
    manifest |>
      select(
        artifact_key, local_file, storage_key, file_hash, file_size_bytes,
        artifact_type, artifact_subtype, project_codes
      ) |>
      mutate(project_codes = map_chr(.data$project_codes, paste, collapse = ";")),
    file.path(preview_report_dir, "artifact_manifest.csv"),
    na = ""
  )
  readr::write_csv(project_plan, file.path(preview_report_dir, "project_plan.csv"), na = "")
  readr::write_csv(step_plan, file.path(preview_report_dir, "transformation_step_plan.csv"), na = "")
  readr::write_csv(artifact_step_plan, file.path(preview_report_dir, "step_artifact_link_plan.csv"), na = "")

  report <- c(
    "# 2026-08-14 correction archival and registration plan",
    "",
    paste0("Workflow version: `", workflow_version, "`"),
    paste0("Primary correction Storage root: `", storage_bucket, "/", storage_root, "`"),
    paste0(
      "Canonical GAZP5 crosswalk: `", storage_bucket,
      "/GAZP/GAZP5/crosswalks/GAZP5_species_crosswalk.csv`"
    ),
    paste0(
      "Global species correction archive: `", storage_bucket,
      "/species/corrections/", correction_datestamp, "/`"
    ),
    paste0("Artifacts: ", nrow(manifest)),
    paste0("Affected projects: ", paste(project_plan$project_code, collapse = ", ")),
    paste0("Existing matching batches: ", nrow(existing_batch)),
    paste0("Mode: `", if (apply_changes) "APPLY" else "PREVIEW", "`"),
    "",
    "No grp.project_object_crosswalk rows are planned or written."
  )
  writeLines(report, file.path(preview_report_dir, "registration_plan.md"), useBytes = TRUE)
}

# ---- Apply ------------------------------------------------------------------

register_documentation <- function(con, manifest) {
  DBI::dbBegin(con)
  committed <- FALSE
  on.exit(if (!committed && DBI::dbIsValid(con)) DBI::dbRollback(con), add = TRUE)

  existing <- DBI::dbGetQuery(
    con,
    glue::glue_sql(
      "SELECT import_batchid FROM grp.import_batch WHERE workflow_version = {workflow_version} FOR UPDATE",
      .con = con
    )
  )
  if (nrow(existing) > 0L) {
    DBI::dbRollback(con)
    committed <- TRUE
    message("Documentation already exists for ", workflow_version, ". No rows inserted.")
    return(existing$import_batchid[[1]])
  }

  source_file_list <- paste(sort(unique(manifest$storage_key)), collapse = ", ")
  batch_id <- DBI::dbGetQuery(
    con,
    glue::glue_sql("
      INSERT INTO grp.import_batch (
        database, projectid, source_folder, source_file_list,
        pipeline_stage_start, pipeline_stage_end, processed_by,
        processed_date, workflow_version, notes
      ) VALUES (
        'GAZP', NULL, {paste0('Supabase Storage: ', storage_bucket, '/', storage_root)},
        {source_file_list}, 'Post-import Supabase audit',
        'Corrected and provenance-documented Supabase data', {processed_by},
        {correction_date}, {workflow_version},
        'Dated correction batch for GAZP1-3 monitoring months and GAZP5 taxonomy/species crosswalk work. Does not populate project_object_crosswalk.'
      ) RETURNING import_batchid
    ", .con = con)
  )$import_batchid[[1]]

  import_projects <- map_dfr(seq_len(nrow(project_plan)), function(i) {
    row <- project_plan[i, ]
    id <- DBI::dbGetQuery(
      con,
      glue::glue_sql("
        INSERT INTO grp.import_project (
          import_batchid, database, projectid,
          contribution_type, contribution_period, documentation_tier,
          import_status, import_started_at, import_completed_at,
          is_current_version, notes
        ) VALUES (
          {batch_id}, 'GAZP', {row$projectid},
          'correction', {row$contribution_period}, 'fully_reproducible',
          'validated', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, TRUE, {row$notes}
        ) RETURNING import_projectid
      ", .con = con)
    )$import_projectid[[1]]
    tibble(project_code = row$project_code, projectid = row$projectid, import_projectid = id)
  })

  artifact_rows <- manifest |>
    select(-project_codes) |>
    crossing(import_projects) |>
    inner_join(
      manifest |>
        select(.data$artifact_key, .data$project_codes) |>
        unnest(.data$project_codes) |>
        rename(project_code = .data$project_codes),
      by = c("artifact_key", "project_code"), relationship = "many-to-many"
    ) |>
    transmute(
      import_projectid, import_batchid = batch_id, database = "GAZP", projectid,
      artifact_key, artifact_type, artifact_subtype, file_name, file_extension,
      file_path_or_storage_key = storage_key, storage_bucket,
      file_hash, source_layer, workflow_stage, created_by = processed_by,
      created_date = correction_date, loaded_at = Sys.time(), notes
    )

  DBI::dbWriteTable(
    con, DBI::Id(schema = "grp", table = "import_artifact"),
    artifact_rows |> select(-.data$artifact_key), append = TRUE, row.names = FALSE
  )

  artifact_ids <- DBI::dbGetQuery(
    con,
    glue::glue_sql("
      SELECT import_artifactid, import_projectid, file_path_or_storage_key
      FROM grp.import_artifact WHERE import_batchid = {batch_id}
    ", .con = con)
  ) |>
    inner_join(
      artifact_rows |>
        select(.data$artifact_key, .data$import_projectid, .data$file_path_or_storage_key),
      by = c("import_projectid", "file_path_or_storage_key")
    )

  steps_to_write <- step_plan |>
    inner_join(import_projects, by = c("project_code", "projectid")) |>
    transmute(
      import_projectid, import_batchid = batch_id, database = "GAZP", projectid,
      step_order, step_name, step_description, transformation_type,
      software_or_language, notes
    )
  DBI::dbWriteTable(
    con, DBI::Id(schema = "grp", table = "import_transformation_step"),
    steps_to_write, append = TRUE, row.names = FALSE
  )

  step_ids <- DBI::dbGetQuery(
    con,
    glue::glue_sql("
      SELECT import_transformation_stepid, import_projectid, step_order
      FROM grp.import_transformation_step WHERE import_batchid = {batch_id}
    ", .con = con)
  ) |>
    inner_join(import_projects, by = "import_projectid")

  links <- artifact_step_plan |>
    inner_join(step_ids, by = c("project_code", "step_order")) |>
    inner_join(
      artifact_ids,
      by = c("artifact_key", "import_projectid"),
      relationship = "many-to-one"
    ) |>
    transmute(
      import_transformation_stepid, import_artifactid, artifact_role,
      notes = paste0("Artifact `", artifact_key, "` supports this correction step.")
    )

  if (nrow(links) != nrow(artifact_step_plan)) {
    stop("Not all planned step-artifact links resolved.", call. = FALSE)
  }
  DBI::dbWriteTable(
    con, DBI::Id(schema = "grp", table = "import_transformation_step_artifact"),
    links, append = TRUE, row.names = FALSE
  )

  # Deliberate safeguard for the deferred design work.
  poc_rows <- DBI::dbGetQuery(
    con,
    glue::glue_sql("
      SELECT COUNT(*)::integer AS n
      FROM grp.project_object_crosswalk WHERE import_projectid IN ({import_projects$import_projectid*})
    ", .con = con)
  )$n[[1]]
  if (poc_rows != 0L) stop("Unexpected project_object_crosswalk rows detected.", call. = FALSE)

  DBI::dbCommit(con)
  committed <- TRUE
  batch_id
}

run_correction_artifact_registration <- function() {
  message("Validating completed correction evidence ...")
  validate_source_outcomes()
  manifest <- build_manifest()

  con <- connect_to_supabase()
  on.exit(if (DBI::dbIsValid(con)) DBI::dbDisconnect(con), add = TRUE)
  existing_batch <- validate_live_schema(con)
  write_preview_report(manifest, existing_batch)

  print(
    manifest |>
      transmute(
        artifact_key, projects = map_chr(project_codes, paste, collapse = ";"),
        size_bytes = file_size_bytes, storage_key
      ),
    n = Inf
  )

  if (!apply_changes) {
    message("PREVIEW ONLY: no Storage objects or database rows were created.")
    message("Preview report written to: ", preview_report_dir)
    return(invisible(list(manifest = manifest, existing_batch = existing_batch)))
  }

  if (nrow(existing_batch) > 0L) {
    message("Workflow already documented as import_batchid ", existing_batch$import_batchid[[1]], ".")
    return(invisible(list(
      manifest = manifest,
      import_batchid = existing_batch$import_batchid[[1]],
      outcome = "ALREADY_DOCUMENTED"
    )))
  }

  service_key <- read_secret(service_key_path, "Supabase service key")
  message("Uploading and verifying ", nrow(manifest), " unique Storage artifacts ...")
  upload_results <- manifest |>
    mutate(
      upload_status = pmap_chr(
        list(.data$local_file, .data$storage_key, .data$artifact_key),
        function(local_file, storage_key, artifact_key) {
          storage_upload_immutable(
            local_file = local_file,
            destination_path = storage_key,
            service_key = service_key,
            # The first apply uploaded this script before the documentation
            # transaction exposed a live-schema mismatch. Until a batch exists,
            # replace only this self-documenting code file with the repaired copy.
            replace_incomplete_registration_code =
              identical(artifact_key, "correction_04_code")
          )
        }
      )
    )
  print(upload_results |> count(.data$upload_status))

  message("Registering correction provenance in a database transaction ...")
  batch_id <- register_documentation(con, manifest)

  verification <- DBI::dbGetQuery(
    con,
    glue::glue_sql("
      SELECT
        b.import_batchid,
        COUNT(DISTINCT p.import_projectid)::integer AS project_records,
        COUNT(DISTINCT a.import_artifactid)::integer AS artifact_records,
        COUNT(DISTINCT s.import_transformation_stepid)::integer AS step_records,
        COUNT(DISTINCT l.import_transformation_step_artifactid)::integer AS link_records
      FROM grp.import_batch b
      JOIN grp.import_project p ON p.import_batchid = b.import_batchid
      LEFT JOIN grp.import_artifact a ON a.import_batchid = b.import_batchid
      LEFT JOIN grp.import_transformation_step s ON s.import_batchid = b.import_batchid
      LEFT JOIN grp.import_transformation_step_artifact l
        ON l.import_transformation_stepid = s.import_transformation_stepid
      WHERE b.import_batchid = {batch_id}
      GROUP BY b.import_batchid
    ", .con = con)
  )
  print(verification)

  message("COMPLETE: Storage artifacts verified and correction provenance registered.")
  invisible(list(
    manifest = upload_results,
    import_batchid = batch_id,
    verification = verification,
    outcome = "STORAGE_AND_DOCUMENTATION_VERIFIED"
  ))
}

GAZP_correction_registration <- run_correction_artifact_registration()
