### Build SQL-shaped GAZP10 staging tables for review; no database writes.

library(dplyr)
library(readr)
library(readxl)
library(stringr)
library(tidyr)
library(DBI)
library(RPostgres)

framework_dir <- file.path("R", "import_framework", "20260915_framework")
source(file.path(framework_dir, "build_functions.R"))

prepare_dir <- file.path("outputs", "import_review", "GAZP10", "prepare")
build_dir <- file.path("outputs", "import_review", "GAZP10", "build")
dir.create(build_dir, recursive = TRUE, showWarnings = FALSE)
validate_prepare_approval(prepare_dir)

areas <- read_csv(file.path(prepare_dir, "prepared_area.csv"), show_col_types = FALSE)
area_links <- read_csv(file.path(prepare_dir, "prepared_area_treatment.csv"), show_col_types = FALSE)
treatments <- read_csv(file.path(prepare_dir, "prepared_treatment.csv"), show_col_types = FALSE)
vegresults <- read_csv(file.path(prepare_dir, "prepared_vegresults.csv"), show_col_types = FALSE)
species <- read_csv(file.path(prepare_dir, "species_review.csv"), show_col_types = FALSE)
manifest <- read_csv(file.path(prepare_dir, "project_manifest.csv"), show_col_types = FALSE)
harmonized_path <- file.path("data", "harmonized", "GAZP", "GAZP10", "GAZP10_reprocessed.xlsx")
study <- read_excel(harmonized_path, "study")
site <- read_excel(harmonized_path, "site")
refs <- read_excel(harmonized_path, "refs")
trtrates <- read_excel(harmonized_path, "trtrates")
source_treatments <- read_excel(harmonized_path, "treatments")

password <- read_secret_bom_safe(
  "C:/Users/nshack/OneDrive - University of Victoria/Documents/R/GRP/pword.csv"
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
on.exit(dbDisconnect(con), add = TRUE)
source(file.path(framework_dir, "import_registry.r"))

id_state <- read_sql_id_state(con, "GAZP", 10L)
area_crosswalk <- build_area_id_crosswalk(areas, id_state$max_areaid[[1]] + 1L)
treatment_build <- build_treatment_staging(treatments, id_state$max_treatmentid[[1]] + 1L)
species_crosswalk <- build_species_crosswalk(species)

species_names <- dbGetQuery(
  con,
  "SELECT speciesid, species_code, name FROM grp.species_names"
)

id_maxima <- dbGetQuery(con, paste(
  "SELECT",
  "(SELECT COALESCE(MAX(locationid),0) FROM grp.location) max_locationid,",
  "(SELECT COALESCE(MAX(paperid),0) FROM grp.paper) max_paperid,",
  "(SELECT COALESCE(MAX(author_contributorid),0) FROM grp.author_contributor) max_authorid,",
  "(SELECT COALESCE(MAX(seed_mixid),0) FROM grp.seed_mix) max_seedmixid,",
  "(SELECT COALESCE(MAX(seedingid),0) FROM grp.seeding) max_seedingid"
))

stg_project <- tibble::tibble(
  database = "GAZP",
  projectid = 10L,
  type = manifest$type[[1]],
  community = manifest$community[[1]],
  reference = manifest$reference[[1]],
  notes = paste(
    manifest$source_project_notes[[1]],
    manifest$project_note_append[[1]],
    sep = "; "
  ),
  date_received = as.Date(manifest$date_received[[1]])
)
stg_area <- build_area_staging(areas, area_crosswalk)
stg_treatment <- treatment_build$staging
stg_area_treatment <- build_area_treatment_staging(
  area_links, area_crosswalk, treatment_build$crosswalk, "GAZP", 10L
)
stg_veg_result <- build_veg_result_staging(vegresults, area_crosswalk, species_crosswalk)

stg_project_data_accessibility <- tibble::tibble(
  database = "GAZP", projectid = 10L,
  availability = as.character(study$availability[[1]]),
  data_citation = NA_character_, data_doi = NA_character_, data_url = NA_character_,
  creativecommons_license = NA_character_, use_conditions = NA_character_,
  date_received = as.Date(manifest$date_received[[1]]),
  data_accessibility_notes = NA_character_
)
stg_location <- tibble::tibble(
  locationid = as.integer(id_maxima$max_locationid[[1]] + 1L),
  continent = "North America", country = "United States of America", state = "California"
)
stg_project_location <- transmute(stg_location, database="GAZP", projectid=10L, locationid)
stg_site <- site |> transmute(
  siteid=as.integer(siteid), name=as.character(sitename), latitude=as.numeric(latitude),
  longitude=as.numeric(longitude), aridity=as.numeric(aridity),
  annual_temp=as.numeric(temp), annual_precip=as.integer(precip)
)
stg_project_site <- tibble::tibble(database="GAZP", projectid=10L, siteid=167L)
stg_paper <- refs |> transmute(
  paperid=as.integer(id_maxima$max_paperid[[1]] + row_number()),
  publication_year=as.integer(pubyear), publication_title=as.character(pubtitle),
  publication_journal=as.character(pubjournal), publication_doi=as.character(pubDOI),
  publication_url=as.character(pubURL)
)
stg_project_paper <- transmute(stg_paper, database="GAZP", projectid=10L, paperid, notes=NA_character_)
name_parts <- str_split_fixed(study$contributor[[1]], "\\s+", 2)
stg_author_contributor <- tibble::tibble(
  author_contributorid=as.integer(id_maxima$max_authorid[[1]] + 1L),
  given_name=name_parts[1], surname=name_parts[2], email=as.character(study$email[[1]])
)
stg_project_contributor <- transmute(stg_author_contributor, database="GAZP", projectid=10L, author_contributorid)
stg_paper_author <- stg_paper |>
  transmute(
    paperid,
    author_contributorid=stg_author_contributor$author_contributorid[[1]],
    is_corresponding_author=FALSE
  )
stg_project_vegmetric <- tibble::tibble(database="GAZP",projectid=10L,type="cover")
stg_site_classification <- tibble::tibble(siteid=167L,classificationid="2.B.1")
stg_site_disturbance <- tibble::tibble(siteid=167L,type="agriculture")
stg_site_ref_ecosystem <- tibble::tibble(siteid=167L,description=as.character(site$refecosystem[[1]]))
stg_site_soil <- tibble::tibble(
  siteid=167L,sand=NA_real_,silt=NA_real_,clay=NA_real_,
  description=as.character(site$soildescription[[1]]),depth=NA_character_
)
stg_site_invasive <- tibble::tibble(siteid=integer(),speciesid=integer())
stg_treatment_application <- source_treatments |>
  transmute(source_treatmentid=as.character(treatmentid),type=str_to_lower(as.character(treatment_type))) |>
  left_join(treatment_build$crosswalk,by="source_treatmentid") |>
  transmute(treatmentid=as.integer(treatmentid),type) |> distinct()

trt_species <- trtrates |> count(source_species_code=as.character(speciesid),name="source_rows") |>
  left_join(species_names,by=c("source_species_code"="species_code"))
if(anyNA(trt_species$speciesid)) stop("A trtrates species did not resolve.")
stg_seed_mix <- treatments |> transmute(source_treatmentid) |>
  left_join(treatment_build$crosswalk,by="source_treatmentid") |>
  mutate(seed_mixid=as.integer(id_maxima$max_seedmixid[[1]]+row_number())) |>
  transmute(seed_mixid,treatmentid=as.integer(treatmentid),mix_name="known",
            mix_composition_status="known",treated_richness="8",notes=NA_character_)
seeding_resolved <- trtrates |>
  transmute(source_treatmentid=as.character(treatmentid),mix=as.character(mix_trt),
            source_species_code=as.character(speciesid),cultivarid=suppressWarnings(as.integer(cultivarid)),
            type=str_to_lower(as.character(trt)),rate=as.numeric(rate),unit=as.character(unit),
            viability=as.character(viability),origin=str_to_lower(as.character(seed_origin)),
            source=na_if(as.character(source),"NA"),seed_distance=na_if(as.character(seeddist),"NA")) |>
  left_join(treatment_build$crosswalk,by="source_treatmentid") |>
  left_join(select(trt_species,source_species_code,speciesid),by="source_species_code") |>
  left_join(select(stg_seed_mix,treatmentid,seed_mixid),by="treatmentid") |>
  mutate(seedingid=as.integer(id_maxima$max_seedingid[[1]]+row_number()))
stg_seeding <- seeding_resolved |> transmute(
  seedingid,treatmentid=as.integer(treatmentid),mix,speciesid=as.integer(speciesid),cultivarid,
  type,rate,unit,viability,origin,source,seed_distance,seed_mixid,notes=NA_character_)
stg_seeding_pretreatment <- tibble::tibble(seedingid=integer(),type=character())

empty_staged <- list(
  treatment_cover_crop=tibble(treatmentid=integer(),speciesid=integer(),amount=numeric(),units=character(),notes=character()),
  treatment_erosion=tibble(treatmentid=integer(),type=character()),
  treatment_fertilization=tibble(treatmentid=integer(),type=character(),amount=numeric(),units=character(),notes=character()),
  treatment_grazer=tibble(treatmentid=integer(),type=character(),notes=character()),
  treatment_herbicide=tibble(treatmentid=integer(),type=character(),chemical=character(),amount=numeric(),units=character(),notes=character()),
  treatment_invasion=tibble(treatmentid=integer(),type=character()),
  treatment_irrigation=tibble(treatmentid=integer(),type=character(),amount=numeric(),units=character(),notes=character()),
  treatment_material=tibble(treatmentid=integer(),type=character()),
  treatment_medium=tibble(treatmentid=integer(),type=character(),top_soil_age=numeric(),notes=character(),growth_medium_depth=numeric(),growth_medium_depth_units=character()),
  treatment_mowing=tibble(treatmentid=integer(),type=character(),height_class=character(),amount=numeric(),units=character(),notes=character()),
  treatment_prep=tibble(treatmentid=integer(),type=character())
)

harmonized_sql_crosswalk <- area_links |>
  left_join(
    areas |>
      select(area_key, type, source_block, source_replicate),
    by = "area_key"
  ) |>
  left_join(area_crosswalk, by = "area_key") |>
  left_join(treatment_build$crosswalk, by = "source_treatmentid") |>
  transmute(
    database = "GAZP",
    projectid = 10L,
    object_type = type,
    source_treatmentid,
    block = source_block,
    replicate = source_replicate,
    areaid = as.integer(areaid),
    treatmentid = as.integer(treatmentid),
    source_trt_tsr = 0L
  ) |>
  arrange(object_type, block, replicate, source_treatmentid)

project_species_crosswalk <- species |>
  left_join(species_names, by = c("sql_speciesid" = "speciesid")) |>
  transmute(
    database = "GAZP",
    projectid = 10L,
    project_code = "GAZP10",
    crosswalk_row_type = "default",
    rule_source_table = "all_relevant_tables",
    source_table = "vegresults",
    source_column = "speciesid",
    source_value_type = "species_code",
    source_value = source_species_code,
    source_occurrences = source_rows,
    speciesid = as.integer(sql_speciesid),
    accepted_species_code = species_code,
    accepted_species_name = name,
    mapping_status = "accepted_code_mapping",
    reverse_mapping_rule = "speciesid",
    match_rate = NA_real_,
    match_unit = NA_character_,
    contextual_rule_validated = TRUE,
    global_source_code_count = NA_integer_,
    global_source_codes = NA_character_,
    review_required = FALSE,
    reviewed = FALSE,
    decision_note = "Resolved through the global species-code crosswalk."
  )
project_species_crosswalk <- bind_rows(
  project_species_crosswalk,
  trt_species |> transmute(
    database="GAZP",projectid=10L,project_code="GAZP10",crosswalk_row_type="default",
    rule_source_table="all_relevant_tables",source_table="trtrates",source_column="speciesid",
    source_value_type="species_code",source_value=source_species_code,source_occurrences=source_rows,
    speciesid=as.integer(speciesid),accepted_species_code=source_species_code,accepted_species_name=name,
    mapping_status="accepted_code_mapping",reverse_mapping_rule="speciesid",match_rate=NA_real_,
    match_unit=NA_character_,contextual_rule_validated=TRUE,global_source_code_count=NA_integer_,
    global_source_codes=NA_character_,review_required=FALSE,reviewed=FALSE,
    decision_note="Resolved through the global species-code crosswalk."
  )
)

stopifnot(
  nrow(stg_area) == 75L,
  nrow(stg_treatment) == 4L,
  nrow(stg_area_treatment) == 114L,
  nrow(stg_veg_result) == 2625L,
  !anyNA(stg_area$areaid),
  !anyNA(stg_veg_result$areaid),
  !anyNA(stg_veg_result$speciesid)
)

staged_tables <- list(
  project=stg_project,project_data_accessibility=stg_project_data_accessibility,
  location=stg_location,project_location=stg_project_location,site=stg_site,
  project_site=stg_project_site,paper=stg_paper,project_paper=stg_project_paper,
  author_contributor=stg_author_contributor,paper_author=stg_paper_author,
  project_contributor=stg_project_contributor,project_vegmetric=stg_project_vegmetric,
  site_classification=stg_site_classification,site_disturbance=stg_site_disturbance,
  site_ref_ecosystem=stg_site_ref_ecosystem,site_soil=stg_site_soil,site_invasive=stg_site_invasive,
  area=stg_area,treatment=stg_treatment,area_treatment=stg_area_treatment,
  treatment_application=stg_treatment_application,seed_mix=stg_seed_mix,
  seeding=stg_seeding,seeding_pretreatment=stg_seeding_pretreatment,veg_result=stg_veg_result
)
staged_tables <- c(staged_tables,empty_staged)

stopifnot(
  all(na.omit(stg_area$parentid) %in% stg_area$areaid),
  all(stg_area_treatment$areaid %in% stg_area$areaid),
  all(stg_area_treatment$treatmentid %in% stg_treatment$treatmentid),
  all(stg_treatment_application$treatmentid %in% stg_treatment$treatmentid),
  all(stg_seed_mix$treatmentid %in% stg_treatment$treatmentid),
  all(stg_seeding$treatmentid %in% stg_treatment$treatmentid),
  all(stg_seeding$seed_mixid %in% stg_seed_mix$seed_mixid),
  all(stg_seeding$speciesid %in% species_names$speciesid),
  all(stg_veg_result$areaid %in% stg_area$areaid),
  all(stg_veg_result$speciesid %in% species_names$speciesid)
)

constraint_issues <- purrr::imap_dfr(staged_tables, function(tbl, table_name) {
  validate_staged_table(tbl, table_name, import_registry$constraints)
})
lookup_issues <- purrr::imap_dfr(staged_tables, function(tbl, table_name) {
  if (nrow(tbl) == 0L) return(NULL)
  validate_lookup_constraints(tbl, table_name, import_registry$constraints, con)
})
referential_issues <- validate_referential_integrity(
  staged_tables=staged_tables,
  constraints_tbl=import_registry$constraints,
  con=con
)
validation_issues <- bind_rows(constraint_issues,lookup_issues,referential_issues)

build_summary <- tibble::tribble(
  ~check, ~value, ~status,
  "project_rows", nrow(stg_project), "pass",
  "area_rows", nrow(stg_area), "pass",
  "treatment_rows", nrow(stg_treatment), "pass",
  "area_treatment_rows", nrow(stg_area_treatment), "pass",
  "veg_result_rows", nrow(stg_veg_result), "pass",
  "veg_rows_lost", nrow(vegresults) - nrow(stg_veg_result), "pass",
  "existing_project_rows", id_state$existing_project[[1]], "pass"
)
table_inventory <- tibble::tibble(table=names(staged_tables),rows=vapply(staged_tables,nrow,integer(1)),status="built")

write_csv(stg_project, file.path(build_dir, "stg_project.csv"), na = "")
write_csv(stg_area, file.path(build_dir, "stg_area.csv"), na = "")
write_csv(stg_treatment, file.path(build_dir, "stg_treatment.csv"), na = "")
write_csv(stg_area_treatment, file.path(build_dir, "stg_area_treatment.csv"), na = "")
write_csv(stg_veg_result, file.path(build_dir, "stg_veg_result.csv"), na = "")
write_csv(build_summary, file.path(build_dir, "build_summary.csv"), na = "")
purrr::iwalk(staged_tables, ~write_csv(.x,file.path(build_dir,paste0("stg_",.y,".csv")),na=""))
write_csv(table_inventory,file.path(build_dir,"staging_table_inventory.csv"),na="")
write_csv(validation_issues,file.path(build_dir,"build_validation_issues.csv"),na="")
write_csv(
  harmonized_sql_crosswalk,
  file.path(build_dir, "GAZP10_harmonized-SQL_crosswalk.csv"),
  na = "NA"
)
write_csv(
  project_species_crosswalk,
  file.path(build_dir, "GAZP10_species_crosswalk.csv"),
  na = ""
)

unlink(file.path(
  build_dir,
  c("area_crosswalk.csv", "treatment_crosswalk.csv", "species_crosswalk.csv")
))

crosswalk_dir <- file.path("crosswalk_tables", "GAZP", "GAZP10")
dir.create(crosswalk_dir, recursive = TRUE, showWarnings = FALSE)
write_csv(
  harmonized_sql_crosswalk,
  file.path(crosswalk_dir, "GAZP10_harmonized-SQL_crosswalk.csv"),
  na = "NA"
)
write_csv(
  project_species_crosswalk,
  file.path(crosswalk_dir, "GAZP10_species_crosswalk.csv"),
  na = ""
)

print(build_summary)
if(nrow(validation_issues)>0L) print(validation_issues,n=Inf)
if(any(validation_issues$issue_severity=="blocker")) stop("Build validation produced blocker issues.",call.=FALSE)
message("Build review written to: ", build_dir)
message("No SQL write was performed.")
