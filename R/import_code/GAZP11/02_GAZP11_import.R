### Prepare GAZP11 harmonized data for review before SQL build/commit
###
### This script intentionally stops at reviewable prepare-stage files. It does
### not connect to Supabase, allocate SQL identifiers, or write database rows.

library(dplyr)
library(readr)
library(readxl)
library(stringr)
library(tibble)

framework_version <- "20260918_framework"
framework_dir <- file.path("R", "import_framework", framework_version)
source(file.path(framework_dir, "prepare_functions.R"))

input_workbook <- file.path(
  "data", "harmonized", "GAZP", "GAZP11", "GAZP11_reprocessed.xlsx"
)
output_dir <- file.path("outputs", "import_review", "GAZP11", "prepare")

project_config <- list(
  database = "GAZP",
  projectid = 11L,
  date_received = as.Date("2018-04-12"),
  # Parent blocks are source-derived, year-specific identifiers. Their physical
  # size is not recoverable. Child plots retain their actual sampled area.
  block_size = NA_real_,
  block_units = "m2",
  child_area_type = "plot",
  route_other_treatment_to_notes = FALSE,
  # Import mechanics belong in code/provenance, not the reader-facing project note.
  project_note_append = NA_character_
)

harmonized <- read_harmonized_workbook(input_workbook)
validate_harmonized_identity(
  harmonized,
  expected_database = project_config$database,
  expected_projectid = project_config$projectid
)

prepared_treatments <- prepare_treatments(
  harmonized$treatments,
  route_other_treatment_to_notes = project_config$route_other_treatment_to_notes
)

treatment_detail_review <- prepare_treatment_detail_source(harmonized$treatments)
if (any(
  treatment_detail_review$details$treatment_category == "application method" &
    treatment_detail_review$details$treatment_type == "none"
)) {
  stop("A false 'none' application method survived standard treatment preparation.", call. = FALSE)
}

if (any(
  prepared_treatments$event_category == "application method" &
    prepared_treatments$event_type == "none"
)) {
  stop("A passive control was incorrectly prepared as a no-application event.", call. = FALSE)
}

event_key_issues <- prepared_treatments |>
  count(.data$source_treatment_event_key, name = "rows") |>
  filter(.data$rows != 1L)
if (nrow(event_key_issues) > 0L) {
  stop("Prepared treatment-event keys are not unique.", call. = FALSE)
}

# The shared helper assumes one restoration context per site. GAZP11 has seeded
# and passive herbicide-control strata at the same site, and the reprocessed
# source block uniquely identifies the treatment stratum. Preserve context at
# block level rather than flattening the passive controls into seeding areas.
prepare_GAZP11_spatial_areas <- function(vegresults, prepared_treatments) {
  treatment_context <- prepared_treatments |>
    select(
      .data$source_treatmentid, .data$siteid,
      .data$restoration_start_year, .data$restoration_type
    ) |>
    distinct()

  observations <- vegresults |>
    transmute(
      source_treatmentid = prepare_na_if_blank(.data$treatmentid),
      block = prepare_na_if_blank(.data$block),
      replicate = prepare_na_if_blank(.data$replicate),
      measurement_scale = suppressWarnings(as.numeric(.data$measurementscale)),
      measurement_units = prepare_na_if_blank(.data$measurementmetric)
    ) |>
    left_join(treatment_context, by = "source_treatmentid")

  if (anyNA(observations$source_treatmentid) || anyNA(observations$siteid) || anyNA(observations$block)) {
    stop("Every GAZP11 vegetation row must resolve to a treatment, site, and block.", call. = FALSE)
  }

  block_context <- observations |>
    distinct(
      .data$siteid, .data$block, .data$restoration_start_year,
      .data$restoration_type
    )
  if (any((block_context |> count(.data$siteid, .data$block))$n != 1L)) {
    stop("A GAZP11 block has conflicting restoration context.", call. = FALSE)
  }

  child_scales <- observations |>
    filter(!is.na(.data$replicate)) |>
    distinct(
      .data$siteid, .data$block, .data$replicate,
      .data$measurement_scale, .data$measurement_units
    )
  if (any((child_scales |> count(.data$siteid, .data$block, .data$replicate))$n != 1L)) {
    stop("A GAZP11 child area has more than one measurement scale or unit.", call. = FALSE)
  }

  blocks <- block_context |>
    transmute(
      area_key = make_block_area_key(.data$siteid, .data$block),
      parent_area_key = NA_character_,
      siteid = as.integer(.data$siteid),
      source_block = .data$block,
      source_replicate = NA_character_,
      type = "block",
      size = project_config$block_size,
      units = project_config$block_units,
      restoration_start_year = .data$restoration_start_year,
      restoration_type = .data$restoration_type,
      disturbance_end_year = NA_real_
    )

  children <- child_scales |>
    left_join(block_context, by = c("siteid", "block")) |>
    transmute(
      area_key = make_child_area_key(.data$siteid, .data$block, .data$replicate),
      parent_area_key = make_block_area_key(.data$siteid, .data$block),
      siteid = as.integer(.data$siteid),
      source_block = .data$block,
      source_replicate = .data$replicate,
      type = project_config$child_area_type,
      size = .data$measurement_scale,
      units = .data$measurement_units,
      restoration_start_year = .data$restoration_start_year,
      restoration_type = .data$restoration_type,
      disturbance_end_year = NA_real_
    )

  bind_rows(blocks, children) |>
    arrange(.data$siteid, .data$source_block, .data$type, .data$source_replicate)
}

prepared_areas <- prepare_GAZP11_spatial_areas(
  vegresults = harmonized$vegresults,
  prepared_treatments = prepared_treatments
)

prepared_area_treatments <- prepare_area_treatment_links(
  vegresults = harmonized$vegresults,
  prepared_treatments = prepared_treatments,
  areas = prepared_areas
) |>
  inner_join(
    prepared_areas |>
      filter(.data$type == "plot") |>
      select(.data$area_key),
    by = "area_key"
  )

if (any(startsWith(prepared_area_treatments$area_key, "block:")) ||
    !all(prepared_area_treatments$area_key %in%
         prepared_areas$area_key[prepared_areas$type == "plot"])) {
  stop("GAZP11 treatments must link only to child plots.", call. = FALSE)
}

prepared_vegresults <- prepare_vegresults(
  vegresults = harmonized$vegresults,
  timepoints = harmonized$timepoints,
  prepared_treatments = prepared_treatments,
  areas = prepared_areas
)

species_crosswalk <- read_csv(
  file.path(framework_dir, "sp_crosswalk.csv"),
  show_col_types = FALSE
)
species_inventory <- prepare_species_inventory(
  harmonized$vegresults,
  species_crosswalk
)

prepare_audit <- build_prepare_audit(
  source_vegresults = harmonized$vegresults,
  prepared_vegresults = prepared_vegresults,
  areas = prepared_areas,
  area_treatments = prepared_area_treatments,
  species_inventory = species_inventory
)

pretreatment_review <- harmonized$trtrates |>
  transmute(
    source_treatmentid = as.character(.data$treatmentid),
    source_species_code = as.character(.data$speciesid),
    seedpretreatment = str_to_lower(prepare_na_if_blank(.data$seedpretreatment))
  ) |>
  filter(!is.na(.data$seedpretreatment), !.data$seedpretreatment %in% c("none", "na", "n/a")) |>
  distinct()

if (!setequal(unique(pretreatment_review$seedpretreatment), "coated")) {
  stop("GAZP11 contains an unreviewed seed pretreatment value.", call. = FALSE)
}

seeding_events <- prepared_treatments |>
  filter(
    .data$event_category == "application method",
    .data$event_type == "drill"
  ) |>
  select(.data$source_treatmentid, .data$source_treatment_event_key)

seed_trtrate_event_review <- harmonized$trtrates |>
  transmute(
    source_treatmentid = as.character(.data$treatmentid),
    source_species_code = as.character(.data$speciesid),
    rate = suppressWarnings(as.numeric(.data$rate)),
    unit = as.character(.data$unit),
    viability = as.character(.data$viability),
    seedpretreatment = str_to_lower(prepare_na_if_blank_or_token(.data$seedpretreatment))
  ) |>
  left_join(seeding_events, by = "source_treatmentid") |>
  mutate(
    review_status = if_else(
      is.na(.data$source_treatment_event_key),
      "missing seeding event",
      "ready for build"
    )
  )

if (any(seed_trtrate_event_review$review_status != "ready for build")) {
  stop("A seed trtrate row did not resolve to exactly one seeding event.", call. = FALSE)
}

area_event_review <- prepared_area_treatments |>
  left_join(
    prepared_treatments |>
      select(
        .data$source_treatment_event_key,
        .data$event_category,
        .data$event_type,
        .data$year
      ),
    by = "source_treatment_event_key"
  ) |>
  arrange(.data$area_key, .data$source_treatment_event_key)

if (anyNA(area_event_review$event_category)) {
  stop("An area-treatment link did not resolve to a treatment event.", call. = FALSE)
}

treatment_event_summary <- prepared_treatments |>
  count(.data$event_category, .data$event_type, name = "treatment_events") |>
  arrange(.data$event_category, .data$event_type)

area_event_summary <- area_event_review |>
  left_join(
    prepared_areas |>
      select(.data$area_key, area_type = .data$type),
    by = "area_key"
  ) |>
  count(.data$area_type, .data$event_category, .data$event_type,
        name = "area_event_links") |>
  arrange(.data$area_type, .data$event_category, .data$event_type)

prepare_review_gate <- tibble::tribble(
  ~check, ~value, ~status,
  "source vegetation rows retained", nrow(prepared_vegresults), ifelse(nrow(prepared_vegresults) == nrow(harmonized$vegresults), "pass", "blocker"),
  "unique treatment events", n_distinct(prepared_treatments$source_treatment_event_key), ifelse(!anyDuplicated(prepared_treatments$source_treatment_event_key), "pass", "blocker"),
  "seeding events", sum(prepared_treatments$event_category == "application method" & prepared_treatments$event_type == "drill"), "information",
  "grazing events", sum(prepared_treatments$event_category == "grazer manipulation" & prepared_treatments$event_type == "added"), "information",
  "passive reference events", sum(prepared_treatments$event_category == "passive reference"), "information",
  "child sampling areas", sum(prepared_areas$type != "block"), "information",
  "area-event links", nrow(prepared_area_treatments), ifelse(!anyDuplicated(paste(prepared_area_treatments$area_key, prepared_area_treatments$source_treatment_event_key)), "pass", "blocker"),
  "parent block treatment links", sum(startsWith(prepared_area_treatments$area_key, "block:")), ifelse(any(startsWith(prepared_area_treatments$area_key, "block:")), "blocker", "pass"),
  "seed trtrate rows routed to seeding events", sum(seed_trtrate_event_review$review_status == "ready for build"), ifelse(all(seed_trtrate_event_review$review_status == "ready for build"), "pass", "blocker"),
  "false none application details retained", sum(treatment_detail_review$details$treatment_type == "none"), ifelse(any(treatment_detail_review$details$treatment_type == "none"), "blocker", "pass"),
  "absent application details omitted", nrow(treatment_detail_review$omitted_absent), "information",
  "unready vegetation rows", sum(prepared_vegresults$prepare_status != "ready_for_build"), ifelse(all(prepared_vegresults$prepare_status == "ready_for_build"), "pass", "blocker"),
  "species requiring review", sum(species_inventory$review_status != "matched"), ifelse(all(species_inventory$review_status == "matched"), "pass", "review")
)

treatment_event_decision_review <- tibble::tribble(
  ~decision_id, ~scope, ~evidence, ~prepared_state, ~decision_required_before_build, ~status,
  "GAZP11-E01", "Pre-seeding glyphosate on seeded plots", "Contributor email reports 16 oz/acre glyphosate in April 2014; publication describes glyphosate on active seeded plots before seeding.", "Not represented as a prepared event; retained in project notes.", "No herbicide event is inferred from the incomplete retained dataset under the 2026-09-21 preprocessing decision.", "resolved",
  "GAZP11-E02", "Passive IDs 11_25 and 11_50", "The retained row-level source does not identify either group's herbicide status.", "Prepared as two neutral passive-reference events; no false seed application details.", "Do not assign either passive ID to herbicide without new source evidence.", "resolved",
  "GAZP11-E03", "Herbicide-only imazapic events", "Contributor email reports Plateau in two consecutive years; publication describes imazapic in spring 2015 and 2016.", "Not represented as a prepared event; retained in project notes.", "Do not create imazapic events without an identified treated area.", "resolved"
)

prepare_review_gate <- bind_rows(
  prepare_review_gate,
  tibble(
    check = "treatment-event decisions requiring review",
    value = sum(treatment_event_decision_review$status == "review"),
    status = ifelse(any(treatment_event_decision_review$status == "review"), "review", "pass")
  )
)

project_manifest <- tibble(
  database = project_config$database,
  projectid = project_config$projectid,
  type = str_to_lower(harmonized$study$studytype[[1]]),
  community = str_to_lower(harmonized$study$community[[1]]),
  reference = if_else(
    is.na(harmonized$study$refdata[[1]]),
    NA_character_,
    str_to_lower(as.character(harmonized$study$refdata[[1]]))
  ),
  input_workbook = input_workbook,
  date_received = project_config$date_received,
  source_project_notes = harmonized$study$notes[[1]],
  project_note_append = project_config$project_note_append,
  prepare_completed_at = Sys.time(),
  sql_write_performed = FALSE
)

prepared <- list(
  areas = prepared_areas,
  area_treatments = prepared_area_treatments,
  treatments = prepared_treatments,
  vegresults = prepared_vegresults,
  species = species_inventory,
  audit = prepare_audit
)

write_prepare_review(prepared, output_dir)
write_csv(pretreatment_review, file.path(output_dir, "seed_pretreatment_review.csv"), na = "")
write_csv(
  seed_trtrate_event_review,
  file.path(output_dir, "seed_trtrate_event_review.csv"),
  na = ""
)
write_csv(
  area_event_review,
  file.path(output_dir, "area_treatment_event_review.csv"),
  na = ""
)
write_csv(
  treatment_event_summary,
  file.path(output_dir, "treatment_event_summary.csv"),
  na = ""
)
write_csv(
  area_event_summary,
  file.path(output_dir, "area_event_summary.csv"),
  na = ""
)
write_csv(
  prepare_review_gate,
  file.path(output_dir, "prepare_review_gate.csv"),
  na = ""
)
write_csv(
  treatment_event_decision_review,
  file.path(output_dir, "treatment_event_decision_review.csv"),
  na = ""
)
write_csv(
  treatment_detail_review$details,
  file.path(output_dir, "treatment_detail_review.csv"),
  na = ""
)
write_csv(
  treatment_detail_review$omitted_absent,
  file.path(output_dir, "omitted_absent_treatment_detail.csv"),
  na = ""
)
write_csv(project_manifest, file.path(output_dir, "project_manifest.csv"), na = "")

blockers <- prepare_audit$summary |>
  filter(.data$status == "blocker")
gate_blockers <- prepare_review_gate |>
  filter(.data$status == "blocker")

print(prepare_audit$summary)
message("Prepared review files written to: ", output_dir)
message("No SQL connection was opened and no SQL write was performed.")

if (nrow(blockers) > 0L || nrow(gate_blockers) > 0L) {
  stop("GAZP11 prepare stage produced blocker audit results.", call. = FALSE)
}
