### This is to import GAZP8 into the SQL database from the Excel format
### It will be a sixth draft of the larger import process
### The update here will be building in the new import-framework structure for source code files and overarching crosswalk tables

### Libraries and source files ------------------------------------
library(tidyverse)
library(openxlsx)
library(DBI)
library(RPostgres)
library(glue)

### Connect to Supabase database ------------------------------------
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

### Read workbook tables -------------------------------------
# Names of all sheets
sheets <- getSheetNames("data/harmonized/GAZP/GAZP8/GAZP8.xlsx")

# Individual sheets
study <- read.xlsx("data/harmonized/GAZP/GAZP8/GAZP8.xlsx", sheet = "study")
site <- read.xlsx("data/harmonized/GAZP/GAZP8/GAZP8.xlsx", sheet = "site")
treatments <- read.xlsx("data/harmonized/GAZP/GAZP8/GAZP8.xlsx", sheet = "treatments")
timepoints <- read.xlsx("data/harmonized/GAZP/GAZP8/GAZP8.xlsx", sheet = "timepoints")
trtrates <- read.xlsx("data/harmonized/GAZP/GAZP8/GAZP8.xlsx", sheet = "trtrates")
refs <- read.xlsx("data/harmonized/GAZP/GAZP8/GAZP8.xlsx", sheet = "refs")
vegresults <- read.xlsx("data/harmonized/GAZP/GAZP8/GAZP8.xlsx", sheet = "vegresults")

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

### Pull constraints and lookup tables list -----------------------------
framework_version <- "20260903_framework" 

framework_dir <- file.path("R", "import_framework", framework_version)
source(file.path(framework_dir, "import_registry.r"))
source(file.path(framework_dir, "import_helper_functions.r"))

### Create species lookup table
## Foundational GRP species crosswalk (pre-established and stored in the import framework)
sp_crosswalk <- readr::read_csv(
  file.path(framework_dir, "sp_crosswalk.csv"),
  show_col_types = FALSE
)

## Species names from SQL database
lu_species <- get_lookup_table(con, "species_names")

## Reduce to GRP (Excel) codes and SQL IDs from foundational crosswalk
species_lookup <- sp_crosswalk |>
  transmute(
    source_species_code = na_if_blank(excel_speciesid),
    speciesid = as.integer(sql_speciesid)
  ) |>
  filter(!is.na(source_species_code), !is.na(speciesid)) |>
  distinct()

## Get names from SQL database and add to the species lookup table
species_lookup <- species_lookup |>
    mutate(
    species_code = as.character(source_species_code)
  ) |>
  left_join(
    lu_species
  ) |>
  select(-species_code)

### Create species crosswalk table ----------------------------------
source(file.path(framework_dir, "species_crosswalk_creation.R"))

### Create project-level species crosswalk
# Run the species crosswalk. It will flag things.
# Then review them and add them to the project_species_overrides table below.
# Then rerun the species crosswalk

## The below is the template for most projects (not complicated ones)
#project_species_overrides <- tribble(
#  ~source_table, ~source_column, ~source_value,
#  ~accepted_species_code, ~accepted_species_name,
#  ~mapping_status, ~decision_note,

#  "vegresults", "speciesid", "Ach_mil",
#  "Ach_mil", "Achillea millefolium",
#  "human_reviewed_same_taxon",
#  "Reviewed for GAZP8; Ach_mil represents Achillea millefolium.",

#)

#species_crosswalk_result <- build_project_species_crosswalk(
#  data_list = data_list,
#  species_lookup = species_lookup,
#  lu_species = lu_species,
#  global_species_crosswalk = sp_crosswalk,
#  database = "GAZP",
#  projectid = study$projectid[[1]],
#  overrides = project_species_overrides,
#  output_path = file.path(
#    "crosswalk_tables",
#    "GAZP",
#    "GAZP6",
#    "GAZP6_species_crosswalk.csv"
#  )
#)

### GAZP8 is complicated; delete the below in the next -----------------------------
### Project-specific species decisions

excluded_veg_species <- tribble(
  ~source_value,   ~exclusion_reason,
  "UN_ID_BG",      "Bare ground; non-taxonomic observation.",
  "UN_ID_CD",      "Meaning could not be determined from the source data.",
  "UN_ID_FD",      "Fine debris; non-taxonomic observation.",
  "UN_ID_FS",      "Meaning could not be determined from the source data.",
  "UN_ID_GW",      "Meaning could not be determined from the source data.",
  "UN_ID_TC",      "Total cover; non-taxonomic observation.",
  "UN_ID_TP",      "Meaning could not be determined from the source data.",
  "UN_ID_TS",      "Triticale seeds; non-taxonomic observation.",
  "UN_ID_WOC",     "Meaning could not be determined from the source data.",
  "UN_ID_biocrust", "Biocrust; non-taxonomic observation."
)

# Preserve the excluded records as an audit before removing them from the
# data that will be mapped and uploaded.
excluded_vegresults <- vegresults |>
  inner_join(
    excluded_veg_species,
    by = c("speciesid" = "source_value")
  )

readr::write_csv(
  excluded_vegresults,
  file.path(
    "crosswalk_tables",
    "GAZP",
    "GAZP8",
    "GAZP8_excluded_vegresults.csv"
  ),
  na = ""
)

vegresults <- vegresults |>
  anti_join(
    excluded_veg_species,
    by = c("speciesid" = "source_value")
  )

# SAVE and SETE intentionally map to the same generic unknown species. Keep
# them in vegresults for staging, but omit them from the general builder and
# add reviewed project-specific crosswalk rows after its collision checks.
reviewed_unknown_source_codes <- c("UN_ID_SAVE", "UN_ID_SETE")

data_list_for_species_crosswalk <- data_list
data_list_for_species_crosswalk$vegresults <- vegresults |>
  filter(
    !stringr::str_squish(as.character(speciesid)) %in%
      reviewed_unknown_source_codes
  )

# Obtain the canonical GRP lookup values rather than hard-coding names or
# relying on row order.
art_tri <- lu_species |>
  filter(species_code == "Art_tri") |>
  distinct(speciesid, species_code, name)

unknown_species <- DBI::dbGetQuery(
  con,
  "
  SELECT
    speciesid,
    species_code,
    concat_ws(
      ' ',
      NULLIF(genus, ''),
      NULLIF(species, ''),
      NULLIF(subtype_name, '')
    ) AS name
  FROM grp.species
  WHERE speciesid = 1
  "
) |>
  mutate(
    name = if_else(
      is.na(name) | name == "",
      "Unknown",
      name
    )
  ) |>
  distinct(speciesid, species_code, name)

stopifnot(nrow(art_tri) == 1L)
stopifnot(nrow(unknown_species) == 1L)

# Refresh after any species additions made during this import session. The
# generic unknown record is absent from grp.species_names, so add it back.
lu_species <- get_lookup_table(con, "species_names") |>
  bind_rows(unknown_species) |>
  distinct(speciesid, species_code, name)

unknown_lifeform_species <- lu_species |>
  filter(species_code %in% c("L_Forb", "L_moss", "L_Shrub")) |>
  distinct(speciesid, species_code, name)

stopifnot(
  setequal(
    unknown_lifeform_species$species_code,
    c("L_Forb", "L_moss", "L_Shrub")
  )
)

get_lifeform_species <- function(species_code_value) {
  unknown_lifeform_species |>
    filter(species_code == species_code_value) |>
    slice_head(n = 1)
}

unknown_forb <- get_lifeform_species("L_Forb")
unknown_moss <- get_lifeform_species("L_moss")
unknown_shrub <- get_lifeform_species("L_Shrub")

reviewed_species_codes <- c(
  "Ach_mil__var_occ",
  "Ely_ely__sub_ely",
  "Pla_pat",
  "Pas_smi",
  "G_Festuc_spp",
  "Sal_tra"
)

reviewed_species <- DBI::dbGetQuery(
  con,
  "
  SELECT DISTINCT
    s.speciesid,
    s.species_code,
    COALESCE(
      sn.name,
      concat_ws(
        ' ',
        NULLIF(s.genus, ''),
        NULLIF(s.species, ''),
        CASE
          WHEN s.subtype = 'subspecies' THEN 'subsp.'
          WHEN s.subtype = 'variety' THEN 'var.'
          ELSE NULL
        END,
        NULLIF(s.subtype_name, '')
      )
    ) AS name
  FROM grp.species s
  LEFT JOIN grp.species_names sn
    ON sn.speciesid = s.speciesid
   AND sn.species_code = s.species_code
  WHERE s.species_code IN (
    'Ach_mil__var_occ',
    'Ely_ely__sub_ely',
    'Pla_pat',
    'Pas_smi',
    'G_Festuc_spp',
    'Sal_tra'
  )
  "
) |>
  as_tibble() |>
  distinct(speciesid, species_code, name)

stopifnot(setequal(reviewed_species$species_code, reviewed_species_codes))

# Some accepted infraspecific records are absent from grp.species_names. Add
# their canonical rows locally so the project override validator can resolve
# every reviewed target without changing the shared framework code.
lu_species <- lu_species |>
  bind_rows(reviewed_species) |>
  distinct(speciesid, species_code, name)

get_reviewed_species <- function(species_code_value) {
  reviewed_species |>
    filter(species_code == species_code_value) |>
    slice_head(n = 1)
}

ach_mil_occ <- get_reviewed_species("Ach_mil__var_occ")
ely_ely_ssp <- get_reviewed_species("Ely_ely__sub_ely")
pla_pat <- get_reviewed_species("Pla_pat")
pas_smi <- get_reviewed_species("Pas_smi")
festuca_spp <- get_reviewed_species("G_Festuc_spp")
sal_tra <- get_reviewed_species("Sal_tra")

project_species_overrides <- tribble(
  ~source_table, ~source_column, ~source_value,
  ~accepted_species_code, ~accepted_species_name,
  ~mapping_status, ~decision_note,

  "vegresults", "speciesid", "UN_ID_ARTR",
  art_tri$species_code[[1]], art_tri$name[[1]],
  "human_reviewed_same_taxon",
  paste(
    "Reviewed for GAZP8;",
    "source code ARTR represents Artemisia tridentata."
  ),

  "vegresults", "speciesid", "UN_ID_UNKFORB",
  unknown_forb$species_code[[1]], unknown_forb$name[[1]],
  "human_reviewed_lifeform",
  "Reviewed for GAZP8; source observation identifies an unknown forb.",

  "vegresults", "speciesid", "UN_ID_UNKMOSS",
  unknown_moss$species_code[[1]], unknown_moss$name[[1]],
  "human_reviewed_lifeform",
  "Reviewed for GAZP8; source observation identifies an unknown moss.",

  "vegresults", "speciesid", "UN_ID_UNKSHRUB",
  unknown_shrub$species_code[[1]], unknown_shrub$name[[1]],
  "human_reviewed_lifeform",
  "Reviewed for GAZP8; source observation identifies an unknown shrub.",

  "trtrates", "speciesid", "Ach_mil1",
  ach_mil_occ$species_code[[1]], ach_mil_occ$name[[1]],
  "human_reviewed_infraspecific_taxon",
  paste(
    "Reviewed for GAZP8; all Ach_mil1 records represent",
    "Achillea millefolium var. occidentalis."
  ),

  "vegresults", "speciesid", "Ach_mil1",
  ach_mil_occ$species_code[[1]], ach_mil_occ$name[[1]],
  "human_reviewed_infraspecific_taxon",
  paste(
    "Reviewed for GAZP8; all Ach_mil1 records represent",
    "Achillea millefolium var. occidentalis."
  ),

  "trtrates", "speciesid", "Ely_ely",
  ely_ely_ssp$species_code[[1]], ely_ely_ssp$name[[1]],
  "human_reviewed_infraspecific_taxon",
  paste(
    "Reviewed against the source PDF for GAZP8; Ely_ely represents",
    "Elymus elymoides subsp. elymoides."
  ),

  "vegresults", "speciesid", "Ely_ely",
  ely_ely_ssp$species_code[[1]], ely_ely_ssp$name[[1]],
  "human_reviewed_infraspecific_taxon",
  paste(
    "Reviewed against the source PDF for GAZP8; Ely_ely represents",
    "Elymus elymoides subsp. elymoides."
  ),

  "trtrates", "speciesid", "Pla_pat",
  pla_pat$species_code[[1]], pla_pat$name[[1]],
  "human_reviewed_same_taxon",
  paste(
    "Reviewed for GAZP8; the raw data identify Plantago patagonica",
    "without an infraspecific taxon."
  ),

  "vegresults", "speciesid", "Pla_pat",
  pla_pat$species_code[[1]], pla_pat$name[[1]],
  "human_reviewed_same_taxon",
  paste(
    "Reviewed for GAZP8; the raw data identify Plantago patagonica",
    "without an infraspecific taxon."
  ),

  "trtrates", "speciesid", "Pse_rup",
  pas_smi$species_code[[1]], pas_smi$name[[1]],
  "human_reviewed_source_correction",
  paste(
    "Corrected for GAZP8; Pse_rup was derived incorrectly from raw code",
    "PASM, which the source workbook and PDF identify as Pascopyrum smithii."
  ),

  "vegresults", "speciesid", "Pse_rup",
  pas_smi$species_code[[1]], pas_smi$name[[1]],
  "human_reviewed_source_correction",
  paste(
    "Corrected for GAZP8; Pse_rup was derived incorrectly from raw code",
    "PASM, which the source workbook and PDF identify as Pascopyrum smithii."
  ),

  "vegresults", "speciesid", "G_Vul_spp",
  festuca_spp$species_code[[1]], festuca_spp$name[[1]],
  "human_reviewed_taxonomic_update",
  paste(
    "Reviewed for GAZP8; unresolved raw VULPI observations are retained",
    "at genus level under the accepted Festuca genus."
  ),

  "vegresults", "speciesid", "Sal_kal1",
  sal_tra$species_code[[1]], sal_tra$name[[1]],
  "human_reviewed_source_correction",
  paste(
    "Corrected for GAZP8; raw code SATR represents Salsola tragus.",
    "A one-record note equating SATR with SAKA was not generalized."
  )
)

# Build crosswalk table (Delete from "complicated" comment to here; keep this)
species_crosswalk_path <- file.path(
  "crosswalk_tables", "GAZP", "GAZP8", "GAZP8_species_crosswalk.csv"
)

species_crosswalk_result <- build_project_species_crosswalk(
  data_list = data_list_for_species_crosswalk,
  species_lookup = species_lookup,
  lu_species = lu_species,
  global_species_crosswalk = sp_crosswalk,
  database = "GAZP",
  projectid = study$projectid[[1]],
  overrides = project_species_overrides,
  output_path = species_crosswalk_path
)

project_species_crosswalk <- species_crosswalk_result$crosswalk

reviewed_unknown_crosswalk <- vegresults |>
  mutate(source_species_code = stringr::str_squish(as.character(speciesid))) |>
  filter(source_species_code %in% reviewed_unknown_source_codes) |>
  count(source_species_code, name = "source_occurrences") |>
  transmute(
    database = "GAZP",
    projectid = as.integer(study$projectid[[1]]),
    project_code = paste0("GAZP", study$projectid[[1]]),
    crosswalk_row_type = "default",
    rule_source_table = "vegresults",
    source_table = "vegresults",
    source_column = "speciesid",
    source_value_type = "species_code",
    source_value = source_species_code,
    source_occurrences = as.integer(source_occurrences),
    speciesid = as.integer(unknown_species$speciesid[[1]]),
    accepted_species_code = unknown_species$species_code[[1]],
    accepted_species_name = unknown_species$name[[1]],
    mapping_status = "human_reviewed_unknown",
    reverse_mapping_rule = "source_value_preserved_in_notes",
    match_rate = NA_real_,
    match_unit = NA_character_,
    contextual_rule_validated = TRUE,
    global_source_code_count = NA_integer_,
    global_source_codes = NA_character_,
    review_required = FALSE,
    reviewed = TRUE,
    decision_note = paste(
      "Reviewed for GAZP8; source code", source_value,
      "is retained separately and mapped to unknown species."
    )
  )

stopifnot(
  setequal(
    reviewed_unknown_crosswalk$source_value,
    reviewed_unknown_source_codes
  )
)

project_species_crosswalk <- bind_rows(
  project_species_crosswalk,
  reviewed_unknown_crosswalk
) |>
  arrange(source_table, source_column, source_value)

project_species_lookup <- bind_rows(
  species_crosswalk_result$lookup,
  reviewed_unknown_crosswalk |>
    select(
      source_table, source_column, source_value, speciesid,
      accepted_species_code, accepted_species_name, mapping_status
    )
) |>
  distinct()

readr::write_csv(project_species_crosswalk, species_crosswalk_path, na = "")

species_contextual_rules <- species_crosswalk_result$contextual_rules
species_mapping_collisions <- species_crosswalk_result$collisions
species_mapping_discrepancies <- species_crosswalk_result$discrepancies
# These should be empty!

### Staging output --------------------------------------------------------------
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


#### Group 1: Project backbone --------------------------------------------------------------
# ---- project ----

stg_project <- study |>
  transmute(
    database = DB,
    projectid = as.integer(projectid),
    type = stringr::str_to_lower(na_if_blank(studytype)),
    community = na_if_blank(community),
    reference = na_if_blank(refdata),
    notes = na_if_blank(notes),
    date_received = as.Date("2018-03-30") ############# CHANGE PER PROJECT
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

### Set values for staging (set as NA if no separate data DOI exists)
data_doi <- NA
data_url <- NA
data_accessibility_notes <- NA

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
        creativecommons_license = na_if_blank(creativecommonsliscence),
        use_conditions = na_if_blank(conditionsforuseandrepublishing)
      ) |>
      distinct(),
    by = c("database", "projectid")
  ) |>
  mutate(
    data_doi = .env$data_doi,
    data_url = .env$data_url,
    data_accessibility_notes = .env$data_accessibility_notes,
    date_received = as.Date("2018-03-30") # Confirm for GAZP8
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

nrow(site_matched[!is.na(site_matched$existing_siteid), ]) # How many matches were found in the database?

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
# Allocate paper IDs after the current maximum in grp.paper.

max_paperid <- DBI::dbGetQuery(
  con,
  "SELECT COALESCE(MAX(paperid), 0) AS max_paperid FROM grp.paper"
)$max_paperid[[1]]

stg_paper <- refs |>
  filter(if_any(everything(), ~ !is.na(.x) & .x != "")) |>
  transmute(
    publication_year = na_if_blank(pubyear),
    publication_title = na_if_blank(pubtitle),
    publication_journal = na_if_blank(pubjournal),
    publication_doi = na_if_blank(pubDOI),
    publication_url = na_if_blank(pubURL)
  ) |>
  distinct() |>
  mutate(paperid = as.integer(max_paperid) + row_number()) |>
  relocate(paperid)

head(stg_paper)

paper_issues <- validate_staged_table(
  stg_tbl = stg_paper,
  target_table = "paper",
  constraints_tbl = import_registry$constraints
)

paper_issues

# ---- project_paper ----

stg_project_paper <- refs |>
  transmute(
    database = as.character(DB),
    projectid = as.integer(projectid),
    publication_doi = na_if_blank(pubDOI)
  ) |>
  left_join(
    stg_paper |>
      select(paperid, publication_doi),
    by = "publication_doi"
  ) |>
  filter(!is.na(paperid)) |>
  transmute(
    database,
    projectid,
    paperid,
    notes = NA_character_
  ) |>
  distinct()

head(stg_project_paper)

project_paper_issues <- validate_staged_table(
  stg_tbl = stg_project_paper,
  target_table = "project_paper",
  constraints_tbl = import_registry$constraints
)

project_paper_issues

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

nrow(author_matched[!is.na(author_matched$author_contributorid), ]) # How many matches were found in the database?

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

# ---- paper_author ----
# Store the project contributor as a paper author, then determine whether
# that contributor is also the corresponding author.

stg_paper_author <- refs |>
  transmute(
    database = as.character(DB),
    projectid = as.integer(projectid),
    publication_doi = na_if_blank(pubDOI),
    corresponding_email = str_to_lower(
      na_if_blank(pubcorrespondingauthoremail)
    )
  ) |>
  left_join(
    stg_paper |>
      select(paperid, publication_doi),
    by = "publication_doi"
  ) |>
  left_join(
    study |>
      transmute(
        database = as.character(DB),
        projectid = as.integer(projectid),
        contributor_email = str_to_lower(na_if_blank(email))
      ) |>
      distinct(),
    by = c("database", "projectid")
  ) |>
  left_join(
    stg_author_contributor |>
      transmute(
        author_contributorid,
        contributor_email = str_to_lower(na_if_blank(email))
      ),
    by = "contributor_email"
  ) |>
    filter(
    !is.na(paperid),
    !is.na(author_contributorid)
  ) |>
  transmute(
    paperid,
    author_contributorid,
    is_corresponding_author =
      !is.na(contributor_email) &
      !is.na(corresponding_email) &
      contributor_email == corresponding_email
  ) |>
  distinct()

head(stg_paper_author)

paper_author_issues <- validate_staged_table(
  stg_tbl = stg_paper_author,
  target_table = "paper_author",
  constraints_tbl = import_registry$constraints
)

paper_author_issues

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
  project_paper = stg_project_paper,
  author_contributor = stg_author_contributor,
  paper_author = stg_paper_author,
  project_contributor = stg_project_contributor,
  project_vegmetric = stg_project_vegmetric
)

purrr::map_int(group1_staged, nrow)

# Lookup validation not needed for group 1, as any controlled vocabulary is embedded in table constraints for this group


#### Group 2: Site attributes --------------------------------------------------------------
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
    type = na_if_blank(disturbance)
  ) |>
  filter(!is.na(type)) |>
  separate_rows(
    type,
    sep = "\\s*\\|\\s*"
  ) |>
  mutate(
    type = normalize_vocab(type)
  ) |>
  filter(!is.na(type)) |>
  distinct(
    siteid,
    type
  )

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
site_invasive_resolved <- site |>
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
    project_species_lookup |>
      filter(
        source_table == "site",
        source_column == "invasivespe"
      ) |>
      transmute(
        invasive_species_name = source_value |>
          stringr::str_squish(),
        speciesid = as.integer(speciesid)
      ) |>
      distinct(),
    by = "invasive_species_name",
    relationship = "many-to-one"
  )

site_invasive_unresolved <- site_invasive_resolved |>
  filter(is.na(speciesid))

if (nrow(site_invasive_unresolved) > 0L) {
  print(site_invasive_unresolved)

  stop(
    "A site invasive species did not resolve through the reviewed project species crosswalk.",
    call. = FALSE
  )
}

stg_site_invasive <- site_invasive_resolved |>
  transmute(
    siteid,
    speciesid
  ) |>
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


#### Group 3: Experimental structure --------------------------------------------------------------
# ---- area ----
# Build plot areas for either blocked or unblocked designs. For blocked
# designs, blocks are identified within sites and become the plot parents.
treatment_area_context <- treatments |>
  transmute(
    source_treatmentid = as.character(treatmentid),
    siteid = as.integer(siteid),
    restoration_start_year = as.numeric(tsr_start_year),
    restoration_type = normalize_vocab(restorationtype),
    disturbance_end_year = as.numeric(disturbanceendyear)
  ) |>
  distinct()

ambiguous_treatment_sites <- treatment_area_context |>
  distinct(source_treatmentid, siteid) |>
  count(source_treatmentid, name = "n_sites") |>
  filter(n_sites != 1L)

stopifnot(nrow(ambiguous_treatment_sites) == 0L)

# Check that measurement scale and units are unique to each replicate.
vegresults |>
  transmute(
    source_treatmentid = as.character(treatmentid),
    block = na_if_blank(block),
    replicate = na_if_blank(replicate),
    size = as.numeric(measurementscale),
    units = na_if_blank(measurementmetric)
  ) |>
  distinct() |>
  count(source_treatmentid, block, replicate) |>
  filter(n > 1)

replicate_candidates <- vegresults |>
  transmute(
    source_treatmentid = as.character(treatmentid),
    block = na_if_blank(block),
    replicate = na_if_blank(replicate),
    size = as.numeric(measurementscale),
    units = na_if_blank(measurementmetric)
  ) |>
  filter(
    !is.na(source_treatmentid),
    !is.na(replicate)
  ) |>
  distinct() |>
  left_join(treatment_area_context, by = "source_treatmentid")

stopifnot(!anyNA(replicate_candidates$siteid))

# Treat the project as blocked only when more than one distinct, nonblank block
# value occurs. Some legacy unblocked projects use block = 1 for every plot.
block_present <- !is.na(replicate_candidates$block)
block_values <- unique(replicate_candidates$block[block_present])
has_blocks <- length(block_values) > 1L

if (has_blocks && !all(block_present)) {
  stop("Some, but not all, area candidates have block IDs. Review before continuing.")
}

if (has_blocks) {
  # Block numbers can repeat among sites, so siteid and block form the key.
  block_candidates <- replicate_candidates |>
    distinct(siteid, block) |>
    arrange(siteid, block) |>
    mutate(
      size = 18 * 16 * 8,
      units = "m2"
    )
} else {
  block_candidates <- tibble(
    siteid = integer(),
    block = character(),
    size = numeric(),
    units = character()
  )
}

n_blocks <- nrow(block_candidates)
n_replicates <- nrow(replicate_candidates)

# Allocate all area IDs together so block and plot ranges cannot overlap.
allocated_areaids <- next_ids(
  con,
  table = "area",
  id_col = "areaid",
  n = n_blocks + n_replicates
)

block_candidates <- block_candidates |>
  mutate(areaid = allocated_areaids[seq_len(n_blocks)])

replicate_candidates <- replicate_candidates |>
  arrange(siteid, block, source_treatmentid, replicate) |>
  mutate(areaid = allocated_areaids[n_blocks + seq_len(n_replicates)])

if (has_blocks) {
  replicate_candidates <- replicate_candidates |>
    left_join(
      block_candidates |>
        select(siteid, block, parentid = areaid),
      by = c("siteid", "block")
    )
} else {
  replicate_candidates <- replicate_candidates |>
    mutate(parentid = NA_integer_)
}

if (has_blocks) {
  stopifnot(!anyNA(replicate_candidates$parentid))
}

if (has_blocks) {
  stg_block_area <- block_candidates |>
    transmute(
      areaid = as.integer(areaid),
      siteid,
      type = "block",
      size,
      units,
      restoration_start_year = NA_real_,
      restoration_type = NA_character_,
      disturbance_end_year = NA_real_,
      parentid = NA_integer_
    )
} else {
  stg_block_area <- tibble(
    areaid = integer(),
    siteid = integer(),
    type = character(),
    size = numeric(),
    units = character(),
    restoration_start_year = numeric(),
    restoration_type = character(),
    disturbance_end_year = numeric(),
    parentid = integer()
  )
}

stg_replicate_area <- replicate_candidates |>
  transmute(
    areaid = as.integer(areaid),
    siteid,
    type = "plot",
    size,
    units,
    restoration_start_year,
    restoration_type,
    disturbance_end_year,
    parentid = as.integer(parentid)
  )

stg_area <- bind_rows(stg_block_area, stg_replicate_area) |>
  distinct()

head(stg_area)

area_issues <- validate_staged_table(
  stg_tbl = stg_area,
  target_table = "area",
  constraints_tbl = import_registry$constraints
)

area_issues

# Write crosswalk output for plot children and, when present, block parents.
block_crosswalk <- if (has_blocks) {
  block_candidates |>
    transmute(
      database = "GAZP",
      projectid = as.integer(study$projectid[1]),
      object_type = "block",
      source_treatmentid = NA_character_,
      block,
      replicate = NA_character_,
      areaid
    )
} else {
  tibble(
    database = character(),
    projectid = integer(),
    object_type = character(),
    source_treatmentid = character(),
    block = character(),
    replicate = character(),
    areaid = integer()
  )
}

harmonized_SQL_crosswalk <- bind_rows(
  block_crosswalk,
  replicate_candidates |>
    transmute(
      database = "GAZP",
      projectid = as.integer(study$projectid[1]),
      object_type = "plot",
      source_treatmentid,
      block,
      replicate,
      areaid
    )
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

# Route recognized values out of treatment.other_treatment
# and into their appropriate treatment-detail tables.

other_treatment_src <- treatments |>
  transmute(
    source_treatmentid = na_if_blank(treatmentid),
    source_trt_tsr = as.integer(trt_tsr),
    other_treatment_raw = na_if_blank(othertreatments),
    other_treatment_norm = normalize_vocab(othertreatments)
  ) |>
  left_join(
    treatment_crosswalk |>
      select(source_treatmentid, source_trt_tsr, treatmentid),
    by = c("source_treatmentid", "source_trt_tsr")
  ) |>
  mutate(
    has_cover_crop = coalesce(
      other_treatment_norm == "cover crop",
      FALSE
    ),
    has_cultipack = coalesce(
      other_treatment_norm == "cultipack",
      FALSE
    )
  )

head(other_treatment_src)

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
    other_treatment = case_when(
        normalize_vocab(othertreatments) %in%
        c("cover crop", "cultipack") ~ NA_character_,
        TRUE ~ na_if_blank(othertreatments)
        ),
    treatment_type_norm = normalize_vocab(treatment_type),
    treatment_category_norm = normalize_vocab(treatment_category)
  ) |>
  group_by(source_treatmentid, source_trt_tsr) |>
  summarise(
    year = first(na.omit(year)),
    month = first(na.omit(month)),
    day = first(na.omit(day)),
    weeks_since_restoration = first(na.omit(weeks_since_restoration)),
    other_treatment = first(
        na.omit(other_treatment),
        default = NA_character_
        ),

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


#### Group 4: Treatment details ------------------------------
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
# GAZP2 has "none" for treatments that weren't seeded for the treatment_category of "application method"
# This is not a valid value for the application_method lookup table, so filter it out here.
# treatment_detail_src <- treatment_detail_src |>
# filter(!(treatment_category == "application method" & treatment_type == "none"))

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
  # covercropid is identity-generated, so omit it.
  # speciesid 1 represents an unknown or unreported species.
  
  stg_treatment_cover_crop <- other_treatment_src |>
    filter(has_cover_crop) |>
    transmute(
    treatmentid,
    speciesid = 1L,
    amount = NA_real_,
    units = NA_character_,
    notes = "Cover crop present; species, amount, and units not reported."
  ) |>
  distinct()

head(stg_treatment_cover_crop)

treatment_cover_crop_issues <- validate_staged_table(
  stg_tbl = stg_treatment_cover_crop,
  target_table = "treatment_cover_crop",
  constraints_tbl = import_registry$constraints
)

treatment_cover_crop_issues

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

stg_treatment_prep <- bind_rows(
  treatment_detail_src |>
    filter(treatment_category == "bed prep") |>
    transmute(
      treatmentid,
      type = treatment_type
    ),
  other_treatment_src |>
    filter(has_cultipack) |>
    transmute(
      treatmentid,
      type = "packing"
    )
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
  treatment_cover_crop = stg_treatment_cover_crop,
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

# Verify that recognized other-treatment values were routed correctly.

routed_other_treatment_issues <- stg_treatment |>
  filter(
    normalize_vocab(other_treatment) %in%
      c("cover crop", "cultipack")
  )

cover_crop_routing_issues <- other_treatment_src |>
  filter(has_cover_crop) |>
  distinct(treatmentid) |>
  anti_join(
    stg_treatment_cover_crop |>
      distinct(treatmentid),
    by = "treatmentid"
  )

cultipack_routing_issues <- other_treatment_src |>
  filter(has_cultipack) |>
  distinct(treatmentid) |>
  anti_join(
    stg_treatment_prep |>
      filter(type == "packing") |>
      distinct(treatmentid),
    by = "treatmentid"
  )

routed_other_treatment_issues
cover_crop_routing_issues
cultipack_routing_issues


#### Group 5: Seeding and planting ---------------------------
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
    project_species_lookup |>
      filter(
        source_table == "trtrates",
        source_column == "speciesid"
      ) |>
      transmute(
        source_species_code = source_value,
        speciesid = as.integer(speciesid)
      ) |>
      distinct(),
    by = "source_species_code",
    relationship = "many-to-one"
  )

seeding_species_unresolved <- seeding_src |>
  filter(
    !is.na(source_species_code),
    is.na(speciesid)
  )

if (nrow(seeding_species_unresolved) > 0L) {
  print(seeding_species_unresolved)

  stop(
    "A seeded species did not resolve through the reviewed project species crosswalk.",
    call. = FALSE
  )
}

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

## For GAZP8, add seed mix confusion notes
stg_seed_mix <- stg_seed_mix |>
  mutate(
    notes = case_when(
      as.numeric(treated_richness) == 12 ~ paste(
        "Composition retained from the detailed source seed data, which list",
        "12 species for the BLM90.10 mixture; the published study narrative",
        "instead reports 14 species."
      ),
      as.numeric(treated_richness) == 23 ~ paste(
        "Composition retained from the detailed source seed data, which list",
        "23 species for this mixture; the published study narrative instead",
        "reports 21 species."
      ),
      TRUE ~ notes
    )
  )

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


#### Group 6: Results -------------------------------------------
# ---- veg_result ----

veg_timepoint_lookup <- timepoints |>
  transmute(
    database = as.character(DB),
    source_treatmentid = na_if_blank(treatmentid),
    time_since_restoration = as.integer(tsr),
    timepoint_year = suppressWarnings(as.numeric(year)),
    month = suppressWarnings(as.numeric(month)),
    day = suppressWarnings(as.numeric(day))
  ) |>
  distinct()

veg_result_resolved <- vegresults |>
  transmute(
    database = as.character(DB),
    source_year = suppressWarnings(as.numeric(year)),
    source_observationid = id,
    source_treatmentid = na_if_blank(treatmentid),
    block = na_if_blank(block),
    replicate = na_if_blank(replicate),
    time_since_restoration = as.integer(tsr),
    source_species_code = na_if_blank(speciesid),
    origin = case_when(
      normalize_vocab(speciesorigin) == "unknown_sp" ~ "unknown",
      TRUE ~ normalize_vocab(speciesorigin)
      ),
    response = as.numeric(response),
    level = normalize_vocab(responselevel),
    metric = normalize_vocab(responsemetric),
    measurement_scale = na_if_blank(measurementscale),
    measurement_metric = na_if_blank(measurementmetric)
  ) |>
  left_join(
    veg_timepoint_lookup,
    by = c(
        "database",
        "source_treatmentid",
        "time_since_restoration"
        )
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
    project_species_lookup |>
      filter(
        source_table == "vegresults",
        source_column == "speciesid"
      ) |>
      transmute(
        source_species_code = source_value,
        speciesid = as.integer(speciesid)
      ) |>
      distinct(),
    by = "source_species_code",
    relationship = "many-to-one"
  )

veg_result_species_unresolved <- veg_result_resolved |>
  filter(
    !is.na(source_species_code),
    is.na(speciesid)
  )

if (nrow(veg_result_species_unresolved) > 0L) {
  print(veg_result_species_unresolved)

  stop(
    "A vegetation-result species did not resolve through the reviewed project species crosswalk.",
    call. = FALSE
  )
}

## GAZP8: Adding notes for unknown forbs so they don't collapse in the distinct() call
veg_result_resolved <- veg_result_resolved |>
  mutate(staging_year = coalesce(timepoint_year, source_year)) |>
  group_by(
    areaid,
    time_since_restoration,
    staging_year,
    month,
    day,
    source_species_code,
    speciesid,
    origin,
    level,
    response,
    metric
  ) |>
  mutate(
    unknown_forb_occurrence = if_else(
      source_species_code == "UN_ID_UNKFORB",
      row_number(),
      NA_integer_
    )
  ) |>
  ungroup() |>
  select(-staging_year)

stg_veg_result <- veg_result_resolved |>
  transmute(
    areaid = as.integer(areaid),
    time_since_restoration,
    year = coalesce(timepoint_year, source_year),
    month,
    day,
    speciesid,
    cultivarid = NA_integer_,
    individualid = NA_integer_,
    origin,
    level,
    response,
    metric,
    notes = case_when(
      source_species_code == "UN_ID_UNKFORB" ~ paste(
        "Original unresolved species code:",
        source_species_code,
        "| Distinct source taxon occurrence:",
        unknown_forb_occurrence
      ),
      source_species_code %in% reviewed_unknown_source_codes ~
        paste("Original unresolved species code:", source_species_code),
      TRUE ~ NA_character_
    )
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

veg_timepoint_key_issues <- veg_timepoint_lookup |>
  count(
    database,
    source_treatmentid,
    time_since_restoration
  ) |>
  filter(n > 1)

veg_timepoint_check <- vegresults |>
  transmute(
    database = as.character(DB),
    source_treatmentid = na_if_blank(treatmentid),
    time_since_restoration = as.integer(tsr),
    source_year = suppressWarnings(as.numeric(year))
  ) |>
  distinct() |>
  left_join(
    veg_timepoint_lookup,
    by = c(
      "database",
      "source_treatmentid",
      "time_since_restoration"
    )
  )

veg_timepoint_missing_issues <- veg_timepoint_check |>
  filter(is.na(timepoint_year))

veg_timepoint_year_issues <- veg_timepoint_check |>
  filter(
    !is.na(source_year),
    !is.na(timepoint_year),
    source_year != timepoint_year
  )

veg_timepoint_key_issues
veg_timepoint_missing_issues
veg_timepoint_year_issues


#### Referential validation ----------------------------------------
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


#### Write crosswalk outputs -------------------------------------------
crosswalk_dir <- "crosswalk_tables/GAZP/GAZP8"
dir.create(crosswalk_dir, recursive = TRUE, showWarnings = FALSE)

write_csv(
  harmonized_SQL_crosswalk,
  file.path(crosswalk_dir, "GAZP8_harmonized-SQL_crosswalk.csv")
)

#### Write to Supabase ------------------------------------------------
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
  append_if_rows(con, "paper", stg_paper)
  append_if_rows(con, "paper_author", stg_paper_author)
  append_if_rows(con, "project_paper", stg_project_paper)

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
  append_if_rows(con, "treatment_cover_crop", stg_treatment_cover_crop)
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


#### Write files to Supabase ------------------------------------------------
supabase_url <- "https://rudybfqutvodkakgctpo.supabase.co"
service_key <- service_role

# Files produced or reviewed for this import.
gazp8_uploads <- tribble(
  ~local_file, ~destination_path,

  # Crosswalk and exclusion-audit files
  "crosswalk_tables/GAZP/GAZP8/GAZP8_harmonized-SQL_crosswalk.csv",
  "GAZP/GAZP8/crosswalks/GAZP8_harmonized-SQL_crosswalk.csv",

  "crosswalk_tables/GAZP/GAZP8/GAZP8_species_crosswalk.csv",
  "GAZP/GAZP8/crosswalks/GAZP8_species_crosswalk.csv",

  "crosswalk_tables/GAZP/GAZP8/GAZP8_excluded_vegresults.csv",
  "GAZP/GAZP8/crosswalks/GAZP8_excluded_vegresults.csv",

  # Harmonized workbook
  "data/harmonized/GAZP/GAZP8/GAZP8.xlsx",
  "GAZP/GAZP8/harmonized/GAZP8.xlsx",

  # Original source files
  "data/source/GAZP/GAZP8/Cover classes.csv",
  "GAZP/GAZP8/source/Cover_classes.csv",

  "data/source/GAZP/GAZP8/Final Report Jan2017 for Conservation Registry.pdf",
  "GAZP/GAZP8/source/Final_Report_Jan2017_for_Conservation_Registry.pdf",

  "data/source/GAZP/GAZP8/PineRidgeStudyPlots.csv",
  "GAZP/GAZP8/source/PineRidgeStudyPlots.csv",

  "data/source/GAZP/GAZP8/PineRidgeStudyPlots.xlsx",
  "GAZP/GAZP8/source/PineRidgeStudyPlots.xlsx",

  "data/source/GAZP/GAZP8/Seed data.csv",
  "GAZP/GAZP8/source/Seed_data.csv",

  # Import and species-addition code
  "R/import_code/GAZP8/20260903_GAZP8_import.r",
  "GAZP/GAZP8/code/20260903_GAZP8_import.r",

  "R/import_code/GAZP8/20260903_GAZP8_add_species.r",
  "GAZP/GAZP8/code/20260903_GAZP8_add_species.r"
)

missing_gazp8_uploads <- gazp8_uploads |>
  filter(!file.exists(local_file))

if (nrow(missing_gazp8_uploads) > 0L) {
  print(missing_gazp8_uploads)
  stop("One or more GAZP8 files are missing; upload cancelled.", call. = FALSE)
}

purrr::pwalk(
  gazp8_uploads,
  function(local_file, destination_path) {
    upload_to_supabase(
      local_file = local_file,
      destination_path = destination_path,
      supabase_url = supabase_url,
      service_key = service_key
    )
  }
)
