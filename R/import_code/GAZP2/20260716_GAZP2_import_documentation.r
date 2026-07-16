## This script creates the import documentation for GAZP2 from the harmonized Excel data
## Entries are created for six tables: 
## import_batch, import_project, project_object_crosswalk, import_artifact, import_transformation_step, and import_transformation_step_artifact


######### If you copied this from GAZP2 into GAZP3, you read the note below and didn't know what it meant for GAZP2 so you ignored it
######### If you copied this from GAZP1 into GAZP2, you still need to design the project_object_crosswalk piece of this
######### You'll need to pull the crosswalk table itself in, and then standardize it to match the p_o_c table
######### Eventually you want to add import_validation_issue here

######### ALSO: This doesn't fill in the "projectid" column for any of the tables
######### This documentation step happens after the projectid is generated in the import process, 
######### so this needs to be fixed somehow in the next iteration. 
######### I did it by hand in Supabase this time, which is dum dum

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
supabase_extension <- "GAZP/GAZP2"
import <- "GAZP2"
version <- 1
name <- "Nancy Shackelford"
date_start <- as.Date("2026-07-15")
date_end <- as.Date("2026-07-16")

# ---- Supabase file names ---- #
harmonized <- "GAZP/GAZP2/harmonized/GAZP2.xlsx"
desc <- "GAZP/GAZP2/source/Fire_complex_description.docx"
data <- "GAZP/GAZP2/source/James_fire_seeding_data.xlsx"
meta_data_bartlett <- "GAZP/GAZP2/source/Meta-data_Bartlett.xlsx"
meta_data_butte <- "GAZP/GAZP2/source/Meta-data_Butte.xlsx"
meta_data_egley <- "GAZP/GAZP2/source/Meta-data_Egley.xlsx"
meta_data_roundtop <- "GAZP/GAZP2/source/Meta-data_Roundtop.xlsx"
meta_data_bartlett_v2 <- "GAZP/GAZP2/source/Updated_Meta-data_Bartlett.xlsx"
meta_data_butte_v2 <- "GAZP/GAZP2/source/updated_Meta-data_Butte_(2).xlsx"
meta_data_egley_v2 <- "GAZP/GAZP2/source/Updated_Meta-data_Egley.xlsx"
meta_data_roundtop_v2 <- "GAZP/GAZP2/source/Updated_Meta-data_Roundtop.xlsx"
code <- "GAZP/GAZP2/code/20260715_GAZP2_import.r"
crosswalk <- "GAZP/GAZP2/crosswalks/GAZP2_harmonized-SQL_crosswalk.csv"

# --- upload ---- #
tryCatch(
    {

dbBegin(con)

batch_id <- dbGetQuery(
  con,
  glue::glue_sql("
    INSERT INTO grp.import_batch (
      database,
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
      {paste0('Supabase Storage: grp-import-artifacts/', supabase_extension)},
      {paste(harmonized, desc, data, meta_data_bartlett, meta_data_butte, meta_data_egley, meta_data_roundtop, meta_data_bartlett_v2, meta_data_butte_v2, meta_data_egley_v2, meta_data_roundtop_v2, code, crosswalk, sep = ', ')},
      {paste0(import, '_v', version)},
      {name},
      {date_end},

      -- Pipeline start stage
      'GAZP2 harmonized data',

      -- Pipeline end stage
      'GAZP2 SQL imported data',

      -- Notes
      'Import of GAZP2 from harmonized Excel to SQL tables.'
    )
    RETURNING import_batchid;
  ", .con = con)
)$import_batchid

import_project_id <- dbGetQuery(con, glue::glue_sql("
  INSERT INTO grp.import_project (
    import_batchid,
    database,
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

    -- Contribution type
    -- PICK ONE OF: 'initial_import', 'additional_contribution', 'correction', 'reprocessing', 'test_import'
    'initial_import',

    -- Contribution period
    'six months in 2007/2008',

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
    'First import of GAZP2 into Supabase SQL.'
  )
  RETURNING import_projectid;
", .con = con))$import_projectid


artifacts <- tibble::tribble(
  ~artifact_type, ~artifact_subtype, ~file_name, ~file_extension, ~file_path_or_storage_key, ~source_layer, ~workflow_stage, ~notes,
    # artifact_type, PICK ONE: 'raw_data', 'harmonized_data', 'transformation_code', 'mapping_table', 'transformation_table', 'processed_output', 'metadata', 'notes', 'other'

  "harmonized_data",
  "GAZP2",
  "GAZP2.xlsx",
  "xlsx",
  harmonized,
  "legacy Excel database",
  "input",
  "Harmonized GAZP2 data from GRP Excel database.",

  "raw_data",
  "GAZP2",
  "Fire_complex_description.docx",
  "docx",
  desc,
  "Original GAZP2 data contribution.",
  "input",
  "General description of disturbance, sites, and treatments.",

  "raw_data",
  "GAZP2",
  "James_fire_seeding_data.xlsx",
  "xlsx",
  data,
  "Original GAZP2 data contribution.",
  "input",
  "Original vegetation results data, with harmonized treatment IDs inserted between the contribution stage and harmonization stage (so added by N. Shackelford, not part of original data).",

  "raw_data",
  "GAZP2",
  "Meta-data_Bartlett.xlsx",
  "xlsx",
  meta_data_bartlett,
  "Original GAZP2 data contribution for Bartlett site.",
  "input",
  "First version of standard meta-data contribution.",
  
  "raw_data",
  "GAZP2",
  "Updated_Meta-data_Bartlett.xlsx",
  "xlsx",
  meta_data_bartlett_v2,
  "Original GAZP2 data contribution for Bartlett site.",
  "input",
  "Second version of standard meta-data contribution.",
  
 "raw_data",
  "GAZP2",
  "Meta-data_Butte.xlsx",
  "xlsx",
  meta_data_butte,
  "Original GAZP2 data contribution for Butte site.",
  "input",
  "First version of standard meta-data contribution.",
  
  "raw_data",
  "GAZP2",
  "updated_Meta-data_Butte_(2).xlsx",
  "xlsx",
  meta_data_butte_v2,
  "Original GAZP2 data contribution for Butte site.",
  "input",
  "Second version of standard meta-data contribution.",

  "raw_data",
  "GAZP2",
  "Meta-data_Egley.xlsx",
  "xlsx",
  meta_data_egley,
  "Original GAZP2 data contribution for Egley site.",
  "input",
  "First version of standard meta-data contribution.",
  
  "raw_data",
  "GAZP2",
  "Updated_Meta-data_Egley.xlsx",
  "xlsx",
  meta_data_egley_v2,
  "Original GAZP2 data contribution for Egley site.",
  "input",
  "Second version of standard meta-data contribution.",

  "raw_data",
  "GAZP2",
  "Meta-data_Roundtop.xlsx",
  "xlsx",
  meta_data_roundtop,
  "Original GAZP2 data contribution for Roundtop site.",
  "input",
  "First version of standard meta-data contribution.",
  
  "raw_data",
  "GAZP2",
  "Updated_Meta-data_Roundtop.xlsx",
  "xlsx",
  meta_data_roundtop_v2,
  "Original GAZP2 data contribution for Roundtop site.",
  "input",
  "Second version of standard meta-data contribution.",

  "transformation_code",
  "R import script",
  "20260715_GAZP2_import.r",
  "R",
  code,
  "R transformation workflow",
  "transform/load",
  "R script used to clean Excel data, create staging tables, create the crosswalk table, and load all tables and files in Supabase.",

  "mapping_table",
  "GAZP2 crosswalk",
  "GAZP2_harmonized-SQL_crosswalk.csv",
  "csv",
  crosswalk,
  "GAZP2 import crosswalk",
  "output",
  "Crosswalk linking legacy Excel GAZP2 data to SQL tables."
)

artifacts_to_write <- artifacts %>%
  mutate(
    import_projectid = import_project_id,
    import_batchid = batch_id,
    database = database,
    storage_bucket = "grp-import-artifacts",
    created_by = name,
    created_date = Sys.Date(),
    loaded_at = Sys.time()
  ) %>%
  select(
    import_projectid,
    import_batchid,
    database,
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
    database = database
  ) %>%
  select(
    import_projectid,
    import_batchid,
    database,
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

  1, "GAZP2.xlsx", "input",
  "Harmonized Excel workbook read as the main structured input for the GAZP2 import.",

  1, "Fire_complex_description.docx", "input",
  "Original project description used as supporting source documentation.",

  1, "Meta-data_Bartlett.xlsx", "input",
  "Original metadata contribution used as supporting source documentation.",

  1, "Updated_Meta-data_Bartlett.xlsx", "input",
  "Original metadata contribution used as supporting source documentation.",

  1, "Meta-data_Butte.xlsx", "input",
  "Original metadata contribution used as supporting source documentation.",

  1, "updated_Meta-data_Butte_(2).xlsx", "input",
  "Original metadata contribution used as supporting source documentation.",

  1, "Meta-data_Egley.xlsx", "input",
  "Original metadata contribution used as supporting source documentation.",

  1, "Updated_Meta-data_Egley.xlsx", "input",
  "Original metadata contribution used as supporting source documentation.",

  1, "Meta-data_Roundtop.xlsx", "input",
  "Original metadata contribution used as supporting source documentation.",

  1, "Updated_Meta-data_Roundtop.xlsx", "input",
  "Original metadata contribution used as supporting source documentation.",

  1, "James_fire_seeding_data.xlsx", "input",
  "Original raw data contribution retained as source artifact.",

  2, "20260715_GAZP2_import.r", "code",
  "R script used to transform harmonized Excel data into GRP staging tables.",

  3, "20260715_GAZP2_import.r", "code",
  "R script used to generate source-to-SQL crosswalk records.",

  3, "GAZP2_harmonized-SQL_crosswalk.csv", "mapping",
  "Crosswalk produced during staging to link harmonized GAZP2 source identifiers to SQL identifiers.",

  4, "20260715_GAZP2_import.r", "code",
  "R script used to validate staged tables prior to database loading.",

  5, "20260715_GAZP2_import.r", "code",
  "R script used to load validated staging tables into the GRP PostgreSQL database.",

  6, "20260715_GAZP2_import.r", "code",
  "R script used to upload source, code, and crosswalk artifacts to Supabase Storage.",

  6, "GAZP2.xlsx", "input",
  "Harmonized workbook archived to Supabase Storage.",

  6, "Fire_complex_description.docx", "documentation",
  "Original project description archived to Supabase Storage.",

  6, "Meta-data_Bartlett.xlsx", "input",
  "Original metadata file archived to Supabase Storage.",

  6, "Updated_Meta-data_Bartlett.xlsx", "input",
  "Original metadata file archived to Supabase Storage.",

  6, "Meta-data_Butte.xlsx", "input",
  "Original metadata file archived to Supabase Storage.",

  6, "updated_Meta-data_Butte_(2).xlsx", "input",
  "Original metadata file archived to Supabase Storage.",

  6, "Meta-data_Egley.xlsx", "input",
  "Original metadata file archived to Supabase Storage.",

  6, "Updated_Meta-data_Egley.xlsx", "input",
  "Original metadata file archived to Supabase Storage.",

  6, "Meta-data_Roundtop.xlsx", "input",
  "Original metadata file archived to Supabase Storage.",

  6, "Updated_Meta-data_Roundtop.xlsx", "input",
  "Original metadata file archived to Supabase Storage.",

  6, "James_fire_seeding_data.xlsx", "input",
  "Original raw data file archived to Supabase Storage.",

  6, "GAZP2_harmonized-SQL_crosswalk.csv", "mapping",
  "Generated crosswalk table archived to Supabase Storage.",

  7, "20260715_GAZP2_import.r", "code",
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
