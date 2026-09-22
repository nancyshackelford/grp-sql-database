### Build reviewable SQL-shaped GAZP11 staging tables. No database writes.

library(dplyr)
library(readr)
library(readxl)
library(stringr)
library(tidyr)
library(DBI)
library(RPostgres)

framework_dir <- file.path("R", "import_framework", "20260915_framework")
source(file.path(framework_dir, "build_functions.R"))
prepare_dir <- file.path("outputs", "import_review", "GAZP11", "prepare")
build_dir <- file.path("outputs", "import_review", "GAZP11", "build")
template_dir <- file.path("outputs", "import_review", "GAZP10", "build")
dir.create(build_dir, recursive = TRUE, showWarnings = FALSE)
validate_prepare_approval(prepare_dir)

gate <- read_csv(file.path(prepare_dir, "prepare_review_gate.csv"), show_col_types = FALSE)
decisions <- read_csv(file.path(prepare_dir, "treatment_event_decision_review.csv"), show_col_types = FALSE)
if (any(gate$status %in% c("blocker", "review")) || any(decisions$status != "resolved")) {
  stop("GAZP11 prepare review is not resolved.", call. = FALSE)
}

areas <- read_csv(file.path(prepare_dir, "prepared_area.csv"), show_col_types = FALSE)
links <- read_csv(file.path(prepare_dir, "prepared_area_treatment.csv"), show_col_types = FALSE)
events <- read_csv(file.path(prepare_dir, "prepared_treatment.csv"), show_col_types = FALSE)
observations <- read_csv(file.path(prepare_dir, "prepared_vegresults.csv"), show_col_types = FALSE)
species_review <- read_csv(file.path(prepare_dir, "species_review.csv"), show_col_types = FALSE)
rate_review <- read_csv(file.path(prepare_dir, "seed_trtrate_event_review.csv"), show_col_types = FALSE)
detail_review <- read_csv(file.path(prepare_dir, "treatment_detail_review.csv"), show_col_types = FALSE)
manifest <- read_csv(file.path(prepare_dir, "project_manifest.csv"), show_col_types = FALSE)

workbook <- file.path("data", "harmonized", "GAZP", "GAZP11", "GAZP11_reprocessed.xlsx")
study <- read_excel(workbook, "study")
site <- read_excel(workbook, "site")
refs <- read_excel(workbook, "refs")
trtrates <- read_excel(workbook, "trtrates")

password <- read_secret_bom_safe(
  "C:/Users/nshack/OneDrive - University of Victoria/Documents/R/GRP/pword.csv"
)
con <- dbConnect(Postgres(), host = "aws-1-ca-central-1.pooler.supabase.com",
                 port = 6543, dbname = "postgres",
                 user = "postgres.rudybfqutvodkakgctpo", password = password,
                 sslmode = "require")
on.exit(dbDisconnect(con), add = TRUE)
source(file.path(framework_dir, "import_registry.r"))
id_state <- read_sql_id_state(con, "GAZP", 11L)
maxima <- dbGetQuery(con, paste(
  "SELECT",
  "(SELECT COALESCE(MAX(locationid),0) FROM grp.location) max_locationid,",
  "(SELECT COALESCE(MAX(paperid),0) FROM grp.paper) max_paperid,",
  "(SELECT COALESCE(MAX(author_contributorid),0) FROM grp.author_contributor) max_authorid,",
  "(SELECT COALESCE(MAX(seed_mixid),0) FROM grp.seed_mix) max_seedmixid,",
  "(SELECT COALESCE(MAX(seedingid),0) FROM grp.seeding) max_seedingid"
))
species_names <- dbGetQuery(con, "SELECT speciesid, species_code, name FROM grp.species_names")

area_ids <- build_area_id_crosswalk(areas, as.integer(id_state$max_areaid[[1]]) + 1L)
event_ids <- events |>
  arrange(source_treatment_event_key) |>
  mutate(treatmentid = seq.int(as.integer(id_state$max_treatmentid[[1]]) + 1L,
                                length.out = n())) |>
  select(source_treatment_event_key, treatmentid)
species_ids <- build_species_crosswalk(species_review)

resolved_links <- links |>
  left_join(area_ids, by = "area_key") |>
  left_join(event_ids, by = "source_treatment_event_key")
if (anyNA(resolved_links$areaid) || anyNA(resolved_links$treatmentid)) {
  stop("An area-event link failed SQL ID resolution.", call. = FALSE)
}

stg <- list()
stg$project <- tibble(database = "GAZP", projectid = 11L,
                      type = manifest$type[[1]], community = manifest$community[[1]],
                      reference = manifest$reference[[1]],
                      notes = manifest$source_project_notes[[1]],
                      date_received = as.Date(manifest$date_received[[1]]))
stg$project_data_accessibility <- tibble(
  database = "GAZP", projectid = 11L, availability = as.character(study$availability[[1]]),
  data_citation = NA_character_, data_doi = NA_character_, data_url = NA_character_,
  creativecommons_license = NA_character_, use_conditions = NA_character_,
  date_received = as.Date(manifest$date_received[[1]]), data_accessibility_notes = NA_character_
)
stg$location <- tibble(locationid = as.integer(maxima$max_locationid[[1]]) + 1L,
                       continent = "North America", country = "United States of America",
                       state = "Nevada")
stg$project_location <- transmute(stg$location, database = "GAZP", projectid = 11L, locationid)
stg$site <- site |> transmute(
  siteid = as.integer(siteid), name = as.character(sitename), latitude = as.numeric(latitude),
  longitude = as.numeric(longitude), aridity = as.numeric(aridity),
  annual_temp = as.numeric(temp), annual_precip = as.integer(precip)
)
stg$project_site <- tibble(database = "GAZP", projectid = 11L, siteid = as.integer(site$siteid))
stg$paper <- refs |> transmute(
  paperid = as.integer(maxima$max_paperid[[1]] + row_number()),
  publication_year = as.integer(pubyear), publication_title = as.character(pubtitle),
  publication_journal = as.character(pubjournal), publication_doi = as.character(pubDOI),
  publication_url = as.character(pubURL)
)
stg$project_paper <- transmute(stg$paper, database = "GAZP", projectid = 11L,
                               paperid, notes = NA_character_)
contributor_parts <- str_split_fixed(as.character(study$contributor[[1]]), "\\s+", 2)
stg$author_contributor <- tibble(
  author_contributorid = as.integer(maxima$max_authorid[[1]]) + 1L,
  given_name = contributor_parts[1], surname = contributor_parts[2],
  email = as.character(study$email[[1]])
)
stg$paper_author <- tibble(paperid = stg$paper$paperid,
                           author_contributorid = stg$author_contributor$author_contributorid[[1]],
                           is_corresponding_author = FALSE)
stg$project_contributor <- tibble(database = "GAZP", projectid = 11L,
                                  author_contributorid = stg$author_contributor$author_contributorid)
stg$project_vegmetric <- tibble(database = "GAZP", projectid = 11L, type = "abundance")
classification <- dbGetQuery(con, paste(
  "SELECT classificationid FROM grp.classification WHERE",
  "lower(subsubclass) = lower('Cool Semi-Desert Scrub & Grassland')"
))
if (nrow(classification) != 1L) stop("GAZP11 site classification did not resolve uniquely.")
stg$site_classification <- tibble(siteid = as.integer(site$siteid),
                                  classificationid = classification$classificationid[[1]])
invasive <- species_names |>
  filter(str_to_lower(name) == str_to_lower(as.character(site$invasivespe[[1]])))
if (nrow(invasive) != 1L) stop("GAZP11 site invasive species did not resolve uniquely.")
stg$site_invasive <- tibble(siteid = as.integer(site$siteid),
                            speciesid = as.integer(invasive$speciesid[[1]]))
stg$site_ref_ecosystem <- tibble(siteid = as.integer(site$siteid),
                                 description = as.character(site$refecosystem))
stg$site_soil <- tibble(siteid = as.integer(site$siteid), sand = as.numeric(site$sand),
                        silt = as.numeric(site$silt), clay = as.numeric(site$clay),
                        description = as.character(site$soildescription), depth = NA_character_)
stg$site_disturbance <- tibble(siteid = as.integer(site$siteid), type = "invasion")
stg$area <- build_area_staging(areas, area_ids)
stg$treatment <- events |>
  left_join(event_ids, by = "source_treatment_event_key") |>
  transmute(treatmentid = as.integer(treatmentid), year, month, day,
            weeks_since_restoration = as.integer(weeks_since_restoration),
            other_treatment, shelter = NA_character_, grading = NA_character_,
            maintenance_fire = NA, notes)
stg$area_treatment <- resolved_links |>
  transmute(database = "GAZP", projectid = 11L, areaid = as.integer(areaid),
            treatmentid = as.integer(treatmentid)) |> distinct()
stg$veg_result <- build_veg_result_staging(observations, area_ids, species_ids)

stg$treatment_application <- detail_review |>
  filter(treatment_category == "application method", treatment_type == "drill") |>
  distinct(source_treatment_event_key, type = treatment_type) |>
  left_join(event_ids, by = "source_treatment_event_key") |>
  transmute(treatmentid = as.integer(treatmentid), type)
stg$treatment_grazer <- detail_review |>
  filter(treatment_category == "grazer manipulation") |>
  distinct(source_treatment_event_key, type = treatment_type) |>
  left_join(event_ids, by = "source_treatment_event_key") |>
  transmute(treatmentid = as.integer(treatmentid), type, notes = NA_character_)

seed_events <- events |>
  filter(event_category == "application method", event_type == "drill") |>
  select(source_treatmentid, source_treatment_event_key) |>
  left_join(event_ids, by = "source_treatment_event_key")
seed_rates <- rate_review |>
  filter(review_status == "ready for build") |>
  left_join(select(seed_events, source_treatment_event_key, treatmentid),
            by = "source_treatment_event_key") |>
  left_join(select(species_names, speciesid, species_code),
            by = c("source_species_code" = "species_code"))
if (anyNA(seed_rates$treatmentid) || anyNA(seed_rates$speciesid)) {
  stop("A seed-rate row did not resolve to a seeding event or SQL species.", call. = FALSE)
}
stg$seed_mix <- seed_events |>
  left_join(trtrates |>
              group_by(treatmentid) |>
              summarise(mix_name = first(as.character(mix_trt)),
                        treated_richness = first(as.character(treated_richness)), .groups = "drop"),
            by = c("source_treatmentid" = "treatmentid")) |>
  arrange(treatmentid) |>
  mutate(seed_mixid = seq.int(as.integer(maxima$max_seedmixid[[1]]) + 1L,
                                length.out = n())) |>
  transmute(seed_mixid, treatmentid = as.integer(treatmentid), mix_name,
            mix_composition_status = "known", treated_richness, notes = NA_character_)
seed_rates <- seed_rates |>
  left_join(select(stg$seed_mix, treatmentid, seed_mixid), by = "treatmentid") |>
  arrange(treatmentid, source_species_code) |>
  mutate(seedingid = seq.int(as.integer(maxima$max_seedingid[[1]]) + 1L,
                             length.out = n()))
stg$seeding <- seed_rates |>
  transmute(seedingid = as.integer(seedingid), treatmentid = as.integer(treatmentid),
            mix = "known", speciesid = as.integer(speciesid), cultivarid = NA_integer_,
            type = "seeding", rate = as.numeric(rate), unit, viability,
            origin = "native", source = NA_character_, seed_distance = NA_character_,
            seed_mixid = as.integer(seed_mixid), notes = NA_character_)
stg$seeding_pretreatment <- seed_rates |>
  filter(!is.na(seedpretreatment), seedpretreatment != "") |>
  transmute(seedingid = as.integer(seedingid), type = as.character(seedpretreatment))

# Use GAZP10's complete build-table inventory as a schema-shaped output contract.
template_files <- list.files(template_dir, pattern = "^stg_.*\\.csv$", full.names = TRUE)
table_names <- sub("\\.csv$", "", sub("^stg_", "", basename(template_files)))
for (i in seq_along(table_names)) {
  name <- table_names[[i]]
  columns <- names(read_csv(template_files[[i]], n_max = 0, show_col_types = FALSE))
  if (is.null(stg[[name]])) stg[[name]] <- tibble()
  extra <- setdiff(names(stg[[name]]), columns)
  if (length(extra)) stop("Unexpected columns in ", name, ": ", paste(extra, collapse = ", "))
  for (column in setdiff(columns, names(stg[[name]]))) stg[[name]][[column]] <- NA
  stg[[name]] <- stg[[name]][, columns, drop = FALSE]
}
stg <- stg[table_names]

message("Build counts: observations=", nrow(observations), " staged_veg=", nrow(stg$veg_result),
        " areas=", nrow(areas), " staged_area=", nrow(stg$area),
        " events=", nrow(events), " staged_treatment=", nrow(stg$treatment))
stopifnot(nrow(stg$veg_result) == nrow(observations),
          nrow(stg$area) == nrow(areas),
          nrow(stg$treatment) == nrow(events),
          nrow(stg$area_treatment) == nrow(distinct(resolved_links, areaid, treatmentid)),
          nrow(stg$seeding) == nrow(rate_review),
          !anyNA(stg$seeding$seed_mixid),
          all(na.omit(stg$area$parentid) %in% stg$area$areaid),
          all(stg$area_treatment$areaid %in% stg$area$areaid),
          all(stg$area_treatment$areaid %in% stg$area$areaid[stg$area$type == "plot"]),
          all(stg$area_treatment$treatmentid %in% stg$treatment$treatmentid))

constraint_issues <- purrr::imap_dfr(stg, function(tbl, name) {
  validate_staged_table(tbl, name, import_registry$constraints)
})
lookup_issues <- purrr::imap_dfr(stg, function(tbl, name) {
  if (nrow(tbl) == 0L) return(NULL)
  validate_lookup_constraints(tbl, name, import_registry$constraints, con)
})
referential_issues <- validate_referential_integrity(stg, import_registry$constraints, con)
issues <- bind_rows(constraint_issues, lookup_issues, referential_issues)

crosswalk <- resolved_links |>
  left_join(select(areas, area_key, type, source_block, source_replicate), by = "area_key") |>
  transmute(database = "GAZP", projectid = 11L, object_type = type,
            source_treatmentid, source_treatment_event_key,
            block = source_block, replicate = source_replicate,
            areaid = as.integer(areaid), treatmentid = as.integer(treatmentid),
            source_trt_tsr = 0L) |>
  arrange(object_type, block, replicate, source_treatment_event_key)
species_crosswalk <- species_review |>
  left_join(species_names,
            by = c("sql_speciesid" = "speciesid",
                   "source_species_code" = "species_code")) |>
  transmute(database = "GAZP", projectid = 11L, project_code = "GAZP11",
            crosswalk_row_type = "default", rule_source_table = "all_relevant_tables",
            source_table = "vegresults", source_column = "speciesid",
            source_value_type = "species_code", source_value = source_species_code,
            source_occurrences = source_rows, speciesid = as.integer(sql_speciesid),
            accepted_species_code = source_species_code, accepted_species_name = name,
            mapping_status = "accepted_code_mapping", reverse_mapping_rule = "speciesid",
            match_rate = NA_real_, match_unit = NA_character_, contextual_rule_validated = TRUE,
            global_source_code_count = NA_integer_, global_source_codes = NA_character_,
            review_required = FALSE, reviewed = FALSE,
            decision_note = "Resolved through the global species-code crosswalk.")
if (nrow(species_crosswalk) != nrow(species_review) ||
    anyNA(species_crosswalk$accepted_species_name) ||
    anyDuplicated(species_crosswalk$source_value)) {
  stop("Species crosswalk must contain one exact-code row per harmonized species.")
}

summary <- tibble(
  check = c("project_rows", "area_rows", "treatment_rows", "area_treatment_rows",
            "veg_result_rows", "veg_rows_lost", "seeding_rows", "grazer_rows",
            "pretreatment_rows", "existing_project_rows"),
  value = c(nrow(stg$project), nrow(stg$area), nrow(stg$treatment),
            nrow(stg$area_treatment), nrow(stg$veg_result),
            nrow(observations) - nrow(stg$veg_result), nrow(stg$seeding),
            nrow(stg$treatment_grazer), nrow(stg$seeding_pretreatment),
            id_state$existing_project[[1]]),
  status = "pass"
)
inventory <- tibble(table = names(stg), rows = vapply(stg, nrow, integer(1)), status = "built")
purrr::iwalk(stg, ~write_csv(.x, file.path(build_dir, paste0("stg_", .y, ".csv")), na = ""))
write_csv(summary, file.path(build_dir, "build_summary.csv"), na = "")
write_csv(inventory, file.path(build_dir, "staging_table_inventory.csv"), na = "")
write_csv(issues, file.path(build_dir, "build_validation_issues.csv"), na = "")
write_csv(crosswalk, file.path(build_dir, "GAZP11_harmonized-SQL_crosswalk.csv"), na = "NA")
write_csv(species_crosswalk, file.path(build_dir, "GAZP11_species_crosswalk.csv"), na = "")
crosswalk_dir <- file.path("crosswalk_tables", "GAZP", "GAZP11")
dir.create(crosswalk_dir, recursive = TRUE, showWarnings = FALSE)
write_csv(crosswalk, file.path(crosswalk_dir, "GAZP11_harmonized-SQL_crosswalk.csv"), na = "NA")
write_csv(species_crosswalk, file.path(crosswalk_dir, "GAZP11_species_crosswalk.csv"), na = "")

print(summary)
if (nrow(issues)) print(issues, n = Inf)
if (any(issues$issue_severity == "blocker")) stop("Build validation produced blockers.", call. = FALSE)
message("Build review written to: ", build_dir)
message("No SQL write was performed.")
