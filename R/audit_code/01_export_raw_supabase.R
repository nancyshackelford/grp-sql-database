# Export a read-only, project-scoped snapshot of the GAZP data in Supabase.
#
# AUDIT STATUS AFTER REVIEW OF SNAPSHOT 2026-08-13: This exporter successfully
# produced the raw, ID-preserving snapshot used for the first reconstruction
# audit. The audit confirmed that the USDA ecological classification assigned
# to each site is stored in Supabase through grp.site_classification; future raw
# snapshots must continue to include that relationship and must also include
# the referenced classification vocabulary needed to translate its hierarchical
# classificationid back to the familiar USDA.class, USDA.subclass, and
# USDA.subsubclass labels. The audit also established two database-repair tasks
# that are intentionally NOT performed by this read-only exporter. The missing
# timepoint months for GAZP1, GAZP2, and GAZP3 were successfully backfilled on
# 2026-08-14: 1,282 veg_result rows were committed and verified (625, 576, and
# 81 rows respectively). The original timepoint sheets contained no day values,
# so no days were changed. A new raw snapshot is required for later export audit
# outputs to reflect that repair. The GAZP5 Art_tri3 taxonomy error was also
# corrected and verified on 2026-08-14: Art_tri_sub_tri was created as speciesid
# 7171, 462 veg_result rows and 177 seeding rows were reassigned, and the global
# repository species crosswalk was updated to Art_tri3 -> 7171 ->
# Art_tri_sub_tri. Review of the other ambiguous legacy
# codes found no further central taxonomy corrections. Historical or regional
# taxonomic distinctions instead belong in project-specific crosswalks created
# during import and consumed during export. Because GAZP5 predates that practice,
# its species crosswalk will be reconstructed as a standalone post-import
# provenance artifact; this raw exporter must not attempt to invent it.
#
# Outputs:
#   data/supabase_snapshots/YYYY-MM-DD/grp_<table>.csv
#   data/supabase_snapshots/YYYY-MM-DD/database_columns.csv
#   data/supabase_snapshots/YYYY-MM-DD/export_manifest.csv
#
# The raw table values and all current Supabase IDs are retained. No values
# are harmonized, renamed, joined into reporting shapes, or otherwise changed.
# Crosswalk files are not downloaded or copied by this script.

suppressPackageStartupMessages({
  library(DBI)
  library(RPostgres)
  library(readr)
  library(dplyr)
  library(purrr)
  library(tibble)
})

source("R/audit_code/00_audit_config.R")


# ---- Connection ---------------------------------------------------------

required_env_value <- function(variable_name, default = NULL) {
  value <- Sys.getenv(variable_name, unset = "")

  if (!nzchar(value) && !is.null(default)) {
    value <- as.character(default)
  }

  if (!nzchar(value)) {
    stop(
      "Required environment variable is not set: ",
      variable_name,
      call. = FALSE
    )
  }

  value
}


connect_to_supabase_read_only <- function(config) {
  password <- readLines(
    "C:/Users/nshack/OneDrive - University of Victoria/Documents/R/GRP/pword.csv",
    warn = FALSE
  )[1]

  con <- DBI::dbConnect(
    RPostgres::Postgres(),
    host = "aws-1-ca-central-1.pooler.supabase.com",
    port = 6543,
    dbname = "postgres",
    user = "postgres.rudybfqutvodkakgctpo",
    password = password,
    sslmode = "require"
  )

  DBI::dbExecute(con, "SET default_transaction_read_only = on")
  con
}

# ---- SQL construction ---------------------------------------------------

sql_list <- function(con, values) {
  if (length(values) == 0L) {
    stop("Cannot construct an SQL list from zero values.", call. = FALSE)
  }

  paste(DBI::dbQuoteLiteral(con, values), collapse = ", ")
}


build_scope_sql <- function(con, config) {
  schema <- as.character(DBI::dbQuoteIdentifier(con, config$schema))
  database <- as.character(DBI::dbQuoteLiteral(
    con,
    config$source_database
  ))
  projectids <- sql_list(con, as.integer(config$projectids))

  paste0(
    "WITH selected_projects AS (\n",
    "  SELECT database, projectid\n",
    "  FROM ", schema, ".project\n",
    "  WHERE database = ", database, "\n",
    "    AND projectid IN (", projectids, ")\n",
    "),\n",
    "selected_sites AS (\n",
    "  SELECT DISTINCT ps.siteid\n",
    "  FROM ", schema, ".project_site ps\n",
    "  JOIN selected_projects sp USING (database, projectid)\n",
    "),\n",
    "selected_area_treatments AS (\n",
    "  SELECT DISTINCT at.database, at.projectid, at.areaid, at.treatmentid\n",
    "  FROM ", schema, ".area_treatment at\n",
    "  JOIN selected_projects sp USING (database, projectid)\n",
    "),\n",
    "selected_areas AS (\n",
    "  SELECT DISTINCT areaid FROM selected_area_treatments\n",
    "),\n",
    "selected_treatments AS (\n",
    "  SELECT DISTINCT treatmentid FROM selected_area_treatments\n",
    "),\n",
    "selected_seed_mixes AS (\n",
    "  SELECT DISTINCT sm.seed_mixid\n",
    "  FROM ", schema, ".seed_mix sm\n",
    "  JOIN selected_treatments st USING (treatmentid)\n",
    "),\n",
    "selected_seedings AS (\n",
    "  SELECT DISTINCT s.seedingid\n",
    "  FROM ", schema, ".seeding s\n",
    "  JOIN selected_treatments st USING (treatmentid)\n",
    "),\n",
    "selected_papers AS (\n",
    "  SELECT DISTINCT pp.paperid\n",
    "  FROM ", schema, ".project_paper pp\n",
    "  JOIN selected_projects sp USING (database, projectid)\n",
    "),\n",
    "selected_authors AS (\n",
    "  SELECT DISTINCT pc.author_contributorid\n",
    "  FROM ", schema, ".project_contributor pc\n",
    "  JOIN selected_projects sp USING (database, projectid)\n",
    "  UNION\n",
    "  SELECT DISTINCT pa.author_contributorid\n",
    "  FROM ", schema, ".paper_author pa\n",
    "  JOIN selected_papers spp USING (paperid)\n",
    "),\n",
    "selected_species AS (\n",
    "  SELECT DISTINCT vr.speciesid\n",
    "  FROM ", schema, ".veg_result vr\n",
    "  JOIN selected_areas sa USING (areaid)\n",
    "  WHERE vr.speciesid IS NOT NULL\n",
    "  UNION\n",
    "  SELECT DISTINCT se.speciesid\n",
    "  FROM ", schema, ".seeding se\n",
    "  JOIN selected_treatments st USING (treatmentid)\n",
    "  WHERE se.speciesid IS NOT NULL\n",
    "  UNION\n",
    "  SELECT DISTINCT si.speciesid\n",
    "  FROM ", schema, ".site_invasive si\n",
    "  JOIN selected_sites ss USING (siteid)\n",
    "  WHERE si.speciesid IS NOT NULL\n",
    "),\n",
    "selected_cultivars AS (\n",
    "  SELECT DISTINCT vr.cultivarid\n",
    "  FROM ", schema, ".veg_result vr\n",
    "  JOIN selected_areas sa USING (areaid)\n",
    "  WHERE vr.cultivarid IS NOT NULL\n",
    "  UNION\n",
    "  SELECT DISTINCT se.cultivarid\n",
    "  FROM ", schema, ".seeding se\n",
    "  JOIN selected_treatments st USING (treatmentid)\n",
    "  WHERE se.cultivarid IS NOT NULL\n",
    ")\n"
  )
}


build_export_queries <- function(con, config) {
  schema <- as.character(DBI::dbQuoteIdentifier(con, config$schema))
  scope <- build_scope_sql(con, config)

  scoped_query <- function(select_sql) {
    paste0(scope, select_sql)
  }

  queries <- list(
    project = scoped_query(
      paste0(
        "SELECT p.* FROM ", schema, ".project p ",
        "JOIN selected_projects sp USING (database, projectid)"
      )
    ),
    project_data_accessibility = scoped_query(
      paste0(
        "SELECT pda.* FROM ", schema, ".project_data_accessibility pda ",
        "JOIN selected_projects sp USING (database, projectid)"
      )
    ),
    project_location = scoped_query(
      paste0(
        "SELECT pl.* FROM ", schema, ".project_location pl ",
        "JOIN selected_projects sp USING (database, projectid)"
      )
    ),
    location = scoped_query(
      paste0(
        "SELECT DISTINCT l.* FROM ", schema, ".location l ",
        "JOIN ", schema, ".project_location pl USING (locationid) ",
        "JOIN selected_projects sp USING (database, projectid)"
      )
    ),
    project_site = scoped_query(
      paste0(
        "SELECT ps.* FROM ", schema, ".project_site ps ",
        "JOIN selected_projects sp USING (database, projectid)"
      )
    ),
    site = scoped_query(
      paste0(
        "SELECT s.* FROM ", schema, ".site s ",
        "JOIN selected_sites ss USING (siteid)"
      )
    ),
    project_paper = scoped_query(
      paste0(
        "SELECT pp.* FROM ", schema, ".project_paper pp ",
        "JOIN selected_projects sp USING (database, projectid)"
      )
    ),
    paper = scoped_query(
      paste0(
        "SELECT p.* FROM ", schema, ".paper p ",
        "JOIN selected_papers spp USING (paperid)"
      )
    ),
    paper_author = scoped_query(
      paste0(
        "SELECT pa.* FROM ", schema, ".paper_author pa ",
        "JOIN selected_papers spp USING (paperid)"
      )
    ),
    project_contributor = scoped_query(
      paste0(
        "SELECT pc.* FROM ", schema, ".project_contributor pc ",
        "JOIN selected_projects sp USING (database, projectid)"
      )
    ),
    author_contributor = scoped_query(
      paste0(
        "SELECT ac.* FROM ", schema, ".author_contributor ac ",
        "JOIN selected_authors sa USING (author_contributorid)"
      )
    ),
    project_vegmetric = scoped_query(
      paste0(
        "SELECT pv.* FROM ", schema, ".project_vegmetric pv ",
        "JOIN selected_projects sp USING (database, projectid)"
      )
    ),
    area_treatment = scoped_query(
      paste0(
        "SELECT at.* FROM ", schema, ".area_treatment at ",
        "JOIN selected_projects sp USING (database, projectid)"
      )
    ),
    area = scoped_query(
      paste0(
        "SELECT a.* FROM ", schema, ".area a ",
        "JOIN selected_areas sa USING (areaid)"
      )
    ),
    treatment = scoped_query(
      paste0(
        "SELECT t.* FROM ", schema, ".treatment t ",
        "JOIN selected_treatments st USING (treatmentid)"
      )
    ),
    seed_mix = scoped_query(
      paste0(
        "SELECT sm.* FROM ", schema, ".seed_mix sm ",
        "JOIN selected_treatments st USING (treatmentid)"
      )
    ),
    seeding = scoped_query(
      paste0(
        "SELECT se.* FROM ", schema, ".seeding se ",
        "JOIN selected_treatments st USING (treatmentid)"
      )
    ),
    seeding_pretreatment = scoped_query(
      paste0(
        "SELECT sp.* FROM ", schema, ".seeding_pretreatment sp ",
        "JOIN selected_seedings ss USING (seedingid)"
      )
    ),
    veg_result = scoped_query(
      paste0(
        "SELECT vr.* FROM ", schema, ".veg_result vr ",
        "JOIN selected_areas sa USING (areaid)"
      )
    ),
    species = scoped_query(
      paste0(
        "SELECT s.* FROM ", schema, ".species s ",
        "JOIN selected_species ss USING (speciesid)"
      )
    ),
    species_names = scoped_query(
      paste0(
        "SELECT sn.* FROM ", schema, ".species_names sn ",
        "JOIN selected_species ss USING (speciesid)"
      )
    ),
    cultivar = scoped_query(
      paste0(
        "SELECT c.* FROM ", schema, ".cultivar c ",
        "JOIN selected_cultivars sc USING (cultivarid)"
      )
    )
  )

  site_tables <- c(
    "site_classification",
    "site_disturbance",
    "site_ref_ecosystem",
    "site_soil",
    "site_invasive"
  )

  for (table_name in site_tables) {
    table_sql <- as.character(DBI::dbQuoteIdentifier(con, table_name))
    queries[[table_name]] <- scoped_query(
      paste0(
        "SELECT x.* FROM ", schema, ".", table_sql, " x ",
        "JOIN selected_sites ss USING (siteid)"
      )
    )
  }

  treatment_detail_tables <- config$export_tables$treatment_details

  for (table_name in treatment_detail_tables) {
    table_sql <- as.character(DBI::dbQuoteIdentifier(con, table_name))
    queries[[table_name]] <- scoped_query(
      paste0(
        "SELECT x.* FROM ", schema, ".", table_sql, " x ",
        "JOIN selected_treatments st USING (treatmentid)"
      )
    )
  }

  missing_queries <- setdiff(config$export_table_names, names(queries))
  extra_queries <- setdiff(names(queries), config$export_table_names)

  if (length(missing_queries) > 0L) {
    stop(
      "No export query is defined for: ",
      paste(missing_queries, collapse = ", "),
      call. = FALSE
    )
  }

  if (length(extra_queries) > 0L) {
    stop(
      "Export queries exist for unconfigured tables: ",
      paste(extra_queries, collapse = ", "),
      call. = FALSE
    )
  }

  queries[config$export_table_names]
}


# ---- Database metadata and validation ----------------------------------

get_table_metadata <- function(con, config) {
  tables <- sql_list(con, config$export_table_names)
  schema <- as.character(DBI::dbQuoteLiteral(con, config$schema))

  DBI::dbGetQuery(
    con,
    paste0(
      "SELECT table_schema, table_name, column_name, ordinal_position, ",
      "data_type, udt_name, is_nullable, column_default, is_identity, ",
      "identity_generation ",
      "FROM information_schema.columns ",
      "WHERE table_schema = ", schema, " ",
      "AND table_name IN (", tables, ") ",
      "ORDER BY table_name, ordinal_position"
    )
  )
}


get_primary_keys <- function(con, config) {
  tables <- sql_list(con, config$export_table_names)
  schema <- as.character(DBI::dbQuoteLiteral(con, config$schema))

  DBI::dbGetQuery(
    con,
    paste0(
      "SELECT tc.table_name, kcu.column_name, kcu.ordinal_position ",
      "FROM information_schema.table_constraints tc ",
      "JOIN information_schema.key_column_usage kcu ",
      "  ON tc.constraint_name = kcu.constraint_name ",
      " AND tc.constraint_schema = kcu.constraint_schema ",
      "WHERE tc.constraint_type = 'PRIMARY KEY' ",
      "AND tc.table_schema = ", schema, " ",
      "AND tc.table_name IN (", tables, ") ",
      "ORDER BY tc.table_name, kcu.ordinal_position"
    )
  )
}


validate_configured_tables <- function(metadata, config) {
  found <- unique(metadata$table_name)
  missing <- setdiff(config$export_table_names, found)

  if (length(missing) > 0L) {
    stop(
      "Configured Supabase tables were not found in schema ",
      config$schema,
      ": ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  invisible(TRUE)
}


validate_primary_keys <- function(data, table_name, primary_keys) {
  key_columns <- primary_keys |>
    filter(.data$table_name == .env$table_name) |>
    arrange(.data$ordinal_position) |>
    pull(.data$column_name)

  # Some bridge/lookup tables may be constrained by UNIQUE rather than a
  # formal primary key in older schema versions. Those are not guessed here.
  if (length(key_columns) == 0L || nrow(data) == 0L) {
    return(invisible(TRUE))
  }

  duplicated_keys <- data |>
    count(across(all_of(key_columns)), name = ".audit_n") |>
    filter(.data$.audit_n > 1L)

  if (nrow(duplicated_keys) > 0L) {
    stop(
      "Duplicate primary keys found while exporting grp.",
      table_name,
      ".",
      call. = FALSE
    )
  }

  invisible(TRUE)
}


# ---- Snapshot output ----------------------------------------------------

create_snapshot_directory <- function(config) {
  snapshot_name <- format(Sys.Date(), config$snapshot$date_format)
  snapshot_dir <- file.path(config$paths$raw_supabase_root, snapshot_name)

  if (dir.exists(snapshot_dir) &&
      !isTRUE(config$snapshot$overwrite_existing_snapshot)) {
    stop(
      "Snapshot directory already exists and overwrite is disabled: ",
      snapshot_dir,
      call. = FALSE
    )
  }

  dir.create(snapshot_dir, recursive = TRUE, showWarnings = FALSE)

  if (!dir.exists(snapshot_dir)) {
    stop("Could not create snapshot directory: ", snapshot_dir, call. = FALSE)
  }

  snapshot_dir
}


sha256_file <- function(path) {
  if (!requireNamespace("digest", quietly = TRUE)) {
    stop(
      "Package 'digest' is required when calculate_sha256 is TRUE.",
      call. = FALSE
    )
  }

  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}


write_snapshot_table <- function(data, table_name, snapshot_dir, config) {
  output_file <- file.path(
    snapshot_dir,
    paste0(
      config$snapshot$file_prefix,
      table_name,
      config$snapshot$file_extension
    )
  )

  readr::write_csv(data, output_file, na = "")

  # Confirm that the file is readable and has the expected number of rows.
  written_rows <- nrow(readr::read_csv(
    output_file,
    show_col_types = FALSE,
    progress = FALSE
  ))

  if (!identical(as.integer(written_rows), as.integer(nrow(data)))) {
    stop("Written row-count check failed for ", table_name, call. = FALSE)
  }

  tibble::tibble(
    schema = config$schema,
    table = table_name,
    file = basename(output_file),
    row_count = nrow(data),
    column_count = ncol(data),
    sha256 = if (isTRUE(config$snapshot$calculate_sha256)) {
      sha256_file(output_file)
    } else {
      NA_character_
    }
  )
}


# ---- Run export ---------------------------------------------------------

run_raw_supabase_export <- function(config = audit_config) {
  con <- connect_to_supabase_read_only(config)
  on.exit(DBI::dbDisconnect(con), add = TRUE)

  transaction_open <- FALSE
  committed <- FALSE

  DBI::dbExecute(
    con,
    paste(
      "BEGIN TRANSACTION ISOLATION LEVEL",
      config$snapshot$transaction_isolation,
      "READ ONLY"
    )
  )
  transaction_open <- TRUE

  on.exit({
    if (transaction_open && !committed) {
      try(DBI::dbExecute(con, "ROLLBACK"), silent = TRUE)
    }
  }, add = TRUE)

  metadata <- get_table_metadata(con, config)
  primary_keys <- get_primary_keys(con, config)
  validate_configured_tables(metadata, config)

  queries <- build_export_queries(con, config)
  exported_tables <- purrr::imap(queries, function(query, table_name) {
    message("Reading grp.", table_name, " ...")
    data <- DBI::dbGetQuery(con, query)
    validate_primary_keys(data, table_name, primary_keys)
    data
  })

  selected_projects <- exported_tables$project |>
    transmute(
      database = as.character(.data$database),
      projectid = as.integer(.data$projectid)
    ) |>
    arrange(.data$database, .data$projectid)

  expected_projects <- tidyr::expand_grid(
    database = config$source_database,
    projectid = as.integer(config$projectids)
  ) |>
    arrange(.data$database, .data$projectid)

  missing_projects <- expected_projects |>
  anti_join(
    selected_projects,
    by = c("database", "projectid")
  )

unexpected_projects <- selected_projects |>
  anti_join(
    expected_projects,
    by = c("database", "projectid")
  )

  if (nrow(missing_projects) > 0L ||
    nrow(unexpected_projects) > 0L) {
  stop(
    "The project export does not exactly match the configured projects.",
    call. = FALSE
  )
  }

  DBI::dbExecute(con, "COMMIT")
  committed <- TRUE
  transaction_open <- FALSE

  # Files are written only after every database query and validation succeeds.
  snapshot_dir <- create_snapshot_directory(config)

  manifest <- purrr::imap_dfr(
    exported_tables,
    ~ write_snapshot_table(.x, .y, snapshot_dir, config)
  ) |>
    mutate(
      source_database = config$source_database,
      projectids = paste(config$projectids, collapse = ";"),
      exported_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
      .after = "schema"
    )

  if (isTRUE(config$snapshot$write_schema_metadata)) {
    readr::write_csv(
      metadata,
      file.path(snapshot_dir, "database_columns.csv"),
      na = ""
    )
  }

  if (isTRUE(config$snapshot$write_manifest)) {
    readr::write_csv(
      manifest,
      file.path(snapshot_dir, "export_manifest.csv"),
      na = ""
    )
  }

  message("Raw Supabase snapshot written to: ", snapshot_dir)
  invisible(manifest)
}


run_raw_supabase_export()
