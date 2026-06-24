# ---- cultivar import ----------------------------------------------------
# Assumes:
# - con exists
# - R/source_drafts/20260612_import_registry.r has been sourced
# - R/source_drafts/20260620_import_helper_functions.r has been sourced
# - crosswalk_tables/20260605_sp_crosswalk.csv maps Excel species codes to SQL speciesid

# ---- libraries ----
library(tidyverse)
library(openxlsx)
library(DBI)
library(RPostgres)
library(glue)

# Pull constraints and lookup tables list
source("R/source_drafts/20260612_import_registry.r") # Note this code requires the db connection be called con
source("R/source_drafts/20260620_import_helper_functions.r")

# ---- connect to the database ----
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

# ---- bring in data ----
# Bring in cultivar data from harmonized GRP Excel source
cultivar_raw <- read.csv("data/harmonized/cultivars.csv")

# Bring in species crosswalk table
# Important: use source Excel species codes, not grp.species_names,
# because codes like Ach_mil1 may not exist in SQL after numeric suffix cleanup.

sp_crosswalk <- readr::read_csv("crosswalk_tables/20260605_sp_crosswalk.csv",
  show_col_types = FALSE
)

species_lookup <- sp_crosswalk |>
  transmute(
    source_species_code = na_if(excel_speciesid, ""),
    speciesid = as.integer(sql_speciesid)
  ) |>
  filter(!is.na(source_species_code), !is.na(speciesid)) |>
  distinct()

# ---- intial clean of cultivar ----

cultivar_src <- cultivar_raw |>
  transmute(
    source_species_code = na_if(speciesid, ""),
    source_cultivarid = suppressWarnings(as.integer(cultivarid)),
    cultivar_name = na_if(cultivar, ""),
    cultivar_origin = na_if(cultivarorigin, ""),
    latitude = suppressWarnings(as.numeric(seedlat)),
    longitude = suppressWarnings(as.numeric(seedlong))
  ) |>
  filter(
    !is.na(source_species_code),
    !is.na(source_cultivarid)
  ) |>
  left_join(species_lookup, by = "source_species_code")

# Checks

missing_species_matches <- cultivar_src |>
  filter(is.na(speciesid)) |>
  distinct(source_species_code)
## No issues

bad_coordinates <- cultivar_src |>
  mutate(row_number = row_number()) |>
  filter(
    (!is.na(latitude) & (latitude < -90 | latitude > 90)) |
      (!is.na(longitude) & (longitude < -180 | longitude > 180))
  )
## No issues

# ---- resolve ambiguities ----
# Same source species + source cultivarid maps to multiple cultivar records.
# These are the truly ambiguous cases for later seeding imports unless raw data
# has another field that distinguishes which cultivar was used.
ambiguous_source_cultivar_keys <- cultivar_src |>
  distinct(
    source_species_code,
    source_cultivarid,
    cultivar_name,
    cultivar_origin,
    latitude,
    longitude
  ) |>
  count(source_species_code, source_cultivarid, name = "n_distinct_cultivars") |>
  filter(n_distinct_cultivars > 1)

true_ambiguous_source_keys <- tibble::tribble(
  ~source_species_code, ~source_cultivarid,
  "Sch_sco", 1L,
  "Pan_vir", 1L
)

cultivar_variants <- cultivar_src |>
  distinct(
    source_species_code,
    source_cultivarid,
    speciesid,
    cultivar_name,
    cultivar_origin,
    latitude,
    longitude
  ) |>
  mutate(
    true_ambiguity = paste(source_species_code, source_cultivarid, sep = "::") %in%
      paste(true_ambiguous_source_keys$source_species_code,
            true_ambiguous_source_keys$source_cultivarid,
            sep = "::")
  )

# Collapse non-ambiguous duplicated rows by cultivar name.
# Prefer rows with more complete metadata.
cultivar_canonical <- cultivar_variants |>
  filter(!true_ambiguity) |>
  mutate(
    completeness_score =
      as.integer(!is.na(cultivar_origin)) +
      as.integer(!is.na(latitude)) +
      as.integer(!is.na(longitude))
  ) |>
  group_by(source_species_code, source_cultivarid, speciesid, cultivar_name) |>
  arrange(desc(completeness_score), cultivar_origin, latitude, longitude, .by_group = TRUE) |>
  slice(1) |>
  ungroup() |>
  select(-completeness_score, -true_ambiguity)

# Keep true ambiguities as separate cultivar records.
cultivar_true_ambiguous <- cultivar_variants |>
  filter(true_ambiguity) |>
  select(-true_ambiguity)

cultivar_records <- bind_rows(
  cultivar_canonical,
  cultivar_true_ambiguous
) |>
  arrange(speciesid, source_cultivarid, cultivar_name, cultivar_origin)

# ---- build staged cultivar table ----
# Rules:
# - Generate globally unique SQL cultivar IDs.
# - Collapse duplicate source rows that represent the same cultivar and only differ
#   by added origin/coordinate metadata.
# - Preserve true ambiguous Excel speciesid + cultivarid cases in the crosswalk.
# - Later Excel imports must use the cultivar crosswalk, not raw Excel cultivarid.

# Get IDs
existing_max_cultivarid <- DBI::dbGetQuery(
  con,
  "SELECT COALESCE(MAX(cultivarid), 0) AS max_cultivarid FROM grp.cultivar;"
)$max_cultivarid

cultivar_records <- cultivar_records |>
  mutate(
    sql_cultivarid = existing_max_cultivarid + row_number(),
    sql_speciesid = speciesid
  )

# Crosswalk stays source-row oriented enough to document collapsed variants.
# Non-ambiguous source variants all map to the one chosen SQL cultivar record.
cultivar_crosswalk <- cultivar_variants |>
  left_join(
    cultivar_records |>
      select(
        source_species_code,
        source_cultivarid,
        speciesid,
        cultivar_name,
        sql_speciesid,
        sql_cultivarid,
        sql_cultivar_origin = cultivar_origin,
        sql_seedlat = latitude,
        sql_seedlong = longitude
      ) |>
      mutate(
        sql_cultivar = cultivar_name
      ),
    by = c(
      "source_species_code",
      "source_cultivarid",
      "speciesid",
      "cultivar_name"
    )
  ) |>
  mutate(
    cultivar_match_status = case_when(
      source_species_code %in% true_ambiguous_source_keys$source_species_code &
        source_cultivarid %in% true_ambiguous_source_keys$source_cultivarid ~
        "ambiguous_source_key",
      is.na(sql_cultivarid) ~
        "unmatched_review_needed",
      !is.na(cultivar_origin) & cultivar_origin != sql_cultivar_origin ~
        "collapsed_variant",
      !is.na(latitude) & latitude != sql_seedlat ~
        "collapsed_variant",
      !is.na(longitude) & longitude != sql_seedlong ~
        "collapsed_variant",
      TRUE ~
        "matched"
    ),
    notes = case_when(
      cultivar_match_status == "ambiguous_source_key" ~
        "Excel speciesid + cultivarid maps to multiple cultivar names; future project imports require manual review.",
      cultivar_match_status == "collapsed_variant" ~
        "Source row was treated as the same cultivar as another row with more complete SQL metadata.",
      TRUE ~ NA_character_
    )
  ) |>
  transmute(
    excel_speciesid = source_species_code,
    excel_cultivarid = source_cultivarid,
    excel_cultivar = cultivar_name,
    excel_cultivarorigin = cultivar_origin,
    excel_seedlat = latitude,
    excel_seedlong = longitude,
    sql_speciesid,
    sql_cultivarid,
    sql_cultivar,
    sql_cultivarorigin = sql_cultivar_origin,
    sql_seedlat,
    sql_seedlong,
    cultivar_match_status,
    notes
  ) |>
  arrange(excel_speciesid, excel_cultivarid, excel_cultivar)

stg_cultivar <- cultivar_records |>
  transmute(
    cultivarid = sql_cultivarid,
    speciesid = sql_speciesid,
    name = cultivar_name,
    origin = cultivar_origin,
    latitude,
    longitude
  )

# ---- validate staged cultivar ----

cultivar_internal_issues <- validate_staged_table(
  stg_tbl = stg_cultivar,
  target_table = "cultivar",
  constraints_tbl = import_registry$constraints
)
## No issues

cultivar_lookup_issues <- validate_lookup_constraints(
  stg_tbl = stg_cultivar,
  target_table = "cultivar",
  constraints_tbl = import_registry$constraints,
  con = con
)
## No issues

cultivar_crosswalk_unmatched <- cultivar_crosswalk |>
  filter(is.na(sql_speciesid) | is.na(sql_cultivarid))
  ## None unmatched

# ---- write cultivar and crosswalk artifact ----

DBI::dbWithTransaction(con, {
  append_if_rows(con, "cultivar", stg_cultivar)
})

readr::write_csv(
  cultivar_crosswalk,
  "crosswalk_tables/cultivar_crosswalk.csv"
)

# ---- write files to Supabase ----
supabase_url <- "https://rudybfqutvodkakgctpo.supabase.co"
service_key <- service_role

# Crosswalk table
upload_to_supabase(
  local_file = "crosswalk_tables/cultivar_crosswalk.csv",
  destination_path = "cultivar_vocabulary_20260624/cultivar_crosswalk.csv",
  supabase_url = supabase_url,
  service_key = service_key
)

# Code
upload_to_supabase(
  local_file = "R/import_code/vocab_import/20260624_populate_cultivars.r",
  destination_path = "cultivar_vocabulary_20260624/populate_cultivars.r",
  supabase_url = supabase_url,
  service_key = service_key
)

# Code
upload_to_supabase(
  local_file = "data/harmonized/cultivars.csv",
  destination_path = "cultivar_vocabulary_20260624/source_cultivars.csv",
  supabase_url = supabase_url,
  service_key = service_key
)