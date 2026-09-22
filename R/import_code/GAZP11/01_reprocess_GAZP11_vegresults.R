### Reprocess GAZP11 harmonized data before the GAZP10-style SQL workflow
###
### Corrections: raw counts, survey units, source sampling identifiers, and
### distinct Fall/Spring/Ungrazed grazing treatments. Passive-control SQL
### representation remains an import-stage decision.

library(dplyr)
library(readxl)
library(stringr)
library(openxlsx)

source_dir <- file.path("data", "source", "GAZP", "GAZP11")
harmonized_dir <- file.path("data", "harmonized", "GAZP", "GAZP11")
review_dir <- file.path("outputs", "preprocess_review", "GAZP11")
input_workbook <- file.path(harmonized_dir, "GAZP11.xlsx")
output_workbook <- file.path(harmonized_dir, "GAZP11_reprocessed.xlsx")
raw_workbook <- file.path(source_dir, "NV_seedlings_edit.xlsx")

required_files <- c(input_workbook, raw_workbook)
missing_files <- required_files[!file.exists(required_files)]
if (length(missing_files) > 0L) {
  stop("Missing required GAZP11 files: ", paste(missing_files, collapse = ", "), call. = FALSE)
}
dir.create(review_dir, recursive = TRUE, showWarnings = FALSE)

raw <- read_excel(raw_workbook, sheet = "NV_seedlings_edit") |>
  mutate(source_row = dplyr::row_number() + 1L)
current_study <- read_excel(input_workbook, sheet = "study")
current_treatments <- read_excel(input_workbook, sheet = "treatments")
current_timepoints <- read_excel(input_workbook, sheet = "timepoints")
current_trtrates <- read_excel(input_workbook, sheet = "trtrates")
current_vegresults <- read_excel(input_workbook, sheet = "vegresults")

# Literal source tokens such as "NA" mean missing, not the text value NA.
current_treatments <- current_treatments |>
  mutate(across(where(is.character), ~ if_else(str_to_upper(str_squish(.x)) == "NA", NA_character_, .x)))
if (!"notes" %in% names(current_treatments)) {
  current_treatments$notes <- NA_character_
}
current_trtrates <- current_trtrates |>
  mutate(across(where(is.character), ~ if_else(str_to_upper(str_squish(.x)) == "NA", NA_character_, .x)))

species_map <- c(ELEL = "Ely_ely", ELTR = "Ely_tra", POFE = "Poa_fen",
                 POSE = "Pse_rup", VUMI = "Vul_mic", VUMY = "Vul_mic",
                 na = "L_Pgrass")
mono_order <- c(ELEL = 0L, ELTR = 1L, POFE = 2L, POSE = 3L, VUMI = 4L, VUMY = 4L)
seed_base_map <- c(ELEL = 103, ELTR = 121, POFE = 87, POSE = 112,
                   VUMI = 49, VUMY = 49, na = 472)

### Source-supported active observations -----------------------------------

active_crosswalk <- raw |>
  mutate(
    year = if_else(.data$Time == 1, 2015L, 2016L),
    tsr = if_else(.data$Time == 1, 26L, 78L),
    source_id_number = as.integer(str_extract(.data$ID, "[0-9]+$")),
    source_block_number = recode(.data$Block, one = 1L, two = 2L, three = 3L),
    speciesid = unname(species_map[.data$Species]),
    base_seeding_number = case_when(
      .data$Spatial_arrangement == "mix" ~
        1L + if_else(.data$Seed_Rate == "low", 2L, 0L) +
        if_else(.data$Coating == "UC", 1L, 0L),
      .data$Spatial_arrangement == "mono" ~
        5L + 4L * unname(mono_order[.data$Species]) +
        if_else(.data$Seed_Rate == "low", 2L, 0L) +
        if_else(.data$Coating == "UC", 1L, 0L),
      TRUE ~ NA_integer_
    ),
    treatment_number = case_when(
      .data$Her_Grazed == "Fall" ~ .data$base_seeding_number,
      .data$Her_Grazed == "Spring" ~ 50L + .data$base_seeding_number,
      .data$Her_Grazed == "Ungrazed" ~ 25L + .data$base_seeding_number,
      TRUE ~ NA_integer_
    ),
    treatmentid = paste0("11_", .data$treatment_number),
    # Add a year offset so coincident source labels cannot imply an unsupported
    # cross-year area match. The source components remain reversible.
    block = 10000L * (.data$year - 2015L) +
      100L * .data$source_id_number + as.integer(.data$Rep),
    replicate = 10L * as.integer(.data$Distance_Along_Transect_m) +
      .data$source_block_number,
    response = dplyr::coalesce(as.numeric(.data$Seeded_Seedlings), 0),
    measurementscale = if_else(.data$year == 2015L, 0.125, 0.25)
  )

if (anyNA(active_crosswalk$treatment_number) || anyNA(active_crosswalk$speciesid) ||
    anyNA(active_crosswalk$block) || anyNA(active_crosswalk$replicate)) {
  stop("A raw active row did not resolve to the preprocessing crosswalk.", call. = FALSE)
}

active_vegresults <- active_crosswalk |>
  transmute(
    id = "GAZP_11", DB = "GAZP", treatmentid = .data$treatmentid,
    year = .data$year, tsr = .data$tsr, block = .data$block,
    replicate = .data$replicate, speciesid = .data$speciesid,
    speciesorigin = "native", response = .data$response,
    responselevel = "species", responsemetric = "abundance",
    measurementscale = .data$measurementscale, measurementmetric = "m2"
  )

# These 196 passive rows have no retained detailed source. Keep their current
# identifiers and apply only the reviewed 2016 inverse conversion.
passive_vegresults <- current_vegresults |>
  filter(.data$treatmentid %in% c("11_25", "11_50")) |>
  mutate(
    response = as.numeric(.data$response) / 16,
    responsemetric = "abundance",
    measurementscale = 0.25,
    measurementmetric = "m2",
    block = 20000L + as.integer(str_extract(.data$treatmentid, "[0-9]+$"))
  )

reprocessed_vegresults <- bind_rows(active_vegresults, passive_vegresults) |>
  arrange(.data$year, as.integer(str_extract(.data$treatmentid, "[0-9]+$")),
          .data$block, .data$replicate, .data$speciesid)

if (nrow(active_vegresults) != 1024L || nrow(passive_vegresults) != 196L ||
    nrow(reprocessed_vegresults) != 1220L) {
  stop("Unexpected active/passive row accounting after preprocessing.", call. = FALSE)
}
if (any(abs(reprocessed_vegresults$response - round(reprocessed_vegresults$response)) > 1e-9)) {
  stop("Preprocessed responses are not whole seedling counts.", call. = FALSE)
}
duplicate_keys <- reprocessed_vegresults |>
  count(.data$DB, .data$treatmentid, .data$year, .data$tsr, .data$block,
        .data$replicate, .data$speciesid, name = "rows") |>
  filter(.data$rows > 1L)
if (nrow(duplicate_keys) > 0L) {
  print(duplicate_keys)
  stop("Preprocessing produced duplicate vegetation-result keys.", call. = FALSE)
}

### Treatment structure ----------------------------------------------------

base_treatment_rows <- current_treatments |>
  filter(.data$treatmentid %in% c(paste0("11_", 1:24), paste0("11_", 26:49)))
spring_treatment_rows <- current_treatments |>
  filter(.data$treatmentid %in% paste0("11_", 1:24)) |>
  mutate(treatmentid = paste0("11_", 50L + as.integer(str_extract(.data$treatmentid, "[0-9]+$"))))

make_grazer_rows <- function(treatment_ids, treatment_year, treatment_note) {
  output <- current_treatments[rep(1L, length(treatment_ids)), , drop = FALSE]
  output$DB <- "GAZP"
  output$treatmentid <- treatment_ids
  output$siteid <- 166
  output$restorationtype <- "seeding"
  output$tsr_start_year <- 2014
  output$trt_year <- treatment_year
  output$trt_tsr <- NA_real_
  output$disturbanceendyear <- NA_character_
  output$treatmentmonth <- NA_real_
  output$treatmentday <- NA_character_
  output$othertreatments <- NA_character_
  output$notes <- treatment_note
  output$treatment_category <- "grazer manipulation"
  output$treatment_type <- "added"
  output$treatment_amount <- "applied"
  output$treatment_units <- "treatment presence"
  output
}

grazer_rows <- bind_rows(
  make_grazer_rows(
    paste0("11_", 1:24), 2015,
    "Cattle grazing occurred in October-November 2015; exact month varies or is not retained."
  ),
  make_grazer_rows(
    paste0("11_", 51:74), 2016,
    "Cattle grazing occurred before May 2016 sampling; exact date is not retained."
  )
)
passive_treatment_rows <- current_treatments |>
  filter(.data$treatmentid %in% c("11_25", "11_50"))

reprocessed_treatments <- bind_rows(base_treatment_rows, spring_treatment_rows,
                                    passive_treatment_rows, grazer_rows) |>
  arrange(as.integer(str_extract(.data$treatmentid, "[0-9]+$")),
          .data$treatment_category)

spring_trtrates <- current_trtrates |>
  filter(.data$treatmentid %in% paste0("11_", 1:24)) |>
  mutate(treatmentid = paste0("11_", 50L + as.integer(str_extract(.data$treatmentid, "[0-9]+$"))))
reprocessed_trtrates <- bind_rows(current_trtrates, spring_trtrates) |>
  arrange(as.integer(str_extract(.data$treatmentid, "[0-9]+$")), .data$speciesid)

spring_timepoints <- current_timepoints |>
  filter(.data$treatmentid %in% paste0("11_", 1:24), as.integer(.data$year) == 2016L) |>
  mutate(treatmentid = paste0("11_", 50L + as.integer(str_extract(.data$treatmentid, "[0-9]+$"))))
reprocessed_timepoints <- bind_rows(current_timepoints, spring_timepoints) |>
  arrange(as.integer(str_extract(.data$treatmentid, "[0-9]+$")), .data$year)

expected_active_ids <- c(paste0("11_", 1:24), paste0("11_", 26:49), paste0("11_", 51:74))
if (!setequal(unique(active_vegresults$treatmentid), expected_active_ids)) {
  stop("Expected 72 grazing-by-seeding treatments were not produced.", call. = FALSE)
}

### Study metadata ---------------------------------------------------------

project_note <- paste(
  "Seedling results are raw counts from 0.125 m2 quadrats in 2015 and 0.25 m2 quadrats in 2016.",
  "The retained source distinguishes Fall, Spring, and Ungrazed groups.",
  "Sampling areas could not be reliably matched between survey years and are represented separately.",
  "Planned irrigation did not occur.",
  "The paper and contributor correspondence report herbicide treatments, but the retained final data do not identify the herbicide-treated sampling areas; whether the information was lost during submission or processing is unknown.",
  "The treatment identities of the two unseeded passive groups (11_25 and 11_50) cannot be recovered from the retained source records."
)
reprocessed_study <- current_study
reprocessed_study$vegmetric[[1]] <- "abundance"
reprocessed_study$surveyunit[[1]] <- "0.125|0.25"
reprocessed_study$notes[[1]] <- project_note

### Review outputs ---------------------------------------------------------

active_row_crosswalk <- active_crosswalk |>
  transmute(
    source_sheet = "NV_seedlings_edit", source_row = .data$source_row,
    source_id = .data$ID, source_rep = .data$Rep, source_block = .data$Block,
    source_transect_distance_m = .data$Distance_Along_Transect_m,
    survey_year = .data$year, grazing_timing = .data$Her_Grazed,
    planned_irrigation = .data$Water, spatial_arrangement = .data$Spatial_arrangement,
    seed_rate = .data$Seed_Rate, seed_coating = .data$Coating,
    source_species = .data$Species, speciesid = .data$speciesid,
    proposed_treatmentid = .data$treatmentid, proposed_block = .data$block,
    proposed_replicate = .data$replicate, proposed_response = .data$response,
    proposed_measurementscale = .data$measurementscale
  )

preprocessing_summary <- tibble::tribble(
  ~item, ~current_harmonized_state, ~preprocessed_state, ~affected_rows, ~basis,
  "response", "density-like values standardized to 1 m2", "raw seedling counts", 1220L, "Raw-value reconciliation; passive rows use the reviewed 2016 inverse factor.",
  "responsemetric", "density", "abundance", 1220L, "Raw observations are counts; area remains in measurementscale.",
  "passive 2016 measurement scale", "11_50 retained 0.125 m2", "all passive 2016 rows use 0.25 m2", 60L, "Contributor documentation states that 2016 sampling used 50x50 cm quadrats.",
  "passive area identifiers", "11_25 and 11_50 shared block/replicate labels", "treatment-specific passive blocks", 196L, "Prevents distinct passive source groups from collapsing into the same sampling areas without interpreting their treatment meaning.",
  "study.surveyunit", "1|0.25", "0.125|0.25", 1L, "25x50 cm in 2015 and 50x50 cm in 2016.",
  "active block/replicate", "synthetic block=1 and treatment-local sequence", "year-source ID-Rep block and distance-quadrat replicate", 1024L, "Restores all retained source sampling identifiers without key collisions and prevents unsupported cross-year alignment.",
  "grazing timing", "Fall and Spring collapsed as Grazed", "Fall, Spring, and Ungrazed retained", 522L, "Raw Her_Grazed field.",
  "treatment structure", "48 seeded IDs: 24 Grazed plus 24 Ungrazed", "72 seeded IDs: 24 Fall, 24 Spring, 24 Ungrazed", 72L, "Separates grazing timing without changing seeding combinations.",
  "Spring observation timepoints", "No timepoint rows for new Spring IDs", "2016 timepoint cloned for IDs 11_51 through 11_74", 24L, "Provides explicit timepoint keys for all Spring observations.",
  "planned irrigation", "implicit source grouping", "not represented as an applied treatment", 0L, "Contributor confirmed irrigation never occurred."
)
grazing_counts <- active_row_crosswalk |>
  count(.data$survey_year, .data$grazing_timing, name = "observation_rows") |>
  arrange(.data$survey_year, .data$grazing_timing)
source_area_keys <- active_row_crosswalk |>
  distinct(.data$survey_year, .data$source_id, .data$source_rep,
           .data$source_block, .data$source_transect_distance_m) |>
  count(.data$source_id, .data$source_rep, .data$source_block,
        .data$source_transect_distance_m, name = "years_present")
year_alignment_summary <- tibble(
  source_sampling_keys = nrow(source_area_keys),
  keys_present_both_years = sum(source_area_keys$years_present == 2L),
  keys_present_one_year = sum(source_area_keys$years_present == 1L),
  candidate_area_keys_shared_between_years = 0L,
  decision = "Keep candidate sampling areas separate by year because original cross-year alignment is unclear."
)
deferred_import_decisions <- tibble::tribble(
  ~item, ~harmonized_preprocessing_action, ~sql_import_action,
  "passive treatment meaning", "Retain 11_25 and 11_50, divide their standardized responses by 16, and do not infer herbicide identity.", "Herbicide is reported in the paper but cannot be mapped to a passive ID from retained data; do not assign an herbicide event without new source evidence.",
  "applicationmethod = none", "Retain source token for provenance; it is not an applied method.", "Omit the application-detail row when the source token means no application.",
  "seed pretreatment", "Retain coated/blank values in trtrates.", "Validate vocabulary and route coated values to the seeding-pretreatment structure."
)

# Count rows separately from response totals to avoid conflating abundance and
# completeness. This is intentionally calculated independently on both sides.
raw_count_audit <- active_crosswalk |>
  group_by(.data$year, .data$treatmentid, .data$speciesid) |>
  summarise(
    raw_rows = dplyr::n(),
    raw_response_sum = sum(.data$response),
    .groups = "drop"
  )
candidate_count_audit <- active_vegresults |>
  group_by(.data$year, .data$treatmentid, .data$speciesid) |>
  summarise(
    candidate_rows = dplyr::n(),
    candidate_response_sum = sum(.data$response),
    .groups = "drop"
  )
treatment_species_audit <- full_join(
  raw_count_audit,
  candidate_count_audit,
  by = c("year", "treatmentid", "speciesid")
) |>
  mutate(
    row_difference = dplyr::coalesce(.data$candidate_rows, 0L) -
      dplyr::coalesce(.data$raw_rows, 0L),
    response_difference = dplyr::coalesce(.data$candidate_response_sum, 0) -
      dplyr::coalesce(.data$raw_response_sum, 0),
    status = if_else(.data$row_difference == 0L & .data$response_difference == 0,
                     "matches raw", "review")
  ) |>
  arrange(.data$year, as.integer(str_extract(.data$treatmentid, "[0-9]+$")),
          .data$speciesid)

if (any(treatment_species_audit$status != "matches raw")) {
  print(treatment_species_audit |> filter(.data$status != "matches raw"))
  stop("Treatment/species counts do not reconcile to the raw source.", call. = FALSE)
}

expected_treatment_definition <- active_crosswalk |>
  mutate(
    expected_rate_total = unname(seed_base_map[.data$Species]) *
      if_else(.data$Seed_Rate == "high", 2, 1),
    expected_species_count = if_else(.data$Spatial_arrangement == "mix", 5L, 1L),
    expected_coating = if_else(.data$Coating == "C", "coated", "blank")
  ) |>
  group_by(.data$treatmentid) |>
  summarise(
    expected_rate_total = dplyr::first(.data$expected_rate_total),
    expected_species_count = dplyr::first(.data$expected_species_count),
    expected_coating = dplyr::first(.data$expected_coating),
    distinct_expected_rates = n_distinct(.data$expected_rate_total),
    distinct_expected_species_counts = n_distinct(.data$expected_species_count),
    distinct_expected_coatings = n_distinct(.data$expected_coating),
    .groups = "drop"
  )

candidate_treatment_definition <- reprocessed_trtrates |>
  filter(.data$treatmentid %in% expected_active_ids) |>
  group_by(.data$treatmentid) |>
  summarise(
    candidate_rate_total = sum(as.numeric(.data$rate)),
    candidate_species_count = dplyr::n(),
    candidate_coating = if_else(
      all(is.na(.data$seedpretreatment) | str_squish(as.character(.data$seedpretreatment)) == ""),
      "blank",
      "coated"
    ),
    .groups = "drop"
  )

treatment_definition_audit <- full_join(
  expected_treatment_definition,
  candidate_treatment_definition,
  by = "treatmentid"
) |>
  mutate(
    status = if_else(
      .data$distinct_expected_rates == 1L &
        .data$distinct_expected_species_counts == 1L &
        .data$distinct_expected_coatings == 1L &
        .data$expected_rate_total == .data$candidate_rate_total &
        .data$expected_species_count == .data$candidate_species_count &
        .data$expected_coating == .data$candidate_coating,
      "matches raw design",
      "review"
    )
  ) |>
  arrange(as.integer(str_extract(.data$treatmentid, "[0-9]+$")))

bad_treatment_definitions <- treatment_definition_audit |>
  filter(is.na(.data$status) | .data$status != "matches raw design")
if (nrow(bad_treatment_definitions) > 0L) {
  print(bad_treatment_definitions)
  stop("One or more treatment definitions do not match the raw design fields.", call. = FALSE)
}

block_audit <- tibble(
  check = c(
    "active raw rows",
    "active candidate rows",
    "unique candidate vegetation keys",
    "unique source sampling keys",
    "source sampling keys occurring in both years",
    "candidate area keys shared between years",
    "duplicate candidate vegetation keys"
  ),
  value = c(
    nrow(active_crosswalk),
    nrow(active_vegresults),
    nrow(active_vegresults |> distinct(.data$treatmentid, .data$year, .data$block,
                                       .data$replicate, .data$speciesid)),
    nrow(source_area_keys),
    sum(source_area_keys$years_present == 2L),
    0L,
    nrow(duplicate_keys)
  )
)

active_ids_vec <- sort(unique(active_vegresults$treatmentid))
trtrate_ids_vec <- sort(unique(
  reprocessed_trtrates$treatmentid[
    reprocessed_trtrates$treatmentid %in% expected_active_ids
  ]
))
if (!identical(active_ids_vec, trtrate_ids_vec)) {
  stop("Active observation treatments and seed-rate treatments do not match.", call. = FALSE)
}

area_treatment_cardinality <- active_vegresults |>
  group_by(.data$year, .data$block, .data$replicate) |>
  summarise(
    treatment_count = n_distinct(.data$treatmentid),
    treatmentids = paste(sort(unique(.data$treatmentid)), collapse = ","),
    .groups = "drop"
  )
if (any(area_treatment_cardinality$treatment_count != 1L)) {
  print(area_treatment_cardinality |> filter(.data$treatment_count != 1L))
  stop("An active sampling area resolves to more than one treatment.", call. = FALSE)
}

area_counts <- active_vegresults |>
  distinct(.data$year, .data$treatmentid, .data$block, .data$replicate) |>
  count(.data$year, .data$treatmentid, name = "area_count")
trtrate_counts <- reprocessed_trtrates |>
  filter(.data$treatmentid %in% expected_active_ids) |>
  count(.data$treatmentid, name = "seed_trtrate_rows")
area_seed_trtrate_audit <- area_counts |>
  left_join(trtrate_counts, by = "treatmentid") |>
  mutate(
    status = if_else(!is.na(.data$seed_trtrate_rows) & .data$seed_trtrate_rows > 0L,
                     "covered", "missing seed trtrates")
  ) |>
  arrange(.data$year, as.integer(str_extract(.data$treatmentid, "[0-9]+$")))
if (any(area_seed_trtrate_audit$status != "covered")) {
  stop("One or more active area-treatment groups lack seed trtrates.", call. = FALSE)
}

area_seed_trtrate_summary <- tibble(
  active_sampling_areas = nrow(area_treatment_cardinality),
  areas_with_one_treatment = sum(area_treatment_cardinality$treatment_count == 1L),
  areas_with_multiple_treatments = sum(area_treatment_cardinality$treatment_count > 1L),
  active_treatment_ids = length(active_ids_vec),
  active_treatments_with_seed_trtrates = length(intersect(active_ids_vec, trtrate_ids_vec)),
  active_treatments_missing_seed_trtrates = length(setdiff(active_ids_vec, trtrate_ids_vec)),
  seed_trtrate_treatments_without_active_areas = length(setdiff(trtrate_ids_vec, active_ids_vec))
)

write.csv(active_row_crosswalk, file.path(review_dir, "active_row_crosswalk.csv"), row.names = FALSE, na = "")
write.csv(preprocessing_summary, file.path(review_dir, "preprocessing_summary.csv"), row.names = FALSE, na = "")
write.csv(grazing_counts, file.path(review_dir, "grazing_counts.csv"), row.names = FALSE, na = "")
write.csv(year_alignment_summary, file.path(review_dir, "year_alignment_summary.csv"), row.names = FALSE, na = "")
write.csv(deferred_import_decisions, file.path(review_dir, "deferred_import_decisions.csv"), row.names = FALSE, na = "")
write.csv(treatment_species_audit, file.path(review_dir, "treatment_species_audit.csv"), row.names = FALSE, na = "")
write.csv(treatment_definition_audit, file.path(review_dir, "treatment_definition_audit.csv"), row.names = FALSE, na = "")
write.csv(block_audit, file.path(review_dir, "block_audit.csv"), row.names = FALSE, na = "")
write.csv(area_seed_trtrate_audit, file.path(review_dir, "area_seed_trtrate_audit.csv"), row.names = FALSE, na = "")
write.csv(area_seed_trtrate_summary, file.path(review_dir, "area_seed_trtrate_summary.csv"), row.names = FALSE, na = "")

### Write separate review candidate ----------------------------------------

sheet_names <- excel_sheets(input_workbook)
workbook <- createWorkbook()
sheet_dimensions <- character(length(sheet_names))
for (sheet_index in seq_along(sheet_names)) {
  sheet_name <- sheet_names[[sheet_index]]
  addWorksheet(workbook, sheet_name)
  sheet_data <- switch(sheet_name,
    study = reprocessed_study,
    treatments = reprocessed_treatments,
    timepoints = reprocessed_timepoints,
    trtrates = reprocessed_trtrates,
    vegresults = reprocessed_vegresults,
    read_excel(input_workbook, sheet = sheet_name)
  )
  writeData(workbook, sheet = sheet_name, x = sheet_data, startCol = 1L,
            startRow = 1L, colNames = TRUE, rowNames = FALSE, keepNA = FALSE,
            withFilter = FALSE)
  freezePane(workbook, sheet = sheet_name, firstRow = TRUE)
  setColWidths(workbook, sheet = sheet_name, cols = seq_len(ncol(sheet_data)), widths = "auto")
  sheet_dimensions[[sheet_index]] <- paste0("A1:", int2col(ncol(sheet_data)), nrow(sheet_data) + 1L)
}
saveWorkbook(workbook, output_workbook, overwrite = TRUE)

package_dir <- tempfile("gazp11_xlsx_")
dir.create(package_dir)
unzip(output_workbook, exdir = package_dir)
for (sheet_index in seq_along(sheet_names)) {
  worksheet_path <- file.path(package_dir, "xl", "worksheets", paste0("sheet", sheet_index, ".xml"))
  worksheet_xml <- paste(readLines(worksheet_path, warn = FALSE), collapse = "")
  worksheet_xml <- sub('<dimension ref="A1"/>',
                       paste0('<dimension ref="', sheet_dimensions[[sheet_index]], '"/>'),
                       worksheet_xml, fixed = TRUE)
  worksheet_xml <- sub('<pageSetup[^>]*/>', "", worksheet_xml)
  writeLines(worksheet_xml, worksheet_path, useBytes = TRUE)
}
unlink(file.path(package_dir, "xl", "worksheets", "_rels"), recursive = TRUE)
repacked_workbook <- tempfile(fileext = ".xlsx")
zip::zipr(repacked_workbook, files = list.files(package_dir, full.names = TRUE),
          root = package_dir, include_directories = TRUE)
file.copy(repacked_workbook, output_workbook, overwrite = TRUE)
unlink(c(package_dir, repacked_workbook), recursive = TRUE)

message("Wrote finalized GAZP11 preprocessed workbook: ", output_workbook)
message("Original harmonized workbook left unchanged: ", input_workbook)
message("No SQL preparation, connection, or write was performed.")
