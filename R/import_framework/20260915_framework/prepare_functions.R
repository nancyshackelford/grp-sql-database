### Reusable prepare-stage functions for harmonized-to-SQL imports
###
### These functions perform deterministic, reviewable transformations only.
### They do not connect to SQL, allocate database IDs, or write database rows.

prepare_na_if_blank <- function(x) {
  x <- stringr::str_squish(as.character(x))
  dplyr::na_if(x, "")
}

assert_columns <- function(data, required, table_name) {
  missing <- setdiff(required, names(data))
  if (length(missing) > 0L) {
    stop(
      table_name, " is missing required columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

read_harmonized_workbook <- function(path, required_sheets = c(
    "study", "site", "treatments", "timepoints", "trtrates", "refs", "vegresults"
)) {
  if (!file.exists(path)) {
    stop("Harmonized workbook not found: ", path, call. = FALSE)
  }

  available <- readxl::excel_sheets(path)
  missing <- setdiff(required_sheets, available)
  if (length(missing) > 0L) {
    stop("Harmonized workbook is missing sheets: ", paste(missing, collapse = ", "), call. = FALSE)
  }

  stats::setNames(
    lapply(required_sheets, function(sheet) readxl::read_excel(path, sheet = sheet)),
    required_sheets
  )
}

validate_harmonized_identity <- function(data, expected_database, expected_projectid) {
  identity_rows <- dplyr::bind_rows(lapply(names(data), function(sheet_name) {
    table <- data[[sheet_name]]
    if (!"DB" %in% names(table)) return(NULL)

    projectid <- if ("projectid" %in% names(table)) {
      suppressWarnings(as.integer(table$projectid))
    } else if ("treatmentid" %in% names(table)) {
      suppressWarnings(as.integer(stringr::str_extract(table$treatmentid, "^[0-9]+")))
    } else {
      rep(NA_integer_, nrow(table))
    }

    tibble::tibble(
      sheet = sheet_name,
      database = prepare_na_if_blank(table$DB),
      projectid = projectid
    )
  }))

  bad_database <- identity_rows |>
    dplyr::filter(!is.na(.data$database), .data$database != expected_database)
  bad_project <- identity_rows |>
    dplyr::filter(!is.na(.data$projectid), .data$projectid != expected_projectid)

  if (nrow(bad_database) > 0L || nrow(bad_project) > 0L) {
    stop("Workbook identity does not match the requested database/project.", call. = FALSE)
  }

  invisible(identity_rows)
}

make_block_area_key <- function(siteid, block) {
  paste("block", siteid, block, sep = ":")
}

make_child_area_key <- function(siteid, block, replicate) {
  paste("plot", siteid, block, replicate, sep = ":")
}

prepare_treatments <- function(treatments, route_other_treatment_to_notes = FALSE) {
  assert_columns(
    treatments,
    c(
      "DB", "treatmentid", "siteid", "restorationtype", "tsr_start_year",
      "trt_year", "trt_tsr", "treatmentmonth", "treatmentday", "othertreatments"
    ),
    "treatments"
  )

  treatments |>
    dplyr::transmute(
      database = prepare_na_if_blank(.data$DB),
      source_treatmentid = prepare_na_if_blank(.data$treatmentid),
      siteid = as.integer(.data$siteid),
      restoration_type = stringr::str_to_lower(prepare_na_if_blank(.data$restorationtype)),
      restoration_start_year = suppressWarnings(as.numeric(.data$tsr_start_year)),
      year = suppressWarnings(as.numeric(.data$trt_year)),
      month = suppressWarnings(as.numeric(.data$treatmentmonth)),
      day = suppressWarnings(as.numeric(.data$treatmentday)),
      weeks_since_restoration = suppressWarnings(as.integer(.data$trt_tsr)),
      other_treatment_source = prepare_na_if_blank(.data$othertreatments),
      other_treatment = if (route_other_treatment_to_notes) {
        rep(NA_character_, dplyr::n())
      } else {
        prepare_na_if_blank(.data$othertreatments)
      },
      notes = dplyr::if_else(
        route_other_treatment_to_notes & !is.na(prepare_na_if_blank(.data$othertreatments)),
        paste0("Seeding treatment note: ", prepare_na_if_blank(.data$othertreatments), "."),
        NA_character_
      )
    ) |>
    dplyr::distinct()
}

prepare_spatial_areas <- function(
    vegresults,
    prepared_treatments,
    block_size,
    block_units = "m2",
    child_area_type = "plot"
) {
  assert_columns(
    vegresults,
    c("treatmentid", "block", "replicate", "measurementscale", "measurementmetric"),
    "vegresults"
  )

  treatment_context <- prepared_treatments |>
    dplyr::select(
      "source_treatmentid", "siteid", "restoration_start_year",
      "restoration_type"
    ) |>
    dplyr::distinct()

  ambiguous_context <- treatment_context |>
    dplyr::count(.data$source_treatmentid, name = "contexts") |>
    dplyr::filter(.data$contexts != 1L)
  if (nrow(ambiguous_context) > 0L) {
    stop("Each source treatment must resolve to exactly one site/restoration context.", call. = FALSE)
  }

  observations <- vegresults |>
    dplyr::transmute(
      source_treatmentid = prepare_na_if_blank(.data$treatmentid),
      block = prepare_na_if_blank(.data$block),
      replicate = prepare_na_if_blank(.data$replicate),
      measurement_scale = suppressWarnings(as.numeric(.data$measurementscale)),
      measurement_units = prepare_na_if_blank(.data$measurementmetric)
    ) |>
    dplyr::left_join(treatment_context, by = "source_treatmentid")

  if (anyNA(observations$source_treatmentid) || anyNA(observations$siteid) || anyNA(observations$block)) {
    stop("Every vegetation row must resolve to a treatment, site, and spatial block.", call. = FALSE)
  }

  block_scale_issues <- observations |>
    dplyr::filter(is.na(.data$replicate)) |>
    dplyr::distinct(.data$measurement_scale, .data$measurement_units) |>
    dplyr::filter(.data$measurement_scale != block_size | .data$measurement_units != block_units)
  if (nrow(block_scale_issues) > 0L) {
    stop("Block-level measurements do not match the configured block size/units.", call. = FALSE)
  }

  child_scales <- observations |>
    dplyr::filter(!is.na(.data$replicate)) |>
    dplyr::distinct(
      .data$siteid, .data$block, .data$replicate,
      .data$measurement_scale, .data$measurement_units
    )
  ambiguous_child_scales <- child_scales |>
    dplyr::count(.data$siteid, .data$block, .data$replicate, name = "scales") |>
    dplyr::filter(.data$scales != 1L)
  if (nrow(ambiguous_child_scales) > 0L) {
    stop("A child sampling area has more than one measurement scale or unit.", call. = FALSE)
  }

  area_context <- treatment_context |>
    dplyr::distinct(
      .data$siteid, .data$restoration_start_year, .data$restoration_type
    )
  if (nrow(area_context) != dplyr::n_distinct(treatment_context$siteid)) {
    stop("A site has conflicting restoration context across treatments.", call. = FALSE)
  }

  blocks <- observations |>
    dplyr::distinct(.data$siteid, .data$block) |>
    dplyr::left_join(area_context, by = "siteid") |>
    dplyr::transmute(
      area_key = make_block_area_key(.data$siteid, .data$block),
      parent_area_key = NA_character_,
      siteid = as.integer(.data$siteid),
      source_block = .data$block,
      source_replicate = NA_character_,
      type = "block",
      size = as.numeric(block_size),
      units = block_units,
      restoration_start_year = .data$restoration_start_year,
      restoration_type = .data$restoration_type,
      disturbance_end_year = NA_real_
    )

  children <- child_scales |>
    dplyr::left_join(area_context, by = "siteid") |>
    dplyr::transmute(
      area_key = make_child_area_key(.data$siteid, .data$block, .data$replicate),
      parent_area_key = make_block_area_key(.data$siteid, .data$block),
      siteid = as.integer(.data$siteid),
      source_block = .data$block,
      source_replicate = .data$replicate,
      type = child_area_type,
      size = .data$measurement_scale,
      units = .data$measurement_units,
      restoration_start_year = .data$restoration_start_year,
      restoration_type = .data$restoration_type,
      disturbance_end_year = NA_real_
    )

  areas <- dplyr::bind_rows(blocks, children) |>
    dplyr::arrange(.data$siteid, .data$source_block, .data$type, .data$source_replicate)

  if (anyDuplicated(areas$area_key)) {
    stop("Prepared area keys are not unique.", call. = FALSE)
  }
  if (!all(stats::na.omit(children$parent_area_key) %in% blocks$area_key)) {
    stop("A child sampling area lacks its parent block area.", call. = FALSE)
  }

  areas
}

prepare_area_treatment_links <- function(vegresults, prepared_treatments, areas) {
  treatment_context <- prepared_treatments |>
    dplyr::select("source_treatmentid", "siteid") |>
    dplyr::distinct()

  observed <- vegresults |>
    dplyr::transmute(
      source_treatmentid = prepare_na_if_blank(.data$treatmentid),
      block = prepare_na_if_blank(.data$block),
      replicate = prepare_na_if_blank(.data$replicate)
    ) |>
    dplyr::distinct() |>
    dplyr::left_join(treatment_context, by = "source_treatmentid")

  block_links <- observed |>
    dplyr::transmute(
      area_key = make_block_area_key(.data$siteid, .data$block),
      source_treatmentid = .data$source_treatmentid,
      link_reason = "explicit spatial block treatment"
    ) |>
    dplyr::distinct()

  child_links <- observed |>
    dplyr::filter(!is.na(.data$replicate)) |>
    dplyr::transmute(
      area_key = make_child_area_key(.data$siteid, .data$block, .data$replicate),
      source_treatmentid = .data$source_treatmentid,
      link_reason = "explicit sampling area treatment"
    ) |>
    dplyr::distinct()

  links <- dplyr::bind_rows(block_links, child_links) |>
    dplyr::arrange(.data$area_key, .data$source_treatmentid)

  if (anyNA(links$area_key) || anyNA(links$source_treatmentid)) {
    stop("An explicit area-treatment link has a missing key.", call. = FALSE)
  }
  if (!all(links$area_key %in% areas$area_key)) {
    stop("An explicit area-treatment link refers to an unprepared area.", call. = FALSE)
  }

  links
}

prepare_vegresults <- function(vegresults, timepoints, prepared_treatments, areas) {
  assert_columns(
    vegresults,
    c(
      "id", "DB", "treatmentid", "year", "tsr", "block", "replicate",
      "speciesid", "speciesorigin", "response", "responselevel", "responsemetric"
    ),
    "vegresults"
  )

  timepoint_lookup <- timepoints |>
    dplyr::transmute(
      database = prepare_na_if_blank(.data$DB),
      source_treatmentid = prepare_na_if_blank(.data$treatmentid),
      time_since_restoration = suppressWarnings(as.integer(.data$tsr)),
      timepoint_year = suppressWarnings(as.numeric(.data$year)),
      month = suppressWarnings(as.numeric(.data$month)),
      day = suppressWarnings(as.numeric(.data$day))
    ) |>
    dplyr::distinct()

  duplicate_timepoints <- timepoint_lookup |>
    dplyr::count(.data$database, .data$source_treatmentid, .data$time_since_restoration) |>
    dplyr::filter(.data$n != 1L)
  if (nrow(duplicate_timepoints) > 0L) {
    stop("Timepoint keys are not unique.", call. = FALSE)
  }

  treatment_sites <- prepared_treatments |>
    dplyr::select("source_treatmentid", "siteid") |>
    dplyr::distinct()

  prepared <- vegresults |>
    dplyr::mutate(source_row = dplyr::row_number()) |>
    dplyr::transmute(
      source_row = .data$source_row,
      source_observationid = prepare_na_if_blank(.data$id),
      database = prepare_na_if_blank(.data$DB),
      source_treatmentid = prepare_na_if_blank(.data$treatmentid),
      source_year = suppressWarnings(as.numeric(.data$year)),
      time_since_restoration = suppressWarnings(as.integer(.data$tsr)),
      block = prepare_na_if_blank(.data$block),
      replicate = prepare_na_if_blank(.data$replicate),
      source_species_code = prepare_na_if_blank(.data$speciesid),
      origin = stringr::str_to_lower(prepare_na_if_blank(.data$speciesorigin)),
      response = suppressWarnings(as.numeric(.data$response)),
      level = stringr::str_to_lower(prepare_na_if_blank(.data$responselevel)),
      metric = stringr::str_to_lower(prepare_na_if_blank(.data$responsemetric))
    ) |>
    dplyr::left_join(treatment_sites, by = "source_treatmentid") |>
    dplyr::mutate(
      area_key = dplyr::if_else(
        is.na(.data$replicate),
        make_block_area_key(.data$siteid, .data$block),
        make_child_area_key(.data$siteid, .data$block, .data$replicate)
      )
    ) |>
    dplyr::left_join(
      timepoint_lookup,
      by = c("database", "source_treatmentid", "time_since_restoration")
    ) |>
    dplyr::mutate(year = dplyr::coalesce(.data$timepoint_year, .data$source_year)) |>
    dplyr::select(-"timepoint_year")

  prepared <- prepared |>
    dplyr::mutate(
      area_found = .data$area_key %in% areas$area_key,
      timepoint_found = !is.na(.data$year),
      prepare_status = dplyr::case_when(
        !.data$area_found ~ "unmapped_area",
        !.data$timepoint_found ~ "unmapped_timepoint",
        is.na(.data$source_species_code) ~ "missing_species",
        is.na(.data$response) ~ "missing_response",
        TRUE ~ "ready_for_build"
      )
    )

  prepared
}

prepare_species_inventory <- function(vegresults, species_crosswalk) {
  assert_columns(species_crosswalk, c("excel_speciesid", "sql_speciesid"), "species crosswalk")

  vegresults |>
    dplyr::transmute(source_species_code = prepare_na_if_blank(.data$speciesid)) |>
    dplyr::count(.data$source_species_code, name = "source_rows") |>
    dplyr::left_join(
      species_crosswalk |>
        dplyr::transmute(
          source_species_code = prepare_na_if_blank(.data$excel_speciesid),
          sql_speciesid = suppressWarnings(as.integer(.data$sql_speciesid))
        ) |>
        dplyr::filter(!is.na(.data$source_species_code), !is.na(.data$sql_speciesid)) |>
        dplyr::distinct(),
      by = "source_species_code"
    ) |>
    dplyr::group_by(.data$source_species_code, .data$source_rows) |>
    dplyr::summarise(
      match_count = dplyr::n_distinct(.data$sql_speciesid, na.rm = TRUE),
      sql_speciesid = if (match_count == 1L) dplyr::first(stats::na.omit(.data$sql_speciesid)) else NA_integer_,
      .groups = "drop"
    ) |>
    dplyr::mutate(
      review_status = dplyr::case_when(
        .data$match_count == 1L ~ "matched",
        .data$match_count == 0L ~ "review_required_unmatched",
        TRUE ~ "review_required_ambiguous"
      )
    ) |>
    dplyr::arrange(.data$review_status, .data$source_species_code)
}

build_prepare_audit <- function(source_vegresults, prepared_vegresults, areas, area_treatments, species_inventory) {
  explicit_link_keys <- paste(
    area_treatments$area_key,
    area_treatments$source_treatmentid,
    sep = "|"
  )

  row_audit <- prepared_vegresults |>
    dplyr::mutate(
      explicit_area_treatment_found = paste(
        .data$area_key,
        .data$source_treatmentid,
        sep = "|"
      ) %in% explicit_link_keys,
      prepare_status = dplyr::if_else(
        .data$prepare_status == "ready_for_build" & !.data$explicit_area_treatment_found,
        "missing_explicit_area_treatment",
        .data$prepare_status
      )
    ) |>
    dplyr::transmute(
      .data$source_row,
      .data$source_observationid,
      .data$source_treatmentid,
      .data$block,
      .data$replicate,
      .data$area_key,
      .data$area_found,
      .data$explicit_area_treatment_found,
      .data$timepoint_found,
      .data$source_species_code,
      .data$prepare_status
    )

  summary <- tibble::tribble(
    ~check, ~value, ~status,
    "source_vegresult_rows", nrow(source_vegresults), "information",
    "prepared_vegresult_rows", nrow(prepared_vegresults), ifelse(nrow(source_vegresults) == nrow(prepared_vegresults), "pass", "blocker"),
    "ready_for_build_rows", sum(prepared_vegresults$prepare_status == "ready_for_build"), "information",
    "unready_vegresult_rows", sum(row_audit$prepare_status != "ready_for_build"), ifelse(all(row_audit$prepare_status == "ready_for_build"), "pass", "blocker"),
    "rows_missing_explicit_area_treatment", sum(!row_audit$explicit_area_treatment_found), ifelse(all(row_audit$explicit_area_treatment_found), "pass", "blocker"),
    "prepared_block_areas", sum(areas$type == "block"), "information",
    "prepared_child_areas", sum(areas$type != "block"), "information",
    "explicit_area_treatment_links", nrow(area_treatments), "information",
    "species_requiring_review", sum(species_inventory$review_status != "matched"), ifelse(all(species_inventory$review_status == "matched"), "pass", "review")
  )

  list(summary = summary, rows = row_audit)
}

write_prepare_review <- function(prepared, output_dir) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  files <- c(
    areas = "prepared_area.csv",
    area_treatments = "prepared_area_treatment.csv",
    treatments = "prepared_treatment.csv",
    vegresults = "prepared_vegresults.csv",
    species = "species_review.csv",
    row_audit = "vegresult_row_audit.csv",
    summary = "prepare_summary.csv"
  )

  readr::write_csv(prepared$areas, file.path(output_dir, files[["areas"]]), na = "")
  readr::write_csv(prepared$area_treatments, file.path(output_dir, files[["area_treatments"]]), na = "")
  readr::write_csv(prepared$treatments, file.path(output_dir, files[["treatments"]]), na = "")
  readr::write_csv(prepared$vegresults, file.path(output_dir, files[["vegresults"]]), na = "")
  readr::write_csv(prepared$species, file.path(output_dir, files[["species"]]), na = "")
  readr::write_csv(prepared$audit$rows, file.path(output_dir, files[["row_audit"]]), na = "")
  readr::write_csv(prepared$audit$summary, file.path(output_dir, files[["summary"]]), na = "")

  invisible(file.path(output_dir, unname(files)))
}
