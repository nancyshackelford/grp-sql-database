### Reusable build-stage functions for approved prepare outputs
### No function in this file writes to SQL.

validate_prepare_approval <- function(prepare_dir) {
  approval_path <- file.path(prepare_dir, "prepare_approval.csv")
  if (!file.exists(approval_path)) {
    stop("Prepare approval file is missing: ", approval_path, call. = FALSE)
  }

  approval <- readr::read_csv(approval_path, show_col_types = FALSE)
  required <- c("file", "sha256", "approved")
  if (!all(required %in% names(approval)) || !all(approval$approved)) {
    stop("Prepare approval is incomplete.", call. = FALSE)
  }

  current_hash <- vapply(
    file.path(prepare_dir, approval$file),
    digest::digest,
    FUN.VALUE = character(1),
    algo = "sha256",
    file = TRUE
  )

  if (!all(toupper(current_hash) == toupper(approval$sha256))) {
    changed <- approval$file[toupper(current_hash) != toupper(approval$sha256)]
    stop(
      "Approved prepare files changed and require renewed review: ",
      paste(changed, collapse = ", "),
      call. = FALSE
    )
  }

  invisible(approval)
}

build_area_id_crosswalk <- function(prepared_area, first_areaid) {
  prepared_area |>
    dplyr::arrange(.data$siteid, .data$type, .data$source_block, .data$source_replicate) |>
    dplyr::mutate(areaid = seq.int(first_areaid, length.out = dplyr::n())) |>
    dplyr::select("area_key", "areaid")
}

build_area_staging <- function(prepared_area, area_crosswalk) {
  prepared_area |>
    dplyr::left_join(area_crosswalk, by = "area_key") |>
    dplyr::left_join(
      area_crosswalk |>
        dplyr::rename(parent_area_key = .data$area_key, parentid = .data$areaid),
      by = "parent_area_key"
    ) |>
    dplyr::transmute(
      areaid = as.integer(.data$areaid),
      siteid = as.integer(.data$siteid),
      type = .data$type,
      size = .data$size,
      units = .data$units,
      restoration_start_year = .data$restoration_start_year,
      restoration_type = .data$restoration_type,
      disturbance_end_year = .data$disturbance_end_year,
      parentid = as.integer(.data$parentid)
    )
}

build_species_crosswalk <- function(species_review) {
  unresolved <- species_review |>
    dplyr::filter(.data$review_status != "matched" | is.na(.data$sql_speciesid))
  if (nrow(unresolved) > 0L) {
    stop("Species review contains unresolved mappings.", call. = FALSE)
  }

  species_review |>
    dplyr::transmute(
      source_species_code = .data$source_species_code,
      speciesid = as.integer(.data$sql_speciesid)
    )
}

build_veg_result_staging <- function(prepared_vegresults, area_crosswalk, species_crosswalk) {
  staged <- prepared_vegresults |>
    dplyr::left_join(area_crosswalk, by = "area_key") |>
    dplyr::left_join(species_crosswalk, by = "source_species_code")

  if (anyNA(staged$areaid) || anyNA(staged$speciesid)) {
    stop("A prepared vegetation result failed area or species ID resolution.", call. = FALSE)
  }

  staged |>
    dplyr::transmute(
      areaid = as.integer(.data$areaid),
      time_since_restoration = as.integer(.data$time_since_restoration),
      year = .data$year,
      month = .data$month,
      day = .data$day,
      speciesid = as.integer(.data$speciesid),
      cultivarid = NA_integer_,
      individualid = NA_integer_,
      origin = .data$origin,
      level = .data$level,
      response = .data$response,
      metric = .data$metric,
      notes = NA_character_
    )
}

read_secret_bom_safe <- function(path) {
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  if (length(bytes) >= 3L && identical(as.integer(bytes[1:3]), c(239L, 187L, 191L))) {
    bytes <- bytes[-(1:3)]
  }
  while (length(bytes) > 0L && tail(as.integer(bytes), 1L) %in% c(10L, 13L)) {
    bytes <- head(bytes, -1L)
  }
  rawToChar(bytes)
}

read_sql_id_state <- function(con, database, projectid) {
  result <- DBI::dbGetQuery(
    con,
    paste(
      "SELECT",
      "(SELECT COALESCE(MAX(areaid), 0) FROM grp.area) AS max_areaid,",
      "(SELECT COALESCE(MAX(treatmentid), 0) FROM grp.treatment) AS max_treatmentid,",
      "(SELECT COUNT(*) FROM grp.project WHERE database = $1 AND projectid = $2) AS existing_project"
    ),
    params = list(database, as.integer(projectid))
  )
  if (result$existing_project[[1]] != 0L) {
    stop(database, projectid, " already exists in grp.project.", call. = FALSE)
  }
  result
}

build_treatment_staging <- function(prepared_treatment, first_treatmentid) {
  crosswalk <- prepared_treatment |>
    dplyr::arrange(.data$source_treatmentid) |>
    dplyr::mutate(treatmentid = seq.int(first_treatmentid, length.out = dplyr::n())) |>
    dplyr::select("source_treatmentid", "treatmentid")

  staging <- prepared_treatment |>
    dplyr::left_join(crosswalk, by = "source_treatmentid") |>
    dplyr::transmute(
      treatmentid = as.integer(.data$treatmentid),
      year = .data$year,
      month = .data$month,
      day = .data$day,
      weeks_since_restoration = as.integer(.data$weeks_since_restoration),
      other_treatment = .data$other_treatment,
      shelter = NA_character_,
      grading = NA_character_,
      maintenance_fire = NA,
      notes = .data$notes
    )
  list(crosswalk = crosswalk, staging = staging)
}

build_area_treatment_staging <- function(prepared_links, area_crosswalk, treatment_crosswalk, database, projectid) {
  result <- prepared_links |>
    dplyr::left_join(area_crosswalk, by = "area_key") |>
    dplyr::left_join(treatment_crosswalk, by = "source_treatmentid")
  if (anyNA(result$areaid) || anyNA(result$treatmentid)) {
    stop("An area-treatment link failed ID resolution.", call. = FALSE)
  }
  result |>
    dplyr::transmute(
      database = database,
      projectid = as.integer(projectid),
      areaid = as.integer(.data$areaid),
      treatmentid = as.integer(.data$treatmentid)
    ) |>
    dplyr::distinct()
}
