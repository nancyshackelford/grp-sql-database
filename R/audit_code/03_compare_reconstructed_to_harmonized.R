# Compare reconstructed Supabase workbooks with the original harmonized GAZP
# Excel workbooks. Audit results are documentation outputs, not data outputs.
#
# AUDIT STATUS AFTER MANUAL TRIAGE OF SNAPSHOT 2026-08-13: The adjudicated
# triage_pattern_summary.csv is the authoritative review record; do not replace
# its manual status or assessment fields without preserving that review. The
# confirmed import error was missing timepoint months in GAZP1, GAZP2, and
# GAZP3. That error was corrected on 2026-08-14 by a committed and verified
# backfill of 1,282 veg_result rows; source day values were absent and therefore
# no days were changed. Snapshot 2026-08-13 predates the repair and must remain
# interpretable as pre-correction evidence. The species review is complete. The
# sole central taxonomy error, GAZP5 Art_tri3, was corrected and verified on
# 2026-08-14 as Art_tri_sub_tri / speciesid 7171; 462 veg_result rows and 177
# seeding rows were reassigned and the global species crosswalk was updated.
# Other multiple-code cases correctly use the
# accepted Supabase taxon, while historical or regional source concepts should
# be retained in project-specific import crosswalks rather than the central
# database. GAZP5 requires a standalone post-import species crosswalk; it must
# include the contextual speciesid-plus-seeding-rate-and-units rule that recovers
# Pse_rup versus Pse_rup1. Export/reconstruction consumes this provenance and
# does not create it. Accepted differences are: GAZP5 treatment
# expansion caused by the added cover-crop treatment; GAZP5 treatment-rate row
# collapse caused by identical broadcast and drill applications being normalized
# to one species/rate row while both application methods remain represented in
# treatment data; removal of the erroneous duplicate GAZP1 grading treatment;
# and refined Supabase-derived tsrfirst/tsrlast values where the original Excel
# metadata was wrong. The intended study timepoints value is the maximum count
# of distinct monitoring points within a single treatment. Site USDA hierarchy
# is stored in Supabase and its current absence is a reconstruction issue, not
# schema loss. Both confirmed database corrections are complete. The remaining
# provenance task is to build the project-specific GAZP5 species crosswalk.
#
# Outputs are written under:
#   docs/audit_reports/<active_snapshot>/
#
# Comparison layers:
#   1. Raw and normalized row counts.
#   2. Exact normalized multiset comparison across familiar source columns.
#   3. Key-aligned, field-level mismatch comparison where stable keys exist.
#   4. Reconstruction/mapping status inventory from appended audit columns.
#   5. Pattern-level triage that reduces thousands of repeated differences to
#      a short list of causes, priorities, counts, and representative examples.

suppressPackageStartupMessages({
  library(dplyr)
  library(purrr)
  library(readr)
  library(tibble)
  library(tidyr)
  library(stringr)
})

source("R/audit_code/00_audit_config.R")

if (!requireNamespace("openxlsx", quietly = TRUE)) {
  stop("Package 'openxlsx' is required for workbook comparison.", call. = FALSE)
}


# ---- Configuration ------------------------------------------------------

comparison_keys <- list(
  study = c("DB", "projectid"),
  site = c("DB", "siteid", "projectid"),
  treatments = c(
    "DB", "treatmentid", "trt_tsr", "treatment_category",
    "treatment_type"
  ),
  timepoints = c("DB", "treatmentid", "tsr"),
  cultivars = c("speciesid", "cultivarid", "cultivar"),
  trtrates = c(
    "DB", "treatmentid", "speciesid", "cultivarid", "trt", "mix_trt",
    "treatment_type", "trt_year", "rate"
  ),
  refs = c("DB", "projectid", "papernumber"),
  vegresults = c(
    "DB", "treatmentid", "year", "tsr", "block", "replicate",
    "speciesid", "responselevel", "responsemetric"
  )
)

numeric_tolerance <- 1e-8


# ---- General helpers ----------------------------------------------------

require_file <- function(path, description) {
  if (!file.exists(path)) {
    stop(description, " was not found: ", path, call. = FALSE)
  }
  invisible(path)
}


collapse_values <- function(x, separator = " | ") {
  values <- unique(trimws(as.character(x[!is.na(x)])))
  values <- values[nzchar(values)]
  if (length(values) == 0L) NA_character_ else paste(values, collapse = separator)
}


safe_sheet_names <- function(path) {
  require_file(path, "Workbook")
  openxlsx::getSheetNames(path)
}


read_sheet <- function(path, sheet) {
  sheets <- safe_sheet_names(path)
  if (!sheet %in% sheets) return(NULL)

  data <- openxlsx::read.xlsx(
    path,
    sheet = sheet,
    colNames = TRUE,
    skipEmptyRows = TRUE,
    skipEmptyCols = FALSE,
    check.names = FALSE,
    na.strings = character(0)
  )

  tibble::as_tibble(data, .name_repair = "minimal")
}


normalize_scalar <- function(x) {
  value <- trimws(as.character(x))
  missing <- is.na(x) | value == "" | toupper(value) %in% c("NA", "N/A")
  value[missing] <- NA_character_

  numeric_value <- suppressWarnings(as.numeric(value))
  numeric_like <- !is.na(value) & !is.na(numeric_value)
  value[numeric_like] <- format(
    numeric_value[numeric_like],
    scientific = FALSE,
    trim = TRUE,
    digits = 15
  )

  value[!is.na(value)] <- str_to_lower(str_squish(value[!is.na(value)]))
  value
}


normalize_table <- function(data, columns) {
  if (is.null(data)) return(NULL)

  missing_columns <- setdiff(columns, names(data))
  for (column in missing_columns) data[[column]] <- NA

  data |>
    select(all_of(columns)) |>
    mutate(across(everything(), normalize_scalar))
}


row_signature <- function(data, columns) {
  normalized <- normalize_table(data, columns)
  if (nrow(normalized) == 0L) return(character())

  normalized[] <- lapply(normalized, function(x) ifelse(is.na(x), "<NA>", x))
  apply(normalized, 1, paste, collapse = "\u241f")
}


multiset_counts <- function(data, columns) {
  tibble(.row_signature = row_signature(data, columns)) |>
    count(.data$.row_signature, name = "n")
}


expand_multiset_difference <- function(counts, columns, source_data) {
  if (nrow(counts) == 0L || sum(counts$n) == 0L) {
    return(tibble())
  }

  signatures <- rep(counts$.row_signature, counts$n)
  source_signatures <- row_signature(source_data, columns)
  source_data |>
    mutate(.row_signature = source_signatures) |>
    semi_join(tibble(.row_signature = signatures), by = ".row_signature") |>
    group_by(.data$.row_signature) |>
    mutate(.occurrence = row_number()) |>
    ungroup() |>
    inner_join(
      tibble(.row_signature = signatures) |>
        group_by(.data$.row_signature) |>
        mutate(.occurrence = row_number()) |>
        ungroup(),
      by = c(".row_signature", ".occurrence")
    ) |>
    select(-".row_signature", -".occurrence")
}


compare_multisets <- function(original, reconstructed, columns) {
  original_counts <- multiset_counts(original, columns)
  reconstructed_counts <- multiset_counts(reconstructed, columns)

  counts <- full_join(
    original_counts |> rename(original_n = "n"),
    reconstructed_counts |> rename(reconstructed_n = "n"),
    by = ".row_signature"
  ) |>
    mutate(
      original_n = coalesce(.data$original_n, 0L),
      reconstructed_n = coalesce(.data$reconstructed_n, 0L),
      missing_n = pmax(.data$original_n - .data$reconstructed_n, 0L),
      unexpected_n = pmax(.data$reconstructed_n - .data$original_n, 0L)
    )

  missing_counts <- counts |>
    filter(.data$missing_n > 0L) |>
    transmute(.data$.row_signature, n = .data$missing_n)
  unexpected_counts <- counts |>
    filter(.data$unexpected_n > 0L) |>
    transmute(.data$.row_signature, n = .data$unexpected_n)

  list(
    exact_normalized_rows = sum(pmin(counts$original_n, counts$reconstructed_n)),
    missing_rows = sum(counts$missing_n),
    unexpected_rows = sum(counts$unexpected_n),
    missing_detail = expand_multiset_difference(
      missing_counts, columns, original
    ),
    unexpected_detail = expand_multiset_difference(
      unexpected_counts, columns, reconstructed
    )
  )
}


# ---- Key-aligned field comparison --------------------------------------

add_key_occurrence <- function(data, keys) {
  normalized_keys <- normalize_table(data, keys)
  key_names <- paste0(".key_", seq_along(keys))
  names(normalized_keys) <- key_names

  bind_cols(data, normalized_keys) |>
    group_by(across(all_of(key_names))) |>
    mutate(.key_occurrence = row_number()) |>
    ungroup()
}


values_equal <- function(original, reconstructed) {
  original_text <- normalize_scalar(original)
  reconstructed_text <- normalize_scalar(reconstructed)

  both_missing <- is.na(original_text) & is.na(reconstructed_text)
  one_missing <- xor(is.na(original_text), is.na(reconstructed_text))

  original_number <- suppressWarnings(as.numeric(original_text))
  reconstructed_number <- suppressWarnings(as.numeric(reconstructed_text))
  both_numeric <- !is.na(original_number) & !is.na(reconstructed_number)

  equal <- both_missing
  equal[one_missing] <- FALSE
  equal[both_numeric] <- abs(
    original_number[both_numeric] - reconstructed_number[both_numeric]
  ) <= numeric_tolerance * pmax(
    1,
    abs(original_number[both_numeric]),
    abs(reconstructed_number[both_numeric])
  )

  text_comparable <- !both_numeric & !both_missing & !one_missing
  equal[text_comparable] <- original_text[text_comparable] ==
    reconstructed_text[text_comparable]
  equal[is.na(equal)] <- FALSE
  equal
}


field_mismatches <- function(original, reconstructed, columns, keys) {
  if (nrow(original) == 0L || nrow(reconstructed) == 0L) return(tibble())
  if (!all(keys %in% columns)) return(tibble())

  original_keyed <- add_key_occurrence(original, keys)
  reconstructed_keyed <- add_key_occurrence(reconstructed, keys)
  key_columns <- c(paste0(".key_", seq_along(keys)), ".key_occurrence")

  aligned <- inner_join(
    original_keyed,
    reconstructed_keyed,
    by = key_columns,
    suffix = c(".original", ".reconstructed")
  )

  compare_columns <- setdiff(columns, keys)
  if (nrow(aligned) == 0L || length(compare_columns) == 0L) return(tibble())

  key_output <- aligned |>
    select(all_of(key_columns))
  names(key_output) <- c(keys, "key_occurrence")

  purrr::map_dfr(compare_columns, function(column) {
    original_name <- paste0(column, ".original")
    reconstructed_name <- paste0(column, ".reconstructed")
    original_value <- aligned[[original_name]]
    reconstructed_value <- aligned[[reconstructed_name]]
    mismatch <- !values_equal(original_value, reconstructed_value)

    if (!any(mismatch)) return(tibble())

    bind_cols(
      key_output[mismatch, , drop = FALSE],
      tibble(
        column = column,
        original_value = as.character(original_value[mismatch]),
        reconstructed_value = as.character(reconstructed_value[mismatch]),
        normalized_original = normalize_scalar(original_value[mismatch]),
        normalized_reconstructed = normalize_scalar(
          reconstructed_value[mismatch]
        )
      )
    )
  })
}


# ---- Project/sheet comparison ------------------------------------------

compare_sheet <- function(project_code, sheet, original, reconstructed) {
  original_columns <- names(original)
  familiar_columns <- original_columns[nzchar(original_columns)]

  # GAZP5 contains an accidental blank trtrates header; it is not treated as
  # a substantive harmonized field.
  reconstructed_familiar <- normalize_table(reconstructed, familiar_columns)
  original_familiar <- normalize_table(original, familiar_columns)

  multiset <- compare_multisets(
    original_familiar,
    reconstructed_familiar,
    familiar_columns
  )

  keys <- comparison_keys[[sheet]]
  usable_keys <- keys[keys %in% familiar_columns]
  mismatches <- field_mismatches(
    original,
    reconstructed,
    familiar_columns,
    usable_keys
  )

  summary <- tibble(
    project_code = project_code,
    sheet = sheet,
    original_rows = nrow(original),
    reconstructed_rows = nrow(reconstructed),
    row_count_difference = nrow(reconstructed) - nrow(original),
    familiar_columns = length(familiar_columns),
    exact_normalized_rows = multiset$exact_normalized_rows,
    missing_rows = multiset$missing_rows,
    unexpected_rows = multiset$unexpected_rows,
    field_mismatches = nrow(mismatches),
    exact_sheet_match = multiset$missing_rows == 0L &&
      multiset$unexpected_rows == 0L
  )

  list(
    summary = summary,
    missing = multiset$missing_detail |>
      mutate(project_code = project_code, sheet = sheet, .before = 1),
    unexpected = multiset$unexpected_detail |>
      mutate(project_code = project_code, sheet = sheet, .before = 1),
    mismatches = mismatches |>
      mutate(project_code = project_code, sheet = sheet, .before = 1)
  )
}


status_inventory <- function(project_code, sheet, reconstructed) {
  status_columns <- names(reconstructed)[
    grepl("status$", names(reconstructed), ignore.case = TRUE)
  ]

  purrr::map_dfr(status_columns, function(column) {
    reconstructed |>
      count(status_value = .data[[column]], name = "rows") |>
      mutate(
        project_code = project_code,
        sheet = sheet,
        status_column = column,
        .before = 1
      )
  })
}


compare_project <- function(project_code, original_path, reconstructed_path) {
  original_sheets <- safe_sheet_names(original_path)
  reconstructed_sheets <- safe_sheet_names(reconstructed_path)
  sheets <- union(original_sheets, reconstructed_sheets)

  results <- purrr::map(sheets, function(sheet) {
    original <- read_sheet(original_path, sheet)
    reconstructed <- read_sheet(reconstructed_path, sheet)

    if (is.null(original)) original <- tibble()
    if (is.null(reconstructed)) reconstructed <- tibble()

    compare_sheet(project_code, sheet, original, reconstructed)
  })
  names(results) <- sheets

  statuses <- purrr::map_dfr(sheets, function(sheet) {
    reconstructed <- read_sheet(reconstructed_path, sheet)
    if (is.null(reconstructed)) return(tibble())
    status_inventory(project_code, sheet, reconstructed)
  })

  list(sheet_results = results, statuses = statuses)
}


# ---- Report writing -----------------------------------------------------

write_csv_if_rows <- function(data, path) {
  if (nrow(data) > 0L) write_csv_refresh(data, path)
}


write_csv_refresh <- function(data, path) {
  tryCatch(
    {
      readr::write_csv(data, path, na = "")
      TRUE
    },
    error = function(error) {
      if (file.exists(path)) {
        warning(
          "Could not refresh locked report file; existing file retained: ",
          path,
          call. = FALSE
        )
        return(FALSE)
      }
      stop(error)
    }
  )
}


markdown_table <- function(data) {
  if (nrow(data) == 0L) return("No rows.")
  header <- paste0("| ", paste(names(data), collapse = " | "), " |")
  divider <- paste0("| ", paste(rep("---", ncol(data)), collapse = " | "), " |")
  rows <- apply(data, 1, function(row) {
    row <- gsub("\\|", "\\\\|", as.character(row))
    paste0("| ", paste(row, collapse = " | "), " |")
  })
  paste(c(header, divider, rows), collapse = "\n")
}


write_markdown_report <- function(summary, statuses, output_path, config) {
  totals <- summary |>
    summarise(
      projects = n_distinct(.data$project_code),
      sheets = n(),
      exact_sheets = sum(.data$exact_sheet_match),
      missing_rows = sum(.data$missing_rows),
      unexpected_rows = sum(.data$unexpected_rows),
      field_mismatches = sum(.data$field_mismatches)
    )

  review <- summary |>
    filter(!.data$exact_sheet_match | .data$field_mismatches > 0L) |>
    select(
      "project_code", "sheet", "original_rows", "reconstructed_rows",
      "exact_normalized_rows", "missing_rows", "unexpected_rows",
      "field_mismatches"
    )

  status_summary <- statuses |>
    arrange(.data$project_code, .data$sheet, .data$status_column,
            desc(.data$rows))

  lines <- c(
    "# Supabase reconstruction audit",
    "",
    paste0("Snapshot: `", config$active_snapshot, "`"),
    "",
    "This report compares Supabase-first reconstructed workbooks with the original harmonized GAZP Excel workbooks. Appended `supabase_*` audit columns are excluded from value comparison.",
    "",
    "## Overall result",
    "",
    paste0("- Projects compared: ", totals$projects),
    paste0("- Sheets compared: ", totals$sheets),
    paste0("- Exact normalized sheet matches: ", totals$exact_sheets),
    paste0("- Missing reconstructed rows: ", totals$missing_rows),
    paste0("- Unexpected reconstructed rows: ", totals$unexpected_rows),
    paste0("- Key-aligned field mismatches: ", totals$field_mismatches),
    "",
    "Normalization treats blank cells and literal `NA`/`N/A` as missing, compares text without case or redundant whitespace, and compares numeric values with a small floating-point tolerance.",
    "",
    "## Sheet summary",
    "",
    markdown_table(summary),
    "",
    "## Sheets requiring review",
    "",
    markdown_table(review),
    "",
    "## Reconstruction and mapping statuses",
    "",
    markdown_table(status_summary),
    "",
    "Detailed CSV files in this folder retain the original and reconstructed rows/values for investigation."
  )

  writeLines(lines, output_path, useBytes = TRUE)
}


# ---- Pattern-level triage ----------------------------------------------

classify_field_pattern <- function(sheet, column, reconstructed_missing) {
  case_when(
    sheet == "site" & reconstructed_missing ~ "expected_schema_loss",
    sheet == "trtrates" & column %in% c("treatment_type", "trt_year") ~
      "expected_schema_loss",
    sheet == "timepoints" & column %in% c("month", "day") &
      reconstructed_missing ~ "possible_upload_loss",
    sheet == "study" & column %in% c("tsrfirst", "tsrlast", "timepoints") ~
      "timing_discrepancy",
    sheet == "study" & column %in% c("country", "continent") ~
      "controlled_vocabulary_normalization",
    sheet == "treatments" & column == "othertreatments" ~
      "treatment_value_routed_or_normalized",
    sheet == "vegresults" & column == "speciesid" ~
      "reverse_species_mapping_ambiguity",
    TRUE ~ "unclassified_field_difference"
  )
}


priority_for_category <- function(category) {
  case_when(
    category %in% c(
      "possible_upload_loss",
      "timing_discrepancy",
      "row_loss"
    ) ~ "HIGH",
    category %in% c(
      "row_expansion",
      "treatment_value_routed_or_normalized",
      "reverse_species_mapping_ambiguity",
      "unclassified_field_difference"
    ) ~ "MEDIUM",
    category %in% c(
      "expected_schema_loss",
      "controlled_vocabulary_normalization"
    ) ~ "LOW",
    TRUE ~ "MEDIUM"
  )
}


explanation_for_category <- function(category) {
  case_when(
    category == "expected_schema_loss" ~
      "The harmonized field has no equivalent stored in the current SQL schema.",
    category == "possible_upload_loss" ~
      "The source value is populated but the reconstructed Supabase value is missing.",
    category == "timing_discrepancy" ~
      "Timing values derived from uploaded results do not agree with source project metadata.",
    category == "controlled_vocabulary_normalization" ~
      "The source and SQL values use different labels for the same geographic vocabulary.",
    category == "treatment_value_routed_or_normalized" ~
      "Free-text treatment information was moved into structured SQL treatment fields or normalized.",
    category == "reverse_species_mapping_ambiguity" ~
      "One SQL species record corresponds to multiple historical Excel species codes.",
    category == "row_loss" ~
      "Fewer reconstructed rows exist than source rows; import deduplication or many-to-one normalization may have collapsed records.",
    category == "row_expansion" ~
      "More reconstructed rows exist than source rows because normalized SQL details expand during reversal.",
    TRUE ~ "The difference requires focused review before assigning a cause."
  )
}


build_field_patterns <- function(value_mismatches) {
  if (nrow(value_mismatches) == 0L) return(tibble())

  value_mismatches |>
    mutate(
      reconstructed_missing = is.na(.data$normalized_reconstructed) |
        .data$normalized_reconstructed == "",
      original_missing = is.na(.data$normalized_original) |
        .data$normalized_original == "",
      category = classify_field_pattern(
        .data$sheet,
        .data$column,
        .data$reconstructed_missing
      )
    ) |>
    group_by(
      .data$project_code,
      .data$sheet,
      .data$column,
      .data$category,
      .data$reconstructed_missing,
      .data$original_missing
    ) |>
    summarise(
      affected_values = n(),
      example_original = collapse_values(head(unique(.data$original_value), 3)),
      example_reconstructed = collapse_values(
        head(unique(.data$reconstructed_value), 3)
      ),
      .groups = "drop"
    ) |>
    mutate(
      pattern_type = "field_value",
      priority = priority_for_category(.data$category),
      explanation = explanation_for_category(.data$category),
      review_recommendation = case_when(
        .data$priority == "HIGH" ~ "Review representative rows and import code now.",
        .data$priority == "MEDIUM" ~ "Review the transformation rule, not every row.",
        TRUE ~ "Document as expected unless the schema should retain this field."
      ),
      .before = 1
    )
}


build_row_count_patterns <- function(sheet_summary) {
  sheet_summary |>
    filter(.data$row_count_difference != 0L) |>
    transmute(
      pattern_type = "row_count",
      priority = if_else(.data$row_count_difference < 0L, "HIGH", "MEDIUM"),
      project_code = .data$project_code,
      sheet = .data$sheet,
      column = NA_character_,
      category = if_else(
        .data$row_count_difference < 0L,
        "row_loss",
        "row_expansion"
      ),
      reconstructed_missing = .data$row_count_difference < 0L,
      original_missing = FALSE,
      affected_values = abs(.data$row_count_difference),
      example_original = paste0(.data$original_rows, " rows"),
      example_reconstructed = paste0(.data$reconstructed_rows, " rows"),
      explanation = explanation_for_category(.data$category),
      review_recommendation = if_else(
        .data$row_count_difference < 0L,
        "Review source duplicates and import distinct()/join logic.",
        "Review how normalized detail rows are recombined."
      )
    )
}


build_status_patterns <- function(statuses) {
  statuses |>
    filter(
      grepl("ambiguous|no_reverse|partial", .data$status_value,
            ignore.case = TRUE)
    ) |>
    transmute(
      pattern_type = "mapping_status",
      priority = if_else(
        grepl("ambiguous|no_reverse", .data$status_value, ignore.case = TRUE),
        "MEDIUM",
        "LOW"
      ),
      project_code = .data$project_code,
      sheet = .data$sheet,
      column = .data$status_column,
      category = case_when(
        grepl("ambiguous", .data$status_value, ignore.case = TRUE) ~
          "reverse_mapping_ambiguity",
        grepl("no_reverse", .data$status_value, ignore.case = TRUE) ~
          "missing_reverse_mapping",
        TRUE ~ "documented_partial_reconstruction"
      ),
      reconstructed_missing = NA,
      original_missing = NA,
      affected_values = .data$rows,
      example_original = NA_character_,
      example_reconstructed = .data$status_value,
      explanation = case_when(
        .data$category == "reverse_mapping_ambiguity" ~
          "The SQL identifier has multiple possible legacy source identifiers.",
        .data$category == "missing_reverse_mapping" ~
          "No repository crosswalk entry reverses this SQL identifier.",
        TRUE ~ "The reconstruction code already identifies these rows as incomplete."
      ),
      review_recommendation = case_when(
        .data$priority == "MEDIUM" ~
          "Resolve the mapping rule once for the affected identifier group.",
        TRUE ~ "Document the known limitation; do not review every row."
      )
    )
}


build_triage_patterns <- function(sheet_summary, value_mismatches, statuses) {
  bind_rows(
    build_row_count_patterns(sheet_summary),
    build_field_patterns(value_mismatches),
    build_status_patterns(statuses)
  ) |>
    mutate(
      priority_order = match(.data$priority, c("HIGH", "MEDIUM", "LOW"))
    ) |>
    arrange(
      .data$priority_order,
      desc(.data$affected_values),
      .data$project_code,
      .data$sheet
    ) |>
    select(-"priority_order")
}


write_triage_report <- function(patterns, output_path, config) {
  priority_summary <- patterns |>
    group_by(.data$priority) |>
    summarise(
      patterns = n(),
      repeated_values_affected = sum(.data$affected_values),
      .groups = "drop"
    ) |>
    mutate(priority_order = match(.data$priority, c("HIGH", "MEDIUM", "LOW"))) |>
    arrange(.data$priority_order) |>
    select(-"priority_order")

  review_table <- patterns |>
    select(
      "priority", "project_code", "sheet", "column", "category",
      "affected_values", "example_original", "example_reconstructed",
      "explanation", "review_recommendation"
    )

  lines <- c(
    "# Audit findings triage",
    "",
    paste0("Snapshot: `", config$active_snapshot, "`"),
    "",
    "This report reduces repeated cell-level differences to reviewable patterns. `affected_values` is the number of repeated rows or cells represented by a pattern—not the number of separate upload bugs.",
    "",
    "## Review approach",
    "",
    "1. Review each HIGH pattern using its examples and detailed CSV evidence.",
    "2. Review each MEDIUM transformation or mapping rule once, not row by row.",
    "3. Treat LOW patterns as documented schema or reconstruction limitations unless the schema should be expanded.",
    "",
    "## Priority summary",
    "",
    markdown_table(priority_summary),
    "",
    "## Pattern-level findings",
    "",
    markdown_table(review_table)
  )

  writeLines(lines, output_path, useBytes = TRUE)
}


run_comparison_audit <- function(config = audit_config) {
  output_dir <- file.path(config$paths$audit_report_root, config$active_snapshot)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  project_codes <- paste0(config$source_database, config$projectids)
  reconstructed_paths <- file.path(
    config$paths$reconstructed_root,
    config$active_snapshot,
    paste0(project_codes, "_reconstructed_from_supabase.xlsx")
  )

  purrr::walk2(
    config$harmonized_workbooks,
    reconstructed_paths,
    ~ {
      require_file(.x, "Original harmonized workbook")
      require_file(.y, "Reconstructed workbook")
    }
  )

  comparisons <- purrr::pmap(
    list(project_codes, config$harmonized_workbooks, reconstructed_paths),
    compare_project
  )
  names(comparisons) <- project_codes

  sheet_summary <- purrr::map_dfr(comparisons, function(project) {
    purrr::map_dfr(project$sheet_results, "summary")
  })
  missing_rows <- purrr::map_dfr(comparisons, function(project) {
    purrr::map_dfr(project$sheet_results, "missing")
  })
  unexpected_rows <- purrr::map_dfr(comparisons, function(project) {
    purrr::map_dfr(project$sheet_results, "unexpected")
  })
  value_mismatches <- purrr::map_dfr(comparisons, function(project) {
    purrr::map_dfr(project$sheet_results, "mismatches")
  })
  statuses <- purrr::map_dfr(comparisons, "statuses")
  triage_patterns <- build_triage_patterns(
    sheet_summary,
    value_mismatches,
    statuses
  )

  write_csv_refresh(
    sheet_summary,
    file.path(output_dir, "sheet_comparison_summary.csv")
  )
  write_csv_refresh(
    statuses,
    file.path(output_dir, "reconstruction_status_summary.csv")
  )
  write_csv_if_rows(
    missing_rows,
    file.path(output_dir, "missing_from_reconstruction.csv")
  )
  write_csv_if_rows(
    unexpected_rows,
    file.path(output_dir, "unexpected_in_reconstruction.csv")
  )
  write_csv_if_rows(
    value_mismatches,
    file.path(output_dir, "field_value_mismatches.csv")
  )
  write_csv_refresh(
    triage_patterns,
    file.path(output_dir, "triage_pattern_summary.csv")
  )

  write_markdown_report(
    sheet_summary,
    statuses,
    file.path(output_dir, "audit_report.md"),
    config
  )
  write_triage_report(
    triage_patterns,
    file.path(output_dir, "triage_report.md"),
    config
  )

  message("Audit report written to: ", output_dir)
  print(sheet_summary, n = Inf)

  invisible(list(
    summary = sheet_summary,
    missing = missing_rows,
    unexpected = unexpected_rows,
    mismatches = value_mismatches,
    statuses = statuses,
    triage = triage_patterns,
    output_dir = output_dir
  ))
}


audit_results <- run_comparison_audit()
