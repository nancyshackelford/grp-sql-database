### Helper functions
# Helper: normalize blanks
na_if_blank <- function(x) {
  x <- as.character(x)
  x <- stringr::str_squish(x)
  dplyr::na_if(x, "")
}

# Helper: allocate IDs for non-identity tables
next_ids <- function(con, table, id_col, n, schema = "grp") {
  max_id <- DBI::dbGetQuery(
    con,
    glue::glue_sql(
      "SELECT COALESCE(MAX({`id_col`}), 0) AS max_id FROM {`schema`}.{`table`}",
      .con = con
    )
  )$max_id

  seq(max_id + 1, length.out = n)
}

# Helper: clean up character vocab by trimming whitespace and converting to lowercase
normalize_vocab <- function(x) {
  x |>
    as.character() |>
    stringr::str_squish() |>
    stringr::str_to_lower() |>
    dplyr::na_if("")
}


# ---- Insert staged tables into Supabase ----

append_if_rows <- function(con, table_name, df, schema = "grp") {
  if (is.null(df) || nrow(df) == 0) {
    message("Skipping ", table_name, ": 0 rows")
    return(invisible(FALSE))
  }

  message("Inserting ", nrow(df), " rows into ", schema, ".", table_name)

  DBI::dbAppendTable(
    conn = con,
    name = DBI::Id(schema = schema, table = table_name),
    value = df
  )

  invisible(TRUE)
}

# Upload files to Supabase
upload_to_supabase <- function(
    local_file,
    bucket = "grp-import-artifacts",
    destination_path,
    supabase_url,
    service_key,
    upsert = TRUE
) {

  stopifnot(file.exists(local_file))

  endpoint <- paste0(
    supabase_url,
    "/storage/v1/object/",
    bucket,
    "/",
    destination_path
  )

  response <- httr2::request(endpoint) |>
    httr2::req_method("POST") |>
    httr2::req_headers(
      apikey = service_key,
      Authorization = paste("Bearer", service_key),
      "x-upsert" = ifelse(upsert, "true", "false")
    ) |>
    httr2::req_body_file(local_file) |>
    httr2::req_error(is_error = function(resp) FALSE) |>
    httr2::req_perform()

  if (httr2::resp_status(response) >= 400) {
    stop(httr2::resp_body_string(response))
  }

  list(
    local_file = normalizePath(local_file),
    bucket = bucket,
    destination_path = destination_path,
    status_code = httr2::resp_status(response)
  )
}
