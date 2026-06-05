## This script reads in the raw species data from an Excel file, cleans and transforms it, and then populates the 'species' table in the database through a series of iterative steps with this code and SQL code.

# Libraries
library(tidyverse)
library(DBI)
library(RPostgres)

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

# Test connection
dbListTables(conn)

# Species data
##### Change the path to the Excel file as needed
species_raw <- read.csv("C:\\Users\\nshack\\University of Victoria\\ENVI Restoration Futures Lab (O) - Documents\\Projects\\GRP\\GRP_Database_2026-05-15\\GRP_GAZP_Database\\GRP_GAZP_Database\\species_names-2024-Feb-28.csv")

# Clean species data ------------------------------------------------------

species_clean <- species_raw %>%
  transmute(
    species_code_raw = as.character(speciesid),
    `group` = na_if(`group`, "NA"),
    `order` = na_if(`order`, "NA"),
    family = na_if(family, "NA"),
    genus = na_if(genus, "NA"),
    species = na_if(species, "NA"),
    subtype = na_if(subtype, "NA"),
    subtype_name = na_if(subtype_name, "NA"),
    lifeform_raw = na_if(lifeform, "NA")
  ) %>%
  mutate(
    subtype = case_when(
      subtype %in% c("", "NA") ~ NA_character_,
      subtype %in% c("var.", "var") ~ "variety",
      subtype %in% c("subsp.", "ssp.", "subsp", "ssp") ~ "subspecies",
      TRUE ~ subtype
    ),

lifespan = case_when(
  str_detect(lifeform_raw, "^annual ") ~ "annual",
  str_detect(lifeform_raw, "^biennial ") ~ "biennial",
  str_detect(lifeform_raw, "^perennial ") ~ "perennial",
  TRUE ~ NA_character_
),

lifeform = case_when(
  str_detect(lifeform_raw, "^annual ") ~ str_remove(lifeform_raw, "^annual "),
  str_detect(lifeform_raw, "^biennial ") ~ str_remove(lifeform_raw, "^biennial "),
  str_detect(lifeform_raw, "^perennial ") ~ str_remove(lifeform_raw, "^perennial "),
  TRUE ~ lifeform_raw
),

lifeform = case_when(
  lifeform == "orchid" ~ "forb",
  TRUE ~ lifeform
),

    species_code_base = str_remove(species_code_raw, "\\d+$")
  ) %>%
  mutate(
    is_placeholder_taxon = is.na(genus) & species == "spp",

    genus = if_else(
      is_placeholder_taxon,
      "Unknown",
      genus
    ),

    species = if_else(
      is_placeholder_taxon,
      str_replace(species_code_base, "^L_", ""),
      species
    )
  ) %>%
  select(-is_placeholder_taxon) %>%
  mutate(
    source_name = str_squish(paste(genus, species, subtype, subtype_name))
  )


# QA checks before building import tables --------------------------------

# Expected: only NA, variety, subspecies
species_clean %>%
  count(subtype, sort = TRUE)

# Expected: all values should exist in grp.lifeform.type
species_clean %>%
  count(lifeform, sort = TRUE)

# Expected: 0 rows
species_clean %>%
  filter(
    !is.na(subtype),
    !subtype %in% c("variety", "subspecies")
  )


# Build species table -----------------------------------------------------
# One row per unique taxon.
# GRP species_code is generated so varieties/subspecies get unique codes.

species_table <- species_clean %>%
  group_by(
    `group`,
    `order`,
    family,
    genus,
    species,
    subtype,
    subtype_name
  ) %>%
  summarise(
    species_code_base = first(na.omit(species_code_base)),
    lifeform = first(na.omit(lifeform)),
    .groups = "drop"
  ) %>%
  mutate(
    species_code = case_when(
      !is.na(subtype) & !is.na(subtype_name) ~ paste(
        species_code_base,
        str_sub(subtype, 1, 3),
        str_sub(subtype_name, 1, 3),
        sep = "_"
      ),
      TRUE ~ species_code_base
    )
  ) %>%
  select(
    species_code,
    `group`,
    `order`,
    family,
    genus,
    species,
    subtype,
    subtype_name,
    lifeform
  )

# Manual corrections for generated GRP species codes ----------------------
# These resolve legacy code collisions or known source-code problems.

species_code_overrides <- tribble(
  ~genus,       ~species,      ~subtype, ~subtype_name, ~species_code_override,
  "Paspalum",  "spp",         NA,       NA,            "G_Pasp_spp",
  "Verbascum", "chaixii",     NA,       NA,            "Ver_chai",
  "Acacia",    "reficiens",   NA,       NA,            "Aca_ref",
  "Prosopis",  "juliflora",   NA,       NA,            "Pro_jul",
  "Pinus",     "edulis",      NA,       NA,            "Pin_edu",
  "Silene",    "laciniata",   NA,       NA,            "Sil_laciniata"
)

species_table <- species_table %>%
  left_join(
    species_code_overrides,
    by = c("genus", "species", "subtype", "subtype_name")
  ) %>%
  mutate(
    species_code = coalesce(species_code_override, species_code)
  ) %>%
  select(-species_code_override)


# QA: species table must match SQL uniqueness constraint
# Expected: 0 rows

species_table %>%
  count(`group`, `order`, family, genus, species, subtype, subtype_name) %>%
  filter(n > 1)

# QA: generated species_code should be unique
# Expected: 0 rows

species_table %>%
  count(species_code) %>%
  filter(n > 1)


# Optional: preview generated codes for varieties/subspecies

species_table %>%
  filter(!is.na(subtype)) %>%
  select(species_code, genus, species, subtype, subtype_name) %>%
  print(n = 50)


# Write species table -----------------------------------------------------

dbWriteTable(
  conn,
  Id(schema = "grp", table = "species"),
  species_table,
  append = TRUE,
  row.names = FALSE
)


# Pull generated species IDs ---------------------------------------------

species_id_map <- dbGetQuery(conn, '
  SELECT
    speciesid,
    species_code,
    "group",
    "order",
    family,
    genus,
    species,
    subtype,
    subtype_name
  FROM grp.species;
')


# Build species_names table ----------------------------------------------
# Preserves original Excel species codes and links them to generated IDs.

species_names <- species_clean %>%
  distinct(
    species_code_raw,
    `group`,
    `order`,
    family,
    genus,
    species,
    subtype,
    subtype_name
  ) %>%
  left_join(
    species_id_map,
    by = c(
      "group",
      "order",
      "family",
      "genus",
      "species",
      "subtype",
      "subtype_name"
    )
  ) %>%
  transmute(
    speciesid,
    species_code = species_code_raw,
    name = str_squish(
      paste(
        coalesce(genus, ""),
        coalesce(species, ""),
        coalesce(subtype, ""),
        coalesce(subtype_name, "")
      )
    )
  )

# QA: no unmatched species names
# Expected: 0 rows

species_names %>%
  filter(is.na(speciesid))


# Write species_names table ----------------------------------------------

dbWriteTable(
  conn,
  Id(schema = "grp", table = "species_names"),
  species_names,
  append = TRUE,
  row.names = FALSE
)


# Build species_lifespan table -------------------------------------------

species_lifespan <- species_clean %>%
  filter(!is.na(lifespan)) %>%
  distinct(
    `group`,
    `order`,
    family,
    genus,
    species,
    subtype,
    subtype_name,
    lifespan
  ) %>%
  left_join(
    species_id_map,
    by = c(
      "group",
      "order",
      "family",
      "genus",
      "species",
      "subtype",
      "subtype_name"
    )
  ) %>%
  transmute(
    speciesid,
    type = lifespan
  ) %>%
  distinct()


# QA: no unmatched lifespan records
# Expected: 0 rows

species_lifespan %>%
  filter(is.na(speciesid))


# Write species_lifespan table -------------------------------------------

dbWriteTable(
  conn,
  Id(schema = "grp", table = "species_lifespan"),
  species_lifespan,
  append = TRUE,
  row.names = FALSE
)


# Final database checks ---------------------------------------------------

dbGetQuery(conn, "SELECT COUNT(*) AS species_count FROM grp.species;")
dbGetQuery(conn, "SELECT COUNT(*) AS species_names_count FROM grp.species_names;")
dbGetQuery(conn, "SELECT COUNT(*) AS species_lifespan_count FROM grp.species_lifespan;")

dbGetQuery(conn, "
  SELECT *
  FROM grp.full_species
  ORDER BY speciesid
  LIMIT 20;
")

# Build species transformation table -------------------------------------

species_crosswalk <- species_clean %>%
  distinct(
    species_code_raw,
    species_code_base,
    source_name,
    group,
    order,
    family,
    genus,
    species,
    subtype,
    subtype_name
  ) %>%
  left_join(
    species_id_map,
    by = c(
      "group",
      "order",
      "family",
      "genus",
      "species",
      "subtype",
      "subtype_name"
    )
  ) %>%
  select(
    species_code_raw,
    species_code_base,
    grp_speciesid = speciesid,
    grp_species_code = species_code,
    source_name,
    group,
    order,
    family,
    genus,
    species,
    subtype,
    subtype_name
  )