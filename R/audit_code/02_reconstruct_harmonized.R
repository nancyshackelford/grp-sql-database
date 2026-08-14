# Reconstruct the project data as closely as possible to the existing GAZP
# harmonized Excel format while retaining Supabase identifiers for auditing.
#
# AUDIT STATUS AFTER REVIEW OF SNAPSHOT 2026-08-13: The first reconstruction
# completed successfully, but two output rules require revision in a later audit
# iteration; they are documented here and are not yet implemented below. First,
# site classifications are not lost: grp.site_classification stores the USDA
# hierarchy for each site, so reconstruction should join the classification
# vocabulary and return USDA.class, USDA.subclass, and USDA.subsubclass in the
# familiar harmonized columns. Second, study$timepoints should be calculated as
# the maximum number of distinct monitoring points found within any single
# treatment in the project, rather than as the project-wide number of distinct
# tsr values. Review of the ambiguous reverse species mappings found that only
# GAZP5 Art_tri3 required correction in the central taxonomy. That correction
# was completed and verified on 2026-08-14: Artemisia tridentata subsp.
# tridentata now has canonical code Art_tri_sub_tri and speciesid 7171; 462
# veg_result rows and 177 seeding rows were reassigned, and the global repository
# species crosswalk now maps Art_tri3 to that record. The
# remaining ambiguity represents source-level historical or regional concepts,
# not errors in the accepted Supabase taxonomy. Those distinctions should be
# preserved in project-specific crosswalks produced by import and consumed by
# reconstruction. A standalone post-import GAZP5 species crosswalk is therefore
# required. In particular, Pse_rup and Pse_rup1 share a Supabase speciesid but
# remain recoverable from their distinct seeding rates (and units); the GAZP5
# crosswalk should record that contextual reverse rule. Reconstruction should
# apply a project-specific contextual rule before a simple speciesid reversal,
# and should retain every Supabase ID used in the match.
#
# Implemented workflow:
#   A. Load and validate the selected raw Supabase snapshot.
#   B. Load and validate the repository project crosswalks.
#   C. Construct and validate reusable source-to-Supabase mapping objects.
#   D. Reconstruct study, site, and reference sheets.
#   E. Reconstruct treatment and timepoint sheets.
#   F. Reconstruct treatment-rate sheets.
#   G. Reconstruct vegetation-results sheets.
#   H. Write project workbooks in harmonized sheet/column order, followed by
#      extra supabase_* identifiers and reconstruction-status fields.
#
# The reconstruction is Supabase-first. Original Excel workbooks define the
# target shape but are not used to fill reconstructed values. Information not
# retained by Supabase remains missing and is identified by status fields.

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
  library(purrr)
  library(tibble)
  library(tidyr)
})

source("R/audit_code/00_audit_config.R")


# ---- Shared validation helpers -----------------------------------------

stop_with_values <- function(message, values) {
  stop(
    message,
    paste(values, collapse = ", "),
    call. = FALSE
  )
}


require_file <- function(path, description) {
  if (!file.exists(path)) {
    stop(description, " was not found: ", path, call. = FALSE)
  }

  invisible(path)
}


sha256_file <- function(path) {
  if (!requireNamespace("digest", quietly = TRUE)) {
    stop("Package 'digest' is required for hash validation.", call. = FALSE)
  }

  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}


assert_unique <- function(data, keys, object_name) {
  missing_keys <- setdiff(keys, names(data))

  if (length(missing_keys) > 0L) {
    stop_with_values(
      paste0(object_name, " is missing key columns: "),
      missing_keys
    )
  }

  duplicates <- data |>
    count(across(all_of(keys)), name = ".audit_n") |>
    filter(.data$.audit_n > 1L)

  if (nrow(duplicates) > 0L) {
    stop(
      object_name,
      " is not unique at grain: ",
      paste(keys, collapse = " + "),
      ". Duplicate key groups: ",
      nrow(duplicates),
      call. = FALSE
    )
  }

  invisible(TRUE)
}


assert_no_missing <- function(data, columns, object_name) {
  missing_columns <- setdiff(columns, names(data))

  if (length(missing_columns) > 0L) {
    stop_with_values(
      paste0(object_name, " is missing required columns: "),
      missing_columns
    )
  }

  missing_counts <- purrr::map_int(
    columns,
    ~ sum(is.na(data[[.x]]) | trimws(as.character(data[[.x]])) == "")
  )

  bad_columns <- columns[missing_counts > 0L]

  if (length(bad_columns) > 0L) {
    details <- paste0(
      bad_columns,
      "=",
      missing_counts[missing_counts > 0L]
    )
    stop_with_values(
      paste0(object_name, " contains missing required values: "),
      details
    )
  }

  invisible(TRUE)
}


# ---- A. Load and validate the raw snapshot -----------------------------

snapshot_paths <- function(config) {
  snapshot_dir <- file.path(
    config$paths$raw_supabase_root,
    config$active_snapshot
  )

  list(
    directory = snapshot_dir,
    manifest = file.path(snapshot_dir, "export_manifest.csv"),
    columns = file.path(snapshot_dir, "database_columns.csv")
  )
}


validate_manifest_scope <- function(manifest, config) {
  required_columns <- c(
    "schema",
    "source_database",
    "projectids",
    "exported_at",
    "table",
    "file",
    "row_count",
    "column_count",
    "sha256"
  )

  missing_columns <- setdiff(required_columns, names(manifest))
  if (length(missing_columns) > 0L) {
    stop_with_values("Manifest is missing columns: ", missing_columns)
  }

  assert_unique(manifest, "table", "export manifest")

  if (!identical(unique(manifest$schema), config$schema)) {
    stop("Manifest schema does not match audit_config$schema.", call. = FALSE)
  }

  if (!identical(
    unique(manifest$source_database),
    config$source_database
  )) {
    stop(
      "Manifest source_database does not match the configured database.",
      call. = FALSE
    )
  }

  configured_projects <- sort(as.integer(config$projectids))
  manifest_project_strings <- unique(manifest$projectids)

  if (length(manifest_project_strings) != 1L) {
    stop("Manifest contains inconsistent project scopes.", call. = FALSE)
  }

  manifest_projects <- strsplit(
    manifest_project_strings,
    ";",
    fixed = TRUE
  )[[1]] |>
    as.integer() |>
    sort()

  if (!identical(manifest_projects, configured_projects)) {
    stop("Manifest project IDs do not match the configured projects.", call. = FALSE)
  }

  missing_tables <- setdiff(config$export_table_names, manifest$table)
  unexpected_tables <- setdiff(manifest$table, config$export_table_names)

  if (length(missing_tables) > 0L) {
    stop_with_values("Manifest is missing configured tables: ", missing_tables)
  }

  if (length(unexpected_tables) > 0L) {
    stop_with_values(
      "Manifest contains unexpected tables: ",
      unexpected_tables
    )
  }

  invisible(TRUE)
}


validate_snapshot_files <- function(manifest, snapshot_dir) {
  purrr::pwalk(manifest, function(file, sha256, table, ...) {
    path <- file.path(snapshot_dir, file)
    require_file(path, paste0("Snapshot file for grp.", table))

    actual_hash <- sha256_file(path)
    if (!identical(tolower(actual_hash), tolower(sha256))) {
      stop(
        "SHA-256 mismatch for ",
        file,
        ". The raw snapshot file has changed since export.",
        call. = FALSE
      )
    }
  })

  invisible(TRUE)
}


postgres_collector <- function(data_type, udt_name) {
  if (data_type %in% c("smallint", "integer")) {
    return(readr::col_integer())
  }

  if (data_type == "bigint") {
    # R integers are limited to 32 bits. Reading bigint as double preserves
    # exact integer values safely within this database's current ID range.
    return(readr::col_double())
  }

  if (data_type %in% c("numeric", "real", "double precision")) {
    return(readr::col_double())
  }

  if (data_type == "boolean") {
    return(readr::col_logical())
  }

  if (data_type == "date") {
    return(readr::col_date())
  }

  if (grepl("timestamp", data_type, fixed = TRUE)) {
    return(readr::col_datetime())
  }

  if (udt_name %in% c("int2", "int4")) {
    return(readr::col_integer())
  }

  readr::col_character()
}


table_col_types <- function(columns, table_name) {
  table_columns <- columns |>
    filter(.data$table_name == .env$table_name) |>
    arrange(.data$ordinal_position)

  if (nrow(table_columns) == 0L) {
    stop("No database metadata found for grp.", table_name, call. = FALSE)
  }

  collectors <- purrr::map2(
    table_columns$data_type,
    table_columns$udt_name,
    postgres_collector
  )
  names(collectors) <- table_columns$column_name

  do.call(
    readr::cols,
    c(list(.default = readr::col_character()), collectors)
  )
}


load_raw_tables <- function(manifest, columns, snapshot_dir) {
  raw <- purrr::map2(
    manifest$file,
    manifest$table,
    function(file, table_name) {
      path <- file.path(snapshot_dir, file)
      data <- readr::read_csv(
        path,
        col_types = table_col_types(columns, table_name),
        na = "",
        progress = FALSE,
        show_col_types = FALSE
      )

      manifest_row <- manifest |>
        filter(.data$table == .env$table_name)

      if (nrow(data) != manifest_row$row_count) {
        stop("Row-count mismatch while reading ", file, call. = FALSE)
      }

      if (ncol(data) != manifest_row$column_count) {
        stop("Column-count mismatch while reading ", file, call. = FALSE)
      }

      data
    }
  )

  names(raw) <- manifest$table
  raw
}


load_validated_snapshot <- function(config) {
  paths <- snapshot_paths(config)
  require_file(paths$manifest, "Export manifest")
  require_file(paths$columns, "Database-column metadata")

  manifest <- readr::read_csv(
    paths$manifest,
    col_types = readr::cols(
      .default = readr::col_character(),
      row_count = readr::col_integer(),
      column_count = readr::col_integer()
    ),
    progress = FALSE,
    show_col_types = FALSE
  )

  columns <- readr::read_csv(
    paths$columns,
    col_types = readr::cols(
      .default = readr::col_character(),
      ordinal_position = readr::col_integer()
    ),
    progress = FALSE,
    show_col_types = FALSE
  )

  validate_manifest_scope(manifest, config)
  validate_snapshot_files(manifest, paths$directory)

  raw <- load_raw_tables(manifest, columns, paths$directory)

  list(
    snapshot_name = config$active_snapshot,
    snapshot_dir = paths$directory,
    manifest = manifest,
    database_columns = columns,
    raw = raw
  )
}


# ---- B. Load and validate repository crosswalks ------------------------

crosswalk_required_columns <- c(
  "database",
  "projectid",
  "object_type",
  "source_treatmentid",
  "block",
  "replicate",
  "areaid",
  "treatmentid",
  "source_trt_tsr"
)


read_project_crosswalk <- function(path, project_code, expected_projectid) {
  require_file(path, paste0(project_code, " project crosswalk"))

  crosswalk <- readr::read_csv(
    path,
    col_types = readr::cols(
      database = readr::col_character(),
      projectid = readr::col_integer(),
      object_type = readr::col_character(),
      source_treatmentid = readr::col_character(),
      block = readr::col_character(),
      replicate = readr::col_character(),
      areaid = readr::col_double(),
      treatmentid = readr::col_integer(),
      source_trt_tsr = readr::col_integer()
    ),
    na = "",
    progress = FALSE,
    show_col_types = FALSE
  )

  if (!identical(names(crosswalk), crosswalk_required_columns)) {
    stop(
      project_code,
      " crosswalk columns or column order differ from the expected format.",
      call. = FALSE
    )
  }

  if (!identical(unique(crosswalk$database), "GAZP")) {
    stop(project_code, " crosswalk database is not GAZP.", call. = FALSE)
  }

  if (!identical(unique(crosswalk$projectid), expected_projectid)) {
    stop(project_code, " crosswalk projectid is incorrect.", call. = FALSE)
  }

  assert_no_missing(
    crosswalk,
    c(
      "database",
      "projectid",
      "object_type",
      "source_treatmentid",
      "areaid",
      "treatmentid",
      "source_trt_tsr"
    ),
    paste0(project_code, " crosswalk")
  )
  assert_unique(crosswalk, names(crosswalk), paste0(project_code, " crosswalk"))

  crosswalk |>
    mutate(project_code = project_code, .after = "projectid")
}


load_validated_crosswalks <- function(config, raw) {
  expected_names <- paste0(config$source_database, config$projectids)

  if (!identical(names(config$project_crosswalks), expected_names)) {
    stop(
      "Configured project crosswalk names do not match configured projects.",
      call. = FALSE
    )
  }

  crosswalks <- purrr::map2(
    config$project_crosswalks,
    as.integer(config$projectids),
    ~ read_project_crosswalk(.x, basename(dirname(.x)), .y)
  )
  names(crosswalks) <- expected_names

  combined <- bind_rows(crosswalks)

  area_projects <- combined |>
    distinct(.data$projectid, .data$areaid) |>
    count(.data$areaid, name = ".project_count") |>
    filter(.data$.project_count > 1L)

  treatment_projects <- combined |>
    distinct(.data$projectid, .data$treatmentid) |>
    count(.data$treatmentid, name = ".project_count") |>
    filter(.data$.project_count > 1L)

  if (nrow(area_projects) > 0L) {
    stop("Cross-project areaid collisions found in crosswalks.", call. = FALSE)
  }

  if (nrow(treatment_projects) > 0L) {
    stop(
      "Cross-project treatmentid collisions found in crosswalks.",
      call. = FALSE
    )
  }

  missing_areaids <- setdiff(unique(combined$areaid), raw$area$areaid)
  missing_treatmentids <- setdiff(
    unique(combined$treatmentid),
    raw$treatment$treatmentid
  )

  if (length(missing_areaids) > 0L) {
    stop_with_values(
      "Crosswalk areaids absent from raw Supabase snapshot: ",
      missing_areaids
    )
  }

  if (length(missing_treatmentids) > 0L) {
    stop_with_values(
      "Crosswalk treatmentids absent from raw Supabase snapshot: ",
      missing_treatmentids
    )
  }

  list(by_project = crosswalks, combined = combined)
}


# ---- C. Construct and validate mapping objects -------------------------

construct_mapping_objects <- function(crosswalks, raw, config) {
  combined <- crosswalks$combined

  project_map <- tibble::tibble(
    database = config$source_database,
    projectid = as.integer(config$projectids),
    project_code = paste0(config$source_database, config$projectids)
  )
  assert_unique(project_map, c("database", "projectid"), "project map")

  area_map <- combined |>
    select(
      "database",
      "projectid",
      "project_code",
      "areaid",
      "source_treatmentid",
      "block",
      "replicate",
      "object_type"
    ) |>
    distinct()
  assert_unique(
    area_map,
    c("projectid", "areaid"),
    "area/source-plot map"
  )

  treatment_map <- combined |>
    transmute(
      database = .data$database,
      projectid = .data$projectid,
      project_code = .data$project_code,
      supabase_treatmentid = .data$treatmentid,
      source_treatmentid = .data$source_treatmentid,
      source_trt_tsr = .data$source_trt_tsr
    ) |>
    distinct()
  assert_unique(
    treatment_map,
    c("projectid", "supabase_treatmentid"),
    "treatment map"
  )

  area_treatment_map <- combined |>
    transmute(
      database = .data$database,
      projectid = .data$projectid,
      project_code = .data$project_code,
      areaid = .data$areaid,
      supabase_treatmentid = .data$treatmentid,
      source_treatmentid = .data$source_treatmentid,
      block = .data$block,
      replicate = .data$replicate,
      source_trt_tsr = .data$source_trt_tsr
    ) |>
    distinct()
  assert_unique(
    area_treatment_map,
    c("projectid", "areaid", "supabase_treatmentid"),
    "area-treatment map"
  )

  source_timepoint_map <- treatment_map |>
    select(
      "database",
      "projectid",
      "project_code",
      "source_treatmentid",
      "source_trt_tsr",
      "supabase_treatmentid"
    )
  assert_unique(
    source_timepoint_map,
    c("projectid", "source_treatmentid", "source_trt_tsr"),
    "source timepoint map"
  )

  raw_links <- raw$area_treatment |>
    transmute(
      database = as.character(.data$database),
      projectid = as.integer(.data$projectid),
      areaid = as.double(.data$areaid),
      supabase_treatmentid = as.integer(.data$treatmentid)
    ) |>
    distinct()

  mapped_links <- area_treatment_map |>
    select(
      "database",
      "projectid",
      "areaid",
      "supabase_treatmentid"
    ) |>
    distinct()

  raw_links_without_crosswalk <- anti_join(
    raw_links,
    mapped_links,
    by = c("database", "projectid", "areaid", "supabase_treatmentid")
  )
  crosswalk_links_without_raw <- anti_join(
    mapped_links,
    raw_links,
    by = c("database", "projectid", "areaid", "supabase_treatmentid")
  )

  if (nrow(raw_links_without_crosswalk) > 0L) {
    stop(
      "Raw Supabase area-treatment relationships missing from crosswalk: ",
      nrow(raw_links_without_crosswalk),
      call. = FALSE
    )
  }

  if (nrow(crosswalk_links_without_raw) > 0L) {
    stop(
      "Crosswalk area-treatment relationships missing from raw Supabase: ",
      nrow(crosswalk_links_without_raw),
      call. = FALSE
    )
  }

  list(
    project = project_map,
    area = area_map,
    treatment = treatment_map,
    area_treatment = area_treatment_map,
    timepoint = source_timepoint_map
  )
}


mapping_validation_summary <- function(mappings) {
  mappings$area |>
    count(.data$project_code, name = "areas") |>
    left_join(
      mappings$treatment |>
        count(.data$project_code, name = "treatments"),
      by = "project_code"
    ) |>
    left_join(
      mappings$area_treatment |>
        count(.data$project_code, name = "area_treatment_links"),
      by = "project_code"
    ) |>
    mutate(crosswalk_status = "PASS") |>
    arrange(.data$project_code)
}


prepare_audit_inputs <- function(config = audit_config) {
  message("A. Loading and validating snapshot ", config$active_snapshot, " ...")
  snapshot <- load_validated_snapshot(config)

  message("B. Loading and validating repository crosswalks ...")
  crosswalks <- load_validated_crosswalks(config, snapshot$raw)

  message("C. Constructing and validating mapping objects ...")
  mappings <- construct_mapping_objects(crosswalks, snapshot$raw, config)
  validation_summary <- mapping_validation_summary(mappings)

  message("\nSnapshot: ", snapshot$snapshot_name)
  message("Raw tables verified: ", nrow(snapshot$manifest))
  message("File hashes verified: ", nrow(snapshot$manifest))
  print(validation_summary)

  message(
    "\nParts A-C passed. Validated objects are available in `audit_inputs`; ",
    "continuing to reconstruction."
  )

  list(
    config = config,
    snapshot = snapshot,
    raw = snapshot$raw,
    crosswalks = crosswalks,
    mappings = mappings,
    validation = list(mapping_summary = validation_summary)
  )
}


audit_inputs <- prepare_audit_inputs()


# ---- D. Reconstruct study, site, and reference sheets ------------------

collapse_values <- function(x, separator = " | ") {
  values <- unique(trimws(as.character(x[!is.na(x)])))
  values <- values[nzchar(values)]
  if (length(values) == 0L) NA_character_ else paste(values, collapse = separator)
}


collapse_ids <- function(x) {
  values <- sort(unique(x[!is.na(x)]))
  if (length(values) == 0L) NA_character_ else paste(values, collapse = " | ")
}


add_missing_columns <- function(data, columns) {
  for (column in setdiff(columns, names(data))) data[[column]] <- NA
  data
}


harmonized_headers <- list(
  study = c(
    "DB", "projectid", "studytype", "contributor", "email", "continent",
    "country", "state", "vegmetric", "spatialmetric", "surveyunit",
    "tsrfirst", "tsrlast", "timepoints", "community", "refdata",
    "availability", "notes"
  ),
  site = c(
    "DB", "siteid", "projectid", "sitename", "latitude", "longitude",
    "refecosystem", "USDA.class", "USDA.subclass", "USDA.subsubclass",
    "landcover", "growingseasonstart", "growingseasonend", "sand", "silt",
    "clay", "soildescription", "soildepth", "elevation", "aspect", "slope",
    "precipc", "tempc", "aridity", "temp", "drange", "iso", "tseason",
    "mtwarm", "mtcold", "trange", "twetq", "tdryq", "twarmq", "tcoldq",
    "precip", "pwet", "pdry", "pseason", "pwetq", "pdryq", "pwarmq",
    "pcoldq", "disturbance", "minetype", "ogtype", "invasivespe",
    "invasiveform"
  ),
  treatments = c(
    "DB", "treatmentid", "siteid", "restorationtype", "tsr_start_year",
    "trt_year", "trt_tsr", "disturbanceendyear", "treatmentmonth",
    "treatmentday", "othertreatments", "treatment_category",
    "treatment_type", "treatment_amount", "treatment_units"
  ),
  timepoints = c("DB", "treatmentid", "tsr", "year", "month", "day"),
  cultivars = c(
    "speciesid", "cultivarid", "cultivar", "cultivarorigin", "seedlat",
    "seedlong"
  ),
  trtrates = c(
    "DB", "treatmentid", "speciesid", "cultivarid", "trt", "mix_trt",
    "treated_richness", "treatment_type", "trt_year", "rate", "unit",
    "viability", "seedpretreatment", "seed_origin", "source", "seeddist"
  ),
  refs = c(
    "DB", "projectid", "papernumber", "author", "pubyear", "pubtitle",
    "pubjournal", "pubDOI", "pubURL", "pubcorrespondingauthoremail",
    "datadateofdownload", "citationofdatasource",
    "creativecommonsliscence", "conditionsforuseandrepublishing"
  ),
  vegresults = c(
    "id", "DB", "treatmentid", "year", "tsr", "block", "replicate",
    "speciesid", "speciesorigin", "response", "responselevel",
    "responsemetric", "measurementscale", "measurementmetric"
  )
)


project_rows <- function(data, projectid) {
  data |> filter(.data$projectid == .env$projectid)
}


reconstruct_study <- function(projectid, raw, mappings) {
  project <- project_rows(raw$project, projectid)
  contributors <- project_rows(raw$project_contributor, projectid) |>
    left_join(raw$author_contributor, by = "author_contributorid")
  locations <- project_rows(raw$project_location, projectid) |>
    left_join(raw$location, by = "locationid")
  metrics <- project_rows(raw$project_vegmetric, projectid)
  accessibility <- project_rows(raw$project_data_accessibility, projectid)
  project_areas <- mappings$area |> filter(.data$projectid == .env$projectid)
  project_results <- raw$veg_result |>
    semi_join(project_areas, by = "areaid")
  areas <- raw$area |> semi_join(project_areas, by = "areaid")

  tibble(
    DB = project$database[[1]],
    projectid = projectid,
    studytype = project$type[[1]],
    contributor = collapse_values(paste(
      contributors$given_name,
      contributors$surname
    )),
    email = collapse_values(contributors$email),
    continent = collapse_values(locations$continent),
    country = collapse_values(locations$country),
    state = collapse_values(locations$state),
    vegmetric = collapse_values(metrics$type),
    spatialmetric = collapse_values(areas$type),
    surveyunit = if (length(unique(areas$size[!is.na(areas$size)])) == 1L) {
      unique(areas$size[!is.na(areas$size)])
    } else NA_real_,
    tsrfirst = suppressWarnings(min(
      project_results$time_since_restoration,
      na.rm = TRUE
    )),
    tsrlast = suppressWarnings(max(
      project_results$time_since_restoration,
      na.rm = TRUE
    )),
    timepoints = n_distinct(
      project_results$time_since_restoration,
      na.rm = TRUE
    ),
    community = project$community[[1]],
    refdata = project$reference[[1]],
    availability = collapse_values(accessibility$availability),
    notes = project$notes[[1]],
    supabase_author_contributorids = collapse_ids(
      contributors$author_contributorid
    ),
    supabase_locationids = collapse_ids(locations$locationid),
    reconstruction_status = "reconstructed_from_supabase"
  ) |>
    mutate(
      tsrfirst = ifelse(is.infinite(.data$tsrfirst), NA, .data$tsrfirst),
      tsrlast = ifelse(is.infinite(.data$tsrlast), NA, .data$tsrlast)
    )
}


site_aggregate <- function(data, value_column, value_name) {
  if (nrow(data) == 0L) {
    out <- tibble(siteid = integer(), value = character())
  } else {
    out <- data |>
      group_by(.data$siteid) |>
      summarise(value = collapse_values(.data[[value_column]]), .groups = "drop")
  }
  names(out)[names(out) == "value"] <- value_name
  out
}


reconstruct_site <- function(projectid, raw) {
  project_sites <- project_rows(raw$project_site, projectid)
  sites <- project_sites |> left_join(raw$site, by = "siteid")
  soil <- raw$site_soil |>
    semi_join(project_sites, by = "siteid") |>
    group_by(.data$siteid) |>
    summarise(
      sand = if (n_distinct(.data$sand, na.rm = TRUE) <= 1L) first(na.omit(.data$sand)) else NA_real_,
      silt = if (n_distinct(.data$silt, na.rm = TRUE) <= 1L) first(na.omit(.data$silt)) else NA_real_,
      clay = if (n_distinct(.data$clay, na.rm = TRUE) <= 1L) first(na.omit(.data$clay)) else NA_real_,
      soildescription = collapse_values(.data$description),
      soildepth = collapse_values(.data$depth),
      supabase_soilids = collapse_ids(.data$soilid),
      .groups = "drop"
    )
  classification <- site_aggregate(
    raw$site_classification |> semi_join(project_sites, by = "siteid"),
    "classificationid",
    "supabase_classificationids"
  )
  disturbance <- site_aggregate(
    raw$site_disturbance |> semi_join(project_sites, by = "siteid"),
    "type",
    "disturbance"
  )
  reference <- site_aggregate(
    raw$site_ref_ecosystem |> semi_join(project_sites, by = "siteid"),
    "description",
    "refecosystem"
  )
  invasive <- raw$site_invasive |>
    semi_join(project_sites, by = "siteid") |>
    left_join(raw$species, by = "speciesid") |>
    group_by(.data$siteid) |>
    summarise(
      invasivespe = collapse_values(.data$species_code),
      supabase_invasive_speciesids = collapse_ids(.data$speciesid),
      .groups = "drop"
    )

  output <- sites |>
    left_join(reference, by = "siteid") |>
    left_join(soil, by = "siteid") |>
    left_join(classification, by = "siteid") |>
    left_join(disturbance, by = "siteid") |>
    left_join(invasive, by = "siteid") |>
    transmute(
      DB = .data$database,
      siteid = .data$siteid,
      projectid = .data$projectid,
      sitename = .data$name,
      latitude = .data$latitude,
      longitude = .data$longitude,
      refecosystem = .data$refecosystem,
      sand = .data$sand,
      silt = .data$silt,
      clay = .data$clay,
      soildescription = .data$soildescription,
      soildepth = .data$soildepth,
      precipc = .data$annual_precip,
      tempc = .data$annual_temp,
      aridity = .data$aridity,
      disturbance = .data$disturbance,
      invasivespe = .data$invasivespe,
      supabase_siteid = .data$siteid,
      supabase_soilids = .data$supabase_soilids,
      supabase_classificationids = .data$supabase_classificationids,
      supabase_invasive_speciesids = .data$supabase_invasive_speciesids,
      reconstruction_status = paste0(
        "partial; environmental fields not stored in Supabase"
      )
    )

  output <- add_missing_columns(output, harmonized_headers$site)
  output |> select(all_of(harmonized_headers$site), everything())
}


reconstruct_refs <- function(projectid, raw) {
  project_papers <- project_rows(raw$project_paper, projectid)
  if (nrow(project_papers) == 0L) {
    return(as_tibble(setNames(
      replicate(length(harmonized_headers$refs), logical(0), simplify = FALSE),
      harmonized_headers$refs
    )))
  }

  accessibility <- project_rows(raw$project_data_accessibility, projectid)
  author_summary <- raw$paper_author |>
    semi_join(project_papers, by = "paperid") |>
    left_join(raw$author_contributor, by = "author_contributorid") |>
    group_by(.data$paperid) |>
    summarise(
      author = collapse_values(paste(.data$given_name, .data$surname)),
      pubcorrespondingauthoremail = collapse_values(
        .data$email[.data$is_corresponding_author %in% TRUE]
      ),
      supabase_author_contributorids = collapse_ids(.data$author_contributorid),
      .groups = "drop"
    )

  project_papers |>
    left_join(raw$paper, by = "paperid") |>
    left_join(author_summary, by = "paperid") |>
    transmute(
      DB = .data$database,
      projectid = .data$projectid,
      papernumber = row_number(),
      author = .data$author,
      pubyear = .data$publication_year,
      pubtitle = .data$publication_title,
      pubjournal = .data$publication_journal,
      pubDOI = .data$publication_doi,
      pubURL = .data$publication_url,
      pubcorrespondingauthoremail = .data$pubcorrespondingauthoremail,
      datadateofdownload = NA_character_,
      citationofdatasource = collapse_values(accessibility$data_citation),
      creativecommonsliscence = collapse_values(
        accessibility$creativecommons_license
      ),
      conditionsforuseandrepublishing = collapse_values(
        accessibility$use_conditions
      ),
      supabase_paperid = .data$paperid,
      supabase_author_contributorids = .data$supabase_author_contributorids,
      reconstruction_status = "partial; full source author string not stored"
    )
}


# ---- E. Reconstruct treatment and timepoint sheets ---------------------

treatment_detail_spec <- tribble(
  ~table,                    ~category,
  "treatment_application",  "application method",
  "treatment_cover_crop",   "cover crop",
  "treatment_erosion",      "erosion control",
  "treatment_fertilization","fertilization",
  "treatment_grazer",       "grazing",
  "treatment_herbicide",    "herbicide",
  "treatment_invasion",     "invasion control",
  "treatment_irrigation",   "irrigation",
  "treatment_material",     "bed material",
  "treatment_medium",       "growth medium",
  "treatment_mowing",       "mowing",
  "treatment_prep",         "bed prep"
)


detail_to_harmonized <- function(data, table_name, category) {
  if (nrow(data) == 0L) return(tibble())
  id_columns <- setdiff(names(data)[grepl("id$", names(data))], "treatmentid")
  detail_id <- if (length(id_columns) == 0L) {
    rep(NA_character_, nrow(data))
  } else {
    apply(data[id_columns], 1, collapse_ids)
  }

  type <- if ("type" %in% names(data)) data$type else NA_character_
  if (table_name == "treatment_cover_crop") type <- "cover crop"
  if (table_name == "treatment_herbicide" && "chemical" %in% names(data)) {
    type <- ifelse(is.na(data$chemical), type, data$chemical)
  }
  if (table_name == "treatment_medium" && "type" %in% names(data)) {
    type <- data$type
  }

  tibble(
    supabase_treatmentid = data$treatmentid,
    treatment_category = category,
    treatment_type = as.character(type),
    treatment_amount = as.character(
      if ("amount" %in% names(data)) data$amount else "applied"
    ),
    treatment_units = as.character(
      if ("units" %in% names(data)) data$units else "treatment presence"
    ),
    supabase_treatment_detail_table = table_name,
    supabase_treatment_detail_id = detail_id
  )
}


reconstruct_treatments <- function(projectid, raw, mappings) {
  treatment_map <- mappings$treatment |>
    filter(.data$projectid == .env$projectid)
  project_links <- mappings$area_treatment |>
    filter(.data$projectid == .env$projectid)
  area_sites <- raw$area |>
    select("areaid", "siteid", "restoration_type", "restoration_start_year",
           "disturbance_end_year")

  core <- treatment_map |>
    left_join(raw$treatment, by = c("supabase_treatmentid" = "treatmentid")) |>
    left_join(
      project_links |>
        left_join(area_sites, by = "areaid") |>
        group_by(.data$supabase_treatmentid) |>
        summarise(
          siteid = if (n_distinct(.data$siteid, na.rm = TRUE) == 1L) first(na.omit(.data$siteid)) else NA_integer_,
          restorationtype = collapse_values(.data$restoration_type),
          tsr_start_year = if (n_distinct(.data$restoration_start_year, na.rm = TRUE) == 1L) first(na.omit(.data$restoration_start_year)) else NA_real_,
          disturbanceendyear = if (n_distinct(.data$disturbance_end_year, na.rm = TRUE) == 1L) first(na.omit(.data$disturbance_end_year)) else NA_real_,
          supabase_areaids = collapse_ids(.data$areaid),
          .groups = "drop"
        ),
      by = "supabase_treatmentid"
    )

  details <- purrr::map2_dfr(
    treatment_detail_spec$table,
    treatment_detail_spec$category,
    ~ detail_to_harmonized(
      raw[[.x]] |> semi_join(treatment_map, by = c("treatmentid" = "supabase_treatmentid")),
      .x,
      .y
    )
  )

  # Treatment fields stored directly on grp.treatment are represented as
  # additional harmonized detail rows where populated.
  direct_details <- bind_rows(
    core |> filter(!is.na(.data$shelter)) |>
      transmute(supabase_treatmentid, treatment_category = "shelter",
                treatment_type = .data$shelter, treatment_amount = "applied",
                treatment_units = "treatment presence",
                supabase_treatment_detail_table = "treatment",
                supabase_treatment_detail_id = NA_character_),
    core |> filter(!is.na(.data$grading)) |>
      transmute(supabase_treatmentid, treatment_category = "grading",
                treatment_type = .data$grading, treatment_amount = "applied",
                treatment_units = "treatment presence",
                supabase_treatment_detail_table = "treatment",
                supabase_treatment_detail_id = NA_character_),
    core |> filter(.data$maintenance_fire %in% TRUE) |>
      transmute(supabase_treatmentid, treatment_category = "fire",
                treatment_type = "maintenance fire", treatment_amount = "applied",
                treatment_units = "treatment presence",
                supabase_treatment_detail_table = "treatment",
                supabase_treatment_detail_id = NA_character_)
  )
  details <- bind_rows(details, direct_details)

  no_detail <- anti_join(
    core |> select("supabase_treatmentid"),
    details |> distinct(.data$supabase_treatmentid),
    by = "supabase_treatmentid"
  ) |>
    mutate(
      treatment_category = NA_character_, treatment_type = NA_character_,
      treatment_amount = NA_character_, treatment_units = NA_character_,
      supabase_treatment_detail_table = NA_character_,
      supabase_treatment_detail_id = NA_character_
    )

  bind_rows(details, no_detail) |>
    left_join(core, by = "supabase_treatmentid") |>
    transmute(
      DB = .data$database,
      treatmentid = .data$source_treatmentid,
      siteid = .data$siteid,
      restorationtype = .data$restorationtype,
      tsr_start_year = .data$tsr_start_year,
      trt_year = .data$year,
      trt_tsr = .data$source_trt_tsr,
      disturbanceendyear = .data$disturbanceendyear,
      treatmentmonth = .data$month,
      treatmentday = .data$day,
      othertreatments = .data$other_treatment,
      treatment_category = .data$treatment_category,
      treatment_type = .data$treatment_type,
      treatment_amount = .data$treatment_amount,
      treatment_units = .data$treatment_units,
      supabase_treatmentid = .data$supabase_treatmentid,
      supabase_areaids = .data$supabase_areaids,
      supabase_treatment_detail_table = .data$supabase_treatment_detail_table,
      supabase_treatment_detail_id = .data$supabase_treatment_detail_id,
      reconstruction_status = "reverse_mapped_from_normalized_treatment_tables"
    ) |>
    arrange(.data$treatmentid, .data$trt_tsr, .data$treatment_category,
            .data$treatment_type)
}


reconstruct_timepoints <- function(projectid, raw, mappings) {
  area_map <- mappings$area |> filter(.data$projectid == .env$projectid)
  results <- raw$veg_result |>
    inner_join(area_map, by = "areaid")

  conflicts <- results |>
    distinct(.data$source_treatmentid, .data$time_since_restoration,
             .data$year, .data$month, .data$day) |>
    count(.data$source_treatmentid, .data$time_since_restoration) |>
    filter(.data$n > 1L)
  if (nrow(conflicts) > 0L) {
    stop("Conflicting reconstructed timepoints for GAZP", projectid, call. = FALSE)
  }

  results |>
    group_by(.data$source_treatmentid, .data$time_since_restoration,
             .data$year, .data$month, .data$day) |>
    summarise(
      supabase_areaids = collapse_ids(.data$areaid),
      supabase_veg_resultids = collapse_ids(.data$veg_resultid),
      .groups = "drop"
    ) |>
    transmute(
      DB = "GAZP", treatmentid = .data$source_treatmentid,
      tsr = .data$time_since_restoration, year = .data$year,
      month = .data$month, day = .data$day,
      supabase_areaids, supabase_veg_resultids,
      reconstruction_status = "reconstructed_from_veg_result_dates"
    ) |>
    arrange(.data$treatmentid, .data$tsr)
}


# ---- F. Reconstruct treatment-rate sheets ------------------------------

load_species_crosswalk <- function() {
  path <- "crosswalk_tables/20260605_sp_crosswalk.csv"
  require_file(path, "Species crosswalk")
  read_csv(path, show_col_types = FALSE, progress = FALSE, na = "NA") |>
    transmute(
      excel_speciesid = as.character(.data$excel_speciesid),
      sql_speciesid = as.integer(.data$sql_speciesid)
    )
}


load_cultivar_crosswalk <- function() {
  path <- "crosswalk_tables/cultivar_crosswalk.csv"
  require_file(path, "Cultivar crosswalk")
  read_csv(path, show_col_types = FALSE, progress = FALSE, na = "NA") |>
    mutate(
      sql_speciesid = as.integer(.data$sql_speciesid),
      sql_cultivarid = as.integer(.data$sql_cultivarid)
    )
}


unique_reverse_species_map <- function(species_crosswalk) {
  species_crosswalk |>
    group_by(.data$sql_speciesid) |>
    summarise(
      source_species_codes = collapse_values(.data$excel_speciesid),
      source_species_code_count = n_distinct(.data$excel_speciesid),
      excel_speciesid = if (source_species_code_count == 1L) first(.data$excel_speciesid) else NA_character_,
      species_mapping_status = if_else(
        source_species_code_count == 1L,
        "unique_reverse_mapping",
        "ambiguous_multiple_legacy_codes"
      ),
      .groups = "drop"
    )
}


reconstruct_trtrates <- function(projectid, raw, mappings, species_map,
                                 cultivar_crosswalk) {
  treatment_map <- mappings$treatment |>
    filter(.data$projectid == .env$projectid)
  project_seedings <- raw$seeding |>
    inner_join(treatment_map, by = c("treatmentid" = "supabase_treatmentid"))
  pretreatments <- raw$seeding_pretreatment |>
    group_by(.data$seedingid) |>
    summarise(seedpretreatment = collapse_values(.data$type), .groups = "drop")
  mix <- raw$seed_mix |>
    select("seed_mixid", "mix_name", "treated_richness")

  cultivar_map <- cultivar_crosswalk |>
    group_by(.data$sql_speciesid, .data$sql_cultivarid) |>
    summarise(
      excel_cultivarids = collapse_values(.data$excel_cultivarid),
      cultivar_code_count = n_distinct(.data$excel_cultivarid),
      excel_cultivarid = if (cultivar_code_count == 1L) first(.data$excel_cultivarid) else NA_integer_,
      cultivar_mapping_status = if_else(
        cultivar_code_count <= 1L,
        "unique_or_not_applicable",
        "ambiguous_multiple_legacy_ids"
      ),
      .groups = "drop"
    )

  project_seedings |>
    left_join(mix, by = "seed_mixid") |>
    left_join(pretreatments, by = "seedingid") |>
    left_join(species_map, by = c("speciesid" = "sql_speciesid")) |>
    left_join(
      cultivar_map,
      by = c("speciesid" = "sql_speciesid", "cultivarid" = "sql_cultivarid")
    ) |>
    transmute(
      DB = .data$database,
      treatmentid = .data$source_treatmentid,
      speciesid = .data$excel_speciesid,
      cultivarid = .data$excel_cultivarid,
      trt = .data$type,
      mix_trt = coalesce(.data$mix, .data$mix_name),
      treated_richness = .data$treated_richness,
      treatment_type = NA_character_,
      trt_year = NA_integer_,
      rate = .data$rate,
      unit = .data$unit,
      viability = .data$viability,
      seedpretreatment = .data$seedpretreatment,
      seed_origin = .data$origin,
      source = .data$source,
      seeddist = .data$seed_distance,
      supabase_seedingid = .data$seedingid,
      supabase_seed_mixid = .data$seed_mixid,
      supabase_treatmentid = .data$treatmentid,
      supabase_speciesid = .data$speciesid,
      supabase_cultivarid = .data$cultivarid,
      source_species_code_candidates = .data$source_species_codes,
      source_cultivarid_candidates = .data$excel_cultivarids,
      species_mapping_status = coalesce(
        .data$species_mapping_status,
        "no_reverse_mapping"
      ),
      cultivar_mapping_status = coalesce(
        .data$cultivar_mapping_status,
        "not_applicable_or_no_reverse_mapping"
      ),
      reconstruction_status = "partial; treatment_type and trt_year not stored in seeding"
    ) |>
    arrange(.data$treatmentid, .data$speciesid, .data$cultivarid)
}


reconstruct_cultivars <- function(projectid, trtrates, raw,
                                  cultivar_crosswalk) {
  used <- trtrates |>
    filter(!is.na(.data$supabase_cultivarid)) |>
    distinct(.data$supabase_speciesid, .data$supabase_cultivarid)
  if (nrow(used) == 0L) {
    return(as_tibble(setNames(
      replicate(length(harmonized_headers$cultivars), logical(0), simplify = FALSE),
      harmonized_headers$cultivars
    )))
  }
  used |>
    left_join(
      cultivar_crosswalk,
      by = c(
        "supabase_speciesid" = "sql_speciesid",
        "supabase_cultivarid" = "sql_cultivarid"
      )
    ) |>
    transmute(
      speciesid = .data$excel_speciesid,
      cultivarid = .data$excel_cultivarid,
      cultivar = .data$excel_cultivar,
      cultivarorigin = .data$excel_cultivarorigin,
      seedlat = .data$excel_seedlat,
      seedlong = .data$excel_seedlong,
      supabase_speciesid = .data$supabase_speciesid,
      supabase_cultivarid = .data$supabase_cultivarid,
      reconstruction_status = coalesce(
        .data$cultivar_match_status,
        "no_reverse_mapping"
      )
    ) |>
    distinct()
}


# ---- G. Reconstruct vegetation-results sheets --------------------------

reconstruct_vegresults <- function(projectid, raw, mappings, species_map) {
  area_map <- mappings$area |> filter(.data$projectid == .env$projectid)
  response_divisor <- case_when(
    projectid == 1L ~ 8,
    projectid == 5L ~ 210.22,
    TRUE ~ 1
  )

  raw$veg_result |>
    inner_join(area_map, by = "areaid") |>
    left_join(raw$area |> select("areaid", "size", "units"), by = "areaid") |>
    left_join(species_map, by = c("speciesid" = "sql_speciesid")) |>
    transmute(
      id = paste0("GAZP_", projectid),
      DB = .data$database,
      treatmentid = .data$source_treatmentid,
      year = .data$year,
      tsr = .data$time_since_restoration,
      block = .data$block,
      replicate = .data$replicate,
      speciesid = .data$excel_speciesid,
      speciesorigin = .data$origin,
      response = .data$response / response_divisor,
      responselevel = .data$level,
      responsemetric = .data$metric,
      measurementscale = .data$size,
      measurementmetric = .data$units,
      supabase_veg_resultid = .data$veg_resultid,
      supabase_areaid = .data$areaid,
      supabase_speciesid = .data$speciesid,
      supabase_cultivarid = .data$cultivarid,
      source_species_code_candidates = .data$source_species_codes,
      species_mapping_status = coalesce(
        .data$species_mapping_status,
        "no_reverse_mapping"
      ),
      response_reverse_factor = response_divisor,
      reconstruction_status = if_else(
        .data$species_mapping_status == "unique_reverse_mapping",
        "reverse_mapped_from_supabase",
        "partial; species code ambiguous or absent"
      )
    ) |>
    arrange(.data$treatmentid, .data$year, .data$tsr, .data$block,
            .data$replicate, .data$speciesid)
}


# ---- H. Write harmonized-style project workbooks -----------------------

order_harmonized_columns <- function(data, sheet_name) {
  data <- add_missing_columns(data, harmonized_headers[[sheet_name]])
  data |> select(all_of(harmonized_headers[[sheet_name]]), everything())
}


build_reconstructed_projects <- function(audit_inputs) {
  raw <- audit_inputs$raw
  mappings <- audit_inputs$mappings
  species_crosswalk <- load_species_crosswalk()
  species_map <- unique_reverse_species_map(species_crosswalk)
  cultivar_crosswalk <- load_cultivar_crosswalk()

  projects <- purrr::map(
    audit_inputs$config$projectids,
    function(projectid) {
      study <- reconstruct_study(projectid, raw, mappings)
      site <- reconstruct_site(projectid, raw)
      treatments <- reconstruct_treatments(projectid, raw, mappings)
      timepoints <- reconstruct_timepoints(projectid, raw, mappings)
      refs <- reconstruct_refs(projectid, raw)
      trtrates <- reconstruct_trtrates(
        projectid, raw, mappings, species_map, cultivar_crosswalk
      )
      cultivars <- reconstruct_cultivars(
        projectid, trtrates, raw, cultivar_crosswalk
      )
      vegresults <- reconstruct_vegresults(
        projectid, raw, mappings, species_map
      )

      sheets <- list(
        study = order_harmonized_columns(study, "study"),
        site = order_harmonized_columns(site, "site"),
        treatments = order_harmonized_columns(treatments, "treatments"),
        timepoints = order_harmonized_columns(timepoints, "timepoints")
      )
      if (projectid == 1L || nrow(cultivars) > 0L) {
        sheets$cultivars <- order_harmonized_columns(cultivars, "cultivars")
      }
      sheets$trtrates <- order_harmonized_columns(trtrates, "trtrates")
      sheets$refs <- order_harmonized_columns(refs, "refs")
      sheets$vegresults <- order_harmonized_columns(vegresults, "vegresults")
      sheets
    }
  )
  names(projects) <- paste0("GAZP", audit_inputs$config$projectids)
  projects
}


write_reconstructed_workbook <- function(sheets, project_code, config) {
  if (!requireNamespace("openxlsx", quietly = TRUE)) {
    stop("Package 'openxlsx' is required to write reconstructed workbooks.",
         call. = FALSE)
  }
  output_dir <- file.path(
    config$paths$reconstructed_root,
    config$active_snapshot
  )
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_file <- file.path(
    output_dir,
    paste0(project_code, "_reconstructed_from_supabase.xlsx")
  )
  if (file.exists(output_file)) {
    stop("Reconstructed workbook already exists: ", output_file, call. = FALSE)
  }

  workbook <- openxlsx::createWorkbook()
  header_style <- openxlsx::createStyle(
    textDecoration = "bold",
    fgFill = "#D9EAF7",
    border = "bottom"
  )
  audit_header_style <- openxlsx::createStyle(
    textDecoration = "bold",
    fgFill = "#FFF2CC",
    border = "bottom"
  )

  purrr::iwalk(sheets, function(data, sheet_name) {
    openxlsx::addWorksheet(workbook, sheet_name)
    openxlsx::writeData(workbook, sheet_name, data, keepNA = FALSE)
    if (ncol(data) > 0L) {
      openxlsx::addStyle(
        workbook, sheet_name, header_style,
        rows = 1, cols = seq_len(ncol(data)), gridExpand = TRUE
      )
      familiar_count <- length(harmonized_headers[[sheet_name]])
      if (ncol(data) > familiar_count) {
        openxlsx::addStyle(
          workbook, sheet_name, audit_header_style,
          rows = 1, cols = (familiar_count + 1L):ncol(data),
          gridExpand = TRUE
        )
      }
      openxlsx::freezePane(workbook, sheet_name, firstRow = TRUE)
      openxlsx::addFilter(workbook, sheet_name, row = 1, cols = seq_len(ncol(data)))
      openxlsx::setColWidths(
        workbook, sheet_name, cols = seq_len(ncol(data)), widths = "auto"
      )
    }
  })
  openxlsx::saveWorkbook(workbook, output_file, overwrite = FALSE)
  output_file
}


reconstructed <- build_reconstructed_projects(audit_inputs)

reconstruction_summary <- purrr::imap_dfr(
  reconstructed,
  function(sheets, project_code) {
    purrr::imap_dfr(sheets, ~ tibble(
      project_code = project_code,
      sheet = .y,
      reconstructed_rows = nrow(.x),
      reconstructed_columns = ncol(.x)
    ))
  }
)

print(reconstruction_summary)

reconstructed_files <- purrr::imap_chr(
  reconstructed,
  ~ write_reconstructed_workbook(.x, .y, audit_inputs$config)
)

message("\nReconstructed workbooks written:")
purrr::walk(reconstructed_files, ~ message("  ", .x))
