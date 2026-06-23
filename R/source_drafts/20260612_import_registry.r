### This is code to track all constraints and lookup tables in the SQL schema to help control vocab in the import
### This is a work in progress and will be updated as we update the controlled vocabularies and the import process.

# ============================================================
# BUILD IMPORT REGISTRY
# Outputs:
#   1. import_registry$constraints
#   2. import_registry$lookup_table_names
# ============================================================

# ------------------------------------------------------------
# 1. SCHEMA CONSTRAINTS
# ------------------------------------------------------------

constraints_tbl <- dbGetQuery(
  con,
  "
  SELECT
    n.nspname AS table_schema,
    c.relname AS table_name,
    a.attname AS column_name,
    con.conname AS constraint_name,
    con.contype AS constraint_type_code,
    CASE con.contype
      WHEN 'c' THEN 'CHECK'
      WHEN 'f' THEN 'FOREIGN KEY'
      WHEN 'u' THEN 'UNIQUE'
      WHEN 'p' THEN 'PRIMARY KEY'
      ELSE con.contype::text
    END AS constraint_type,
    pg_get_constraintdef(con.oid) AS constraint_definition,
    cols.is_identity,
    cols.identity_generation,
    cols.column_default
  FROM pg_constraint con
  JOIN pg_class c
      ON c.oid = con.conrelid
  JOIN pg_namespace n
      ON n.oid = c.relnamespace
  LEFT JOIN unnest(con.conkey) AS k(attnum)
      ON TRUE
  LEFT JOIN pg_attribute a
      ON a.attrelid = c.oid
     AND a.attnum = k.attnum
  LEFT JOIN information_schema.columns cols
      ON cols.table_schema = n.nspname
     AND cols.table_name = c.relname
     AND cols.column_name = a.attname
  WHERE n.nspname = 'grp'
    AND con.contype IN ('c', 'f', 'u', 'p')
  ORDER BY c.relname, a.attname, con.conname;
  "
)

not_null_constraints <- dbGetQuery(
  con,
  "
  SELECT
      table_schema,
      table_name,
      column_name,
      NULL::text AS constraint_name,
      NULL::text AS constraint_type_code,
      'NOT NULL' AS constraint_type,
      column_name AS constraint_definition,
      is_identity,
      identity_generation,
      column_default
  FROM information_schema.columns
  WHERE table_schema = 'grp'
    AND is_nullable = 'NO'
  ORDER BY table_name, ordinal_position;
  "
)

constraints_tbl <- bind_rows(
  constraints_tbl,
  not_null_constraints
)

# ------------------------------------------------------------
# 2. GET LOOKUP TABLE NAMES FUNCTION
# ------------------------------------------------------------

get_lookup_table_names <- function(constraints_tbl, schema = "grp") {
  constraints_tbl |>
    dplyr::filter(constraint_type == "FOREIGN KEY") |>
    dplyr::mutate(
      referenced_table = stringr::str_match(
        constraint_definition,
        paste0("REFERENCES\\s+", schema, "\\.([A-Za-z0-9_]+)\\s*\\(")
      )[, 2]
    ) |>
    dplyr::filter(!is.na(referenced_table)) |>
    dplyr::distinct(referenced_table) |>
    dplyr::arrange(referenced_table) |>
    dplyr::pull(referenced_table)
}

# ------------------------------------------------------------
# 3. COMBINE INTO IMPORT REGISTRY
# ------------------------------------------------------------

import_registry <- list(
  constraints = constraints_tbl,
  lookup_table_names = get_lookup_table_names(constraints_tbl)
)

# ------------------------------------------------------------
# 4. PULL TABLE FUNCTION
# ------------------------------------------------------------

get_lookup_table <- function(con, table_name, schema = "grp") {
  dbReadTable(con, DBI::Id(schema = schema, table = table_name))
}

# ------------------------------------------------------------
# 5. VALIDATION STEP 1: TABLE-INTERNAL VALIDATION
# ------------------------------------------------------------

validate_staged_table <- function(stg_tbl, target_table, constraints_tbl) {

  table_constraints <- constraints_tbl |>
    dplyr::filter(.data$table_name == .env$target_table)

  issues <- list()

  # ---- 1. Required / NOT NULL checks ----
  not_null_cols <- table_constraints |>
  dplyr::filter(.data$constraint_type == "NOT NULL") |>
  dplyr::filter(is.na(.data$is_identity) | .data$is_identity != "YES") |>
  dplyr::filter(is.na(.data$column_default) |
      !stringr::str_detect(.data$column_default, "^nextval\\(")) |>
  dplyr::pull(.data$column_name) |>
  unique()

  missing_required <- purrr::map_dfr(not_null_cols, function(col) {

    if (!col %in% names(stg_tbl)) {
      return(tibble::tibble(
        table_name = target_table,
        column_name = col,
        issue_type = "missing_required_column",
        issue_severity = "blocker",
        row_number = NA_integer_,
        raw_value = NA_character_,
        notes = "Required column is missing from staged table."
      ))
    }

    bad_rows <- which(is.na(stg_tbl[[col]]))

    if (length(bad_rows) == 0) return(NULL)

    tibble::tibble(
      table_name = target_table,
      column_name = col,
      issue_type = "missing_required_value",
      issue_severity = "blocker",
      row_number = bad_rows,
      raw_value = NA_character_,
      notes = "Required column contains NA."
    )
  })

  issues$missing_required <- missing_required

  # ---- 2. Primary key / unique duplicate checks ----
  unique_constraints <- table_constraints |>
    dplyr::filter(.data$constraint_type %in% c("PRIMARY KEY", "UNIQUE")) |>
    dplyr::filter(!is.na(.data$column_name)) |>
    dplyr::group_by(.data$constraint_name, .data$constraint_type) |>
    dplyr::summarise(
      columns = list(unique(.data$column_name)),
      .groups = "drop"
    )

  duplicate_keys <- purrr::pmap_dfr(
    unique_constraints,
    function(constraint_name, constraint_type, columns) {

      if (!all(columns %in% names(stg_tbl))) return(NULL)

      dupes <- stg_tbl |>
        dplyr::mutate(.row_number = dplyr::row_number()) |>
        dplyr::group_by(dplyr::across(dplyr::all_of(columns))) |>
        dplyr::filter(dplyr::n() > 1) |>
        dplyr::ungroup()

      if (nrow(dupes) == 0) return(NULL)

      dupes |>
        dplyr::transmute(
          table_name = target_table,
          column_name = paste(columns, collapse = ", "),
          issue_type = "duplicate_key",
          issue_severity = "blocker",
          row_number = .data$.row_number,
          raw_value = apply(
            dplyr::select(dupes, dplyr::all_of(columns)),
            1,
            paste,
            collapse = " | "
          ),
          notes = paste0(
            constraint_type,
            " constraint failed: ",
            constraint_name
          )
        )
    }
  )

  issues$duplicate_keys <- duplicate_keys

  # ---- 3. CHECK constraint allowed-value checks ----
  check_constraints <- table_constraints |>
    dplyr::filter(.data$constraint_type == "CHECK") |>
    dplyr::filter(!is.na(.data$column_name)) |>
    dplyr::filter(stringr::str_detect(.data$constraint_definition, "ANY \\(ARRAY"))

  check_issues <- purrr::pmap_dfr(
    check_constraints,
    function(table_schema, table_name, column_name, constraint_name,
             constraint_type_code, constraint_type, constraint_definition, ...) {

      if (!column_name %in% names(stg_tbl)) return(NULL)

      allowed_values <- stringr::str_extract_all(
        constraint_definition,
        "'[^']+'(?=::text)"
      )[[1]] |>
        stringr::str_remove_all("'")

      if (length(allowed_values) == 0) return(NULL)

      values <- stg_tbl[[column_name]] |>
        as.character() |>
        stringr::str_squish()

      bad_rows <- which(!is.na(values) & values != "" & !values %in% allowed_values)

      if (length(bad_rows) == 0) return(NULL)

      tibble::tibble(
        table_name = target_table,
        column_name = column_name,
        issue_type = "unexpected_value",
        issue_severity = "error",
        row_number = bad_rows,
        raw_value = values[bad_rows],
        notes = paste0(
          "Value does not satisfy CHECK constraint ",
          constraint_name,
          ". Allowed values: ",
          paste(allowed_values, collapse = ", ")
        )
      )
    }
  )

  issues$check_constraints <- check_issues

  # ---- Return one issue table ----
out <- dplyr::bind_rows(issues)

if (nrow(out) == 0) {
  return(tibble::tibble(
    table_name = character(),
    column_name = character(),
    issue_type = character(),
    issue_severity = character(),
    row_number = integer(),
    raw_value = character(),
    notes = character()
  ))
}

out |>
  dplyr::arrange(.data$issue_severity, .data$table_name, .data$column_name)
}

# ------------------------------------------------------------
# 6. VALIDATION STEP 2: LOOKUP VALIDATION
# ------------------------------------------------------------

validate_lookup_constraints <- function(stg_tbl, target_table, constraints_tbl, con, schema = "grp") {

  fk_constraints <- constraints_tbl |>
    dplyr::filter(
      .data$table_name == .env$target_table,
      .data$constraint_type == "FOREIGN KEY"
    ) |>
    dplyr::mutate(
      referenced_table = stringr::str_match(
        .data$constraint_definition,
        paste0("REFERENCES\\s+", schema, "\\.([A-Za-z0-9_]+)\\s*\\(")
      )[, 2],
      referenced_column = stringr::str_match(
        .data$constraint_definition,
        paste0("REFERENCES\\s+", schema, "\\.[A-Za-z0-9_]+\\s*\\(([A-Za-z0-9_]+)\\)")
      )[, 2]
    ) |>
    dplyr::filter(!is.na(.data$referenced_table), !is.na(.data$referenced_column))

  purrr::pmap_dfr(
    fk_constraints,
    function(table_schema, table_name, column_name, constraint_name,
             constraint_type_code, constraint_type, constraint_definition,
             is_identity, identity_generation, column_default,
             referenced_table, referenced_column, ...) {

      if (!column_name %in% names(stg_tbl)) return(NULL)

      ref_tbl <- get_lookup_table(con, referenced_table, schema = schema)

      if (!referenced_column %in% names(ref_tbl)) return(NULL)

      staged_values <- stg_tbl |>
        dplyr::mutate(.row_number = dplyr::row_number()) |>
        dplyr::select(.data$.row_number, value = dplyr::all_of(column_name)) |>
        dplyr::filter(!is.na(.data$value)) |>
        dplyr::mutate(value = as.character(.data$value))

      ref_values <- ref_tbl |>
        dplyr::pull(.data[[referenced_column]]) |>
        as.character() |>
        unique()

      bad_rows <- staged_values |>
        dplyr::filter(!.data$value %in% ref_values)

      if (nrow(bad_rows) == 0) return(NULL)

      tibble::tibble(
        table_name = target_table,
        column_name = column_name,
        issue_type = "lookup_mismatch",
        issue_severity = "error",
        row_number = bad_rows$.row_number,
        raw_value = bad_rows$value,
        notes = paste0(
          target_table, ".", column_name,
          " does not exist in ",
          referenced_table, ".", referenced_column,
          " for constraint ",
          constraint_name
        )
      )
    }
  )
}

# ------------------------------------------------------------
# 7. VALIDATION STEP 3: REFERENTIAL INTEGRITY VALIDATION
# ------------------------------------------------------------