## Register the uploaded 20260918 framework bundle, following the 20260915 process.
## This records GAZP11's dependency; it does not approve a future baseline.

library(dplyr)
library(tidyr)
library(readr)
library(DBI)
library(RPostgres)
library(glue)
library(digest)

read_secret_bom_safe <- function(path) {
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  if (length(bytes) >= 3L && identical(as.integer(bytes[1:3]), c(239L, 187L, 191L)))
    bytes <- bytes[-(1:3)]
  while (length(bytes) > 0L && tail(as.integer(bytes), 1L) %in% c(10L, 13L))
    bytes <- head(bytes, -1L)
  rawToChar(bytes)
}

framework_version <- "20260918_framework"
storage_bucket <- "import_framework"
processed_by <- "Nancy Shackelford"
processed_date <- as.Date("2026-09-22")
database <- "GRP"
receipt <- read_csv(file.path(
  "R", "import_code", "import_framework_import", "20260918_import_framework",
  "20260918_framework_upload_receipt.csv"
), show_col_types = FALSE)
framework_files <- c("prepare_functions.R", "build_functions.R", "import_registry.r",
                     "import_helper_functions.r", "sp_crosswalk.csv")
if (nrow(receipt) != 5L || !setequal(receipt$file_name, framework_files) ||
    anyDuplicated(receipt$file_name) || any(receipt$status_code != 200L) ||
    any(receipt$destination_path != paste(framework_version, receipt$file_name, sep = "/")))
  stop("The five-file framework upload receipt is incomplete or inconsistent.", call. = FALSE)
local_files <- file.path("R", "import_framework", framework_version, receipt$file_name)
if (any(!file.exists(local_files)) ||
    any(toupper(vapply(local_files, digest, character(1), algo = "sha256", file = TRUE)) != receipt$sha256))
  stop("Local framework files no longer match the uploaded receipt.", call. = FALSE)

artifacts <- tibble(
  file_name = framework_files,
  artifact_type = c(rep("transformation_code", 4), "mapping_table"),
  artifact_subtype = c("Prepare-stage functions", "Build-stage functions", "Import registry",
                       "Import helper functions", "Global species crosswalk"),
  file_extension = c(rep("r", 4), "csv"),
  source_layer = "shared import framework",
  workflow_stage = c("prepare/review", "build/validate", "build/validate",
                     "load/archive", "lookup/transform"),
  notes = c("GAZP11 prepare-stage dependency; future baseline status awaits review.",
            "Build-stage functions, identical to the 20260915 bundle.",
            "Schema and lookup registry, identical to the 20260915 bundle.",
            "Database and Storage helpers, identical to the 20260915 bundle.",
            "Shared species crosswalk, identical to the 20260915 bundle.")
) |>
  mutate(file_path_or_storage_key = paste(framework_version, file_name, sep = "/"))
source_file_list <- paste(artifacts$file_path_or_storage_key, collapse = ", ")

password <- read_secret_bom_safe(
  "C:/Users/nshack/OneDrive - University of Victoria/Documents/R/GRP/pword.csv"
)
con <- dbConnect(Postgres(), host = "aws-1-ca-central-1.pooler.supabase.com",
                 port = 6543, dbname = "postgres",
                 user = "postgres.rudybfqutvodkakgctpo", password = password,
                 sslmode = "require")
on.exit(dbDisconnect(con), add = TRUE)
existing <- dbGetQuery(con, glue_sql(
  "SELECT COUNT(*) n FROM grp.import_batch
   WHERE database={database} AND workflow_version={framework_version}", .con = con
))$n[[1]]
if (as.numeric(existing) != 0)
  stop("Framework version already documented; no rows written.", call. = FALSE)

dbBegin(con)
tryCatch({
  batch_id <- dbGetQuery(con, glue_sql(
    "INSERT INTO grp.import_batch
     (database,projectid,source_folder,source_file_list,workflow_version,processed_by,
      processed_date,pipeline_stage_start,pipeline_stage_end,notes)
     VALUES ({database},NULL,{paste0('Supabase Storage: ',storage_bucket,'/',framework_version)},
      {source_file_list},{framework_version},{processed_by},{processed_date},
      'Local shared import-framework files','Framework bundle archived and documented',
      'Exact framework dependency used for GAZP11 preparation; not designated the future active baseline.')
     RETURNING import_batchid", .con = con
  ))$import_batchid[[1]]

  import_project_id <- dbGetQuery(con, glue_sql(
    "INSERT INTO grp.import_project
     (import_batchid,database,projectid,contribution_type,contribution_period,
      documentation_tier,import_status,import_started_at,import_completed_at,is_current_version,notes)
     VALUES ({batch_id},{database},NULL,'reprocessing',
      'GAZP11 framework dependency archived September 2026','fully_reproducible','imported',
      CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,FALSE,
      'Non-project framework provenance record; projectid is intentionally NULL. Future baseline status awaits review.')
     RETURNING import_projectid", .con = con
  ))$import_projectid[[1]]

  artifact_rows <- artifacts |>
    mutate(import_projectid = import_project_id, import_batchid = batch_id,
           database = database, projectid = NA_integer_, storage_bucket = storage_bucket,
           created_by = processed_by, created_date = processed_date,
           loaded_at = Sys.time()) |>
    select(import_projectid, import_batchid, database, projectid, artifact_type,
           artifact_subtype, file_name, file_extension, file_path_or_storage_key,
           storage_bucket, source_layer, workflow_stage, created_by, created_date,
           loaded_at, notes)
  if (dbAppendTable(con, Id(schema = "grp", table = "import_artifact"), artifact_rows) != 5L)
    stop("Framework artifact insertion count did not reconcile.", call. = FALSE)

  steps <- tibble(
    step_order = 1:3,
    step_name = c("Assemble shared framework bundle", "Archive framework bundle",
                  "Register framework provenance"),
    step_description = c(
      "Collected the four R files and species crosswalk used by GAZP11 preparation.",
      "Uploaded and read-back verified all five files in the private import_framework Storage bucket.",
      "Recorded the bundle, artifacts, workflow steps, and relationships in GRP provenance tables."
    ),
    transformation_type = c("framework packaging", "artifact archival",
                            "provenance documentation"),
    software_or_language = c("R/filesystem", "R/Supabase Storage", "R/PostgreSQL"),
    notes = c("The dated bundle preserves GAZP11's exact prepare dependency.",
              "The upload receipt records SHA-256 and byte count for each object; no overwrite was used.",
              "This registration does not designate 20260918 as the future active baseline.")
  ) |>
    mutate(import_projectid = import_project_id, import_batchid = batch_id,
           database = database, projectid = NA_integer_) |>
    select(import_projectid, import_batchid, database, projectid, step_order,
           step_name, step_description, transformation_type, software_or_language, notes)
  if (dbAppendTable(con, Id(schema = "grp", table = "import_transformation_step"), steps) != 3L)
    stop("Framework step insertion count did not reconcile.", call. = FALSE)

  artifact_ids <- dbGetQuery(con, glue_sql(
    "SELECT import_artifactid,file_name FROM grp.import_artifact
     WHERE import_batchid={batch_id} AND import_projectid={import_project_id}", .con = con
  ))
  step_ids <- dbGetQuery(con, glue_sql(
    "SELECT import_transformation_stepid,step_order FROM grp.import_transformation_step
     WHERE import_batchid={batch_id} AND import_projectid={import_project_id}", .con = con
  ))
  links <- crossing(step_order = 1:3, file_name = framework_files) |>
    mutate(artifact_role = c("input", "output", "documentation")[step_order],
           notes = "Framework artifact and provenance step.") |>
    left_join(step_ids, by = "step_order") |>
    left_join(artifact_ids, by = "file_name") |>
    select(import_transformation_stepid, import_artifactid, artifact_role, notes)
  if (any(!complete.cases(links)) ||
      dbAppendTable(con, Id(schema = "grp", table = "import_transformation_step_artifact"),
                    links) != 15L)
    stop("Framework step-artifact links did not reconcile.", call. = FALSE)

  check <- dbGetQuery(con, glue_sql(
    "SELECT (SELECT COUNT(*) FROM grp.import_artifact WHERE import_batchid={batch_id}) artifacts,
            (SELECT COUNT(*) FROM grp.import_transformation_step WHERE import_batchid={batch_id}) steps,
            (SELECT COUNT(*) FROM grp.import_transformation_step_artifact a
             JOIN grp.import_transformation_step s
               ON s.import_transformation_stepid=a.import_transformation_stepid
             WHERE s.import_batchid={batch_id}) links", .con = con
  ))
  print(check)
  observed <- vapply(check[1, c("artifacts", "steps", "links")],
                     function(x) as.numeric(x[[1]]), numeric(1))
  print(observed)
  if (any(observed != c(artifacts = 5, steps = 3, links = 15)))
    stop("Framework post-insert audit failed.", call. = FALSE)
  dbCommit(con)
  message("20260918 framework provenance committed; import_batchid ", batch_id, ".")
}, error = function(e) {
  dbRollback(con)
  stop(e)
})
