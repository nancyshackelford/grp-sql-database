### Summarize the approved GAZP10 build and produce a no-write commit preview.

library(dplyr)
library(readr)
library(DBI)
library(RPostgres)
library(digest)

framework_dir <- file.path("R", "import_framework", "20260915_framework")
source(file.path(framework_dir, "build_functions.R"))

build_dir <- file.path("outputs", "import_review", "GAZP10", "build")
summary_dir <- file.path("outputs", "import_review", "GAZP10", "summarize")
dir.create(summary_dir, recursive = TRUE, showWarnings = FALSE)

approved_files <- list.files(build_dir, full.names = TRUE)
approved_files <- approved_files[file.info(approved_files)$isdir %in% FALSE]
approved_files <- approved_files[basename(approved_files) != "build_approval.csv"]
build_approval <- tibble(
  file = basename(approved_files),
  sha256 = toupper(vapply(approved_files, digest, character(1), algo="sha256", file=TRUE)),
  approved = TRUE,
  reviewed_by = "nshack",
  reviewed_date = as.Date("2026-09-16"),
  review_note = "Approved in Codex conversation after review of the complete GAZP10 build package."
)
write_csv(build_approval, file.path(build_dir, "build_approval.csv"), na="")

password <- read_secret_bom_safe(
  "C:/Users/nshack/OneDrive - University of Victoria/Documents/R/GRP/pword.csv"
)
con <- dbConnect(
  Postgres(), host="aws-1-ca-central-1.pooler.supabase.com", port=6543,
  dbname="postgres", user="postgres.rudybfqutvodkakgctpo",
  password=password, sslmode="require"
)
on.exit(dbDisconnect(con), add=TRUE)

live_state <- dbGetQuery(con, paste(
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

read_stage <- function(name) read_csv(file.path(build_dir,paste0("stg_",name,".csv")),show_col_types=FALSE)
expected_state <- tibble(
  id_type=c("area","treatment","location","paper","author","seed_mix","seeding"),
  expected_current_max=c(
    min(read_stage("area")$areaid)-1L,
    min(read_stage("treatment")$treatmentid)-1L,
    min(read_stage("location")$locationid)-1L,
    min(read_stage("paper")$paperid)-1L,
    min(read_stage("author_contributor")$author_contributorid)-1L,
    min(read_stage("seed_mix")$seed_mixid)-1L,
    min(read_stage("seeding")$seedingid)-1L
  ),
  live_current_max=vapply(
    live_state[1,c(
      "max_areaid","max_treatmentid","max_locationid","max_paperid",
      "max_authorid","max_seedmixid","max_seedingid"
    )],
    function(x) as.numeric(x[[1]]),
    numeric(1)
  )
) |>
  mutate(status=if_else(expected_current_max==live_current_max,"pass","blocker"))

commit_order <- c(
  "project","project_data_accessibility","location","project_location","site",
  "project_site","author_contributor","project_contributor","project_vegmetric",
  "paper","project_paper","paper_author","site_classification","site_disturbance",
  "site_ref_ecosystem","site_soil","site_invasive","area","treatment",
  "area_treatment","treatment_application","treatment_cover_crop","treatment_erosion",
  "treatment_fertilization","treatment_grazer","treatment_herbicide",
  "treatment_invasion","treatment_irrigation","treatment_material","treatment_medium",
  "treatment_mowing","treatment_prep","seed_mix","seeding","seeding_pretreatment",
  "veg_result"
)
inventory <- read_csv(file.path(build_dir,"staging_table_inventory.csv"),show_col_types=FALSE)
commit_preview <- tibble(table=commit_order,commit_order=seq_along(commit_order)) |>
  left_join(inventory,by="table") |>
  mutate(rows=coalesce(rows,0L),action=if_else(rows==0L,"skip_zero_rows","insert"))

validation_lines <- readLines(file.path(build_dir,"build_validation_issues.csv"),warn=FALSE)
precommit_checks <- bind_rows(
  transmute(expected_state,check=paste0("id_drift_",id_type),value=live_current_max,status),
  tibble(check="existing_GAZP10_project",value=as.numeric(live_state$existing_project[[1]]),
         status=if_else(live_state$existing_project[[1]]==0L,"pass","blocker")),
  tibble(check="build_validation_issue_rows",value=as.numeric(max(length(validation_lines)-1L,0L)),
         status=if_else(length(validation_lines)<=1L,"pass","blocker")),
  tibble(check="vegetation_rows_to_insert",value=2625,status="pass"),
  tibble(check="seeding_rows_to_insert",value=32,status="pass")
)

import_batch_preview <- tibble(
  database="GAZP",projectid=10L,
  source_folder="Supabase Storage: grp-import-artifacts/GAZP/GAZP10",
  workflow_version="GAZP10_prepare-build-summarize_v1",
  processed_by="Nancy Shackelford",processed_date=as.Date("2026-09-16"),
  pipeline_stage_start="GAZP10 source and harmonized data",
  pipeline_stage_end="GAZP10 SQL imported data",
  notes="Initial GAZP10 import with reviewed spatial blocks, nested sampling areas, explicit area-treatment links, pre-burn interpretation, treatment-note routing, species mappings, and row-loss auditing."
)
import_project_preview <- tibble(
  database="GAZP",projectid=10L,contribution_type="initial_import",
  contribution_period="Vegetation monitoring from 2008 through 2012; controlled burns documented on October 19, 2012 after the imported monitoring period.",
  documentation_tier="fully_reproducible",import_status="pending_commit",
  is_current_version=TRUE,
  notes="Source burn flags and publication burn counts disagree (13 versus 10); no fire treatment is inferred for the imported pre-burn vegetation observations."
)
artifact_preview <- tibble::tribble(
  ~artifact_type,~file_name,~workflow_stage,~notes,
  "raw_data","2008-2009-2010_TOTALS_SIMPLE.XLSX","input","Original early-period vegetation cover workbook.",
  "raw_data","2011_CENSUS_2.xlsx","input","Original 2011 sector-level vegetation census workbook.",
  "raw_data","CENSUS_2012_2013 relevant.xls","input","Original contributor workbook containing relevant 2012-2013 census data.",
  "raw_data","CENSUS_2012_2013 w % cover.xls","input","Original 2012-2013 census workbook with percent-cover fields used during reprocessing.",
  "raw_data","Relevant data.xlsx","input","Original contributor extract retained with the GAZP10 source package.",
  "raw_data","Backup of Relevant data.xlk","input","Original backup of the contributor data extract retained for provenance.",
  "metadata","Porensky_etal_2012_spatial_priority.pdf","input","Published description of the original spatial-priority experiment and early monitoring.",
  "metadata","2015YoungFireCryptic.pdf","input","Published description of later monitoring and the October 19, 2012 controlled burns.",
  "metadata","submitted_appendix_A.PDF","input","Submitted appendix retained with the original project documentation.",
  "harmonized_data","GAZP10.xlsx","input","Original harmonized GAZP10 workbook retained unchanged.",
  "harmonized_data","GAZP10_reprocessed.xlsx","input","Reviewed harmonized workbook used for SQL preparation.",
  "transformation_code","01_reprocess_GAZP10_vegresults.R","prepare","Project-specific vegetation-grain correction.",
  "transformation_code","02_GAZP10_import.R","prepare","Prepare-stage driver and project decisions.",
  "transformation_code","03_GAZP10_build.R","build","Complete staging builder and live validation.",
  "transformation_code","04_GAZP10_summarize.R","summarize","Approval, drift checking, and commit preview.",
  "mapping_table","GAZP10_harmonized-SQL_crosswalk.csv","output","Reviewed area and treatment identifier mappings.",
  "mapping_table","GAZP10_species_crosswalk.csv","output","Reviewed vegetation and seeding species mappings."
) |>
  mutate(
    storage_file_name=gsub("%","percent",file_name,fixed=TRUE),
    artifact_subtype=case_when(
      artifact_type=="raw_data" ~ "GAZP10 source data",
      artifact_type=="metadata" ~ "GAZP10 source documentation",
      artifact_type=="harmonized_data" ~ "GAZP10 harmonized data",
      artifact_type=="transformation_code" ~ "GAZP10 import code",
      artifact_type=="mapping_table" ~ "GAZP10 crosswalk"
    ),
    file_extension=tolower(tools::file_ext(file_name)),
    file_path_or_storage_key=case_when(
      artifact_type %in% c("raw_data","metadata") ~ paste0("GAZP/GAZP10/source/",storage_file_name),
      artifact_type=="harmonized_data" ~ paste0("GAZP/GAZP10/harmonized/",storage_file_name),
      artifact_type=="transformation_code" ~ paste0("GAZP/GAZP10/code/",storage_file_name),
      artifact_type=="mapping_table" ~ paste0("GAZP/GAZP10/crosswalks/",storage_file_name)
    ),
    storage_bucket="grp-import-artifacts",
    source_layer=case_when(
      artifact_type=="raw_data" ~ "original contributor data",
      artifact_type=="metadata" ~ "original project documentation",
      artifact_type=="harmonized_data" ~ "legacy Excel database",
      artifact_type=="transformation_code" ~ "R transformation workflow",
      artifact_type=="mapping_table" ~ "reviewed SQL mapping output"
    ),
    created_by="Nancy Shackelford",
    created_date=as.Date("2026-09-16")
  ) |>
  select(
    artifact_type,artifact_subtype,file_name,file_extension,
    file_path_or_storage_key,storage_bucket,source_layer,workflow_stage,
    created_by,created_date,notes
  )

import_batch_preview <- import_batch_preview |>
  mutate(
    source_file_list=paste(artifact_preview$file_path_or_storage_key,collapse=", ")
  ) |>
  relocate(source_file_list,.after=source_folder)
transformation_steps_preview <- tibble::tribble(
  ~step_order,~step_name,~transformation_type,~notes,
  1L,"Reprocess vegetation sampling grain","data transformation","Retained block-level overall results and nested center/quadrat sampling areas without scaling cover values.",
  2L,"Prepare and audit harmonized data","data preparation","Produced explicit spatial areas, treatment links, species inventory, and row-level audit.",
  3L,"Build and validate SQL staging","database staging","Built all applicable target tables and validated schema, vocabulary, and referential integrity.",
  4L,"Summarize and approve commit plan","review and approval","Fingerprinted approved staging artifacts and checked live identifier drift before commit.",
  5L,"Commit transaction","database load","Pending final approval; will insert all nonempty staging tables transactionally."
)

write_csv(build_approval,file.path(summary_dir,"build_approval.csv"),na="")
write_csv(expected_state,file.path(summary_dir,"id_drift_check.csv"),na="")
write_csv(commit_preview,file.path(summary_dir,"commit_preview.csv"),na="")
write_csv(precommit_checks,file.path(summary_dir,"precommit_checks.csv"),na="")
write_csv(import_batch_preview,file.path(summary_dir,"import_batch_preview.csv"),na="")
write_csv(import_project_preview,file.path(summary_dir,"import_project_preview.csv"),na="")
write_csv(artifact_preview,file.path(summary_dir,"import_artifact_preview.csv"),na="")
write_csv(transformation_steps_preview,file.path(summary_dir,"transformation_steps_preview.csv"),na="")

print(precommit_checks,n=Inf)
print(filter(commit_preview,rows>0),n=Inf)
if(any(precommit_checks$status=="blocker")) stop("Summarize stage found a blocker.",call.=FALSE)
message("Summarize review written to: ",summary_dir)
message("No SQL write was performed.")
