### Reprocess GAZP10 vegetation results before the harmonized-to-SQL import
###
### This script makes the smallest project-specific correction needed for
### GAZP10:
###   * preserve the existing harmonized treatmentid assignments;
###   * use the original source plot as block;
###   * use replicate 1 for center and replicate 2 for quadrat;
###   * retain overall cover as a block-level result (blank replicate);
###   * average the eight sector observations to plot level for 2011-2012;
###   * identify every vegetation response as cover without dividing by 0.25;
###   * write a new harmonized workbook, leaving the original unchanged.

library(readxl)
library(dplyr)
library(tidyr)
library(stringr)
library(openxlsx)

source_dir <- file.path("data", "source", "GAZP", "GAZP10")
harmonized_dir <- file.path("data", "harmonized", "GAZP", "GAZP10")
import_dir <- file.path("R", "import_code", "GAZP10")

input_workbook <- file.path(harmonized_dir, "GAZP10.xlsx")
output_workbook <- file.path(harmonized_dir, "GAZP10_reprocessed.xlsx")

early_source <- file.path(source_dir, "2008-2009-2010_TOTALS_SIMPLE.XLSX")
source_2011 <- file.path(source_dir, "2011_CENSUS_2.xlsx")
source_2012 <- file.path(source_dir, "CENSUS_2012_2013 w % cover.xls")

required_files <- c(input_workbook, early_source, source_2011, source_2012)
missing_files <- required_files[!file.exists(required_files)]

if (length(missing_files) > 0L) {
  stop(
    "Missing required GAZP10 files: ",
    paste(missing_files, collapse = ", "),
    call. = FALSE
  )
}

dir.create(import_dir, recursive = TRUE, showWarnings = FALSE)

species_code_map <- c(
  CC = "Cal_cil",
  EG = "Ely_gla",
  `EG/LT` = "G_Ely_spp",
  GC = "Gri_hir",
  LT = "Ley_tri",
  MC = "Mel_cal",
  NP = "Nas_pul",
  TB = "Tri_bif",
  TW = "Tri_wil"
)

timepoint_map <- tibble(
  year = c(2008L, 2009L, 2010L, 2011L, 2012L),
  tsr = c(16L, 68L, 120L, 224L, 276L)
)

sampling_level_map <- c(
  center = 1L,
  quadrat = 2L,
  overall = NA_integer_
)

normalize_sampling_level <- function(x) {
  x |>
    as.character() |>
    str_squish() |>
    str_to_lower()
}

sampling_replicate <- function(x) {
  normalized <- normalize_sampling_level(x)
  unname(sampling_level_map[normalized])
}

measurement_scale_for <- function(x) {
  if_else(
    normalize_sampling_level(x) == "overall",
    17.6,
    0.25
  )
}

as_numeric_cover <- function(x) {
  suppressWarnings(as.numeric(as.character(x)))
}

build_output_columns <- function(data) {
  data |>
    transmute(
      id = "GAZP_10",
      DB = "GAZP",
      treatmentid = as.character(.data$treatmentid),
      year = as.integer(.data$year),
      tsr = as.integer(.data$tsr),
      block = as.integer(.data$block),
      replicate = as.integer(.data$replicate),
      speciesid = as.character(.data$speciesid),
      speciesorigin = "native",
      response = as.numeric(.data$response),
      responselevel = "species",
      responsemetric = "cover",
      measurementscale = as.numeric(.data$measurementscale),
      measurementmetric = "m2"
    ) |>
    arrange(
      .data$year,
      .data$treatmentid,
      .data$block,
      is.na(.data$replicate),
      .data$replicate,
      .data$speciesid
    )
}

### 2008-2010 ---------------------------------------------------------------

early_wide <- read_excel(
  early_source,
  sheet = "_2008_2009_2010_totals"
)

early_treatment_map <- early_wide |>
  transmute(
    plot = as.integer(.data$plot),
    treatment_group = str_to_lower(str_squish(.data$type_simple)),
    treatmentid = case_when(
      .data$treatment_group == "aggregated" ~ "10_1",
      .data$treatment_group == "interspersed" ~ "10_2",
      TRUE ~ NA_character_
    )
  ) |>
  distinct()

if (anyNA(early_treatment_map$treatmentid)) {
  print(early_treatment_map |> filter(is.na(.data$treatmentid)))
  stop("An early-period plot did not resolve to treatment 10_1 or 10_2.", call. = FALSE)
}

if (any(count(early_treatment_map, .data$plot)$n != 1L)) {
  stop("An early-period source plot maps to more than one treatment.", call. = FALSE)
}

early_long <- bind_rows(lapply(c(2008L, 2009L, 2010L), function(year_value) {
  species_abbreviations <- if (year_value == 2008L) {
    c("CC", "GC", "TW", "TB", "NP", "MC", "EG/LT")
  } else {
    c("CC", "GC", "TW", "TB", "NP", "MC", "LT", "EG")
  }

  cover_columns <- paste0(species_abbreviations, "_%cover_", year_value)

  early_wide |>
    select(
      plot,
      sector,
      type_simple,
      all_of(cover_columns)
    ) |>
    rename(sampling_level = sector) |>
    pivot_longer(
      cols = all_of(cover_columns),
      names_to = "source_species_column",
      values_to = "response"
    ) |>
    mutate(
      year = year_value,
      species_abbreviation = str_remove(
        .data$source_species_column,
        fixed(paste0("_%cover_", year_value))
      ),
      speciesid = unname(species_code_map[.data$species_abbreviation]),
      block = as.integer(.data$plot),
      replicate = sampling_replicate(.data$sampling_level),
      measurementscale = measurement_scale_for(.data$sampling_level),
      response = as_numeric_cover(.data$response)
    ) |>
    left_join(
      early_treatment_map |> select(plot, treatmentid),
      by = "plot"
    ) |>
    left_join(timepoint_map, by = "year") |>
    filter(!is.na(.data$response)) |>
    select(
      treatmentid,
      year,
      tsr,
      block,
      replicate,
      speciesid,
      response,
      measurementscale
    )
}))

### 2011-2012 ---------------------------------------------------------------

# The 2012 workbook contains the aggregation and eventual burn assignments for
# all 25 source plots. These reproduce the treatment groups already used by the
# current harmonized workbook:
#   10_1 = aggregated, not burned
#   10_2 = interspersed (Poly), not burned
#   10_3 = aggregated, burned
#   10_4 = interspersed (Poly), burned
design_2012 <- read_excel(
  source_2012,
  sheet = "Raw Entered Data - 2012"
) |>
  transmute(
    plot = as.integer(.data$plot),
    aggregation = str_to_lower(str_squish(.data[["Agg/Poly"]])),
    burned = str_to_lower(str_squish(.data[["Burned?"]]))
  ) |>
  distinct() |>
  mutate(
    treatmentid = case_when(
      .data$aggregation == "agg" & .data$burned == "no" ~ "10_1",
      .data$aggregation == "poly" & .data$burned == "no" ~ "10_2",
      .data$aggregation == "agg" & .data$burned == "yes" ~ "10_3",
      .data$aggregation == "poly" & .data$burned == "yes" ~ "10_4",
      TRUE ~ NA_character_
    )
  )

if (nrow(design_2012) != 25L || anyNA(design_2012$treatmentid)) {
  print(design_2012 |> filter(is.na(.data$treatmentid)))
  stop("The 2012 plot design did not resolve to 25 treatment assignments.", call. = FALSE)
}

late_cover_columns <- c(
  CC = "CC_%cover",
  GC = "GC_%cover",
  TW = "TW_%cover",
  TB = "TB_%cover",
  NP = "NP_%cover",
  MC = "MC_%cover",
  LT = "LT_%cover",
  EG = "EG_%cover"
)

read_late_year <- function(path, sheet, year_value) {
  source_data <- read_excel(path, sheet = sheet)

  non_numeric_issues <- bind_rows(lapply(names(late_cover_columns), function(abbreviation) {
    column_name <- late_cover_columns[[abbreviation]]
    original_value <- as.character(source_data[[column_name]])
    numeric_value <- as_numeric_cover(original_value)

    source_data |>
      transmute(
        year = year_value,
        plot = as.integer(.data$plot),
        sector = as.character(.data$sector),
        sampling_level = as.character(.data[["sub-sector"]]),
        species_abbreviation = abbreviation,
        source_value = original_value,
        numeric_value = numeric_value
      ) |>
      filter(
        !is.na(.data$source_value),
        .data$source_value != "",
        is.na(.data$numeric_value)
      )
  }))

  if (nrow(non_numeric_issues) > 0L) {
    message(
      "GAZP10 ", year_value, ": ", nrow(non_numeric_issues),
      " non-numeric cover cells were treated as missing."
    )
    print(non_numeric_issues)
  }

  long_data <- bind_rows(lapply(names(late_cover_columns), function(abbreviation) {
    column_name <- late_cover_columns[[abbreviation]]

    source_data |>
      transmute(
        plot = as.integer(.data$plot),
        sector = as.character(.data$sector),
        sampling_level = normalize_sampling_level(.data[["sub-sector"]]),
        species_abbreviation = abbreviation,
        response = as_numeric_cover(.data[[column_name]])
      )
  }))

  summarized <- long_data |>
    filter(!is.na(.data$response)) |>
    group_by(
      .data$plot,
      .data$sampling_level,
      .data$species_abbreviation
    ) |>
    summarise(
      response = mean(.data$response),
      contributing_sectors = n(),
      .groups = "drop"
    ) |>
    mutate(
      year = year_value,
      speciesid = unname(species_code_map[.data$species_abbreviation]),
      block = as.integer(.data$plot),
      replicate = sampling_replicate(.data$sampling_level),
      measurementscale = measurement_scale_for(.data$sampling_level)
    ) |>
    left_join(
      design_2012 |> select(plot, treatmentid),
      by = "plot"
    ) |>
    left_join(timepoint_map, by = "year") |>
    select(
      treatmentid,
      year,
      tsr,
      block,
      replicate,
      speciesid,
      response,
      measurementscale
    )

  list(
    results = summarized,
    non_numeric_issues = non_numeric_issues
  )
}

late_2011 <- read_late_year(
  source_2011,
  "RAW ENTERED DATA",
  2011L
)

late_2012 <- read_late_year(
  source_2012,
  "Raw Entered Data - 2012",
  2012L
)

reprocessed_vegresults <- bind_rows(
  early_long,
  late_2011$results,
  late_2012$results
) |>
  build_output_columns()

### Validation ---------------------------------------------------------------

if (anyNA(reprocessed_vegresults$treatmentid)) {
  stop("One or more reprocessed rows lack a treatmentid.", call. = FALSE)
}

if (anyNA(reprocessed_vegresults$speciesid)) {
  stop("One or more reprocessed rows lack a speciesid.", call. = FALSE)
}

if (anyNA(reprocessed_vegresults$response)) {
  stop("One or more reprocessed rows lack a numeric response.", call. = FALSE)
}

if (!setequal(unique(reprocessed_vegresults$treatmentid), paste0("10_", 1:4))) {
  stop("The reprocessed data do not contain the expected treatment IDs 10_1 through 10_4.", call. = FALSE)
}

duplicate_keys <- reprocessed_vegresults |>
  count(
    .data$DB,
    .data$treatmentid,
    .data$year,
    .data$tsr,
    .data$block,
    .data$replicate,
    .data$speciesid,
    name = "rows"
  ) |>
  filter(.data$rows > 1L)

if (nrow(duplicate_keys) > 0L) {
  print(duplicate_keys)
  stop("Reprocessing produced duplicate vegetation-result keys.", call. = FALSE)
}

if (any(
  is.na(reprocessed_vegresults$replicate) &
    reprocessed_vegresults$measurementscale != 17.6
)) {
  stop("A block-level overall result does not have measurement scale 17.6 m2.", call. = FALSE)
}

if (any(
  !is.na(reprocessed_vegresults$replicate) &
    reprocessed_vegresults$measurementscale != 0.25
)) {
  stop("A center or quadrat result does not have measurement scale 0.25 m2.", call. = FALSE)
}

current_vegresults <- read_excel(input_workbook, sheet = "vegresults")

row_accounting <- bind_rows(
  current_vegresults |>
    count(.data$year, name = "rows") |>
    mutate(version = "current"),
  reprocessed_vegresults |>
    count(.data$year, name = "rows") |>
    mutate(version = "reprocessed")
) |>
  arrange(.data$year, .data$version)

print(row_accounting)

level_accounting <- reprocessed_vegresults |>
  mutate(
    sampling_level = case_when(
      is.na(.data$replicate) ~ "overall",
      .data$replicate == 1L ~ "center",
      .data$replicate == 2L ~ "quadrat",
      TRUE ~ "unexpected"
    )
  ) |>
  count(
    .data$year,
    .data$treatmentid,
    .data$sampling_level,
    name = "rows"
  ) |>
  arrange(.data$year, .data$treatmentid, .data$sampling_level)

print(level_accounting)

### Write a new harmonized workbook -----------------------------------------

project_note <- paste(
  "GAZP10 vegetation reprocessing:",
  "block identifies the original 5 m-wide spatial plot (approximately 17.6 m2);",
  "replicate 1 is the center/inner sampling location;",
  "replicate 2 is the outer 0.5 x 0.5 m quadrat;",
  "blank replicate identifies an overall block-level cover result;",
  "2011-2012 sector observations were averaged within plot and sampling level;",
  "response values are percent cover and were not divided by measurement scale."
)

existing_study <- read_excel(input_workbook, sheet = "study")
notes_column <- match("notes", names(existing_study))

if (is.na(notes_column)) {
  stop("The study sheet does not contain a notes column.", call. = FALSE)
}

existing_note <- as.character(existing_study$notes[[1]])
if (is.na(existing_note) || existing_note == "") {
  updated_note <- project_note
} else if (str_detect(existing_note, fixed(project_note))) {
  updated_note <- existing_note
} else {
  updated_note <- paste(existing_note, project_note, sep = "; ")
}

# Build a clean OOXML package rather than modifying the existing package in
# place. This preserves the workbook's sheet names, order, and tabular content
# while avoiding stale worksheet relationships from the legacy workbook.
workbook <- createWorkbook()
sheet_names <- excel_sheets(input_workbook)
sheet_dimensions <- character(length(sheet_names))

for (sheet_index in seq_along(sheet_names)) {
  sheet_name <- sheet_names[[sheet_index]]
  addWorksheet(workbook, sheet_name)

  sheet_data <- if (sheet_name == "vegresults") {
    reprocessed_vegresults
  } else {
    read_excel(input_workbook, sheet = sheet_name)
  }

  if (sheet_name == "study") {
    sheet_data$notes[[1]] <- updated_note
  }

  writeData(
    workbook,
    sheet = sheet_name,
    x = sheet_data,
    startCol = 1L,
    startRow = 1L,
    colNames = TRUE,
    rowNames = FALSE,
    keepNA = FALSE,
    withFilter = FALSE
  )

  freezePane(workbook, sheet = sheet_name, firstRow = TRUE)
  setColWidths(workbook, sheet = sheet_name, cols = seq_len(ncol(sheet_data)), widths = "auto")
  sheet_dimensions[[sheet_index]] <- paste0(
    "A1:", int2col(ncol(sheet_data)), nrow(sheet_data) + 1L
  )
}

saveWorkbook(workbook, output_workbook, overwrite = TRUE)

# openxlsx 4.2.8 can leave unused drawing/printer relationships and an A1-only
# worksheet dimension in newly created files. Remove those empty relationships
# and write the actual dimensions so Excel readers agree on sheet contents.
package_dir <- tempfile("gazp10_xlsx_")
dir.create(package_dir)
unzip(output_workbook, exdir = package_dir)

for (sheet_index in seq_along(sheet_names)) {
  worksheet_path <- file.path(
    package_dir,
    "xl",
    "worksheets",
    paste0("sheet", sheet_index, ".xml")
  )
  worksheet_xml <- paste(readLines(worksheet_path, warn = FALSE), collapse = "")
  worksheet_xml <- sub(
    '<dimension ref="A1"/>',
    paste0('<dimension ref="', sheet_dimensions[[sheet_index]], '"/>'),
    worksheet_xml,
    fixed = TRUE
  )
  worksheet_xml <- sub(
    '<pageSetup[^>]*/>',
    "",
    worksheet_xml
  )
  writeLines(worksheet_xml, worksheet_path, useBytes = TRUE)
}

unlink(file.path(package_dir, "xl", "worksheets", "_rels"), recursive = TRUE)
repacked_workbook <- tempfile(fileext = ".xlsx")
zip::zipr(
  repacked_workbook,
  files = list.files(package_dir, full.names = TRUE),
  root = package_dir,
  include_directories = TRUE
)
file.copy(repacked_workbook, output_workbook, overwrite = TRUE)
unlink(c(package_dir, repacked_workbook), recursive = TRUE)

message("Wrote reprocessed harmonized workbook: ", output_workbook)
message("Original harmonized workbook left unchanged: ", input_workbook)
