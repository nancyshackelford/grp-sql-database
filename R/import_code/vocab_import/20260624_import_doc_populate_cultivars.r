## This script creates the import documentation for the populate cultivars work
## Entries are created for five tables:
## import_batch, import_project, import_artifact, import_transformation_step,
## and import_transformation_step_artifact

# Libraries
library(tidyverse)
library(DBI)
library(RPostgres)
library(glue)

# Connect to the database
password <- readLines("C:\\Users\\nshack\\OneDrive - University of Victoria\\Documents\\R\\GRP\\pword.csv")

conn <- dbConnect(
  Postgres(),
  host = "aws-1-ca-central-1.pooler.supabase.com",
  port = 6543,
  dbname = "postgres",
  user = "postgres.rudybfqutvodkakgctpo",
  password = password,
  sslmode = "require"
)

# Register cultivar import artifacts -------------------------------------

dbBegin(conn)

batch_id <- dbGetQuery(conn, "
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
    'GRP',
    'Supabase Storage: grp-import-artifacts/cultivar_vocabulary_20260624/',
    'source_cultivars.csv; populate_cultivars.r; cultivar_crosswalk.csv',
    'cultivar_import_v1',
    'Nancy Shackelford',
    CURRENT_DATE,
    'cultivar vocabulary import',
    'cultivar table populated',
    'Initial migration of legacy GAZP cultivar vocabulary into grp.cultivar. SQL cultivar IDs were newly assigned and must be resolved through the cultivar crosswalk for future Excel imports. After initial load, duplicate Toe Jam Creek records for Ely_ely and Ely_ely2 were manually consolidated by deleting SQL cultivarid 42 and remapping the Ely_ely crosswalk row to SQL cultivarid 43.'
  )
  RETURNING import_batchid;
")$import_batchid

import_project_id <- dbGetQuery(conn, glue::glue_sql("
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
    'GRP',
    'initial_import',
    'legacy GAZP cultivar list',
    'fully_reproducible',
    'imported',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    TRUE,
    'Special import_project record used to group cultivar vocabulary migration artifacts and transformation steps. The import generated new SQL cultivar IDs rather than preserving Excel cultivar IDs. True source ambiguities for Sch_sco cultivarid 1 and Pan_vir cultivarid 1 were retained in the crosswalk for manual review during future project imports. Ely_ely Toe Jam Creek was manually reassigned from deleted SQL cultivarid 42 to SQL cultivarid 43 to match Ely_ely2 Toe Jam Creek.'
  )
  RETURNING import_projectid;
", .con = conn))$import_projectid

artifacts <- tibble::tribble(
  ~artifact_type, ~artifact_subtype, ~file_name, ~file_extension, ~file_path_or_storage_key, ~source_layer, ~workflow_stage, ~notes,

  "raw_data",
  "legacy cultivar vocabulary",
  "source_cultivars.csv",
  "csv",
  "cultivar_vocabulary_20260624/source_cultivars.csv",
  "harmonized Excel/CSV export",
  "input",
  "Original harmonized cultivar table used as the source for the GRP cultivar vocabulary import.",

  "transformation_code",
  "R import script",
  "populate_cultivars.r",
  "R",
  "cultivar_vocabulary_20260624/populate_cultivars.r",
  "R transformation workflow",
  "transform/load",
  "R script used to clean cultivar values, resolve species through the species crosswalk, generate SQL cultivar IDs, create the cultivar crosswalk, and load grp.cultivar.",

  "mapping_table",
  "cultivar crosswalk",
  "cultivar_crosswalk.csv",
  "csv",
  "cultivar_vocabulary_20260624/cultivar_crosswalk.csv",
  "migration crosswalk",
  "output",
  "Crosswalk linking legacy Excel species/cultivar IDs to generated GRP cultivar IDs. Includes notes for ambiguous source cultivar IDs and the manual consolidation of Ely_ely Toe Jam Creek from deleted SQL cultivarid 42 to SQL cultivarid 43."
)

artifacts_to_write <- artifacts %>%
  mutate(
    import_projectid = import_project_id,
    import_batchid = batch_id,
    database = "GRP",
    storage_bucket = "grp-import-artifacts",
    created_by = "Nancy Shackelford",
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
  conn,
  Id(schema = "grp", table = "import_artifact"),
  artifacts_to_write,
  append = TRUE,
  row.names = FALSE
)

steps <- tibble::tribble(
  ~step_order, ~step_name, ~step_description, ~transformation_type, ~software_or_language, ~notes,

  1,
  "Clean legacy cultivar source table",
  "Cleaned blank values, cultivar names, cultivar origin fields, and seed origin coordinates from the harmonized cultivar source table.",
  "data cleaning",
  "R",
  "Latitude and longitude were validated against grp.cultivar coordinate constraints.",

  2,
  "Resolve cultivar species IDs",
  "Resolved legacy Excel species IDs to SQL species IDs using the existing species crosswalk rather than grp.species_names.",
  "identifier resolution",
  "R",
  "This was required because some legacy source species codes include numeric endings that are not retained in SQL species_names.",

  3,
  "Generate SQL cultivar IDs",
  "Generated new globally unique SQL cultivar IDs for cultivar records rather than preserving Excel cultivar IDs.",
  "code generation",
  "R",
  "Excel cultivar IDs are only meaningful together with Excel species IDs. Future Excel imports must use the cultivar crosswalk to resolve SQL cultivar IDs.",

  4,
  "Create cultivar crosswalk",
  "Created a crosswalk from legacy Excel species/cultivar identifiers to SQL species IDs and generated SQL cultivar IDs.",
  "crosswalk generation",
  "R",
  "The crosswalk records true ambiguous source IDs for Sch_sco cultivarid 1 and Pan_vir cultivarid 1. It also records manually consolidated Ely_ely Toe Jam Creek mapping to SQL cultivarid 43 after deleting SQL cultivarid 42.",

  5,
  "Load GRP cultivar table",
  "Loaded validated cultivar records into grp.cultivar.",
  "database load",
  "R/PostgreSQL",
  "After loading, SQL cultivarid 42 was manually deleted because Ely_ely Toe Jam Creek and Ely_ely2 Toe Jam Creek were determined to represent the same cultivar. The Ely_ely crosswalk row was manually updated to SQL cultivarid 43."
)

steps_to_write <- steps %>%
  mutate(
    import_projectid = import_project_id,
    import_batchid = batch_id,
    database = "GRP"
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
  conn,
  Id(schema = "grp", table = "import_transformation_step"),
  steps_to_write,
  append = TRUE,
  row.names = FALSE
)

artifact_ids <- dbGetQuery(conn, glue::glue_sql("
  SELECT import_artifactid, file_name
  FROM grp.import_artifact
  WHERE import_batchid = {batch_id}
    AND import_projectid = {import_project_id};
", .con = conn))

step_ids <- dbGetQuery(conn, glue::glue_sql("
  SELECT import_transformation_stepid, step_order, step_name
  FROM grp.import_transformation_step
  WHERE import_batchid = {batch_id}
    AND import_projectid = {import_project_id};
", .con = conn))

step_artifact_links <- tibble::tribble(
  ~step_order, ~file_name, ~artifact_role, ~notes,

  1, "source_cultivars.csv", "input",
  "Source file used for cultivar cleaning.",

  1, "populate_cultivars.r", "code",
  "R script used to clean source cultivar data.",

  2, "populate_cultivars.r", "code",
  "R script used to resolve source species codes through the species crosswalk.",

  3, "populate_cultivars.r", "code",
  "R script used to generate SQL cultivar IDs.",

  4, "populate_cultivars.r", "code",
  "R script used to create the cultivar crosswalk.",

  4, "cultivar_crosswalk.csv", "mapping",
  "Crosswalk produced by the transformation workflow and manually updated for the Ely_ely Toe Jam Creek consolidation.",

  5, "populate_cultivars.r", "code",
  "R script used to load grp.cultivar into PostgreSQL."
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

dbWriteTable(
  conn,
  Id(schema = "grp", table = "import_transformation_step_artifact"),
  step_artifact_links,
  append = TRUE,
  row.names = FALSE
)

dbCommit(conn)