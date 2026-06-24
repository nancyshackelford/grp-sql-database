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

validate_lookup_constraints <- function(
    stg_tbl,
    target_table,
    constraints_tbl,
    con,
    schema = "grp",
    skip_id_columns = TRUE
) {

  fk_constraints <- constraints_tbl |>
    dplyr::filter(
      .data$table_name == .env$target_table,
      .data$constraint_type == "FOREIGN KEY"
    ) |>
    dplyr::mutate(
      fk_columns = stringr::str_match(
        .data$constraint_definition,
        "FOREIGN KEY \\(([^\\)]+)\\)"
      )[, 2],
      referenced_table = stringr::str_match(
        .data$constraint_definition,
        paste0("REFERENCES\\s+", schema, "\\.([A-Za-z0-9_]+)\\s*\\(")
      )[, 2],
      referenced_columns = stringr::str_match(
        .data$constraint_definition,
        paste0("REFERENCES\\s+", schema, "\\.[A-Za-z0-9_]+\\s*\\(([^\\)]+)\\)")
      )[, 2]
    ) |>
    dplyr::filter(
      !is.na(.data$fk_columns),
      !is.na(.data$referenced_table),
      !is.na(.data$referenced_columns)
    ) |>
    dplyr::mutate(
      fk_column_list = stringr::str_split(.data$fk_columns, "\\s*,\\s*"),
      referenced_column_list = stringr::str_split(.data$referenced_columns, "\\s*,\\s*")
    ) |>
    dplyr::filter(lengths(.data$fk_column_list) == 1)

  if (skip_id_columns) {
    fk_constraints <- fk_constraints |>
      dplyr::filter(
        !stringr::str_detect(.data$column_name, "id$")
      )
  }

  purrr::pmap_dfr(
    fk_constraints,
    function(table_schema, table_name, column_name, constraint_name,
             constraint_type_code, constraint_type, constraint_definition,
             is_identity, identity_generation, column_default,
             fk_columns, referenced_table, referenced_columns,
             fk_column_list, referenced_column_list, ...) {

      fk_col <- fk_column_list[[1]]
      ref_col <- referenced_column_list[[1]]

      if (!fk_col %in% names(stg_tbl)) return(NULL)

      ref_tbl <- get_lookup_table(con, referenced_table, schema = schema)

      if (!ref_col %in% names(ref_tbl)) return(NULL)

      staged_values <- stg_tbl |>
        dplyr::mutate(.row_number = dplyr::row_number()) |>
        dplyr::select(.data$.row_number, value = dplyr::all_of(fk_col)) |>
        dplyr::filter(!is.na(.data$value)) |>
        dplyr::mutate(value = as.character(.data$value))

      ref_values <- ref_tbl |>
        dplyr::pull(.data[[ref_col]]) |>
        as.character() |>
        unique()

      bad_rows <- staged_values |>
        dplyr::filter(!.data$value %in% ref_values)

      if (nrow(bad_rows) == 0) return(NULL)

      tibble::tibble(
        table_name = target_table,
        column_name = fk_col,
        issue_type = "lookup_mismatch",
        issue_severity = "error",
        row_number = bad_rows$.row_number,
        raw_value = bad_rows$value,
        notes = paste0(
          target_table, ".", fk_col,
          " does not exist in ",
          referenced_table, ".", ref_col,
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
validate_referential_integrity <- function(
    staged_tables,
    constraints_tbl,
    con,
    schema = "grp",
    id_columns_only = TRUE
) {

  fk_constraints <- constraints_tbl |>
    dplyr::filter(.data$constraint_type == "FOREIGN KEY") |>
    dplyr::mutate(
      fk_columns = stringr::str_match(
        .data$constraint_definition,
        "FOREIGN KEY \\(([^\\)]+)\\)"
      )[, 2],
      referenced_table = stringr::str_match(
        .data$constraint_definition,
        paste0("REFERENCES\\s+", schema, "\\.([A-Za-z0-9_]+)\\s*\\(")
      )[, 2],
      referenced_columns = stringr::str_match(
        .data$constraint_definition,
        paste0("REFERENCES\\s+", schema, "\\.[A-Za-z0-9_]+\\s*\\(([^\\)]+)\\)")
      )[, 2]
    ) |>
    dplyr::filter(
      .data$table_name %in% names(staged_tables),
      !is.na(.data$fk_columns),
      !is.na(.data$referenced_table),
      !is.na(.data$referenced_columns)
    ) |>
    dplyr::distinct(
      .data$table_name,
      .data$constraint_name,
      .data$constraint_definition,
      .data$fk_columns,
      .data$referenced_table,
      .data$referenced_columns
    ) |>
    dplyr::mutate(
      fk_column_list = stringr::str_split(.data$fk_columns, "\\s*,\\s*"),
      referenced_column_list = stringr::str_split(.data$referenced_columns, "\\s*,\\s*")
    ) |>
    dplyr::filter(lengths(.data$fk_column_list) == lengths(.data$referenced_column_list))

  if (id_columns_only) {
    fk_constraints <- fk_constraints |>
      dplyr::filter(
        purrr::map_lgl(
          .data$fk_column_list,
          ~ any(stringr::str_detect(.x, "id$"))
        )
      )
  }

  purrr::pmap_dfr(
    fk_constraints,
    function(table_name, constraint_name, constraint_definition,
             fk_columns, referenced_table, referenced_columns,
             fk_column_list, referenced_column_list, ...) {

      child_tbl <- staged_tables[[table_name]]

      if (is.null(child_tbl) || nrow(child_tbl) == 0) return(NULL)

      if (!all(fk_column_list %in% names(child_tbl))) return(NULL)

      child_keys <- child_tbl |>
        dplyr::mutate(.row_number = dplyr::row_number()) |>
        dplyr::select(
          .data$.row_number,
          dplyr::all_of(fk_column_list)
        ) |>
        dplyr::filter(
          dplyr::if_all(
            dplyr::all_of(fk_column_list),
            ~ !is.na(.x)
          )
        ) |>
        dplyr::distinct()

      if (nrow(child_keys) == 0) return(NULL)

      staged_parent <- staged_tables[[referenced_table]]

      staged_parent_keys <- NULL

      if (!is.null(staged_parent) &&
          nrow(staged_parent) > 0 &&
          all(referenced_column_list %in% names(staged_parent))) {

        staged_parent_keys <- staged_parent |>
          dplyr::select(dplyr::all_of(referenced_column_list)) |>
          dplyr::filter(
            dplyr::if_all(
              dplyr::all_of(referenced_column_list),
              ~ !is.na(.x)
            )
          ) |>
          dplyr::distinct()
      }

      db_parent <- DBI::dbReadTable(
        con,
        DBI::Id(schema = schema, table = referenced_table)
      )

      db_parent_keys <- db_parent |>
        dplyr::select(dplyr::all_of(referenced_column_list)) |>
        dplyr::filter(
          dplyr::if_all(
            dplyr::all_of(referenced_column_list),
            ~ !is.na(.x)
          )
        ) |>
        dplyr::distinct()

      parent_keys <- dplyr::bind_rows(
        staged_parent_keys,
        db_parent_keys
      ) |>
        dplyr::distinct()

      child_compare <- child_keys |>
        dplyr::rename_with(
          ~ referenced_column_list,
          dplyr::all_of(fk_column_list)
        )

      bad_rows <- child_compare |>
        dplyr::anti_join(
          parent_keys,
          by = referenced_column_list
        )

      if (nrow(bad_rows) == 0) return(NULL)

      tibble::tibble(
        table_name = table_name,
        column_name = paste(fk_column_list, collapse = ", "),
        issue_type = "referential_integrity_issue",
        issue_severity = "blocker",
        row_number = bad_rows$.row_number,
        raw_value = bad_rows |>
          dplyr::select(dplyr::all_of(referenced_column_list)) |>
          apply(1, paste, collapse = " | "),
        notes = paste0(
          table_name, ".",
          paste(fk_column_list, collapse = ", "),
          " does not match staged or existing parent key ",
          referenced_table, ".",
          paste(referenced_column_list, collapse = ", "),
          " for constraint ",
          constraint_name
        )
      )
    }
  )
}