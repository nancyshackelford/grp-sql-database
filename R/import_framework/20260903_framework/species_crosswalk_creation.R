# Project-level species crosswalk creation
#
# This helper inventories every species-bearing source currently used by the
# GAZP imports, resolves source values to the accepted GRP species lookup, and
# writes a complete project crosswalk when a non-exact mapping is required.
#
# It also protects against the GAZP5 failure mode in which two distinct source
# taxa map to the same accepted speciesid. For trtrates collisions, contextual
# reverse-mapping rules are generated from accepted speciesid + rate + unit.


normalize_species_value <- function(x) {
  x <- as.character(x)
  x <- stringr::str_squish(x)
  x[x == ""] <- NA_character_
  x
}


species_match_key <- function(x) {
  stringr::str_to_lower(normalize_species_value(x))
}


empty_species_usage <- function() {
  tibble::tibble(
    source_table = character(),
    source_column = character(),
    source_value_type = character(),
    source_value = character(),
    source_match_value = character()
  )
}


collect_project_species_usage <- function(data_list) {
  usage_parts <- list()

  if (!is.null(data_list$trtrates) && "speciesid" %in% names(data_list$trtrates)) {
    usage_parts[[length(usage_parts) + 1L]] <- data_list$trtrates |>
      dplyr::transmute(
        source_table = "trtrates",
        source_column = "speciesid",
        source_value_type = "species_code",
        source_value = normalize_species_value(.data$speciesid)
      )
  }

  if (!is.null(data_list$vegresults) && "speciesid" %in% names(data_list$vegresults)) {
    usage_parts[[length(usage_parts) + 1L]] <- data_list$vegresults |>
      dplyr::transmute(
        source_table = "vegresults",
        source_column = "speciesid",
        source_value_type = "species_code",
        source_value = normalize_species_value(.data$speciesid)
      )
  }

  if (!is.null(data_list$cultivars) && "speciesid" %in% names(data_list$cultivars)) {
    usage_parts[[length(usage_parts) + 1L]] <- data_list$cultivars |>
      dplyr::transmute(
        source_table = "cultivars",
        source_column = "speciesid",
        source_value_type = "species_code",
        source_value = normalize_species_value(.data$speciesid)
      )
  }

  if (!is.null(data_list$site) && "invasivespe" %in% names(data_list$site)) {
    usage_parts[[length(usage_parts) + 1L]] <- data_list$site |>
      dplyr::transmute(
        source_table = "site",
        source_column = "invasivespe",
        source_value_type = "scientific_name",
        source_value = normalize_species_value(.data$invasivespe)
      ) |>
      dplyr::filter(!is.na(.data$source_value)) |>
      tidyr::separate_rows(source_value, sep = "\\|") |>
      dplyr::mutate(source_value = normalize_species_value(.data$source_value))
  }

  if (length(usage_parts) == 0L) {
    return(empty_species_usage())
  }

  dplyr::bind_rows(usage_parts) |>
    dplyr::filter(!is.na(.data$source_value)) |>
    dplyr::mutate(
      source_match_value = species_match_key(.data$source_value)
    )
}


prepare_project_species_overrides <- function(overrides) {
  required_columns <- c(
    "source_table",
    "source_column",
    "source_value",
    "accepted_species_code",
    "accepted_species_name",
    "mapping_status",
    "decision_note"
  )

  if (is.null(overrides)) {
    overrides <- tibble::tibble(
      source_table = character(),
      source_column = character(),
      source_value = character(),
      accepted_species_code = character(),
      accepted_species_name = character(),
      mapping_status = character(),
      decision_note = character()
    )
  }

  missing_columns <- setdiff(required_columns, names(overrides))
  if (length(missing_columns) > 0L) {
    stop(
      "Project species overrides are missing columns: ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }

  overrides |>
    dplyr::transmute(
      source_table = as.character(.data$source_table),
      source_column = as.character(.data$source_column),
      source_value = normalize_species_value(.data$source_value),
      source_match_value = species_match_key(.data$source_value),
      accepted_species_code = normalize_species_value(.data$accepted_species_code),
      accepted_species_name = normalize_species_value(.data$accepted_species_name),
      accepted_match_value = species_match_key(.data$accepted_species_name),
      mapping_status = as.character(.data$mapping_status),
      decision_note = as.character(.data$decision_note)
    ) |>
    dplyr::distinct()
}


assert_unique_species_lookup <- function(lookup, key_column, label) {
  duplicates <- lookup |>
    dplyr::filter(!is.na(.data[[key_column]])) |>
    dplyr::count(.data[[key_column]], name = "n") |>
    dplyr::filter(.data$n > 1L)

  if (nrow(duplicates) > 0L) {
    print(duplicates)
    stop(label, " contains non-unique match values.", call. = FALSE)
  }

  invisible(TRUE)
}


build_trtrates_context_rules <- function(data_list, resolved_usage) {
  collisions <- resolved_usage |>
    dplyr::filter(
      !is.na(.data$speciesid),
      .data$source_value_type == "species_code"
    ) |>
    dplyr::group_by(.data$speciesid) |>
    dplyr::summarise(
      source_taxon_count = dplyr::n_distinct(.data$source_match_value),
      source_values = paste(
        sort(unique(.data$source_value)),
        collapse = ";"
      ),
      .groups = "drop"
    ) |>
    dplyr::filter(.data$source_taxon_count > 1L)

  if (nrow(collisions) == 0L) {
    return(list(
      collisions = collisions,
      rules = tibble::tibble(
        source_table = character(),
        source_column = character(),
        source_value = character(),
        source_match_value = character(),
        speciesid = integer(),
        match_rate = double(),
        match_unit = character(),
        reverse_mapping_rule = character(),
        contextual_rule_validated = logical()
      )
    ))
  }

  collision_usage <- resolved_usage |>
    dplyr::filter(.data$source_value_type == "species_code") |>
    dplyr::semi_join(collisions, by = "speciesid")

  unsupported_locations <- collision_usage |>
    dplyr::filter(
      .data$source_table != "trtrates" |
        .data$source_column != "speciesid"
    ) |>
    dplyr::distinct(
      .data$speciesid,
      .data$source_table,
      .data$source_column,
      .data$source_value
    )

  if (nrow(unsupported_locations) > 0L) {
    print(unsupported_locations)
    stop(
      paste(
        "Multiple source taxa map to one accepted speciesid outside",
        "trtrates. A table-specific contextual rule is required."
      ),
      call. = FALSE
    )
  }

  trtrates <- data_list$trtrates
  required_columns <- c("speciesid", "rate", "unit")
  missing_columns <- setdiff(required_columns, names(trtrates))
  if (length(missing_columns) > 0L) {
    stop(
      "Contextual species rules require trtrates columns: ",
      paste(required_columns, collapse = ", "),
      call. = FALSE
    )
  }

  rules <- trtrates |>
    dplyr::transmute(
      source_table = "trtrates",
      source_column = "speciesid",
      source_value = normalize_species_value(.data$speciesid),
      source_match_value = species_match_key(.data$speciesid),
      match_rate = suppressWarnings(as.numeric(.data$rate)),
      match_unit = species_match_key(.data$unit)
    ) |>
    dplyr::inner_join(
      collision_usage |>
        dplyr::select("source_match_value", "speciesid") |>
        dplyr::distinct(),
      by = "source_match_value"
    ) |>
    dplyr::distinct()

  incomplete_rules <- rules |>
    dplyr::filter(is.na(.data$match_rate) | is.na(.data$match_unit))
  if (nrow(incomplete_rules) > 0L) {
    print(incomplete_rules)
    stop(
      "A colliding seeded taxon has a missing rate or unit.",
      call. = FALSE
    )
  }

  ambiguous_rules <- rules |>
    dplyr::group_by(
      .data$speciesid,
      .data$match_rate,
      .data$match_unit
    ) |>
    dplyr::summarise(
      source_taxon_count = dplyr::n_distinct(.data$source_match_value),
      source_values = paste(
        sort(unique(.data$source_value)),
        collapse = ";"
      ),
      .groups = "drop"
    ) |>
    dplyr::filter(.data$source_taxon_count > 1L)

  if (nrow(ambiguous_rules) > 0L) {
    print(ambiguous_rules)
    stop(
      paste(
        "Accepted speciesid + seed rate + unit does not uniquely identify",
        "the original source taxon. Add another contextual field before",
        "using this crosswalk for reconstruction."
      ),
      call. = FALSE
    )
  }

  missing_collision_taxa <- setdiff(
    unique(collision_usage$source_match_value),
    unique(rules$source_match_value)
  )
  if (length(missing_collision_taxa) > 0L) {
    stop(
      "No contextual seed-rate rules were produced for: ",
      paste(missing_collision_taxa, collapse = ", "),
      call. = FALSE
    )
  }

  rules <- rules |>
    dplyr::mutate(
      reverse_mapping_rule = "speciesid_rate_unit",
      contextual_rule_validated = TRUE
    )

  list(collisions = collisions, rules = rules)
}


build_project_species_crosswalk <- function(
    data_list,
    species_lookup,
    lu_species,
    global_species_crosswalk,
    database,
    projectid,
    project_code = paste0(database, projectid),
    overrides = NULL,
    output_path = NULL,
    write_when_discrepancy = TRUE) {

  database_value <- as.character(database)[[1]]
  projectid_value <- as.integer(projectid)[[1]]
  project_code_value <- as.character(project_code)[[1]]

  usage <- collect_project_species_usage(data_list)
  if (nrow(usage) == 0L) {
    stop("No project species values were found.", call. = FALSE)
  }

  usage_summary <- usage |>
    dplyr::count(
      .data$source_table,
      .data$source_column,
      .data$source_value_type,
      .data$source_value,
      .data$source_match_value,
      name = "source_occurrences"
    )

  accepted_species_lookup <- lu_species |>
    dplyr::transmute(
      speciesid = as.integer(.data$speciesid),
      accepted_species_code = as.character(.data$species_code),
      accepted_species_name = as.character(.data$name)
    ) |>
    dplyr::filter(!is.na(.data$speciesid)) |>
    dplyr::distinct()

  required_global_columns <- c(
    "excel_speciesid",
    "sql_speciesid",
    "sql_species_code"
  )
  missing_global_columns <- setdiff(
    required_global_columns,
    names(global_species_crosswalk)
  )
  if (length(missing_global_columns) > 0L) {
    stop(
      "Global species crosswalk is missing columns: ",
      paste(missing_global_columns, collapse = ", "),
      call. = FALSE
    )
  }

  global_code_map <- global_species_crosswalk |>
    dplyr::transmute(
      source_species_code = normalize_species_value(.data$excel_speciesid),
      source_match_value = species_match_key(.data$excel_speciesid),
      speciesid = as.integer(.data$sql_speciesid),
      accepted_species_code = normalize_species_value(.data$sql_species_code)
    ) |>
    dplyr::filter(
      !is.na(.data$source_match_value),
      !is.na(.data$speciesid),
      !is.na(.data$accepted_species_code)
    ) |>
    dplyr::distinct()

  project_code_map <- global_code_map |>
    dplyr::semi_join(
      usage_summary |>
        dplyr::filter(.data$source_value_type == "species_code") |>
        dplyr::select("source_match_value") |>
        dplyr::distinct(),
      by = "source_match_value"
    )

  conflicting_global_codes <- project_code_map |>
    dplyr::count(.data$source_match_value, name = "n") |>
    dplyr::filter(.data$n > 1L)
  if (nrow(conflicting_global_codes) > 0L) {
    print(conflicting_global_codes)
    stop(
      paste(
        "The global species crosswalk maps a source code to more than one",
        "accepted species record. Resolve that conflict before importing."
      ),
      call. = FALSE
    )
  }

  global_code_collisions <- global_code_map |>
    dplyr::transmute(
      source_species_code = normalize_species_value(.data$source_species_code),
      speciesid = as.integer(.data$speciesid)
    ) |>
    dplyr::filter(
      !is.na(.data$source_species_code),
      !is.na(.data$speciesid)
    ) |>
    dplyr::distinct() |>
    dplyr::group_by(.data$speciesid) |>
    dplyr::summarise(
      global_source_code_count = dplyr::n_distinct(.data$source_species_code),
      global_source_codes = paste(
        sort(unique(.data$source_species_code)),
        collapse = ";"
      ),
      .groups = "drop"
    ) |>
    dplyr::filter(.data$global_source_code_count > 1L)

  code_lookup <- project_code_map |>
    dplyr::left_join(
      accepted_species_lookup,
      by = c("speciesid", "accepted_species_code")
    ) |>
    dplyr::transmute(
      source_match_value = .data$source_match_value,
      code_speciesid = .data$speciesid,
      code_species_code = .data$accepted_species_code,
      code_species_name = .data$accepted_species_name
    ) |>
    dplyr::left_join(
      global_code_collisions |>
        dplyr::rename(code_speciesid = "speciesid"),
      by = "code_speciesid"
    ) |>
    dplyr::filter(
      !is.na(.data$source_match_value),
      !is.na(.data$code_speciesid)
    ) |>
    dplyr::distinct()

  name_lookup <- lu_species |>
    dplyr::transmute(
      source_match_value = species_match_key(.data$name),
      name_speciesid = as.integer(.data$speciesid),
      name_species_code = as.character(.data$species_code),
      name_species_name = as.character(.data$name)
    ) |>
    dplyr::filter(
      !is.na(.data$source_match_value),
      !is.na(.data$name_speciesid)
    ) |>
    dplyr::distinct()

  project_name_lookup <- name_lookup |>
    dplyr::semi_join(
      usage_summary |>
        dplyr::filter(.data$source_value_type == "scientific_name") |>
        dplyr::select("source_match_value") |>
        dplyr::distinct(),
      by = "source_match_value"
    )

  assert_unique_species_lookup(code_lookup, "source_match_value", "Species-code lookup")
  assert_unique_species_lookup(
    project_name_lookup,
    "source_match_value",
    "Project species-name lookup"
  )

  reviewed_overrides <- prepare_project_species_overrides(overrides) |>
    dplyr::left_join(
      accepted_species_lookup |>
        dplyr::transmute(
          accepted_match_value = species_match_key(.data$accepted_species_name),
          accepted_species_code = .data$accepted_species_code,
          reviewed_speciesid = .data$speciesid,
          reviewed_species_code = .data$accepted_species_code,
          reviewed_species_name = .data$accepted_species_name
        ),
      by = c("accepted_match_value", "accepted_species_code")
    )

  unresolved_override_names <- reviewed_overrides |>
    dplyr::filter(is.na(.data$reviewed_speciesid))
  if (nrow(unresolved_override_names) > 0L) {
    print(unresolved_override_names)
    stop(
      "A reviewed accepted name does not resolve to the GRP species lookup.",
      call. = FALSE
    )
  }

  resolved_usage <- usage_summary |>
    dplyr::left_join(code_lookup, by = "source_match_value") |>
    dplyr::left_join(project_name_lookup, by = "source_match_value") |>
    dplyr::left_join(
      reviewed_overrides |>
        dplyr::select(
          "source_table",
          "source_column",
          "source_match_value",
          "reviewed_speciesid",
          "reviewed_species_code",
          "reviewed_species_name",
          "mapping_status",
          "decision_note"
        ),
      by = c("source_table", "source_column", "source_match_value")
    ) |>
    dplyr::mutate(
      speciesid = dplyr::coalesce(
        .data$reviewed_speciesid,
        .data$code_speciesid,
        .data$name_speciesid
      ),
      accepted_species_code = dplyr::coalesce(
        .data$reviewed_species_code,
        .data$code_species_code,
        .data$name_species_code
      ),
      accepted_species_name = dplyr::coalesce(
        .data$reviewed_species_name,
        .data$code_species_name,
        .data$name_species_name
      ),
      mapping_status = dplyr::case_when(
        !is.na(.data$reviewed_speciesid) ~ .data$mapping_status,
        .data$source_value_type == "species_code" &
          !is.na(.data$global_source_code_count) ~
          "review_required_many_to_one_global",
        !is.na(.data$code_speciesid) ~ "accepted_code_mapping",
        !is.na(.data$name_speciesid) ~ "exact_current_taxon",
        TRUE ~ "unresolved"
      ),
      decision_note = dplyr::case_when(
        !is.na(.data$decision_note) ~ .data$decision_note,
        .data$mapping_status == "review_required_many_to_one_global" ~
          paste0(
            "Human review required: global source codes ",
            .data$global_source_codes,
            " currently collapse to accepted speciesid ",
            .data$speciesid,
            ". The mapping may represent a synonym, spelling variant, ",
            "or a lost infraspecific concept."
          ),
        .data$mapping_status == "accepted_code_mapping" ~
          "Resolved through the global species-code crosswalk.",
        .data$mapping_status == "exact_current_taxon" ~
          "Source name exactly matches the accepted GRP species name.",
        TRUE ~ "No automatic or reviewed mapping was found."
      )
    )

  context <- build_trtrates_context_rules(data_list, resolved_usage)
  collision_ids <- context$collisions$speciesid

  default_rows <- resolved_usage |>
    dplyr::mutate(
      crosswalk_row_type = "default",
      rule_source_table = "all_relevant_tables",
      reverse_mapping_rule = dplyr::if_else(
        .data$speciesid %in% collision_ids,
        "not_unique_without_context",
        "speciesid"
      ),
      match_rate = NA_real_,
      match_unit = NA_character_,
      contextual_rule_validated = !(.data$speciesid %in% collision_ids)
    )

  contextual_rows <- context$rules |>
    dplyr::left_join(
      resolved_usage,
      by = c(
        "source_table",
        "source_column",
        "source_value",
        "source_match_value",
        "speciesid"
      )
    ) |>
    dplyr::mutate(
      crosswalk_row_type = "contextual",
      rule_source_table = "trtrates",
      mapping_status = "contextual_mapping",
      decision_note = paste(
        .data$decision_note,
        "The source taxon is recoverable from speciesid + rate + unit."
      )
    )

  crosswalk <- dplyr::bind_rows(default_rows, contextual_rows) |>
    dplyr::transmute(
      database = .env$database_value,
      projectid = .env$projectid_value,
      project_code = .env$project_code_value,
      crosswalk_row_type = .data$crosswalk_row_type,
      rule_source_table = .data$rule_source_table,
      source_table = .data$source_table,
      source_column = .data$source_column,
      source_value_type = .data$source_value_type,
      source_value = .data$source_value,
      source_occurrences = as.integer(.data$source_occurrences),
      speciesid = as.integer(.data$speciesid),
      accepted_species_code = .data$accepted_species_code,
      accepted_species_name = .data$accepted_species_name,
      mapping_status = .data$mapping_status,
      reverse_mapping_rule = .data$reverse_mapping_rule,
      match_rate = .data$match_rate,
      match_unit = .data$match_unit,
      contextual_rule_validated = .data$contextual_rule_validated,
      global_source_code_count = as.integer(.data$global_source_code_count),
      global_source_codes = .data$global_source_codes,
      review_required = .data$mapping_status ==
        "review_required_many_to_one_global",
      reviewed = !is.na(.data$reviewed_speciesid),
      decision_note = .data$decision_note
    ) |>
    dplyr::arrange(
      .data$source_table,
      .data$source_column,
      .data$source_value,
      .data$crosswalk_row_type,
      .data$match_unit,
      .data$match_rate
    )

  discrepancies <- crosswalk |>
    dplyr::filter(
      .data$mapping_status %in% c(
        "synonym_or_name_update",
        "contextual_mapping",
        "review_required_many_to_one_global",
        "unresolved",
        "ambiguous"
      ) |
        .data$reverse_mapping_rule == "not_unique_without_context"
    )

  if (
    isTRUE(write_when_discrepancy) &&
      nrow(discrepancies) > 0L &&
      !is.null(output_path)
  ) {
    dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
    readr::write_csv(crosswalk, output_path, na = "")
  }

  unresolved <- crosswalk |>
    dplyr::filter(
      .data$crosswalk_row_type == "default",
      is.na(.data$speciesid) | .data$mapping_status == "unresolved"
    )
  if (nrow(unresolved) > 0L) {
    print(unresolved)
    stop(
      paste(
        "Unresolved species were found. Add reviewed project overrides",
        "before continuing the import."
      ),
      call. = FALSE
    )
  }

  review_required <- crosswalk |>
    dplyr::filter(
      .data$crosswalk_row_type == "default",
      .data$review_required
    )
  if (nrow(review_required) > 0L) {
    print(review_required)
    stop(
      paste(
        "Potential many-to-one taxonomic mappings require human review.",
        "Add a project override for each flagged source code before",
        "continuing the import."
      ),
      call. = FALSE
    )
  }

  list(
    crosswalk = crosswalk,
    lookup = crosswalk |>
      dplyr::filter(.data$crosswalk_row_type == "default") |>
      dplyr::select(
        "source_table",
        "source_column",
        "source_value",
        "speciesid",
        "accepted_species_code",
        "accepted_species_name",
        "mapping_status"
      ),
    contextual_rules = context$rules,
    collisions = context$collisions,
    discrepancies = discrepancies,
    review_required = review_required
  )
}
