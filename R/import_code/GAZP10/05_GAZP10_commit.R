### Commit the approved GAZP10 staging package and register its provenance.
### Safety default: this script performs validation only until COMMIT_IMPORT is TRUE.

library(dplyr)
library(readr)
library(DBI)
library(RPostgres)
library(digest)
library(glue)

COMMIT_IMPORT <- TRUE

framework_dir <- file.path("R", "import_framework", "20260915_framework")
source(file.path(framework_dir, "build_functions.R"))
source(file.path(framework_dir, "import_helper_functions.r"))

build_dir <- file.path("outputs", "import_review", "GAZP10", "build")
summary_dir <- file.path("outputs", "import_review", "GAZP10", "summarize")
commit_dir <- file.path("outputs", "import_review", "GAZP10", "commit")
dir.create(commit_dir, recursive=TRUE, showWarnings=FALSE)

stop_if <- function(condition, message) if (isTRUE(condition)) stop(message, call.=FALSE)

# ---- Verify the exact reviewed build package ----
approval <- read_csv(file.path(build_dir,"build_approval.csv"),show_col_types=FALSE)
stop_if(nrow(approval)==0L || any(!approval$approved),"The complete build package has not been approved.")
approved_paths <- file.path(build_dir,approval$file)
stop_if(any(!file.exists(approved_paths)),"One or more approved build files are missing.")
current_hashes <- toupper(vapply(approved_paths,digest,character(1),algo="sha256",file=TRUE))
hash_audit <- approval |>
  transmute(file,approved_sha256=sha256,current_sha256=current_hashes,
            status=if_else(approved_sha256==current_sha256,"pass","blocker"))
write_csv(hash_audit,file.path(commit_dir,"approved_build_hash_audit.csv"),na="")
stop_if(any(hash_audit$status!="pass"),"An approved build artifact changed after review.")

inventory <- read_csv(file.path(build_dir,"staging_table_inventory.csv"),show_col_types=FALSE)
commit_preview <- read_csv(file.path(summary_dir,"commit_preview.csv"),show_col_types=FALSE)
precommit_checks <- read_csv(file.path(summary_dir,"precommit_checks.csv"),show_col_types=FALSE)
artifact_preview <- read_csv(file.path(summary_dir,"import_artifact_preview.csv"),show_col_types=FALSE)
batch_preview <- read_csv(file.path(summary_dir,"import_batch_preview.csv"),show_col_types=FALSE)
project_preview <- read_csv(file.path(summary_dir,"import_project_preview.csv"),show_col_types=FALSE)
step_preview <- read_csv(file.path(summary_dir,"transformation_steps_preview.csv"),show_col_types=FALSE)
stop_if(any(precommit_checks$status!="pass"),"The summarize-stage precommit checks contain a blocker.")

tables_to_insert <- commit_preview |> filter(action=="insert") |> arrange(commit_order)
read_stage <- function(table) read_csv(file.path(build_dir,paste0("stg_",table,".csv")),show_col_types=FALSE)
staging <- setNames(lapply(tables_to_insert$table,read_stage),tables_to_insert$table)
staged_counts <- tibble(
  table=names(staging),
  expected_rows=vapply(staging,nrow,integer(1))
)
stop_if(any(staged_counts$expected_rows != tables_to_insert$rows),"Staging row counts differ from the approved commit preview.")

# ---- Resolve and verify every archived artifact ----
artifact_local_path <- function(type,name) {
  if(type %in% c("raw_data","metadata")) return(file.path("data","source","GAZP","GAZP10",name))
  if(type=="harmonized_data") return(file.path("data","harmonized","GAZP","GAZP10",name))
  if(type=="transformation_code") return(file.path("R","import_code","GAZP10",name))
  if(type=="mapping_table") return(file.path("crosswalk_tables","GAZP","GAZP10",name))
  NA_character_
}
artifact_files <- artifact_preview |>
  rowwise() |>
  mutate(local_path=artifact_local_path(artifact_type,file_name),exists=file.exists(local_path),
         bytes=if_else(exists,as.numeric(file.info(local_path)$size),NA_real_)) |>
  ungroup()
write_csv(artifact_files,file.path(commit_dir,"artifact_file_audit.csv"),na="")
stop_if(any(!artifact_files$exists),"One or more import artifacts are missing locally.")

# ---- Connect and repeat live-state/schema checks ----
password <- read_secret_bom_safe(
  "C:/Users/nshack/OneDrive - University of Victoria/Documents/R/GRP/pword.csv"
)
con <- dbConnect(
  Postgres(),host="aws-1-ca-central-1.pooler.supabase.com",port=6543,
  dbname="postgres",user="postgres.rudybfqutvodkakgctpo",password=password,sslmode="require"
)
on.exit(dbDisconnect(con),add=TRUE)

live_state <- dbGetQuery(con,paste(
  "SELECT",
  "(SELECT COALESCE(MAX(areaid),0) FROM grp.area) max_areaid,",
  "(SELECT COALESCE(MAX(treatmentid),0) FROM grp.treatment) max_treatmentid,",
  "(SELECT COALESCE(MAX(locationid),0) FROM grp.location) max_locationid,",
  "(SELECT COALESCE(MAX(paperid),0) FROM grp.paper) max_paperid,",
  "(SELECT COALESCE(MAX(author_contributorid),0) FROM grp.author_contributor) max_authorid,",
  "(SELECT COALESCE(MAX(seed_mixid),0) FROM grp.seed_mix) max_seedmixid,",
  "(SELECT COALESCE(MAX(seedingid),0) FROM grp.seeding) max_seedingid,",
  "(SELECT COUNT(*) FROM grp.project WHERE database='GAZP' AND projectid=10) existing_project"
))
expected_max <- c(
  max_areaid=min(staging$area$areaid)-1,
  max_treatmentid=min(staging$treatment$treatmentid)-1,
  max_locationid=min(staging$location$locationid)-1,
  max_paperid=min(staging$paper$paperid)-1,
  max_authorid=min(staging$author_contributor$author_contributorid)-1,
  max_seedmixid=min(staging$seed_mix$seed_mixid)-1,
  max_seedingid=min(staging$seeding$seedingid)-1
)
live_vector <- vapply(
  live_state[1,names(expected_max)],
  function(x) as.numeric(x[[1]]),
  numeric(1)
)
live_id_audit <- tibble(
  id_type=names(expected_max),expected_max=as.numeric(expected_max),
  live_max=as.numeric(live_vector),
  status=if_else(expected_max==live_vector,"pass","blocker")
)
write_csv(live_id_audit,file.path(commit_dir,"live_id_audit.csv"),na="")
stop_if(any(live_id_audit$status!="pass"),"Live identifier maxima changed after the approved build.")
stop_if(as.numeric(live_state$existing_project[[1]])!=0,"GAZP10 already exists in grp.project.")

schema_audit <- bind_rows(lapply(names(staging),function(table) {
  target_fields <- dbListFields(con,Id(schema="grp",table=table))
  extra <- setdiff(names(staging[[table]]),target_fields)
  tibble(table,staging_columns=ncol(staging[[table]]),
         missing_target_columns=paste(extra,collapse="; "),
         status=if_else(length(extra)==0L,"pass","blocker"))
}))
write_csv(schema_audit,file.path(commit_dir,"target_schema_audit.csv"),na="")
stop_if(any(schema_audit$status!="pass"),"Staging contains columns absent from a target table.")

allowed_artifact_types <- c(
  "raw_data","harmonized_data","transformation_code","mapping_table",
  "transformation_table","processed_output","metadata","notes","other"
)
stop_if(any(!artifact_preview$artifact_type %in% allowed_artifact_types),
        "The artifact manifest contains a type outside the database vocabulary.")
documentation_columns <- list(
  import_batch=c("database","projectid","source_folder","source_file_list","workflow_version",
                 "processed_by","processed_date","pipeline_stage_start","pipeline_stage_end","notes"),
  import_project=c("import_batchid","database","projectid","contribution_type","contribution_period",
                   "documentation_tier","import_status","import_started_at","import_completed_at",
                   "is_current_version","notes"),
  import_artifact=c("import_projectid","import_batchid","database","projectid","artifact_type",
                    "artifact_subtype","file_name","file_extension","file_path_or_storage_key",
                    "storage_bucket","source_layer","workflow_stage","created_by","created_date",
                    "loaded_at","notes"),
  import_transformation_step=c("import_projectid","import_batchid","database","projectid","step_order",
                               "step_name","step_description","transformation_type",
                               "software_or_language","notes"),
  import_transformation_step_artifact=c("import_transformation_stepid","import_artifactid",
                                        "artifact_role","notes")
)
documentation_schema_audit <- bind_rows(lapply(names(documentation_columns),function(table) {
  missing <- setdiff(documentation_columns[[table]],dbListFields(con,Id(schema="grp",table=table)))
  tibble(table,missing_target_columns=paste(missing,collapse="; "),
         status=if_else(length(missing)==0L,"pass","blocker"))
}))
write_csv(documentation_schema_audit,file.path(commit_dir,"documentation_schema_audit.csv"),na="")
stop_if(any(documentation_schema_audit$status!="pass"),"The live provenance-table schema does not match the commit workflow.")

dry_run_receipt <- staged_counts |>
  left_join(select(tables_to_insert,table,commit_order),by="table") |>
  arrange(commit_order) |>
  mutate(status="validated_not_written")
write_csv(dry_run_receipt,file.path(commit_dir,"commit_dry_run.csv"),na="")

if(!COMMIT_IMPORT) {
  message("GAZP10 commit dry run passed.")
  message("Validated ",sum(staged_counts$expected_rows)," staged rows in ",nrow(staged_counts)," nonempty tables.")
  message("Validated ",nrow(artifact_files)," local import artifacts.")
  message("No SQL rows were inserted and no files were uploaded.")
  quit(save="no",status=0)
}

# ---- Explicitly enabled commit: archive files, then load one SQL transaction ----
service_role <- read_secret_bom_safe(
  "C:/Users/nshack/OneDrive - University of Victoria/Documents/R/GRP/skey.csv"
)
supabase_url <- "https://rudybfqutvodkakgctpo.supabase.co"
upload_receipt <- bind_rows(lapply(seq_len(nrow(artifact_files)),function(i) {
  result <- upload_to_supabase(
    local_file=artifact_files$local_path[[i]],
    bucket=artifact_files$storage_bucket[[i]],
    destination_path=artifact_files$file_path_or_storage_key[[i]],
    supabase_url=supabase_url,service_key=service_role,upsert=TRUE
  )
  tibble(file_name=artifact_files$file_name[[i]],destination_path=result$destination_path,
         status_code=result$status_code,status="uploaded")
}))
write_csv(upload_receipt,file.path(commit_dir,"artifact_upload_receipt.csv"),na="")

insert_receipt <- tibble(table=character(),expected_rows=integer(),inserted_rows=integer())
dbBegin(con)
tryCatch({
  for(table in names(staging)) {
    inserted <- dbAppendTable(con,Id(schema="grp",table=table),staging[[table]])
    insert_receipt <- bind_rows(insert_receipt,tibble(
      table=table,expected_rows=nrow(staging[[table]]),inserted_rows=as.integer(inserted)
    ))
  }
  stop_if(any(insert_receipt$expected_rows!=insert_receipt$inserted_rows),"A staged-table insert count did not reconcile.")

  batch_to_write <- batch_preview |>
    transmute(database,projectid=as.integer(projectid),source_folder,source_file_list,
              workflow_version,processed_by,processed_date=as.Date(processed_date),
              pipeline_stage_start,pipeline_stage_end,notes)
  batch_id <- dbGetQuery(con,glue_sql(
    "INSERT INTO grp.import_batch
     (database,projectid,source_folder,source_file_list,workflow_version,processed_by,
      processed_date,pipeline_stage_start,pipeline_stage_end,notes)
     VALUES ({batch_to_write$database[[1]]},{batch_to_write$projectid[[1]]},
      {batch_to_write$source_folder[[1]]},{batch_to_write$source_file_list[[1]]},
      {batch_to_write$workflow_version[[1]]},{batch_to_write$processed_by[[1]]},
      {batch_to_write$processed_date[[1]]},{batch_to_write$pipeline_stage_start[[1]]},
      {batch_to_write$pipeline_stage_end[[1]]},{batch_to_write$notes[[1]]})
     RETURNING import_batchid",.con=con))$import_batchid[[1]]

  project_id <- dbGetQuery(con,glue_sql(
    "INSERT INTO grp.import_project
     (import_batchid,database,projectid,contribution_type,contribution_period,
      documentation_tier,import_status,import_started_at,import_completed_at,is_current_version,notes)
     VALUES ({batch_id},{project_preview$database[[1]]},{as.integer(project_preview$projectid[[1]])},
      {project_preview$contribution_type[[1]]},{project_preview$contribution_period[[1]]},
      {project_preview$documentation_tier[[1]]},'imported',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP,
      {as.logical(project_preview$is_current_version[[1]])},{project_preview$notes[[1]]})
     RETURNING import_projectid",.con=con))$import_projectid[[1]]

  artifacts_to_write <- artifact_preview |>
    mutate(import_projectid=project_id,import_batchid=batch_id,database="GAZP",projectid=10L,
           created_date=as.Date(created_date),loaded_at=Sys.time()) |>
    select(import_projectid,import_batchid,database,projectid,artifact_type,artifact_subtype,
           file_name,file_extension,file_path_or_storage_key,storage_bucket,source_layer,
           workflow_stage,created_by,created_date,loaded_at,notes)
  dbAppendTable(con,Id(schema="grp",table="import_artifact"),artifacts_to_write)

  steps_to_write <- step_preview |>
    mutate(
      step_description=notes,
      software_or_language=case_when(
        step_order %in% c(1L,2L,3L,4L) ~ "R/manual review",
        TRUE ~ "R/PostgreSQL"
      ),import_projectid=project_id,import_batchid=batch_id,database="GAZP",projectid=10L
    ) |>
    select(import_projectid,import_batchid,database,projectid,step_order,step_name,
           step_description,transformation_type,software_or_language,notes)
  dbAppendTable(con,Id(schema="grp",table="import_transformation_step"),steps_to_write)

  artifact_ids <- dbGetQuery(con,glue_sql(
    "SELECT import_artifactid,file_name FROM grp.import_artifact
     WHERE import_batchid={batch_id} AND import_projectid={project_id}",.con=con))
  step_ids <- dbGetQuery(con,glue_sql(
    "SELECT import_transformation_stepid,step_order FROM grp.import_transformation_step
     WHERE import_batchid={batch_id} AND import_projectid={project_id}",.con=con))

  archive_links <- tidyr::crossing(
    step_order=5L,
    artifact_preview |> transmute(
      file_name,
      artifact_role=case_when(
        artifact_type=="transformation_code" ~ "code",
        artifact_type=="mapping_table" ~ "mapping",
        artifact_type=="metadata" ~ "documentation",
        TRUE ~ "input"
      )
    )
  ) |>
    mutate(notes="Artifact archived as part of the complete GAZP10 import record.") |>
    left_join(step_ids,by="step_order") |>
    left_join(artifact_ids,by="file_name") |>
    select(import_transformation_stepid,import_artifactid,artifact_role,notes)
  stop_if(any(!complete.cases(archive_links)),"A provenance step-artifact link could not be resolved.")
  dbAppendTable(con,Id(schema="grp",table="import_transformation_step_artifact"),archive_links)

  postcheck <- dbGetQuery(con,paste(
    "SELECT",
    "(SELECT COUNT(*) FROM grp.project WHERE database='GAZP' AND projectid=10) project_rows,",
    glue("(SELECT COUNT(*) FROM grp.area WHERE areaid BETWEEN {min(staging$area$areaid)} AND {max(staging$area$areaid)}) area_rows,"),
    glue("(SELECT COUNT(*) FROM grp.treatment WHERE treatmentid BETWEEN {min(staging$treatment$treatmentid)} AND {max(staging$treatment$treatmentid)}) treatment_rows,"),
    "(SELECT COUNT(*) FROM grp.area_treatment WHERE database='GAZP' AND projectid=10) area_treatment_rows,",
    glue("(SELECT COUNT(*) FROM grp.seeding WHERE seedingid BETWEEN {min(staging$seeding$seedingid)} AND {max(staging$seeding$seedingid)}) seeding_rows,"),
    glue("(SELECT COUNT(*) FROM grp.veg_result WHERE areaid BETWEEN {min(staging$area$areaid)} AND {max(staging$area$areaid)}) veg_result_rows,"),
    glue("(SELECT COUNT(*) FROM grp.import_artifact WHERE import_batchid={batch_id}) artifact_rows")
  ))
  expected_postcheck <- c(project_rows=1,area_rows=75,treatment_rows=4,
                          area_treatment_rows=114,seeding_rows=32,
                          veg_result_rows=2625,artifact_rows=17)
  observed_postcheck <- vapply(
    postcheck[1,names(expected_postcheck)],function(x) as.numeric(x[[1]]),numeric(1)
  )
  stop_if(any(observed_postcheck!=expected_postcheck),
          "Post-insert row-loss audit failed; transaction will be rolled back.")

  dbCommit(con)
  write_csv(insert_receipt,file.path(commit_dir,"database_insert_receipt.csv"),na="")
  write_csv(postcheck,file.path(commit_dir,"postcommit_row_audit.csv"),na="")
  message("GAZP10 SQL transaction committed successfully.")
},error=function(e) {
  dbRollback(con)
  stop(e)
})
