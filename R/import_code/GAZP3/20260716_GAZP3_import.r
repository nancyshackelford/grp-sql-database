### This is to import GAZP3 into the SQL database from the Excel format
### It will be a third draft of the larger import process
### The update here will be adding the third validation at the end of the staging creation

### Libraries and source files
library(tidyverse)
library(openxlsx)
library(DBI)
library(RPostgres)
library(glue)

### Connect to Supabase database
password <- readLines("C:\\Users\\nshack\\OneDrive - University of Victoria\\Documents\\R\\GRP\\pword.csv")
service_role <- readLines("C:\\Users\\nshack\\OneDrive - University of Victoria\\Documents\\R\\GRP\\skey.csv")

con <- dbConnect(
  Postgres(),
  host = "aws-1-ca-central-1.pooler.supabase.com",
  port = 6543,
  dbname = "postgres",
  user = "postgres.rudybfqutvodkakgctpo",
  password = password,
  sslmode = "require"
)

# Test connection
dbListTables(con)

### Get Supabase details for file upload
Sys.getenv("SUPABASE_URL")
Sys.getenv("SUPABASE_SERVICE_KEY")

### Read workbook tables
# Names of all sheets
sheets <- getSheetNames("data/harmonized/GAZP/GAZP3/GAZP3.xlsx")

# Individual sheets
study <- read.xlsx("data/harmonized/GAZP/GAZP3/GAZP3.xlsx", sheet = "study")
site <- read.xlsx("data/harmonized/GAZP/GAZP3/GAZP3.xlsx", sheet = "site")
treatments <- read.xlsx("data/harmonized/GAZP/GAZP3/GAZP3.xlsx", sheet = "treatments")
timepoints <- read.xlsx("data/harmonized/GAZP/GAZP3/GAZP3.xlsx", sheet = "timepoints")
trtrates <- read.xlsx("data/harmonized/GAZP/GAZP3/GAZP3.xlsx", sheet = "trtrates")
refs <- read.xlsx("data/harmonized/GAZP/GAZP3/GAZP3.xlsx", sheet = "refs")
vegresults <- read.xlsx("data/harmonized/GAZP/GAZP3/GAZP3.xlsx", sheet = "vegresults")

# As a list
data_list <- list(
  study = study,
  site = site,
  treatments = treatments,
  timepoints = timepoints,
  trtrates = trtrates,
  refs = refs,
  vegresults = vegresults
)

### Pull constraints and lookup tables list
source("R/source_drafts/20260612_import_registry.r") # Note this code requires the db connection be called con
source("R/source_drafts/20260620_import_helper_functions.r")

### Create species lookup table
sp_crosswalk <- readr::read_csv(
  "crosswalk_tables/20260605_sp_crosswalk.csv",
  show_col_types = FALSE
)
lu_species <- get_lookup_table(con, "species_names")

species_lookup <- sp_crosswalk |>
  transmute(
    source_species_code = na_if_blank(excel_speciesid),
    speciesid = as.integer(sql_speciesid)
  ) |>
  filter(!is.na(source_species_code), !is.na(speciesid)) |>
  distinct()

species_lookup <- species_lookup |>
    mutate(
    species_code = as.character(source_species_code)
  ) |>
  left_join(
    lu_species
  ) |>
  select(-species_code)

### Staging output
staging_plan <- list(
  # Group 1: Project backbone
  project = c("study"),
  project_data_accessibility = c("study", "refs"),
  location = c("study"),
  project_location = c("study"),
  site = c("site"),
  project_site = c("study", "site"),
  paper = c("refs"),
  author_contributor = c("study", "refs"),
  paper_author = c("refs"),
  project_paper = c("study", "refs"),
  project_contributor = c("study"),
  project_vegmetric = c("study"),

  # Group 2: Site attributes
  site_classification = c("site"),
  site_disturbance = c("site"),
  site_ref_ecosystem = c("site"),
  site_soil = c("site"),
  site_invasive = c("site"),

  # Group 3: Experimental structure
  area = c("treatments", "vegresults"),
  treatment = c("treatments"),
  area_treatment = c("treatments", "vegresults"),

  # Group 4: Treatment details
  treatment_application = c("treatments"),
  treatment_cover_crop = c("treatments"),
  treatment_erosion = c("treatments"),
  treatment_fertilization = c("treatments"),
  treatment_grazer = c("treatments"),
  treatment_herbicide = c("treatments"),
  treatment_invasion = c("treatments"),
  treatment_irrigation = c("treatments"),
  treatment_material = c("treatments"),
  treatment_medium = c("treatments"),
  treatment_mowing = c("treatments"),
  treatment_prep = c("treatments"),
  
  # Group 5: Seeding and planting
  seed_mix = c("trtrates"),
  seeding = c("trtrates"),
  seeding_pretreatment = c("trtrates"),

  # Group 6: Results
  veg_result = c("vegresults", "timepoints")
)


#### Group 1: Project backbone
# ---- project ----

stg_project <- study |>
  transmute(
    database = DB,
    projectid = as.integer(projectid),
    type = stringr::str_to_lower(na_if_blank(studytype)),
    community = na_if_blank(community),
    reference = na_if_blank(refdata),
    notes = na_if_blank(notes),
    date_received = as.Date("2018-02-13") ############# CHANGE PER PROJECT
  ) |>
  distinct()

head(stg_project)

project_issues <- validate_staged_table(
  stg_tbl = stg_project,
  target_table = "project",
  constraints_tbl = import_registry$constraints
)

project_issues

# ---- project_data_accessibility ----
# data_accessibilityid is identity-generated, so omit it.

stg_project_data_accessibility <- study |>
  transmute(
    database = as.character(DB),
    projectid = as.integer(projectid),
    availability = na_if_blank(availability)
  ) |>
  left_join(
    refs |>
      transmute(
        database = as.character(DB),
        projectid = as.integer(projectid),
        data_citation = na_if_blank(citationofdatasource),
        data_doi = NA_character_,
        data_url = NA_character_,
        creativecommons_license = na_if_blank(creativecommonsliscence),
        use_conditions = na_if_blank(conditionsforuseandrepublishing),
        data_accessibility_notes = NA_character_
      ) |>
      distinct(),
    by = c("database", "projectid")
  ) |>
  mutate(
    date_received = as.Date("2018-02-13") # CHANGE PER PROJECT and update when refs sheet has a value
  ) |>
  transmute(
    database,
    projectid,
    availability,
    data_citation,
    data_doi,
    data_url,
    creativecommons_license,
    use_conditions,
    date_received,
    data_accessibility_notes
  ) |>
  distinct()

head(stg_project_data_accessibility)

project_data_accessibility_issues <- validate_staged_table(
  stg_tbl = stg_project_data_accessibility,
  target_table = "project_data_accessibility",
  constraints_tbl = import_registry$constraints
)

project_data_accessibility_issues

# ---- location ----
# Reuse locationid where continent/country/state already exists.
# Otherwise allocate new location IDs.

# Existing database records needed for matching
db_location <- DBI::dbGetQuery(
  con,
  "SELECT locationid, continent, country, state FROM grp.location"
)

location_candidates <- study |>
  transmute(
    continent = na_if_blank(continent),
    country = na_if_blank(country),
    state = na_if_blank(state)
  ) |>
  mutate(
    continent = case_when(
      continent == "Australia" ~ "Oceania",
      TRUE ~ continent
    ),
    country = case_when(
      country == "USA" ~ "United States of America",
      TRUE ~ country
    )
  ) |>
  distinct()

location_matched <- location_candidates |>
  left_join(
    db_location,
    by = c("continent", "country", "state")
  )

new_locations <- location_matched |>
  filter(is.na(locationid)) |>
  select(continent, country, state) |>
  distinct()

if (nrow(new_locations) > 0) {
  new_locations <- new_locations |>
    mutate(
      locationid = next_ids(
        con,
        table = "location",
        id_col = "locationid",
        n = n()
      )
    )
} else {
  new_locations <- new_locations |>
    mutate(locationid = integer())
}

stg_location <- bind_rows(
  location_matched |>
    filter(!is.na(locationid)) |>
    select(locationid, continent, country, state),
  new_locations |>
    select(locationid, continent, country, state)
) |>
  distinct()

head(stg_location)

location_issues <- validate_staged_table(
  stg_tbl = stg_location,
  target_table = "location",
  constraints_tbl = import_registry$constraints
)

location_issues

# ---- project_location ----
# NOTE: If any more caveats / transformations go into the location coding, they must go here, as well

stg_project_location <- study |>
  transmute(
    database = DB,
    projectid = as.integer(projectid),
    continent = na_if_blank(continent),
    country = na_if_blank(country),
    state = na_if_blank(state)
  ) |>
  mutate(
    continent = case_when(
      continent == "Australia" ~ "Oceania",
      TRUE ~ continent
    ),
    country = case_when(
      country == "USA" ~ "United States of America",
      TRUE ~ country
    )
  ) |>
  left_join(
    stg_location,
    by = c("continent", "country", "state")
  ) |>
  transmute(
    database,
    projectid,
    locationid
  ) |>
  distinct()

head(stg_project_location)

project_location_issues <- validate_staged_table(
  stg_tbl = stg_project_location,
  target_table = "project_location",
  constraints_tbl = import_registry$constraints
)

project_location_issues

# ---- site ----
# Reuse siteid where sitename already exists.
# Otherwise use workbook siteid if available.
# This assumes sitename is the first matching rule.

# Existing database records needed for matching
db_site <- DBI::dbGetQuery(
  con,
  "SELECT siteid, name, latitude, longitude FROM grp.site"
)

site_candidates <- site |>
  transmute(
    source_siteid = as.integer(siteid),
    name = na_if_blank(sitename),
    latitude = as.numeric(latitude),
    longitude = as.numeric(longitude),
    aridity = as.numeric(aridity),
    annual_temp = as.numeric(temp),
    annual_precip = as.integer(precip)
  ) |>
  distinct()

site_matched <- site_candidates |>
  left_join(
    db_site |> select(existing_siteid = siteid, name),
    by = "name",
    na_matches = "never"
  )

stg_site <- site_matched |>
  mutate(
    siteid = coalesce(existing_siteid, source_siteid) # This defaults to taking the Excel value for siteid if no match is found in the database
  ) |>
  transmute(
    siteid,
    name,
    latitude,
    longitude,
    aridity,
    annual_temp,
    annual_precip
  ) |>
  distinct()

head(stg_site)

site_issues <- validate_staged_table(
  stg_tbl = stg_site,
  target_table = "site",
  constraints_tbl = import_registry$constraints
)

site_issues

# ---- project_site ----

stg_project_site <- site |>
  transmute(
    database = as.character(DB),
    projectid = as.integer(projectid),
    source_siteid = as.integer(siteid),
    name = na_if_blank(sitename)
  ) |>
  left_join(
    stg_site |>
      select(siteid, name),
    by = "name"
  ) |>
  transmute(
    database,
    projectid,
    siteid
  ) |>
  distinct()

head(stg_project_site)

project_site_issues <- validate_staged_table(
  stg_tbl = stg_project_site,
  target_table = "project_site",
  constraints_tbl = import_registry$constraints
)

project_site_issues

# ---- paper ----
# refs is empty for GAZP2, but this keeps the staged object explicit.
# paperid is identity-generated, so omit it.

stg_paper <- refs |>
  filter(if_any(everything(), ~ !is.na(.x) & .x != "")) |>
  transmute(
    publication_year = if ("publication_year" %in% names(refs)) as.integer(publication_year) else integer(),
    publication_title = if ("publication_title" %in% names(refs)) na_if_blank(publication_title) else character(),
    publication_journal = if ("publication_journal" %in% names(refs)) na_if_blank(publication_journal) else character(),
    publication_doi = if ("publication_doi" %in% names(refs)) na_if_blank(publication_doi) else character(),
    publication_url = if ("publication_url" %in% names(refs)) na_if_blank(publication_url) else character()
  ) |>
  distinct()

head(stg_paper)

paper_issues <- validate_staged_table(
  stg_tbl = stg_paper,
  target_table = "paper",
  constraints_tbl = import_registry$constraints
)

paper_issues

# ---- author_contributor ----
# Pull contributor from study.
# Reuse existing author_contributorid by email.
# If new, allocate new IDs.

# Existing database records needed for matching; matches by email
db_author_contributor <- DBI::dbGetQuery(
  con,
  "SELECT author_contributorid, given_name, surname, email FROM grp.author_contributor"
)

author_candidates <- study |>
  transmute(
    contributor = na_if_blank(contributor),
    email = na_if_blank(email)
  ) |>
  separate(
    contributor,
    into = c("given_name", "surname"),
    sep = "\\s+",
    extra = "merge",
    fill = "right",
    remove = TRUE
  ) |>
  mutate(
    given_name = na_if_blank(given_name),
    surname = na_if_blank(surname),
    email = na_if_blank(email)
  ) |>
  filter(!is.na(given_name) | !is.na(surname) | !is.na(email)) |>
  distinct()

author_matched <- author_candidates |>
  left_join(
    db_author_contributor |> select(author_contributorid, email),
    by = "email"
  )

new_authors <- author_matched |>
  filter(is.na(author_contributorid)) |>
  select(given_name, surname, email) |>
  distinct()

if (nrow(new_authors) > 0) {
  new_authors <- new_authors |>
    mutate(
      author_contributorid = next_ids(
        con,
        table = "author_contributor",
        id_col = "author_contributorid",
        n = n()
      )
    )
} else {
  new_authors <- new_authors |>
    mutate(author_contributorid = integer())
}

stg_author_contributor <- bind_rows(
  author_matched |>
    filter(!is.na(author_contributorid)) |>
    select(author_contributorid, given_name, surname, email),
  new_authors |>
    select(author_contributorid, given_name, surname, email)
) |>
  distinct()

head(stg_author_contributor)

author_contributor_issues <- validate_staged_table(
  stg_tbl = stg_author_contributor,
  target_table = "author_contributor",
  constraints_tbl = import_registry$constraints
)

author_contributor_issues

# ---- project_contributor ----

stg_project_contributor <- study |>
  transmute(
    database = as.character(DB),
    projectid = as.integer(projectid),
    email = na_if_blank(email)
  ) |>
  left_join(
    stg_author_contributor |>
      select(author_contributorid, email),
    by = "email"
  ) |>
  filter(!is.na(author_contributorid)) |>
  transmute(
    database,
    projectid,
    author_contributorid
  ) |>
  distinct()

head(stg_project_contributor)

project_contributor_issues <- validate_staged_table(
  stg_tbl = stg_project_contributor,
  target_table = "project_contributor",
  constraints_tbl = import_registry$constraints
)

project_contributor_issues

# ---- project_vegmetric ----

stg_project_vegmetric <- study |>
  transmute(
    database = as.character(DB),
    projectid = as.integer(projectid),
    type = normalize_vocab(vegmetric)
  ) |>
  filter(!is.na(type)) |>
  distinct()

head(stg_project_vegmetric)

project_vegmetric_issues <- validate_staged_table(
  stg_tbl = stg_project_vegmetric,
  target_table = "project_vegmetric",
  constraints_tbl = import_registry$constraints
)

project_vegmetric_issues

# ---- validation ----

group1_staged <- list(
  project = stg_project,
  project_data_accessibility = stg_project_data_accessibility,
  location = stg_location,
  project_location = stg_project_location,
  site = stg_site,
  project_site = stg_project_site,
  paper = stg_paper,
  author_contributor = stg_author_contributor
)

purrr::map_int(group1_staged, nrow)

# Lookup validation not needed for group 1, as any controlled vocabulary is embedded in table constraints for this group


#### Group 2: Site attributes
# ---- lookup tables ----

lu_classification <- get_lookup_table(con, "classification")
lu_disturbance <- get_lookup_table(con, "disturbance")

# ---- site_classification ----

stg_site_classification <- site |>
  transmute(
    siteid = as.integer(siteid),
    class_code = str_extract(na_if_blank(USDA.class), "^\\d+"),
    subclass_code = str_extract(na_if_blank(USDA.subclass), "^[0-9]+[A-Za-z]"),
    subsubclass_code = str_extract(na_if_blank(USDA.subsubclass), "^[0-9]+[A-Za-z][0-9]+")
  ) |>
  mutate(
    classificationid = case_when(
      !is.na(subsubclass_code) ~ str_replace(
        str_to_upper(subsubclass_code),
        "^(\\d+)([A-Z])(\\d+)$",
        "\\1.\\2.\\3"
      ),
      !is.na(subclass_code) ~ str_replace(
        str_to_upper(subclass_code),
        "^(\\d+)([A-Z])$",
        "\\1.\\2"
      ),
      !is.na(class_code) ~ class_code,
      TRUE ~ NA_character_
    )
  ) |>
  filter(!is.na(classificationid)) |>
  transmute(siteid, classificationid) |>
  distinct()

head(stg_site_classification)

site_classification_issues <- validate_staged_table(
  stg_tbl = stg_site_classification,
  target_table = "site_classification",
  constraints_tbl = import_registry$constraints
)

site_classification_issues

# ---- site_disturbance ----

stg_site_disturbance <- site |>
  transmute(
    siteid = as.integer(siteid),
    type = normalize_vocab(disturbance)
  ) |>
  filter(!is.na(type)) |>
  transmute(
    siteid,
    type
  ) |>
  distinct()

head(stg_site_disturbance)

site_disturbance_issues <- validate_staged_table(
  stg_tbl = stg_site_disturbance,
  target_table = "site_disturbance",
  constraints_tbl = import_registry$constraints
)

site_disturbance_issues

# ---- site_ref_ecosystem ----

stg_site_ref_ecosystem <- site |>
  transmute(
    siteid = as.integer(siteid),
    description = na_if_blank(refecosystem)
  ) |>
  filter(!is.na(description)) |>
  transmute(
    siteid,
    description
  ) |>
  distinct()

head(stg_site_ref_ecosystem)

site_ref_ecosystem_issues <- validate_staged_table(
  stg_tbl = stg_site_ref_ecosystem,
  target_table = "site_ref_ecosystem",
  constraints_tbl = import_registry$constraints
)

site_ref_ecosystem_issues

# ---- site_soil ----
# soilid has a default sequence, so omit it.

stg_site_soil <- site |>
  transmute(
    siteid = as.integer(siteid),
    sand = as.numeric(sand),
    silt = as.numeric(silt),
    clay = as.numeric(clay),
    description = na_if_blank(soildescription),
    depth = na_if_blank(soildepth)
  ) |>
  filter(
    !is.na(sand) |
      !is.na(silt) |
      !is.na(clay) |
      !is.na(description) |
      !is.na(depth)
  ) |>
  transmute(
    siteid,
    sand,
    silt,
    clay,
    description,
    depth
  ) |>
  distinct()

head(stg_site_soil)

site_soil_issues <- validate_staged_table(
  stg_tbl = stg_site_soil,
  target_table = "site_soil",
  constraints_tbl = import_registry$constraints
)

site_soil_issues

# ---- site_invasive ----
stg_site_invasive <- site |>
  transmute(
    siteid = as.integer(siteid),
    invasive_species_raw = na_if_blank(invasivespe)
  ) |>
  filter(!is.na(invasive_species_raw)) |>
  separate_rows(invasive_species_raw, sep = "\\|") |>
  mutate(
    invasive_species_name = invasive_species_raw |>
      stringr::str_squish()
  ) |>
  left_join(
    species_lookup |>
      transmute(
        speciesid = as.integer(speciesid),
        invasive_species_name = name |> stringr::str_squish()
      ),
    by = "invasive_species_name"
  ) |>
  transmute(
    siteid,
    speciesid
  ) |>
  filter(!is.na(speciesid)) |>
  distinct()

head(stg_site_invasive)

site_invasive_issues <- validate_staged_table(
  stg_tbl = stg_site_invasive,
  target_table = "site_invasive",
  constraints_tbl = import_registry$constraints
)

site_invasive_issues

# ---- validation ----
site_classification_lookup_issues <- validate_lookup_constraints(
  stg_tbl = stg_site_classification,
  target_table = "site_classification",
  constraints_tbl = import_registry$constraints,
  con = con
)

site_disturbance_lookup_issues <- validate_lookup_constraints(
  stg_tbl = stg_site_disturbance,
  target_table = "site_disturbance",
  constraints_tbl = import_registry$constraints,
  con = con
)

site_invasive_lookup_issues <- validate_lookup_constraints(
  stg_tbl = stg_site_invasive,
  target_table = "site_invasive",
  constraints_tbl = import_registry$constraints,
  con = con
)

group2_lookup_issues <- bind_rows(
  site_classification_lookup_issues,
  site_disturbance_lookup_issues,
  site_invasive_lookup_issues
)

group2_lookup_issues

group2_staged <- list(
    site_classification = stg_site_classification,
    site_disturbance = stg_site_disturbance,
    site_ref_ecosystem = stg_site_ref_ecosystem,
    site_soil = stg_site_soil,
    site_invasive = stg_site_invasive
)

purrr::map_int(group2_staged, nrow)


#### Group 3: Experimental structure
# ---- area ----
# NOTE FOR FUTURE: This does not handle blocked designs.
## To do that, the plan is to build code that first creates the staging piece for the blocks, 
## then uses that to correctly create the plot staging (needs the areaid for the parentid)
## A bit of this is worked through in the GAZP2 Codex chat.
## Block scale and units will have to be added by hand

# GAZP area grain: plot-level unit from vegresults.
# Check that this measurement scale and units are unique to each replicate
vegresults |>
  transmute(
    source_treatmentid = treatmentid,
    block = na_if_blank(block),
    replicate = na_if_blank(replicate),
    size = as.numeric(measurementscale),
    units = na_if_blank(measurementmetric)
  ) |>
  distinct() |>
  count(source_treatmentid, block, replicate) |>
  filter(n > 1)

area_candidates <- vegresults |>
  transmute(
    source_treatmentid = treatmentid,
    block = na_if_blank(block),
    replicate = na_if_blank(replicate),
    size = as.numeric(measurementscale),
    units = na_if_blank(measurementmetric)
  ) |>
  filter(!is.na(source_treatmentid)) |>
  distinct() |>
  arrange(source_treatmentid, block, replicate) |>
  mutate(
    areaid = next_ids(
      con,
      table = "area",
      id_col = "areaid",
      n = n()
    )
  )

head(area_candidates)

area_crosswalk <- area_candidates |>
  transmute(
    source_treatmentid,
    block,
    replicate,
    areaid
  )

head(area_crosswalk)

stg_area <- area_candidates |>
  left_join(
    treatments |>
      transmute(
        source_treatmentid = treatmentid,
        siteid = as.integer(siteid),
        restoration_start_year = as.numeric(tsr_start_year),
        restoration_type = normalize_vocab(restorationtype),
        disturbance_end_year = as.numeric(disturbanceendyear)
      ) |>
      distinct(),
    by = "source_treatmentid"
  ) |>
  transmute(
    areaid = as.integer(areaid),
    siteid,
    type = "plot",
    size = size,
    units = units,
    restoration_start_year,
    restoration_type,
    disturbance_end_year,
    parentid = NA_integer_
  ) |>
  distinct()

head(stg_area)

area_issues <- validate_staged_table(
  stg_tbl = stg_area,
  target_table = "area",
  constraints_tbl = import_registry$constraints
)

area_issues

# Write crosswalk output

harmonized_SQL_crosswalk <- area_candidates |>
  transmute(
    database = "GAZP",
    projectid = as.integer(study$projectid[1]),
    object_type = "plot",
    source_treatmentid,
    block,
    replicate,
    areaid
  )

# ---- treatment ----
# treatment crosswalk

treatment_crosswalk <- treatments |>
  transmute(
    database = as.character(DB),
    projectid = as.integer(stringr::str_extract(treatmentid, "^\\d+")),
    object_type = "treatment",
    source_treatmentid = na_if_blank(treatmentid),
    source_trt_tsr = as.integer(trt_tsr)
  ) |>
  filter(!is.na(source_treatmentid), !is.na(source_trt_tsr)) |>
  distinct() |>
  arrange(database, projectid, source_treatmentid, source_trt_tsr) |>
  mutate(
    treatmentid = next_ids(
      con,
      table = "treatment",
      id_col = "treatmentid",
      n = n()
    )
  )

head(treatment_crosswalk)

# stage treatment
## check the othertreatments column for what it's doing (might be appropriate for notes)

stg_treatment <- treatments |>
  transmute(
    source_treatmentid = na_if_blank(treatmentid),
    source_trt_tsr = as.integer(trt_tsr),
    year = as.numeric(trt_year),
    month = as.numeric(treatmentmonth),
    day = as.numeric(treatmentday),
    weeks_since_restoration = as.integer(trt_tsr),
    other_treatment = na_if_blank(othertreatments),
    treatment_type_norm = normalize_vocab(treatment_type),
    treatment_category_norm = normalize_vocab(treatment_category)
  ) |>
  group_by(source_treatmentid, source_trt_tsr) |>
  summarise(
    year = first(na.omit(year)),
    month = first(na.omit(month)),
    day = first(na.omit(day)),
    weeks_since_restoration = first(na.omit(weeks_since_restoration)),
    other_treatment = first(na.omit(other_treatment)),

    shelter = {
      vals <- treatment_type_norm[treatment_category_norm == "shelter"]
      vals <- vals[!is.na(vals)]
      if (length(vals) == 0) NA_character_ else vals[1]
    },

    grading = if_else(
      any(treatment_type_norm == "grading", na.rm = TRUE) |
        any(treatment_category_norm == "grading", na.rm = TRUE),
      "yes",
      NA_character_
    ),

    maintenance_fire = if_else(
      any(treatment_type_norm == "fire", na.rm = TRUE) |
        any(treatment_category_norm == "fire", na.rm = TRUE),
      "yes",
      NA_character_
    ),

    notes = NA_character_,
    .groups = "drop"
  ) |>
  left_join(
    treatment_crosswalk |> select(source_treatmentid, source_trt_tsr, treatmentid),
    by = c("source_treatmentid", "source_trt_tsr")
  ) |>
  transmute(
    treatmentid,
    year,
    month,
    day,
    weeks_since_restoration,
    other_treatment,
    shelter,
    grading,
    maintenance_fire,
    notes
  ) |>
  distinct()

stg_treatment |>
  count(treatmentid) |>
  filter(n > 1)

head(stg_treatment)

treatment_issues <- validate_staged_table(
  stg_tbl = stg_treatment,
  target_table = "treatment",
  constraints_tbl = import_registry$constraints
)

treatment_issues

# Update crosswalk output with treatmentid
# Many to many is ok
# It's many-to-many because the same treatmentid can be applied to multiple plots, 
# and the same plot can have multiple treatments applied over time.

harmonized_SQL_crosswalk <- harmonized_SQL_crosswalk |>
  left_join(
    treatment_crosswalk |>
      select(source_treatmentid, source_trt_tsr, treatmentid),
    by = c("source_treatmentid")
  ) |>
  select(database, projectid, object_type, source_treatmentid, block, replicate, areaid, treatmentid, source_trt_tsr)

# ---- area_treatment ----

stg_area_treatment <- harmonized_SQL_crosswalk |>
  filter(
    object_type == "plot",
    !is.na(areaid),
    !is.na(treatmentid)
  ) |>
  transmute(
    database,
    projectid = as.integer(projectid),
    areaid = as.integer(areaid),
    treatmentid = as.integer(treatmentid)
  ) |>
  distinct()

head(stg_area_treatment)

area_treatment_issues <- validate_staged_table(
  stg_tbl = stg_area_treatment,
  target_table = "area_treatment",
  constraints_tbl = import_registry$constraints
)

area_treatment_issues

# ---- validation ----
group3_staged <- list(
  area = stg_area,
  treatment = stg_treatment,
  area_treatment = stg_area_treatment
)

purrr::map_int(group3_staged, nrow)

# No lookup validation needed for group 3, as any controlled vocabulary is embedded in table constraints for this group


#### Group 4: Treatment details
# ---- lookup tables ----

lu_application_method <- get_lookup_table(con, "application_method")
lu_bed_material       <- get_lookup_table(con, "bed_material")
lu_bed_prep           <- get_lookup_table(con, "bed_prep")
lu_erosion_control    <- get_lookup_table(con, "erosion_control")
lu_fertilization      <- get_lookup_table(con, "fertilization")
lu_grazer             <- get_lookup_table(con, "grazer")
lu_herbicide          <- get_lookup_table(con, "herbicide")
lu_invasion_control   <- get_lookup_table(con, "invasion_control")
lu_growth_medium      <- get_lookup_table(con, "growth_medium")
lu_mowing             <- get_lookup_table(con, "mowing")

# ---- treatment detail table ----

treatment_detail_src <- treatments |>
  transmute(
    source_treatmentid = na_if_blank(treatmentid),
    source_trt_tsr = as.integer(trt_tsr),
    treatment_category = normalize_vocab(treatment_category),
    treatment_type = normalize_vocab(treatment_type),
    amount_raw = na_if_blank(treatment_amount),
    amount = suppressWarnings(as.numeric(treatment_amount)),
    applied = normalize_vocab(treatment_amount) == "applied",
    units = na_if_blank(treatment_units)
  ) |>
  left_join(
    treatment_crosswalk |>
      select(source_treatmentid, source_trt_tsr, treatmentid),
    by = c("source_treatmentid", "source_trt_tsr")
  )

head(treatment_detail_src)

####### Need to make this into a process of checking for "none" and correcting
# GAZP2 has "none" for treatements that weren't seeded for the treatment_category of "application method"
# This is not a valid value for the application_method lookup table, so filter it out here.
# treatment_detail_src <- treatment_detail_src |>
#  filter(!(treatment_category == "application method" & treatment_type == "none"))

# For this data, I know that it's one treatment per site, so can change it in the notes manually
# Future iterations of this code will need to first identify the treatments that have this issue
# then apply the correction to the notes column for those treatments
# and then filter out the "none" value from the treatment_type column for the application method category.
# stg_treatment <- stg_treatment |>
#  mutate(
#    notes = if_else(
#      treatmentid %in% c(41, 42, 83, 125),
#      "experimental control; no treatments applied; no seed added",
#      notes
#    )
#  )

# ---- treatment_application ----

stg_treatment_application <- treatment_detail_src |>
  filter(treatment_category == 'application method') |>
  transmute(
    treatmentid,
    type = treatment_type
  ) |>
  distinct()

head(stg_treatment_application)

treatment_application_issues <- validate_staged_table(
  stg_tbl = stg_treatment_application,
  target_table = "treatment_application",
  constraints_tbl = import_registry$constraints
)

treatment_application_issues

# ---- treatment_cover_crop ----
# Build will need an example with a cover crop, so future problem

# ---- treatment_erosion ----

stg_treatment_erosion <- treatment_detail_src |>
  filter(treatment_category == "erosion control") |>
  transmute(
    treatmentid,
    type = treatment_type
  ) |>
  distinct()

head(stg_treatment_erosion)

treatment_erosion_issues <- validate_staged_table(
  stg_tbl = stg_treatment_erosion,
  target_table = "treatment_erosion",
  constraints_tbl = import_registry$constraints
)

treatment_erosion_issues

# ---- treatment_fertilization ----
# ID is sequence/default generated, so omit treatment_fertilizationid.
# The lookup table and treatment_type column need more work to make sense

stg_treatment_fertilization <- treatment_detail_src |>
  filter(treatment_category == 'fertilization treatment') |>
  transmute(
    treatmentid,
    type = treatment_type,
    amount,
    units,
    notes = if_else(is.na(amount) & !is.na(amount_raw), amount_raw, NA_character_)
  ) |>
  distinct()

head(stg_treatment_fertilization)

treatment_fertilization_issues <- validate_staged_table(
  stg_tbl = stg_treatment_fertilization,
  target_table = "treatment_fertilization",
  constraints_tbl = import_registry$constraints
)

treatment_fertilization_issues

# ---- treatment_grazer ----

stg_treatment_grazer <- treatment_detail_src |>
  filter(treatment_category == "grazer manipulation") |>
  transmute(
    treatmentid,
    type = treatment_type,
    notes = dplyr::case_when(
      is.na(amount_raw) ~ NA_character_,
      normalize_vocab(amount_raw) == "applied" ~ NA_character_,
      TRUE ~ amount_raw
    )
  ) |>
  distinct()

head(stg_treatment_grazer)

treatment_grazer_issues <- validate_staged_table(
  stg_tbl = stg_treatment_grazer,
  target_table = "treatment_grazer",
  constraints_tbl = import_registry$constraints
)

treatment_grazer_issues

# ---- treatment_herbicide ----
# ID is sequence/default generated, so omit treatment_herbicideid.
# The lookup table and treatment_type column need more work to align

stg_treatment_herbicide <- treatment_detail_src |>
  filter(treatment_category == 'herbicide') |>
  transmute(
    treatmentid,
    type = treatment_type,
    chemical = NA_character_, ### THIS NEEDS UPDATED
    amount,
    units,
    notes = if_else(is.na(amount) & !is.na(amount_raw), amount_raw, NA_character_)
  ) |>
  distinct()

head(stg_treatment_herbicide)

treatment_herbicide_issues <- validate_staged_table(
  stg_tbl = stg_treatment_herbicide,
  target_table = "treatment_herbicide",
  constraints_tbl = import_registry$constraints
)

treatment_herbicide_issues

# ---- treatment_invasion ----
# The lookup table and treatment_type column need more work to align

stg_treatment_invasion <- treatment_detail_src |>
  filter(treatment_category == 'invasion control') |>
  transmute(
    treatmentid,
    type = treatment_type
  ) |>
  distinct()

head(stg_treatment_invasion)

treatment_invasion_issues <- validate_staged_table(
  stg_tbl = stg_treatment_invasion,
  target_table = "treatment_invasion",
  constraints_tbl = import_registry$constraints
)

treatment_invasion_issues

# ---- treatment_irrigation ----
# ID is sequence/default generated, so omit treatment_irrigationid.

stg_treatment_irrigation <- treatment_detail_src |>
  filter(treatment_category == "irrigation" | treatment_type == "irrigation") |>
  transmute(
    treatmentid,
    type = "irrigation",
    amount,
    units,
    notes = if_else(is.na(amount) & !is.na(amount_raw), amount_raw, NA_character_)
  ) |>
  distinct()

head(stg_treatment_irrigation)

treatment_irrigation_issues <- validate_staged_table(
  stg_tbl = stg_treatment_irrigation,
  target_table = "treatment_irrigation",
  constraints_tbl = import_registry$constraints
)

treatment_irrigation_issues

# ---- treatment_material ----

stg_treatment_material <- treatment_detail_src |>
  filter(treatment_category == 'bed material') |>
  transmute(
    treatmentid,
    type = treatment_type
  ) |>
  distinct()

head(stg_treatment_material)

treatment_material_issues <- validate_staged_table(
  stg_tbl = stg_treatment_material,
  target_table = "treatment_material",
  constraints_tbl = import_registry$constraints
)

treatment_material_issues

# ---- treatment_medium ----
# ID is sequence/default generated, so omit treatment_mediumid.

stg_treatment_medium <- treatment_detail_src |>
  filter(treatment_category == 'growth medium') |>
  transmute(
    treatmentid,
    type = treatment_type,
    top_soil_age = if_else(units == 'years', amount, NA_real_),
    notes = if_else(is.na(amount) & !is.na(amount_raw), amount_raw, NA_character_),
    growth_medium_depth = if_else(units == 'years', NA_real_, amount),
    growth_medium_depth_units = if_else(units == 'years', NA_character_, units)
  ) |>
  distinct()

head(stg_treatment_medium)

treatment_medium_issues <- validate_staged_table(
  stg_tbl = stg_treatment_medium,
  target_table = "treatment_medium",
  constraints_tbl = import_registry$constraints
)

treatment_medium_issues

# ---- treatment_mowing ----
# mowingid is identity-generated, so omit it.
# this will break in some instances

stg_treatment_mowing <- treatment_detail_src |>
  filter(treatment_category == 'mowing') |>
  transmute(
    treatmentid,
    type = 'present',
    height_class = NA_character_,
    amount,
    units,
    notes = if_else(is.na(amount) & !is.na(amount_raw), amount_raw, NA_character_)
  ) |>
  distinct()

head(stg_treatment_mowing)

treatment_mowing_issues <- validate_staged_table(
  stg_tbl = stg_treatment_mowing,
  target_table = "treatment_mowing",
  constraints_tbl = import_registry$constraints
)

treatment_mowing_issues

# ---- treatment_prep ----

stg_treatment_prep <- treatment_detail_src |>
  filter(treatment_category == 'bed prep') |>
  transmute(
    treatmentid,
    type = treatment_type
  ) |>
  distinct()

head(stg_treatment_prep)

treatment_prep_issues <- validate_staged_table(
  stg_tbl = stg_treatment_prep,
  target_table = "treatment_prep",
  constraints_tbl = import_registry$constraints
)

treatment_prep_issues

# ---- validation ----
group4_staged <- list(
  treatment_application = stg_treatment_application,
  #treatment_cover_crop = stg_treatment_cover_crop,
  treatment_erosion = stg_treatment_erosion,
  treatment_fertilization = stg_treatment_fertilization,
  treatment_grazer = stg_treatment_grazer,
  #treatment_herbicide = stg_treatment_herbicide,
  treatment_invasion = stg_treatment_invasion,
  treatment_irrigation = stg_treatment_irrigation,
  treatment_material = stg_treatment_material,
  treatment_medium = stg_treatment_medium,
  treatment_mowing = stg_treatment_mowing,
  treatment_prep = stg_treatment_prep
)

purrr::map_int(group4_staged, nrow)

group4_lookup_issues <- purrr::imap_dfr(
  group4_staged,
  function(tbl, tbl_name) {

    if (nrow(tbl) == 0) return(NULL)

    validate_lookup_constraints(
      stg_tbl = tbl,
      target_table = tbl_name,
      constraints_tbl = import_registry$constraints,
      con = con
    )
  }
)

group4_lookup_issues


#### Group 5: Seeding and planting
# ---- lookup tables ----

lu_pretreatment <- get_lookup_table(con, "pretreatment")

# ---- seeding detail table ----

seeding_treatment_resolver <- treatments |>
  transmute(
    source_treatmentid = na_if_blank(treatmentid),
    source_trt_tsr = as.integer(trt_tsr),
    treatment_category = normalize_vocab(treatment_category)
  ) |>
  group_by(source_treatmentid, source_trt_tsr) |>
  summarise(
    has_application_method = any(treatment_category == "application method", na.rm = TRUE),
    .groups = "drop"
  ) |>
  left_join(
    treatment_crosswalk |>
      select(source_treatmentid, source_trt_tsr, treatmentid),
    by = c("source_treatmentid", "source_trt_tsr")
  ) |>
  group_by(source_treatmentid) |>
  arrange(desc(has_application_method), source_trt_tsr, .by_group = TRUE) |>
  slice(1) |>
  ungroup() |>
  transmute(
    source_treatmentid,
    seeding_treatmentid = treatmentid
  )

head(seeding_treatment_resolver)

seeding_src <- trtrates |>
  transmute(
    source_treatmentid = na_if_blank(treatmentid),
    source_species_code = na_if_blank(speciesid),
    source_cultivarid = suppressWarnings(as.integer(cultivarid)),
    type = normalize_vocab(trt),
    mix = na_if_blank(mix_trt),
    treated_richness = na_if_blank(treated_richness),
    treatment_type = normalize_vocab(treatment_type),
    rate_raw = na_if_blank(rate),
    rate = suppressWarnings(as.numeric(rate)),
    unit = na_if_blank(unit),
    viability = na_if_blank(viability),
    seedpretreatment = normalize_vocab(seedpretreatment),
    origin = normalize_vocab(seed_origin),
    source = normalize_vocab(source),
    seed_distance = na_if_blank(seeddist)
  ) |>
  left_join(
    seeding_treatment_resolver,
    by = "source_treatmentid"
  ) |>
  rename(treatmentid = seeding_treatmentid) |>
  left_join(
    species_lookup,
    by = "source_species_code"
  )

head(seeding_src)

# ---- seed_mix ----

seed_mix_candidates <- seeding_src |>
  transmute(
    treatmentid,
    mix_name = mix,
    treated_richness
  ) |>
  distinct()

head(seed_mix_candidates)

stg_seed_mix <- seed_mix_candidates |>
  mutate(
    seed_mixid = next_ids(
      con,
      table = "seed_mix",
      id_col = "seed_mixid",
      n = n()
    )
  ) |>
  transmute(
    seed_mixid,
    treatmentid,
    mix_name,
    mix_composition_status = case_when(
      is.na(mix_name) ~ NA_character_,
      str_detect(normalize_vocab(mix_name), "unknown") ~ "unknown",
      TRUE ~ "known"
    ),
    treated_richness,
    notes = NA_character_
  )

head(stg_seed_mix)

seed_mix_issues <- validate_staged_table(
  stg_tbl = stg_seed_mix,
  target_table = "seed_mix",
  constraints_tbl = import_registry$constraints
)

seed_mix_issues

# ---- seeding ----

seeding_candidates <- seeding_src |>
  left_join(
    stg_seed_mix |>
      select(seed_mixid, treatmentid, mix_name, treated_richness),
    by = c(
      "treatmentid",
      "mix" = "mix_name",
      "treated_richness"
    )
  ) |>
  transmute(
    treatmentid,
    mix,
    speciesid,
    cultivarid = source_cultivarid,
    type,
    rate,
    unit,
    viability,
    origin,
    source,
    seed_distance,
    seed_mixid,
    notes = case_when(
      is.na(rate) & !is.na(rate_raw) ~ paste0("Source rate value: ", rate_raw),
      TRUE ~ NA_character_
    ),
    seedpretreatment
  ) |>
  filter(!is.na(treatmentid), !is.na(seed_mixid)) |>
  distinct() |>
  arrange(treatmentid, seed_mixid, speciesid, cultivarid, type)

head(seeding_candidates)

seeding_resolved <- seeding_candidates |>
  mutate(
    seedingid = next_ids(
      con,
      table = "seeding",
      id_col = "seedingid",
      n = n()
    )
  )

head(seeding_resolved)

stg_seeding <- seeding_resolved |>
  transmute(
    seedingid,
    treatmentid,
    mix,
    speciesid,
    cultivarid,
    type,
    rate,
    unit,
    viability,
    origin,
    source,
    seed_distance,
    seed_mixid,
    notes
  )

head(stg_seeding)

seeding_issues <- validate_staged_table(
  stg_tbl = stg_seeding,
  target_table = "seeding",
  constraints_tbl = import_registry$constraints
)

seeding_issues

# ---- seeding_pretreatment ----

stg_seeding_pretreatment <- seeding_resolved |>
  filter(!is.na(seedpretreatment)) |>
  separate_rows(seedpretreatment, sep = "\\|") |>
  mutate(type = normalize_vocab(seedpretreatment)) |>
  filter(!is.na(type), !type %in% c("none", "na", "n/a")) |>
  transmute(
    seedingid,
    type
  ) |>
  distinct()

head(stg_seeding_pretreatment)

seeding_pretreatment_issues <- validate_staged_table(
  stg_tbl = stg_seeding_pretreatment,
  target_table = "seeding_pretreatment",
  constraints_tbl = import_registry$constraints
)

seeding_pretreatment_issues

# ---- validation ----

group5_staged <- list(
  seed_mix = stg_seed_mix,
  seeding = stg_seeding,
  seeding_pretreatment = stg_seeding_pretreatment
)

purrr::map_int(group5_staged, nrow)

group5_lookup_issues <- purrr::imap_dfr(
  group5_staged,
  function(tbl, tbl_name) {
    if (nrow(tbl) == 0) return(NULL)

    validate_lookup_constraints(
      stg_tbl = tbl,
      target_table = tbl_name,
      constraints_tbl = import_registry$constraints,
      con = con
    )
  }
)

group5_lookup_issues


#### Group 6: Results
# ---- veg_result ----

stg_veg_result <- vegresults |>
  transmute(
    source_observationid = id,
    source_treatmentid = na_if_blank(treatmentid),
    block = na_if_blank(block),
    replicate = na_if_blank(replicate),
    time_since_restoration = as.integer(tsr),
    year = as.numeric(year),
    source_species_code = na_if_blank(speciesid),
    origin = normalize_vocab(speciesorigin),
    response = as.numeric(response),
    level = normalize_vocab(responselevel),
    metric = normalize_vocab(responsemetric),
    measurement_scale = na_if_blank(measurementscale),
    measurement_metric = na_if_blank(measurementmetric)
  ) |>
  left_join(
    harmonized_SQL_crosswalk |>
      filter(object_type == "plot") |>
      select(
        source_treatmentid,
        block,
        replicate,
        areaid
      ) |>
      distinct(),
    by = c("source_treatmentid", "block", "replicate")
  ) |>
  left_join(
    species_lookup,
    by = "source_species_code"
  ) |>
  transmute(
    areaid = as.integer(areaid),
    time_since_restoration,
    year,
    month = NA_real_,
    day = NA_real_,
    speciesid,
    cultivarid = NA_integer_,
    individualid = NA_integer_,
    origin,
    level,
    response,
    metric,
    notes = NA_character_
    ) |>
  distinct()

head(stg_veg_result)

veg_result_issues <- validate_staged_table(
  stg_tbl = stg_veg_result,
  target_table = "veg_result",
  constraints_tbl = import_registry$constraints
)

veg_result_issues

# ---- validation ----
veg_result_lookup_issues <- validate_lookup_constraints(
  stg_tbl = stg_veg_result,
  target_table = "veg_result",
  constraints_tbl = import_registry$constraints,
  con = con
)

veg_result_lookup_issues

nrow(vegresults)
nrow(stg_veg_result)

stg_veg_result |>
  summarise(
    missing_areaid = sum(is.na(areaid)),
    missing_speciesid = sum(is.na(speciesid)),
    missing_response = sum(is.na(response))
  )


#### Referential validation
# Validate foreign-key relationships across every staged table.
# Parent keys may exist in either another staged table or the SQL database.

group6_staged <- list(
  veg_result = stg_veg_result
)

all_staged <- c(
  group1_staged,
  group2_staged,
  group3_staged,
  group4_staged,
  group5_staged,
  group6_staged
)

# Optional staging inventory
staged_row_counts <- purrr::map_int(all_staged, nrow)
staged_row_counts

referential_integrity_issues <- validate_referential_integrity(
  staged_tables = all_staged,
  constraints_tbl = import_registry$constraints,
  con = con
)

referential_integrity_issues

#### Write crosswalk outputs
crosswalk_dir <- "crosswalk_tables/GAZP/GAZP3"
dir.create(crosswalk_dir, recursive = TRUE, showWarnings = FALSE)

write_csv(
  harmonized_SQL_crosswalk,
  file.path(crosswalk_dir, "GAZP3_harmonized-SQL_crosswalk.csv")
)


#### Write to Supabase
DBI::dbWithTransaction(con, {

  # Group 1: project backbone
  append_if_rows(con, "project", stg_project)
  append_if_rows(con, "project_data_accessibility", stg_project_data_accessibility)
  append_if_rows(con, "location", new_locations)
  append_if_rows(con, "project_location", stg_project_location)
  append_if_rows(con, "site", stg_site)
  append_if_rows(con, "project_site", stg_project_site)
  append_if_rows(con, "author_contributor", new_authors)
  append_if_rows(con, "project_contributor", stg_project_contributor)
  append_if_rows(con, "project_vegmetric", stg_project_vegmetric)

  # Paper tables deferred for GAZP1 unless refs are populated
  append_if_rows(con, "paper", stg_paper)
  # append_if_rows(con, "paper_author", stg_paper_author)
  # append_if_rows(con, "project_paper", stg_project_paper)

  # Group 2: site attributes
  append_if_rows(con, "site_classification", stg_site_classification)
  append_if_rows(con, "site_disturbance", stg_site_disturbance)
  append_if_rows(con, "site_ref_ecosystem", stg_site_ref_ecosystem)
  append_if_rows(con, "site_soil", stg_site_soil)
  append_if_rows(con, "site_invasive", stg_site_invasive)

  # Group 3: experimental structure
  append_if_rows(con, "area", stg_area)
  append_if_rows(con, "treatment", stg_treatment)
  append_if_rows(con, "area_treatment", stg_area_treatment)

  # Group 4: treatment details
  append_if_rows(con, "treatment_application", stg_treatment_application)
  #append_if_rows(con, "treatment_cover_crop", stg_treatment_cover_crop)
  append_if_rows(con, "treatment_erosion", stg_treatment_erosion)
  append_if_rows(con, "treatment_fertilization", stg_treatment_fertilization)
  append_if_rows(con, "treatment_grazer", stg_treatment_grazer)
  #append_if_rows(con, "treatment_herbicide", stg_treatment_herbicide)
  append_if_rows(con, "treatment_invasion", stg_treatment_invasion)
  append_if_rows(con, "treatment_irrigation", stg_treatment_irrigation)
  append_if_rows(con, "treatment_material", stg_treatment_material)
  append_if_rows(con, "treatment_medium", stg_treatment_medium)
  append_if_rows(con, "treatment_mowing", stg_treatment_mowing)
  append_if_rows(con, "treatment_prep", stg_treatment_prep)

  # Group 5: seeding and planting
  append_if_rows(con, "seed_mix", stg_seed_mix)
  append_if_rows(con, "seeding", stg_seeding)
  append_if_rows(con, "seeding_pretreatment", stg_seeding_pretreatment)

  # Group 6: results
  append_if_rows(con, "veg_result", stg_veg_result)
})

#### Check and rollback if needed
import_check_tables <- c(
  "project", "project_data_accessibility", "location", "project_location",
  "site", "project_site", "author_contributor", "project_contributor",
  "project_vegmetric", "site_classification", "site_disturbance",
  "site_ref_ecosystem", "site_soil", "site_invasive", "area", "treatment",
  "area_treatment", "treatment_application", "treatment_cover_crop",
  "treatment_erosion", "treatment_fertilization", "treatment_grazer",
  "treatment_herbicide", "treatment_invasion", "treatment_irrigation",
  "treatment_material", "treatment_medium", "treatment_mowing",
  "treatment_prep", "seed_mix", "seeding", "seeding_pretreatment",
  "veg_result"
)

purrr::map_dfr(import_check_tables, function(tbl) {
  DBI::dbGetQuery(
    con,
    paste0("SELECT '", tbl, "' AS table_name, COUNT(*) AS n FROM grp.", tbl)
  )
})


#### Write files to Supabase
supabase_url <- "https://rudybfqutvodkakgctpo.supabase.co"
service_key <- service_role

# Crosswalk table
upload_to_supabase(
  local_file = "crosswalk_tables/GAZP/GAZP3/GAZP3_harmonized-SQL_crosswalk.csv",
  destination_path = "GAZP/GAZP3/crosswalks/GAZP3_harmonized-SQL_crosswalk.csv",
  supabase_url = supabase_url,
  service_key = service_key
)

# Harmonized data
upload_to_supabase(
  local_file =
    "data/harmonized/GAZP/GAZP3/GAZP3.xlsx",

  destination_path =
    "GAZP/GAZP3/harmonized/GAZP3.xlsx",

  supabase_url = supabase_url,
  service_key = service_key
)

# Source data
upload_to_supabase(
  local_file =
    "data/source/GAZP/GAZP3/bunchgrass demography.xlsx",

  destination_path =
    "GAZP/GAZP3/source/bunchgrass_demography.xlsx",

  supabase_url = supabase_url,
  service_key = service_key
)

upload_to_supabase(
  local_file =
    "data/source/GAZP/GAZP3/Meta-data_bunchgrass.xlsx",

  destination_path =
    "GAZP/GAZP3/source/Meta-data_bunchgrass.xlsx",

  supabase_url = supabase_url,
  service_key = service_key
)

upload_to_supabase(
  local_file =
    "data/source/GAZP/GAZP3/Updated Meta-data_bunchgrass (2).xlsx",

  destination_path =
    "GAZP/GAZP3/source/Updated_Meta-data_bunchgrass_(2).xlsx",

  supabase_url = supabase_url,
  service_key = service_key
)

# Code
upload_to_supabase(
  local_file =
    "R/import_code/GAZP3/20260716_GAZP3_import.r",

  destination_path =
    "GAZP/GAZP3/code/20260716_GAZP3_import.r",

  supabase_url = supabase_url,
  service_key = service_key
)
