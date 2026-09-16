## Register the versioned GRP import-framework bundle in the import
## documentation tables. The bundle is shared across imports, so projectid is
## intentionally NULL rather than being assigned to a particular project.

library(tidyverse)
library(DBI)
library(RPostgres)
library(glue)

password <- readLines(
  "C:\\Users\\nshack\\OneDrive - University of Victoria\\Documents\\R\\GRP\\pword.csv",
  warn = FALSE
)

con <- dbConnect(
  Postgres(),
  host = "aws-1-ca-central-1.pooler.supabase.com",
  port = 6543,
  dbname = "postgres",
  user = "postgres.rudybfqutvodkakgctpo",
  password = password,
  sslmode = "require"
)

database <- "GRP"
projectid <- NA_integer_
framework_version <- "20260903_framework"
storage_bucket <- "import_framework"
storage_folder <- framework_version
processed_by <- "Nancy Shackelford"
processed_date <- as.Date("2026-09-03")

artifacts <- tibble::tribble(
  ~artifact_type, ~artifact_subtype, ~file_name, ~file_extension, ~source_layer, ~workflow_stage, ~notes,
  "transformation_code", "Import registry", "20260612_import_registry.r", "r",
  "shared import framework", "stage/validate",
  "Builds the schema-constraint and lookup-table registry used to validate staged import tables.",
  "transformation_code", "Import helper functions", "20260620_import_helper_functions.r", "r",
  "shared import framework", "transform/load/archive",
  "Reusable helper functions for database loading, validation, identifier handling, and Supabase Storage uploads.",
  "transformation_code", "Species crosswalk creation", "20260825_species_crosswalk_creation.R", "R",
  "shared import framework", "transform/validate",
  "Reusable species-resolution workflow for inventorying project taxa, applying reviewed mappings, and identifying unresolved or ambiguous mappings.",
  "mapping_table", "Global species crosswalk", "20260605_sp_crosswalk.csv", "csv",
  "shared import framework", "lookup/transform",
  "Shared source-to-accepted-species crosswalk used by import workflows for taxonomic standardization.",
  "mapping_table", "Global cultivar crosswalk", "cultivar_crosswalk.csv", "csv",
  "shared import framework", "lookup/transform",
  "Shared cultivar crosswalk used by import workflows to standardize cultivar names and related identifiers."
) |>
  mutate(
    file_path_or_storage_key = paste(
      storage_folder,
      file_name,
      sep = "/"
    )
  )

source_file_list <- paste(
  artifacts$file_path_or_storage_key,
  collapse = ", "
)

tryCatch(
  {
    dbBegin(con)

    batch_id <- dbGetQuery(
      con,
      glue_sql("
        INSERT INTO grp.import_batch (
          database,
          projectid,
          source_folder,
          source_file_list,
          workflow_version,
          processed_by,
          processed_date,
          pipeline_stage_start,
          pipeline_stage_end,
          notes
        )
        VALUES (
          {database},
          NULL,
          {paste0('Supabase Storage: ', storage_bucket, '/', storage_folder)},
          {source_file_list},
          {framework_version},
          {processed_by},
          {processed_date},
          'Local shared import-framework files',
          'Versioned shared import-framework bundle archived and documented',
          'Archives a reusable, versioned dependency bundle shared by future GRP database imports.'
        )
        RETURNING import_batchid;
      ", .con = con)
    )$import_batchid

    import_project_id <- dbGetQuery(
      con,
      glue_sql("
        INSERT INTO grp.import_project (
          import_batchid,
          database,
          projectid,
          contribution_type,
          contribution_period,
          documentation_tier,
          import_status,
          import_started_at,
          import_completed_at,
          is_current_version,
          notes
        )
        VALUES (
          {batch_id},
          {database},
          NULL,
          'reprocessing',
          'Shared framework version archived 2026-09-03',
          'fully_reproducible',
          'imported',
          CURRENT_TIMESTAMP,
          CURRENT_TIMESTAMP,
          TRUE,
          'Non-project provenance record for shared import code and crosswalk dependencies; projectid is intentionally NULL.'
        )
        RETURNING import_projectid;
      ", .con = con)
    )$import_projectid

    artifacts_to_write <- artifacts |>
      mutate(
        import_projectid = import_project_id,
        import_batchid = batch_id,
        database = database,
        projectid = projectid,
        storage_bucket = storage_bucket,
        created_by = processed_by,
        created_date = processed_date,
        loaded_at = Sys.time()
      ) |>
      select(
        import_projectid,
        import_batchid,
        database,
        projectid,
        artifact_type,
        artifact_subtype,
        file_name,
        file_extension,
        file_path_or_storage_key,
        storage_bucket,
        source_layer,
        workflow_stage,
        created_by,
        created_date,
        loaded_at,
        notes
      )

    dbWriteTable(
      con,
      Id(schema = "grp", table = "import_artifact"),
      artifacts_to_write,
      append = TRUE,
      row.names = FALSE
    )

    steps <- tibble::tribble(
      ~step_order, ~step_name, ~step_description, ~transformation_type, ~software_or_language, ~notes,
      1L, "Assemble shared framework bundle",
      "Collected the three reusable R code files and two overarching crosswalk tables into a dated, versioned local bundle.",
      "framework packaging", "R/filesystem",
      "The dated directory preserves the exact dependency versions used by import workflows.",
      2L, "Archive framework bundle",
      "Uploaded the five framework files to the private import_framework Supabase Storage bucket under the dated folder.",
      "artifact archival", "R/Supabase Storage",
      "Uploads use upsert semantics within this exact framework version.",
      3L, "Register framework provenance",
      "Recorded the bundle, its five artifacts, and their workflow relationships in the GRP import documentation tables.",
      "provenance documentation", "R/PostgreSQL",
      "The documentation uses a null projectid because these dependencies are shared across projects."
    )

    steps_to_write <- steps |>
      mutate(
        import_projectid = import_project_id,
        import_batchid = batch_id,
        database = database,
        projectid = projectid
      ) |>
      select(
        import_projectid,
        import_batchid,
        database,
        projectid,
        step_order,
        step_name,
        step_description,
        transformation_type,
        software_or_language,
        notes
      )

    dbWriteTable(
      con,
      Id(schema = "grp", table = "import_transformation_step"),
      steps_to_write,
      append = TRUE,
      row.names = FALSE
    )

    artifact_ids <- dbGetQuery(
      con,
      glue_sql("
        SELECT import_artifactid, file_name
        FROM grp.import_artifact
        WHERE import_batchid = {batch_id}
          AND import_projectid = {import_project_id};
      ", .con = con)
    )

    step_ids <- dbGetQuery(
      con,
      glue_sql("
        SELECT import_transformation_stepid, step_order
        FROM grp.import_transformation_step
        WHERE import_batchid = {batch_id}
          AND import_projectid = {import_project_id};
      ", .con = con)
    )

    step_artifact_links <- tidyr::crossing(
      step_order = c(1L, 2L),
      file_name = artifacts$file_name
    ) |>
      mutate(
        artifact_role = if_else(
          step_order == 1L,
          "input",
          "output"
        ),
        notes = if_else(
          step_order == 1L,
          "File included in the dated shared import-framework bundle.",
          "Versioned framework artifact archived in Supabase Storage."
        )
      ) |>
      bind_rows(
        tibble(
          step_order = 3L,
          file_name = artifacts$file_name,
          artifact_role = "documentation",
          notes = "Artifact registered in the GRP import documentation tables."
        )
      ) |>
      left_join(step_ids, by = "step_order") |>
      left_join(artifact_ids, by = "file_name") |>
      select(
        import_transformation_stepid,
        import_artifactid,
        artifact_role,
        notes
      )

    missing_links <- step_artifact_links |>
      filter(
        is.na(import_transformation_stepid) |
          is.na(import_artifactid)
      )

    if (nrow(missing_links) > 0) {
      print(missing_links)
      stop("Some framework step-artifact links could not be resolved.")
    }

    dbWriteTable(
      con,
      Id(
        schema = "grp",
        table = "import_transformation_step_artifact"
      ),
      step_artifact_links,
      append = TRUE,
      row.names = FALSE
    )

    dbCommit(con)
    message(
      "Import-framework documentation committed for import_batchid ",
      batch_id,
      "."
    )
  },
  error = function(e) {
    if (dbIsValid(con)) {
      try(dbRollback(con), silent = TRUE)
    }
    stop(e)
  },
  finally = {
    if (dbIsValid(con)) {
      dbDisconnect(con)
    }
  }
)
