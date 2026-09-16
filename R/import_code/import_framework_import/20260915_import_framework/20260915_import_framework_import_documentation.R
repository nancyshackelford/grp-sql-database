## Register the shared 20260915 import-framework bundle in the GRP provenance tables.
## Run only after 20260915_import_framework_import.R uploads all five files.

library(dplyr)
library(tidyr)
library(tibble)
library(DBI)
library(RPostgres)
library(glue)

read_secret_bom_safe <- function(path) {
  bytes <- readBin(path,"raw",n=file.info(path)$size)
  if(length(bytes)>=3L && identical(as.integer(bytes[1:3]),c(239L,187L,191L))) bytes <- bytes[-(1:3)]
  while(length(bytes)>0L && tail(as.integer(bytes),1L) %in% c(10L,13L)) bytes <- head(bytes,-1L)
  rawToChar(bytes)
}

framework_version <- "20260915_framework"
storage_bucket <- "import_framework"
processed_by <- "Nancy Shackelford"
processed_date <- as.Date("2026-09-16")
database <- "GRP"
projectid <- NA_integer_

artifacts <- tribble(
  ~artifact_type,~artifact_subtype,~file_name,~file_extension,~source_layer,~workflow_stage,~notes,
  "transformation_code","Prepare-stage functions","prepare_functions.R","r","shared import framework","prepare/review","Reusable functions for converting harmonized project data into reviewable areas, treatments, vegetation results, species inventories, and row audits.",
  "transformation_code","Build-stage functions","build_functions.R","r","shared import framework","build/validate","Reusable functions for converting approved prepare outputs into SQL-shaped staging tables, crosswalks, and validation results.",
  "transformation_code","Import registry","import_registry.r","r","shared import framework","build/validate","Schema, constraint, and lookup registry used to validate staged GRP imports.",
  "transformation_code","Import helper functions","import_helper_functions.r","r","shared import framework","load/archive","Reusable database-loading and Supabase Storage helpers, including safe encoding of artifact object keys.",
  "mapping_table","Global species crosswalk","sp_crosswalk.csv","csv","shared import framework","lookup/transform","Shared source-to-accepted-species crosswalk used during taxonomic standardization."
) |>
  mutate(file_path_or_storage_key=paste(framework_version,file_name,sep="/"))
source_file_list <- paste(artifacts$file_path_or_storage_key,collapse=", ")

password <- read_secret_bom_safe(
  "C:/Users/nshack/OneDrive - University of Victoria/Documents/R/GRP/pword.csv"
)
con <- dbConnect(
  Postgres(),host="aws-1-ca-central-1.pooler.supabase.com",port=6543,
  dbname="postgres",user="postgres.rudybfqutvodkakgctpo",password=password,sslmode="require"
)

tryCatch({
  existing <- dbGetQuery(con,glue_sql(
    "SELECT COUNT(*) AS n FROM grp.import_batch
     WHERE database={database} AND workflow_version={framework_version}",.con=con
  ))$n[[1]]
  if(as.numeric(existing)>0) stop("This framework version is already documented; no rows were written.",call.=FALSE)

  dbBegin(con)
  batch_id <- dbGetQuery(con,glue_sql(
    "INSERT INTO grp.import_batch
     (database,projectid,source_folder,source_file_list,workflow_version,processed_by,
      processed_date,pipeline_stage_start,pipeline_stage_end,notes)
     VALUES ({database},NULL,{paste0('Supabase Storage: ',storage_bucket,'/',framework_version)},
      {source_file_list},{framework_version},{processed_by},{processed_date},
      'Local shared import-framework files',
      'Versioned shared import-framework bundle archived and documented',
      'Archives the prepare-build-summarize-commit support bundle first used for GAZP10 and available to future GRP imports.')
     RETURNING import_batchid",.con=con))$import_batchid[[1]]

  import_project_id <- dbGetQuery(con,glue_sql(
    "INSERT INTO grp.import_project
     (import_batchid,database,projectid,contribution_type,contribution_period,
      documentation_tier,import_status,import_started_at,import_completed_at,is_current_version,notes)
     VALUES ({batch_id},{database},NULL,'reprocessing',
      'Shared framework version archived September 2026','fully_reproducible','imported',
      CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,TRUE,
      'Non-project provenance record for the shared 20260915 import framework; projectid is intentionally NULL.')
     RETURNING import_projectid",.con=con))$import_projectid[[1]]

  artifacts_to_write <- artifacts |>
    mutate(
      import_projectid=import_project_id,import_batchid=batch_id,database=database,
      projectid=projectid,storage_bucket=storage_bucket,created_by=processed_by,
      created_date=processed_date,loaded_at=Sys.time()
    ) |>
    select(import_projectid,import_batchid,database,projectid,artifact_type,
           artifact_subtype,file_name,file_extension,file_path_or_storage_key,
           storage_bucket,source_layer,workflow_stage,created_by,created_date,loaded_at,notes)
  dbAppendTable(con,Id(schema="grp",table="import_artifact"),artifacts_to_write)

  steps <- tribble(
    ~step_order,~step_name,~step_description,~transformation_type,~software_or_language,~notes,
    1L,"Assemble shared framework bundle","Collected the four reusable R files and shared species crosswalk in a dated version directory.","framework packaging","R/filesystem","The dated directory preserves the exact dependencies used by GAZP10.",
    2L,"Archive framework bundle","Uploaded all five files to the private import_framework Storage bucket.","artifact archival","R/Supabase Storage","Uploads use overwrite-safe semantics within this exact framework version.",
    3L,"Register framework provenance","Recorded the bundle, artifacts, workflow steps, and their relationships in the GRP provenance tables.","provenance documentation","R/PostgreSQL","The shared bundle has a null projectid because it supports multiple projects."
  )
  steps_to_write <- steps |>
    mutate(import_projectid=import_project_id,import_batchid=batch_id,database=database,projectid=projectid) |>
    select(import_projectid,import_batchid,database,projectid,step_order,step_name,
           step_description,transformation_type,software_or_language,notes)
  dbAppendTable(con,Id(schema="grp",table="import_transformation_step"),steps_to_write)

  artifact_ids <- dbGetQuery(con,glue_sql(
    "SELECT import_artifactid,file_name FROM grp.import_artifact
     WHERE import_batchid={batch_id} AND import_projectid={import_project_id}",.con=con))
  step_ids <- dbGetQuery(con,glue_sql(
    "SELECT import_transformation_stepid,step_order FROM grp.import_transformation_step
     WHERE import_batchid={batch_id} AND import_projectid={import_project_id}",.con=con))
  links <- crossing(step_order=c(1L,2L),file_name=artifacts$file_name) |>
    mutate(
      artifact_role=if_else(step_order==1L,"input","output"),
      notes=if_else(step_order==1L,"File included in the dated framework bundle.",
                    "Versioned framework artifact archived in Supabase Storage.")
    ) |>
    bind_rows(tibble(step_order=3L,file_name=artifacts$file_name,
                     artifact_role="documentation",
                     notes="Artifact registered in the GRP provenance tables.")) |>
    left_join(step_ids,by="step_order") |>
    left_join(artifact_ids,by="file_name") |>
    select(import_transformation_stepid,import_artifactid,artifact_role,notes)
  if(any(!complete.cases(links))) stop("A framework step-artifact link could not be resolved.",call.=FALSE)
  dbAppendTable(con,Id(schema="grp",table="import_transformation_step_artifact"),links)

  dbCommit(con)
  message("Framework provenance committed for import_batchid ",batch_id,".")
},error=function(e) {
  if(dbIsValid(con)) try(dbRollback(con),silent=TRUE)
  stop(e)
},finally={
  if(dbIsValid(con)) dbDisconnect(con)
})
