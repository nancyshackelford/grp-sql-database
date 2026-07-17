## This script creates the import documentation for GAZP3 from the harmonized Excel data
## Entries are created for six tables: 
## import_batch, import_project, project_object_crosswalk, import_artifact, import_transformation_step, and import_transformation_step_artifact


######### You still need to design the project_object_crosswalk piece of this
######### The p_o_c table is a standalone SQL table (currently empty) that merges and standardizes all crosswalk table data
######### You are confused thinking about how to do this, so will wait until after GAZP5
######### You'll need to pull the crosswalk table itself in, and then standardize it to match the p_o_c table
######### Eventually you also want to add import_validation_issue here

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
projectid <- 3
supabase_extension <- "GAZP/GAZP3"
import <- "GAZP3"
version <- 1
name <- "Nancy Shackelford"
date_start <- as.Date("2026-07-16")
date_end <- as.Date("2026-07-16")

# ---- Supabase file names ---- #
harmonized <- "GAZP/GAZP3/harmonized/GAZP3.xlsx"
#desc <- "GAZP/GAZP3/source/Fire_complex_description.docx"
data <- "GAZP/GAZP3/source/bunchgrass_demography.xlsx"
meta_data_v1 <- "GAZP/GAZP3/source/Meta-data_bunchgrass.xlsx"
meta_data_v2 <- "GAZP/GAZP3/source/Updated_Meta-data_bunchgrass_(2).xlsx"
code <- "GAZP/GAZP3/code/20260716_GAZP3_import.r"
crosswalk <- "GAZP/GAZP3/crosswalks/GAZP3_harmonized-SQL_crosswalk.csv"

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
      {paste(harmonized, data, meta_data_v1, meta_data_v2, code, crosswalk, sep = ', ')},
      {paste0(import, '_v', version)},
      {name},
      {date_end},

      -- Pipeline start stage
      'GAZP3 harmonized data',

      -- Pipeline end stage
      'GAZP3 SQL imported data',

      -- Notes
      'Import of GAZP3 from harmonized Excel to SQL tables.'
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
    '2007-2009; or 2008-2010; or 2009-2011',

    -- Documentation tier
    -- PICK ONE OF: 'legacy_minimal', 'legacy_documented', 'transformation_documented', 'fully_reproducible'
    'fully_reproducible',

    -- Import status
    -- PICK ONE OF: 'planned', 'staged', 'validated', 'imported', 'failed', 'skipped'
    'validated',

    -- Import started at
    CURRENT_TIMESTAMP,

    -- Import completed at
    CURRENT_TIMESTAMP,

    -- Is current version
    TRUE,

    -- Notes
    'First import of GAZP3 into Supabase SQL.'
  )
  RETURNING import_projectid;
", .con = con))$import_projectid


artifacts <- tibble::tribble(
  ~artifact_type, ~artifact_subtype, ~file_name, ~file_extension, ~file_path_or_storage_key, ~source_layer, ~workflow_stage, ~notes,
    # artifact_type, PICK ONE: 'raw_data', 'harmonized_data', 'transformation_code', 'mapping_table', 'transformation_table', 'processed_output', 'metadata', 'notes', 'other'

  "harmonized_data",
  "GAZP3",
  "GAZP3.xlsx",
  "xlsx",
  harmonized,
  "legacy Excel database",
  "input",
  "Harmonized GAZP3 data from GRP Excel database.",

 # "raw_data",
 # "GAZP3",
 # "Fire_complex_description.docx",
 # "docx",
 # desc,
 # "Original GAZP2 data contribution.",
 # "input",
 # "General description of disturbance, sites, and treatments.",

  "raw_data",
  "GAZP3",
  "bunchgrass_demography.xlsx",
  "xlsx",
  data,
  "Original GAZP3 data contribution.",
  "input",
  "Original vegetation results data.",

  "raw_data",
  "GAZP3",
  "Meta-data_bunchgrass.xlsx",
  "xlsx",
  meta_data_v1,
  "Original GAZP3 data contribution.",
  "input",
  "First version of standard meta-data contribution.",
  
  "raw_data",
  "GAZP3",
  "Updated_Meta-data_bunchgrass_(2).xlsx",
  "xlsx",
  meta_data_v2,
  "Original GAZP2 data contribution.",
  "input",
  "Second version of standard meta-data contribution.",
  
  "transformation_code",
  "R import script",
  "20260716_GAZP3_import.r",
  "R",
  code,
  "R transformation workflow",
  "transform/load",
  "R script used to clean Excel data, create staging tables, create the crosswalk table, and load all tables and files in Supabase.",

  "mapping_table",
  "GAZP3 crosswalk",
  "GAZP3_harmonized-SQL_crosswalk.csv",
  "csv",
  crosswalk,
  "GAZP3 import crosswalk",
  "output",
  "Crosswalk linking legacy Excel GAZP3 data to SQL tables."
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
  "Source workbook contained project, site, treatment, seeding, and vegetation monitoring data.",

  2, "Transform harmonized data to GRP staging tables",
  "Mapped harmonized worksheets to GRP schema structure, generated required identifiers, resolved lookup values, and created staging tables for all import targets.",
  "data transformation", "R",
  "Included generation of area, treatment, seeding, and other SQL identifiers; construction of relationship tables; and normalization of controlled vocabulary values.",

  3, "Generate import crosswalk tables",
  "Created crosswalk tables linking source identifiers to GRP SQL identifiers generated during the import process.",
  "crosswalk generation", "R",
  "Included treatment and area crosswalks used to preserve relationships between source data and imported SQL records.",

  4, "Validate staged import data",
  "Validated staging tables against GRP schema requirements, including required fields, uniqueness constraints, controlled vocabularies, lookup values, and foreign-key relationships.",
  "data validation", "R",
  "Import proceeded only after validation issues were reviewed and resolved.",

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

  1, "GAZP3.xlsx", "input",
  "Harmonized Excel workbook read as the main structured input for the GAZP3 import.",

 # 1, "Fire_complex_description.docx", "input",
 # "Original project description used as supporting source documentation.",

  1, "Meta-data_bunchgrass.xlsx", "input",
  "Original metadata contribution used as supporting source documentation.",

  1, "Updated_Meta-data_bunchgrass_(2).xlsx", "input",
  "Original metadata contribution used as supporting source documentation.",

  1, "bunchgrass_demography.xlsx", "input",
  "Original raw data contribution retained as source artifact.",

  2, "20260716_GAZP3_import.r", "code",
  "R script used to transform harmonized Excel data into GRP staging tables.",

  3, "20260716_GAZP3_import.r", "code",
  "R script used to generate source-to-SQL crosswalk records.",

  3, "GAZP3_harmonized-SQL_crosswalk.csv", "mapping",
  "Crosswalk produced during staging to link harmonized GAZP3 source identifiers to SQL identifiers.",

  4, "20260716_GAZP3_import.r", "code",
  "R script used to validate staged tables prior to database loading.",

  5, "20260716_GAZP3_import.r", "code",
  "R script used to load validated staging tables into the GRP PostgreSQL database.",

  6, "20260716_GAZP3_import.r", "code",
  "R script used to upload source, code, and crosswalk artifacts to Supabase Storage.",

  6, "GAZP3.xlsx", "input",
  "Harmonized workbook archived to Supabase Storage.",

#  6, "Fire_complex_description.docx", "documentation",
#  "Original project description archived to Supabase Storage.",

  6, "Meta-data_bunchgrass.xlsx", "input",
  "Original metadata file archived to Supabase Storage.",

  6, "Updated_Meta-data_bunchgrass_(2).xlsx", "input",
  "Original metadata file archived to Supabase Storage.",

  6, "bunchgrass_demography.xlsx", "input",
  "Original raw data file archived to Supabase Storage.",

  6, "GAZP3_harmonized-SQL_crosswalk.csv", "mapping",
  "Generated crosswalk table archived to Supabase Storage.",

  7, "20260716_GAZP3_import.r", "code",
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