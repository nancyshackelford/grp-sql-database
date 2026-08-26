## This script creates the import documentation for GAZP6 after import from
## the harmonized Excel workbook into the GRP PostgreSQL database.
## Entries are created for five tables: import_batch, import_project,
## import_artifact, import_transformation_step, and
## import_transformation_step_artifact.

## project_object_crosswalk is not populated by this workflow. The generated
## harmonized-to-SQL and project species crosswalks are registered as artifacts
## until a standardized project_object_crosswalk loading workflow is available.
## import_validation_issue is also outside the current documentation workflow.

# Libraries
library(tidyverse)
library(DBI)
library(RPostgres)
library(glue)

# Connect to the database
password <- readLines("C:\\Users\\nshack\\OneDrive - University of Victoria\\Documents\\R\\GRP\\pword.csv")

con <- dbConnect(
  Postgres(),
  host = "aws-1-ca-central-1.pooler.supabase.com",
  port = 6543,
  dbname = "postgres",
  user = "postgres.rudybfqutvodkakgctpo",
  password = password,
  sslmode = "require"
)

# ---- set baselines ---- #
database <- "GAZP"
projectid <- 6
supabase_extension <- "GAZP/GAZP6"
import <- "GAZP6"
version <- 1
name <- "Nancy Shackelford"
date_start <- as.Date("2026-08-25")
date_end <- as.Date("2026-08-25")

# ---- Supabase file names ---- #
harmonized <- "GAZP/GAZP6/harmonized/GAZP6.xlsx"
source_lf <- "GAZP/GAZP6/source/LF.csv"
source_metadata <- "GAZP/GAZP6/source/Meta_data_CBecker_Namaqualand_south_africa.xlsx"
source_tr <- "GAZP/GAZP6/source/TR.csv"
source_supplement <- "GAZP/GAZP6/source/Supplementary_Material_1.docx"
code <- "GAZP/GAZP6/code/20260825_GAZP6_import.r"
species_crosswalk_code <- "GAZP/GAZP6/code/20260825_species_crosswalk_creation.r"
crosswalk <- "GAZP/GAZP6/crosswalks/GAZP6_harmonized-SQL_crosswalk.csv"
species_crosswalk <- "GAZP/GAZP6/crosswalks/GAZP6_species_crosswalk.csv"

# --- upload ---- #
tryCatch(
    {

dbBegin(con)

batch_id <- dbGetQuery(
  con,
  glue::glue_sql("
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
      {projectid},
      {paste0('Supabase Storage: grp-import-artifacts/', supabase_extension)},
      {paste(
        harmonized,
        source_lf,
        source_metadata,
        source_tr,
        source_supplement,
        code,
        species_crosswalk_code,
        crosswalk,
        species_crosswalk,
        sep = ', '
      )},
      {paste0(import, '_v', version)},
      {name},
      {date_end},

      -- Pipeline start stage
      'GAZP6 harmonized data',

      -- Pipeline end stage
      'GAZP6 SQL imported data',

      -- Notes
      'Import of GAZP6 from harmonized Excel to SQL tables, including reviewed project-level species mappings and monitoring month values from the timepoints sheet.'
    )
    RETURNING import_batchid;
  ", .con = con)
)$import_batchid

import_project_id <- dbGetQuery(con, glue::glue_sql("
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
    {projectid},

    -- Contribution type
    -- PICK ONE OF: 'initial_import', 'additional_contribution', 'correction', 'reprocessing', 'test_import'
    'initial_import',

    -- Contribution period
    'Restoration seeding in 2013; monitoring in August and November 2013-2015',

    -- Documentation tier
    -- PICK ONE OF: 'legacy_minimal', 'legacy_documented', 'transformation_documented', 'fully_reproducible'
    'fully_reproducible',

    -- Import status
    -- PICK ONE OF: 'planned', 'staged', 'validated', 'imported', 'failed', 'skipped'
    'imported',

    -- Import started at
    CURRENT_TIMESTAMP,

    -- Import completed at
    CURRENT_TIMESTAMP,

    -- Is current version
    TRUE,

    -- Notes
    'First import of GAZP6 into Supabase SQL. The import includes experimental seeding and vegetation-density monitoring from six South African sites.'
  )
  RETURNING import_projectid;
", .con = con))$import_projectid


artifacts <- tibble::tribble(
  ~artifact_type, ~artifact_subtype, ~file_name, ~file_extension, ~file_path_or_storage_key, ~source_layer, ~workflow_stage, ~notes,
  # artifact_type, PICK ONE: 'raw_data', 'harmonized_data', 'transformation_code', 'mapping_table', 'transformation_table', 'processed_output', 'metadata', 'notes', 'other'

  "harmonized_data",
  "GAZP6",
  "GAZP6.xlsx",
  "xlsx",
  harmonized,
  "legacy Excel database",
  "input",
  "Harmonized GAZP6 workbook used as the structured SQL-import input.",

  "raw_data",
  "GAZP6 renosterveld vegetation data",
  "LF.csv",
  "csv",
  source_lf,
  "original contributor data",
  "input",
  "Original LF-region plot-level vegetation-density observations from 2013-2015.",

  "metadata",
  "GAZP6 contributor metadata",
  "Meta_data_CBecker_Namaqualand_south_africa.xlsx",
  "xlsx",
  source_metadata,
  "original contributor metadata",
  "input",
  "Original TR and LF project, site, treatment, and monitoring metadata workbook.",

  "raw_data",
  "GAZP6 hardeveld vegetation data",
  "TR.csv",
  "csv",
  source_tr,
  "original contributor data",
  "input",
  "Original TR-region plot-level vegetation-density observations from 2013-2015.",

  "metadata",
  "GAZP6 seeding details",
  "Supplementary_Material_1.docx",
  "docx",
  source_supplement,
  "original supporting documentation",
  "input",
  "Supplementary tables documenting species, seed numbers, and functional groups used in the hardeveld and renosterveld experiments.",

  "transformation_code",
  "R import script",
  "20260825_GAZP6_import.r",
  "R",
  code,
  "R transformation workflow",
  "transform/load",
  "R script used to stage and validate GAZP6, apply reviewed species mappings and timepoint dates, load SQL tables, and archive import artifacts.",

  "transformation_code",
  "Species crosswalk creation helper",
  "20260825_species_crosswalk_creation.r",
  "r",
  species_crosswalk_code,
  "R species-resolution workflow",
  "transform/validate",
  "Reusable R helper used to inventory all project species, identify many-to-one and unresolved mappings, apply reviewed project overrides, validate contextual seed-rate rules, and write the project species crosswalk when discrepancies occur.",

  "mapping_table",
  "GAZP6 harmonized-to-SQL crosswalk",
  "GAZP6_harmonized-SQL_crosswalk.csv",
  "csv",
  crosswalk,
  "GAZP6 import crosswalk",
  "output",
  "Crosswalk linking GAZP6 source plot and treatment identifiers to generated GRP SQL identifiers.",

  "mapping_table",
  "GAZP6 species crosswalk",
  "GAZP6_species_crosswalk.csv",
  "csv",
  species_crosswalk,
  "GAZP6 reviewed species crosswalk",
  "output",
  "Complete project species inventory and reviewed mappings, including Elytropappus rhinocerotis to Dicerothamnus rhinocerotis and the reviewed Cha_inv mapping."
)

artifacts_to_write <- artifacts %>%
  mutate(
    import_projectid = import_project_id,
    import_batchid = batch_id,
    database = database,
    projectid = projectid,
    storage_bucket = "grp-import-artifacts",
    created_by = name,
    created_date = Sys.Date(),
    loaded_at = Sys.time()
  ) %>%
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

  1, "Read harmonized source workbook",
  "Loaded harmonized Excel worksheets and standardized source values for import processing.",
  "data ingestion", "R",
  "Source workbook contained project, site, treatment, timepoint, seeding, and vegetation-density data for six South African sites.",

  2, "Transform harmonized data to GRP staging tables",
  "Mapped harmonized worksheets to GRP schema structure, generated required identifiers, resolved lookup values, and created staging tables for all import targets.",
  "data transformation", "R",
  "Included generation of area, treatment, seeding, and other SQL identifiers; month and year resolution from the timepoints sheet; density conversion to the stored survey area; reviewed project species mappings; relationship-table construction; and controlled-vocabulary normalization.",

  3, "Generate import crosswalk tables",
  "Created crosswalk tables linking source identifiers to GRP SQL identifiers generated during the import process.",
  "crosswalk generation", "R",
  "Included treatment and area identifier mappings plus a complete project species crosswalk recording exact, reviewed, and synonym/name-update mappings.",

  4, "Validate staged import data",
  "Validated staging tables against GRP schema requirements, including required fields, uniqueness constraints, controlled vocabularies, lookup values, and foreign-key relationships.",
  "data validation", "R",
  "Import proceeded only after missing species mappings, many-to-one species-code concerns, timepoint joins, and required relationship identifiers were reviewed and resolved.",

  5, "Load staging tables into GRP database",
  "Imported validated staging tables into the GRP PostgreSQL database in dependency-aware order.",
  "database load", "R/PostgreSQL",
  "Load executed within a transaction to maintain referential integrity across related tables.",

  6, "Archive import artifacts",
  "Uploaded source data files, transformation code, crosswalk tables, validation outputs, and other import artifacts to Supabase Storage.",
  "artifact archival", "R/Supabase Storage",
  "Artifacts retained to support reproducibility, provenance tracking, auditing, and future re-import workflows.",

  7, "Register import provenance",
  "Recorded import metadata, artifacts, transformation steps, and related provenance information in GRP import-tracking tables.",
  "provenance documentation", "R/PostgreSQL",
  "Provides a complete record of source files, transformations, generated identifiers, and import outputs."
)

steps_to_write <- steps %>%
  mutate(
    import_projectid = import_project_id,
    import_batchid = batch_id,
    database = database,
    projectid = projectid
  ) %>%
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

artifact_ids <- dbGetQuery(con, glue::glue_sql("
  SELECT import_artifactid, file_name
  FROM grp.import_artifact
  WHERE import_batchid = {batch_id}
    AND import_projectid = {import_project_id};
", .con = con))

step_ids <- dbGetQuery(con, glue::glue_sql("
  SELECT import_transformation_stepid, step_order, step_name
  FROM grp.import_transformation_step
  WHERE import_batchid = {batch_id}
    AND import_projectid = {import_project_id};
", .con = con))

step_artifact_links <- tibble::tribble(
  ~step_order, ~file_name, ~artifact_role, ~notes,
  # artifact_role, PICK ONE: 'input', 'output', 'code', 'lookup', 'mapping', 'documentation', 'other'

  1, "GAZP6.xlsx", "input",
  "Harmonized Excel workbook read as the main structured input for the GAZP6 import.",

  1, "LF.csv", "input",
  "Original LF-region vegetation-density data retained as a source artifact.",

  1, "Meta_data_CBecker_Namaqualand_south_africa.xlsx", "input",
  "Original contributor metadata used as supporting source documentation.",

  1, "TR.csv", "input",
  "Original TR-region vegetation-density data retained as a source artifact.",

  1, "Supplementary_Material_1.docx", "input",
  "Original supplementary seeding tables used as supporting source documentation.",

  2, "20260825_GAZP6_import.r", "code",
  "R script used to transform harmonized Excel data into GRP staging tables.",

  2, "20260825_species_crosswalk_creation.r", "code",
  "R helper used to inventory and resolve project species before species-bearing staging tables were created.",

  3, "20260825_GAZP6_import.r", "code",
  "R script used to generate source-to-SQL and reviewed project species crosswalk records.",

  3, "20260825_species_crosswalk_creation.r", "code",
  "R helper used to generate and validate the reviewed GAZP6 species crosswalk.",

  3, "GAZP6_harmonized-SQL_crosswalk.csv", "mapping",
  "Crosswalk produced during staging to link harmonized GAZP6 source identifiers to SQL identifiers.",

  3, "GAZP6_species_crosswalk.csv", "mapping",
  "Complete project species inventory and reviewed source-to-accepted-taxon mappings.",

  4, "20260825_GAZP6_import.r", "code",
  "R script used to validate staged tables prior to database loading.",

  4, "20260825_species_crosswalk_creation.r", "code",
  "R helper used to stop the workflow on unresolved, ambiguous, or unreviewed many-to-one species mappings.",

  4, "GAZP6_species_crosswalk.csv", "lookup",
  "Reviewed species mappings used to validate invasive, seeded, and monitored taxa.",

  5, "20260825_GAZP6_import.r", "code",
  "R script used to load validated staging tables into the GRP PostgreSQL database.",

  6, "20260825_GAZP6_import.r", "code",
  "R script used to upload source, code, and crosswalk artifacts to Supabase Storage.",

  6, "20260825_species_crosswalk_creation.r", "code",
  "Species crosswalk helper archived to Supabase Storage with the project import artifacts.",

  6, "GAZP6.xlsx", "input",
  "Harmonized workbook archived to Supabase Storage.",

  6, "LF.csv", "input",
  "Original LF-region data archived to Supabase Storage.",

  6, "Meta_data_CBecker_Namaqualand_south_africa.xlsx", "input",
  "Original metadata file archived to Supabase Storage.",

  6, "TR.csv", "input",
  "Original TR-region data archived to Supabase Storage.",

  6, "Supplementary_Material_1.docx", "documentation",
  "Original supplementary seeding documentation archived to Supabase Storage.",

  6, "GAZP6_harmonized-SQL_crosswalk.csv", "mapping",
  "Generated identifier crosswalk archived to Supabase Storage.",

  6, "GAZP6_species_crosswalk.csv", "mapping",
  "Generated reviewed species crosswalk archived to Supabase Storage.",

  7, "20260825_GAZP6_import.r", "code",
  "R script used to register import provenance in GRP import-tracking tables."
) %>%
  left_join(step_ids, by = "step_order") %>%
  left_join(artifact_ids, by = "file_name") %>%
  select(
    import_transformation_stepid,
    import_artifactid,
    artifact_role,
    notes
  )

step_artifact_links %>%
  filter(is.na(import_transformation_stepid) | is.na(import_artifactid))

missing_links <- step_artifact_links %>%
  filter(is.na(import_transformation_stepid) | is.na(import_artifactid))

if (nrow(missing_links) > 0) {
  print(missing_links)
  stop("Some step-artifact links could not be resolved.")
}

dbWriteTable(
  con,
  Id(schema = "grp", table = "import_transformation_step_artifact"),
  step_artifact_links,
  append = TRUE,
  row.names = FALSE
)

dbCommit(con)

    },
    error = function(e) {
        dbRollback(con)
        stop(e)
    }

)
