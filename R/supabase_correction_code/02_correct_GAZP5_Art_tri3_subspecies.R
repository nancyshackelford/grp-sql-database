# Correct GAZP5 Art_tri3 to Artemisia tridentata subsp. tridentata.
#
# COMPLETED CORRECTION: The database apply run at 2026-08-14 12:11:18 created
# Art_tri_sub_tri as speciesid 7171, reassigned and verified 462 GAZP5
# veg_result rows and 177 GAZP5 seeding rows, and moved the Art_tri3 name record.
# The automatic repository crosswalk replacement was initially blocked because
# the CSV was open. After the file was closed, its single Art_tri3 row was
# completed as Art_tri3 -> 7171 -> Art_tri_sub_tri and verified. Do not rerun
# this pre-correction workflow against the completed database state. The control
# below is reset to FALSE as an additional safeguard.
#
# This controlled correction has three targets:
#   1. grp.species / grp.species_names: create the accepted subspecies record
#      with canonical species_code Art_tri_sub_tri and attach Art_tri3 to it.
#   2. GAZP5 data: reassign the applicable grp.veg_result and grp.seeding rows
#      from the species-level record (speciesid 484) to the new subspecies ID.
#   3. Repository crosswalk: change Art_tri3 from speciesid 484 / Art_tri to the
#      generated subspecies ID / Art_tri_sub_tri.
#
# The script defaults to PREVIEW ONLY. The PostgreSQL correction is committed
# and verified before the repository CSV is replaced and re-verified. PostgreSQL and
# a local Git-tracked file cannot share one transaction; if the CSV replacement
# fails after the database commit, the correction report clearly identifies the
# required follow-up and the generated speciesid.

suppressPackageStartupMessages({
  library(DBI)
  library(RPostgres)
  library(openxlsx)
  library(readr)
  library(dplyr)
  library(tibble)
  library(stringr)
})


# ---- Operator control --------------------------------------------------

apply_changes <- FALSE

schema_name <- "grp"
database_name <- "GAZP"
projectid <- 5L
project_code <- "GAZP5"
old_speciesid <- 484L
source_species_code <- "Art_tri3"
canonical_species_code <- "Art_tri_sub_tri"
canonical_name <- "Artemisia tridentata subsp. tridentata"

expected_source_veg_rows <- 462L
expected_source_trtrate_rows <- 252L
expected_supabase_veg_rows <- 462L
expected_supabase_seeding_rows <- 177L

harmonized_workbook <- "data/harmonized/GAZP/GAZP5/GAZP5.xlsx"
species_crosswalk_path <- "crosswalk_tables/20260605_sp_crosswalk.csv"
report_root <- "docs/supabase_correction_reports"

run_timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
run_mode <- if (isTRUE(apply_changes)) "apply" else "preview"
report_dir <- file.path(
  report_root,
  paste0(run_timestamp, "_GAZP5_Art_tri3_subspecies_", run_mode)
)


# ---- Connection --------------------------------------------------------

connect_to_supabase <- function() {
  password <- readLines(
    "C:/Users/nshack/OneDrive - University of Victoria/Documents/R/GRP/pword.csv",
    warn = FALSE
  )[1]

  if (is.na(password) || !nzchar(password)) {
    stop("The Supabase password file is empty.", call. = FALSE)
  }

  DBI::dbConnect(
    RPostgres::Postgres(),
    host = "aws-1-ca-central-1.pooler.supabase.com",
    port = 6543,
    dbname = "postgres",
    user = "postgres.rudybfqutvodkakgctpo",
    password = password,
    sslmode = "require"
  )
}


# ---- General validation helpers ---------------------------------------

require_file <- function(path, description) {
  if (!file.exists(path)) {
    stop(description, " was not found: ", path, call. = FALSE)
  }
}

require_columns <- function(data, columns, description) {
  missing_columns <- setdiff(columns, names(data))
  if (length(missing_columns) > 0L) {
    stop(
      description,
      " is missing columns: ",
      paste(missing_columns, collapse = ", "),
      call. = FALSE
    )
  }
}

as_integer_id <- function(x) {
  value <- suppressWarnings(as.integer(x))
  if (any(is.na(value) & !is.na(x))) {
    stop("An expected integer ID could not be parsed.", call. = FALSE)
  }
  value
}

sql_literal <- function(con, value) {
  as.character(DBI::dbQuoteLiteral(con, value))
}

quoted_schema <- function(con) {
  as.character(DBI::dbQuoteIdentifier(con, schema_name))
}


# ---- Validate original GAZP5 meaning ----------------------------------

count_species_codes_in_sheet <- function(path, sheet) {
  data <- openxlsx::read.xlsx(
    path,
    sheet = sheet,
    check.names = FALSE,
    detectDates = FALSE
  )
  require_columns(data, "speciesid", paste0("GAZP5 ", sheet, " sheet"))

  data |>
    transmute(speciesid = stringr::str_trim(as.character(.data$speciesid))) |>
    filter(.data$speciesid %in% c("Art_tri", "Art_tri1", "Art_tri2", "Art_tri3")) |>
    count(.data$speciesid, name = "rows") |>
    mutate(sheet = sheet, .before = 1L)
}

validate_source_workbook <- function() {
  require_file(harmonized_workbook, "GAZP5 harmonized workbook")

  counts <- bind_rows(
    count_species_codes_in_sheet(harmonized_workbook, "trtrates"),
    count_species_codes_in_sheet(harmonized_workbook, "vegresults")
  )

  unexpected <- counts |>
    filter(.data$speciesid != source_species_code)
  if (nrow(unexpected) > 0L) {
    stop(
      "GAZP5 contains another Art_tri* source code; the project-wide speciesid ",
      "reassignment is no longer safe.",
      call. = FALSE
    )
  }

  source_veg <- counts |>
    filter(.data$sheet == "vegresults", .data$speciesid == source_species_code) |>
    pull(.data$rows)
  source_rates <- counts |>
    filter(.data$sheet == "trtrates", .data$speciesid == source_species_code) |>
    pull(.data$rows)

  if (
    length(source_veg) != 1L ||
    length(source_rates) != 1L ||
    source_veg != expected_source_veg_rows ||
    source_rates != expected_source_trtrate_rows
  ) {
    stop(
      "GAZP5 Art_tri3 source counts differ from the reviewed audit counts.",
      call. = FALSE
    )
  }

  counts
}


# ---- Validate repository species crosswalk ----------------------------

read_species_crosswalk <- function() {
  require_file(species_crosswalk_path, "Repository species crosswalk")
  crosswalk <- readr::read_csv(species_crosswalk_path, show_col_types = FALSE)
  require_columns(
    crosswalk,
    c("excel_speciesid", "sql_speciesid", "sql_species_code"),
    "Repository species crosswalk"
  )

  matches <- crosswalk |>
    filter(.data$excel_speciesid == source_species_code)
  if (nrow(matches) != 1L) {
    stop("The species crosswalk must contain exactly one Art_tri3 row.", call. = FALSE)
  }

  list(data = crosswalk, match = matches)
}


# ---- Read live database state -----------------------------------------

read_live_state <- function(con) {
  schema <- quoted_schema(con)
  database <- sql_literal(con, database_name)
  canonical_code <- sql_literal(con, canonical_species_code)
  source_code <- sql_literal(con, source_species_code)

  old_species <- DBI::dbGetQuery(
    con,
    paste0(
      "SELECT * FROM ", schema, ".species WHERE speciesid = ", old_speciesid
    )
  ) |>
    as_tibble()

  canonical_species <- DBI::dbGetQuery(
    con,
    paste0(
      "SELECT * FROM ", schema, ".species\n",
      "WHERE species_code = ", canonical_code, "\n",
      "   OR (genus = 'Artemisia' AND species = 'tridentata'\n",
      "       AND subtype = 'subspecies' AND subtype_name = 'tridentata')"
    )
  ) |>
    as_tibble()

  art_names <- DBI::dbGetQuery(
    con,
    paste0(
      "SELECT speciesid, species_code, name FROM ", schema, ".species_names\n",
      "WHERE species_code IN ('Art_tri', 'Art_tri2', ", source_code, ")\n",
      "ORDER BY speciesid, species_code"
    )
  ) |>
    as_tibble()

  veg_targets <- DBI::dbGetQuery(
    con,
    paste0(
      "SELECT vr.veg_resultid, vr.areaid, vr.speciesid, vr.cultivarid\n",
      "FROM ", schema, ".veg_result vr\n",
      "WHERE vr.speciesid = ", old_speciesid, "\n",
      "  AND EXISTS (\n",
      "    SELECT 1 FROM ", schema, ".area_treatment at\n",
      "    WHERE at.areaid = vr.areaid\n",
      "      AND at.database = ", database, "\n",
      "      AND at.projectid = ", projectid, "\n",
      "  )\n",
      "ORDER BY vr.veg_resultid"
    )
  ) |>
    as_tibble()

  seeding_targets <- DBI::dbGetQuery(
    con,
    paste0(
      "SELECT se.seedingid, se.treatmentid, se.speciesid, se.cultivarid,\n",
      "       se.rate, se.unit\n",
      "FROM ", schema, ".seeding se\n",
      "WHERE se.speciesid = ", old_speciesid, "\n",
      "  AND EXISTS (\n",
      "    SELECT 1 FROM ", schema, ".area_treatment at\n",
      "    WHERE at.treatmentid = se.treatmentid\n",
      "      AND at.database = ", database, "\n",
      "      AND at.projectid = ", projectid, "\n",
      "  )\n",
      "ORDER BY se.seedingid"
    )
  ) |>
    as_tibble()

  other_references <- DBI::dbGetQuery(
    con,
    paste0(
      "SELECT 'veg_result_outside_GAZP5' AS reference_type, count(*)::integer AS rows\n",
      "FROM ", schema, ".veg_result vr\n",
      "WHERE vr.speciesid = ", old_speciesid, "\n",
      "  AND NOT EXISTS (SELECT 1 FROM ", schema, ".area_treatment at\n",
      "    WHERE at.areaid = vr.areaid AND at.database = ", database,
      " AND at.projectid = ", projectid, ")\n",
      "UNION ALL\n",
      "SELECT 'seeding_outside_GAZP5', count(*)::integer\n",
      "FROM ", schema, ".seeding se\n",
      "WHERE se.speciesid = ", old_speciesid, "\n",
      "  AND NOT EXISTS (SELECT 1 FROM ", schema, ".area_treatment at\n",
      "    WHERE at.treatmentid = se.treatmentid AND at.database = ", database,
      " AND at.projectid = ", projectid, ")\n"
    )
  ) |>
    as_tibble()

  gazp5_other_references <- DBI::dbGetQuery(
    con,
    paste0(
      "SELECT 'individual' AS table_name, count(*)::integer AS rows\n",
      "FROM ", schema, ".individual i\n",
      "WHERE i.speciesid = ", old_speciesid, "\n",
      "  AND EXISTS (SELECT 1 FROM ", schema, ".area_treatment at\n",
      "    WHERE at.areaid = i.areaid AND at.database = ", database,
      " AND at.projectid = ", projectid, ")\n",
      "UNION ALL\n",
      "SELECT 'site_invasive', count(*)::integer\n",
      "FROM ", schema, ".site_invasive si\n",
      "WHERE si.speciesid = ", old_speciesid, "\n",
      "  AND EXISTS (SELECT 1 FROM ", schema, ".project_site ps\n",
      "    WHERE ps.siteid = si.siteid AND ps.database = ", database,
      " AND ps.projectid = ", projectid, ")\n",
      "UNION ALL\n",
      "SELECT 'treatment_cover_crop', count(*)::integer\n",
      "FROM ", schema, ".treatment_cover_crop tc\n",
      "WHERE tc.speciesid = ", old_speciesid, "\n",
      "  AND EXISTS (SELECT 1 FROM ", schema, ".area_treatment at\n",
      "    WHERE at.treatmentid = tc.treatmentid AND at.database = ", database,
      " AND at.projectid = ", projectid, ")"
    )
  ) |>
    as_tibble()

  list(
    old_species = old_species,
    canonical_species = canonical_species,
    art_names = art_names,
    veg_targets = veg_targets,
    seeding_targets = seeding_targets,
    other_references = other_references,
    gazp5_other_references = gazp5_other_references
  )
}


validate_live_state <- function(state, crosswalk_state) {
  expected_old <- tibble(
    speciesid = old_speciesid,
    species_code = "Art_tri",
    group = "Angiosperms",
    order = "Asterales",
    family = "Asteraceae",
    genus = "Artemisia",
    species = "tridentata",
    subtype = NA_character_,
    subtype_name = NA_character_,
    lifeform = "shrub"
  )

  if (nrow(state$old_species) != 1L) {
    stop("Speciesid 484 was not found exactly once.", call. = FALSE)
  }

  compare_columns <- setdiff(names(expected_old), "speciesid")
  for (column in compare_columns) {
    actual <- state$old_species[[column]][[1]]
    expected <- expected_old[[column]][[1]]
    same <- (is.na(actual) && is.na(expected)) || identical(actual, expected)
    if (!same) {
      stop(
        "Speciesid 484 differs from the reviewed value in column ",
        column,
        ".",
        call. = FALSE
      )
    }
  }

  if (nrow(state$canonical_species) > 1L) {
    stop("Multiple possible canonical subspecies records exist.", call. = FALSE)
  }
  if (nrow(state$canonical_species) == 1L) {
    canonical <- state$canonical_species[1, ]
    valid <- identical(canonical$species_code[[1]], canonical_species_code) &&
      identical(canonical$group[[1]], "Angiosperms") &&
      identical(canonical$order[[1]], "Asterales") &&
      identical(canonical$family[[1]], "Asteraceae") &&
      identical(canonical$genus[[1]], "Artemisia") &&
      identical(canonical$species[[1]], "tridentata") &&
      identical(canonical$subtype[[1]], "subspecies") &&
      identical(canonical$subtype_name[[1]], "tridentata") &&
      identical(canonical$lifeform[[1]], "shrub")
    if (!valid) {
      stop("The existing canonical-code record has conflicting taxonomy.", call. = FALSE)
    }
  }

  required_names <- tibble(
    speciesid = c(old_speciesid, old_speciesid, old_speciesid),
    species_code = c("Art_tri", "Art_tri2", source_species_code),
    name = c(
      "Artemisia tridentata",
      "Artemisia tridentata",
      "Artemisia tridentata"
    )
  )
  matched_names <- state$art_names |>
    inner_join(
      required_names,
      by = c("speciesid", "species_code", "name")
    )
  if (nrow(state$art_names) != 3L || nrow(matched_names) != 3L) {
    stop("The live Art_tri species_names rows differ from the reviewed state.", call. = FALSE)
  }

  if (nrow(state$veg_targets) != expected_supabase_veg_rows) {
    stop(
      "Found ", nrow(state$veg_targets), " GAZP5 vegetation targets; expected ",
      expected_supabase_veg_rows, ".",
      call. = FALSE
    )
  }
  if (nrow(state$seeding_targets) != expected_supabase_seeding_rows) {
    stop(
      "Found ", nrow(state$seeding_targets), " GAZP5 seeding targets; expected ",
      expected_supabase_seeding_rows, ".",
      call. = FALSE
    )
  }
  if (
    any(!is.na(state$veg_targets$cultivarid)) ||
    any(!is.na(state$seeding_targets$cultivarid))
  ) {
    stop("A target has a cultivarid and requires separate FK handling.", call. = FALSE)
  }
  if (any(state$gazp5_other_references$rows != 0L)) {
    stop(
      "GAZP5 has an unexpected speciesid 484 reference outside veg_result and ",
      "seeding.",
      call. = FALSE
    )
  }

  crosswalk_match <- crosswalk_state$match
  current_crosswalk_id <- as_integer_id(crosswalk_match$sql_speciesid)
  current_crosswalk_code <- as.character(crosswalk_match$sql_species_code)
  existing_canonical_id <- if (nrow(state$canonical_species) == 1L) {
    as_integer_id(state$canonical_species$speciesid[[1]])
  } else {
    NA_integer_
  }

  crosswalk_is_pre_correction <-
    current_crosswalk_id == old_speciesid && current_crosswalk_code == "Art_tri"
  crosswalk_is_already_correct <-
    !is.na(existing_canonical_id) &&
      current_crosswalk_id == existing_canonical_id &&
      current_crosswalk_code == canonical_species_code

  if (!crosswalk_is_pre_correction && !crosswalk_is_already_correct) {
    stop("The Art_tri3 repository crosswalk row is in an unexpected state.", call. = FALSE)
  }

  invisible(TRUE)
}


# ---- Preview summaries and reports ------------------------------------

build_preview_summary <- function(source_counts, state, crosswalk_state) {
  canonical_id <- if (nrow(state$canonical_species) == 1L) {
    as_integer_id(state$canonical_species$speciesid[[1]])
  } else {
    NA_integer_
  }

  tibble(
    project_code = project_code,
    source_species_code = source_species_code,
    old_speciesid = old_speciesid,
    canonical_species_code = canonical_species_code,
    canonical_speciesid_before_apply = canonical_id,
    source_veg_rows = source_counts |>
      filter(.data$sheet == "vegresults") |>
      pull(.data$rows),
    source_trtrate_rows = source_counts |>
      filter(.data$sheet == "trtrates") |>
      pull(.data$rows),
    supabase_veg_rows_to_reassign = nrow(state$veg_targets),
    supabase_seeding_rows_to_reassign = nrow(state$seeding_targets),
    crosswalk_current_speciesid = as_integer_id(
      crosswalk_state$match$sql_speciesid[[1]]
    ),
    crosswalk_current_species_code = as.character(
      crosswalk_state$match$sql_species_code[[1]]
    )
  )
}

write_correction_reports <- function(summary, state, outcome,
                                     assigned_speciesid = NA_integer_,
                                     crosswalk_outcome = "NOT_ATTEMPTED") {
  dir.create(report_dir, recursive = TRUE, showWarnings = FALSE)

  final_summary <- summary |>
    mutate(
      assigned_speciesid = as.integer(assigned_speciesid),
      database_outcome = outcome,
      repository_crosswalk_outcome = crosswalk_outcome
    )

  readr::write_csv(
    final_summary,
    file.path(report_dir, "Art_tri3_correction_summary.csv"),
    na = ""
  )
  readr::write_csv(
    state$veg_targets,
    file.path(report_dir, "GAZP5_veg_result_targets.csv"),
    na = ""
  )
  readr::write_csv(
    state$seeding_targets,
    file.path(report_dir, "GAZP5_seeding_targets.csv"),
    na = ""
  )
  readr::write_csv(
    state$other_references,
    file.path(report_dir, "speciesid_484_outside_GAZP5_summary.csv"),
    na = ""
  )
  readr::write_csv(
    state$gazp5_other_references,
    file.path(report_dir, "GAZP5_other_speciesid_484_references.csv"),
    na = ""
  )

  lines <- c(
    "# GAZP5 Art_tri3 subspecies correction",
    "",
    paste0("Run timestamp: `", run_timestamp, "`"),
    paste0("Mode: `", run_mode, "`"),
    paste0("Database outcome: `", outcome, "`"),
    paste0("Repository crosswalk outcome: `", crosswalk_outcome, "`"),
    paste0("Assigned subspecies ID: `", ifelse(
      is.na(assigned_speciesid), "not assigned in preview", assigned_speciesid
    ), "`"),
    "",
    "Canonical taxon: Artemisia tridentata subsp. tridentata",
    "Canonical species code: Art_tri_sub_tri",
    "Source GAZP5 code: Art_tri3",
    "",
    "The database transaction and local repository-file replacement are separate",
    "operations because PostgreSQL and Git-tracked files cannot share one",
    "transaction. The database is committed and verified first; the crosswalk is",
    "then backed up, replaced, and re-verified on the local filesystem.",
    "",
    "## Summary",
    "",
    paste(capture.output(print(final_summary, n = Inf)), collapse = "\n")
  )
  writeLines(lines, file.path(report_dir, "correction_report.md"), useBytes = TRUE)
}


# ---- Apply database correction ----------------------------------------

insert_or_get_canonical_species <- function(con) {
  schema <- quoted_schema(con)
  existing <- DBI::dbGetQuery(
    con,
    paste0(
      "SELECT speciesid FROM ", schema, ".species\n",
      "WHERE species_code = 'Art_tri_sub_tri'\n",
      "  AND genus = 'Artemisia' AND species = 'tridentata'\n",
      "  AND subtype = 'subspecies' AND subtype_name = 'tridentata'\n",
      "FOR UPDATE"
    )
  )
  if (nrow(existing) == 1L) {
    return(as_integer_id(existing$speciesid[[1]]))
  }
  if (nrow(existing) > 1L) {
    stop("Multiple canonical subspecies records exist.", call. = FALSE)
  }

  inserted <- DBI::dbGetQuery(
    con,
    paste0(
      "INSERT INTO ", schema, ".species\n",
      "  (species_code, \"group\", \"order\", family, genus, species,\n",
      "   subtype, subtype_name, lifeform)\n",
      "VALUES ('Art_tri_sub_tri', 'Angiosperms', 'Asterales', 'Asteraceae',\n",
      "        'Artemisia', 'tridentata', 'subspecies', 'tridentata', 'shrub')\n",
      "RETURNING speciesid"
    )
  )
  as_integer_id(inserted$speciesid[[1]])
}

apply_database_correction <- function(con, preview_state) {
  schema <- quoted_schema(con)
  database <- sql_literal(con, database_name)

  assigned_speciesid <- DBI::dbWithTransaction(con, {
    # Lock and confirm every previewed target still exists in the same state.
    veg_ids <- paste(preview_state$veg_targets$veg_resultid, collapse = ", ")
    seeding_ids <- paste(preview_state$seeding_targets$seedingid, collapse = ", ")

    locked_veg <- DBI::dbGetQuery(
      con,
      paste0(
        "SELECT veg_resultid, speciesid, cultivarid FROM ", schema,
        ".veg_result WHERE veg_resultid IN (", veg_ids, ") FOR UPDATE"
      )
    )
    locked_seeding <- DBI::dbGetQuery(
      con,
      paste0(
        "SELECT seedingid, speciesid, cultivarid FROM ", schema,
        ".seeding WHERE seedingid IN (", seeding_ids, ") FOR UPDATE"
      )
    )
    DBI::dbGetQuery(
      con,
      paste0(
        "SELECT speciesid FROM ", schema, ".species WHERE speciesid = ",
        old_speciesid, " FOR UPDATE"
      )
    )
    locked_name <- DBI::dbGetQuery(
      con,
      paste0(
        "SELECT speciesid, species_code, name FROM ", schema,
        ".species_names WHERE species_code = 'Art_tri3' FOR UPDATE"
      )
    )

    if (
      nrow(locked_veg) != expected_supabase_veg_rows ||
      nrow(locked_seeding) != expected_supabase_seeding_rows ||
      any(as_integer_id(locked_veg$speciesid) != old_speciesid) ||
      any(as_integer_id(locked_seeding$speciesid) != old_speciesid) ||
      any(!is.na(locked_veg$cultivarid)) ||
      any(!is.na(locked_seeding$cultivarid)) ||
      nrow(locked_name) != 1L ||
      as_integer_id(locked_name$speciesid[[1]]) != old_speciesid ||
      locked_name$name[[1]] != "Artemisia tridentata"
    ) {
      stop("Live targets changed after preview; rolling back.", call. = FALSE)
    }

    assigned_speciesid <- insert_or_get_canonical_species(con)

    names_updated <- DBI::dbExecute(
      con,
      paste0(
        "UPDATE ", schema, ".species_names\n",
        "SET speciesid = ", assigned_speciesid, ",\n",
        "    name = 'Artemisia tridentata subsp. tridentata'\n",
        "WHERE speciesid = ", old_speciesid,
        " AND species_code = 'Art_tri3'"
      )
    )
    if (names_updated != 1L) {
      stop("Expected to move exactly one Art_tri3 name row.", call. = FALSE)
    }

    veg_updated <- DBI::dbExecute(
      con,
      paste0(
        "UPDATE ", schema, ".veg_result vr\n",
        "SET speciesid = ", assigned_speciesid, "\n",
        "WHERE vr.speciesid = ", old_speciesid, "\n",
        "  AND EXISTS (SELECT 1 FROM ", schema, ".area_treatment at\n",
        "    WHERE at.areaid = vr.areaid AND at.database = ", database,
        " AND at.projectid = ", projectid, ")"
      )
    )
    seeding_updated <- DBI::dbExecute(
      con,
      paste0(
        "UPDATE ", schema, ".seeding se\n",
        "SET speciesid = ", assigned_speciesid, "\n",
        "WHERE se.speciesid = ", old_speciesid, "\n",
        "  AND EXISTS (SELECT 1 FROM ", schema, ".area_treatment at\n",
        "    WHERE at.treatmentid = se.treatmentid AND at.database = ", database,
        " AND at.projectid = ", projectid, ")"
      )
    )

    if (
      veg_updated != expected_supabase_veg_rows ||
      seeding_updated != expected_supabase_seeding_rows
    ) {
      stop("Database update counts differ from preview; rolling back.", call. = FALSE)
    }

    verification <- DBI::dbGetQuery(
      con,
      paste0(
        "SELECT\n",
        "  (SELECT count(*) FROM ", schema,
        ".veg_result vr WHERE vr.speciesid = ", assigned_speciesid,
        " AND EXISTS (SELECT 1 FROM ", schema,
        ".area_treatment at WHERE at.areaid = vr.areaid AND at.database = ",
        database, " AND at.projectid = ", projectid, "))::integer AS veg_new,\n",
        "  (SELECT count(*) FROM ", schema,
        ".veg_result vr WHERE vr.speciesid = ", old_speciesid,
        " AND EXISTS (SELECT 1 FROM ", schema,
        ".area_treatment at WHERE at.areaid = vr.areaid AND at.database = ",
        database, " AND at.projectid = ", projectid, "))::integer AS veg_old,\n",
        "  (SELECT count(*) FROM ", schema,
        ".seeding se WHERE se.speciesid = ", assigned_speciesid,
        " AND EXISTS (SELECT 1 FROM ", schema,
        ".area_treatment at WHERE at.treatmentid = se.treatmentid AND at.database = ",
        database, " AND at.projectid = ", projectid, "))::integer AS seeding_new,\n",
        "  (SELECT count(*) FROM ", schema,
        ".seeding se WHERE se.speciesid = ", old_speciesid,
        " AND EXISTS (SELECT 1 FROM ", schema,
        ".area_treatment at WHERE at.treatmentid = se.treatmentid AND at.database = ",
        database, " AND at.projectid = ", projectid, "))::integer AS seeding_old,\n",
        "  (SELECT count(*) FROM ", schema,
        ".species_names WHERE speciesid = ", assigned_speciesid,
        " AND species_code = 'Art_tri3'",
        " AND name = 'Artemisia tridentata subsp. tridentata')::integer AS name_new,\n",
        "  (SELECT count(*) FROM ", schema,
        ".species_names WHERE speciesid = ", old_speciesid,
        " AND species_code IN ('Art_tri','Art_tri2'))::integer AS old_names"
      )
    )

    passed <- verification$veg_new[[1]] == expected_supabase_veg_rows &&
      verification$veg_old[[1]] == 0L &&
      verification$seeding_new[[1]] == expected_supabase_seeding_rows &&
      verification$seeding_old[[1]] == 0L &&
      verification$name_new[[1]] == 1L &&
      verification$old_names[[1]] == 2L
    if (!passed) {
      stop("Post-update database verification failed; rolling back.", call. = FALSE)
    }

    assigned_speciesid
  })

  assigned_speciesid
}


# ---- Atomically update repository crosswalk ----------------------------

update_repository_crosswalk <- function(crosswalk_state, assigned_speciesid) {
  updated <- crosswalk_state$data |>
    mutate(
      sql_speciesid = if_else(
        .data$excel_speciesid == source_species_code,
        as.integer(assigned_speciesid),
        as.integer(.data$sql_speciesid)
      ),
      sql_species_code = if_else(
        .data$excel_speciesid == source_species_code,
        canonical_species_code,
        as.character(.data$sql_species_code)
      )
    )

  parent <- dirname(species_crosswalk_path)
  temporary_path <- tempfile(
    pattern = "species_crosswalk_Art_tri3_",
    tmpdir = parent,
    fileext = ".csv"
  )
  on.exit(if (file.exists(temporary_path)) unlink(temporary_path), add = TRUE)

  readr::write_csv(updated, temporary_path, na = "")
  verify <- readr::read_csv(temporary_path, show_col_types = FALSE) |>
    filter(.data$excel_speciesid == source_species_code)
  if (
    nrow(verify) != 1L ||
    as_integer_id(verify$sql_speciesid[[1]]) != assigned_speciesid ||
    verify$sql_species_code[[1]] != canonical_species_code
  ) {
    stop("Temporary corrected crosswalk failed verification.", call. = FALSE)
  }

  backup_path <- file.path(
    report_dir,
    paste0(
      "20260605_sp_crosswalk_pre_Art_tri3_correction_",
      run_timestamp,
      ".csv"
    )
  )
  if (!file.copy(species_crosswalk_path, backup_path, overwrite = FALSE)) {
    stop("Could not create the pre-correction crosswalk backup.", call. = FALSE)
  }
  if (!file.copy(temporary_path, species_crosswalk_path, overwrite = TRUE)) {
    stop(
      "Database committed, but repository crosswalk replacement failed. Backup: ",
      backup_path,
      call. = FALSE
    )
  }

  final <- readr::read_csv(species_crosswalk_path, show_col_types = FALSE) |>
    filter(.data$excel_speciesid == source_species_code)
  if (
    nrow(final) != 1L ||
    as_integer_id(final$sql_speciesid[[1]]) != assigned_speciesid ||
    final$sql_species_code[[1]] != canonical_species_code
  ) {
    stop(
      "Database committed, but final repository crosswalk verification failed.",
      call. = FALSE
    )
  }

  backup_path
}


# ---- Run ---------------------------------------------------------------

run_Art_tri3_correction <- function() {
  message("Validating original GAZP5 Art_tri3 records ...")
  source_counts <- validate_source_workbook()

  message("Validating repository species crosswalk ...")
  crosswalk_state <- read_species_crosswalk()

  con <- connect_to_supabase()
  on.exit({
    if (DBI::dbIsValid(con)) DBI::dbDisconnect(con)
  }, add = TRUE)

  message("Reading and validating live Supabase state ...")
  state <- read_live_state(con)
  validate_live_state(state, crosswalk_state)
  summary <- build_preview_summary(source_counts, state, crosswalk_state)
  print(summary, n = Inf)

  if (!isTRUE(apply_changes)) {
    write_correction_reports(
      summary,
      state,
      outcome = "PREVIEW_ONLY_NO_CHANGES",
      crosswalk_outcome = "PREVIEW_ONLY_NO_CHANGES"
    )
    message("PREVIEW ONLY: no Supabase or repository values were changed.")
    message("Correction report written to: ", report_dir)
    return(invisible(list(summary = summary, state = state)))
  }

  message("APPLY MODE: correcting and verifying Supabase transaction ...")
  assigned_speciesid <- apply_database_correction(con, state)

  # Record the committed DB state before attempting the separate file update.
  write_correction_reports(
    summary,
    state,
    outcome = "DATABASE_COMMITTED_AND_VERIFIED",
    assigned_speciesid = assigned_speciesid,
    crosswalk_outcome = "PENDING"
  )

  message("Updating and verifying repository species crosswalk ...")
  crosswalk_backup <- update_repository_crosswalk(
    crosswalk_state,
    assigned_speciesid
  )

  write_correction_reports(
    summary,
    state,
    outcome = "DATABASE_COMMITTED_AND_VERIFIED",
    assigned_speciesid = assigned_speciesid,
    crosswalk_outcome = paste0(
      "UPDATED_AND_VERIFIED; backup=",
      crosswalk_backup
    )
  )

  message("Supabase correction committed and verified.")
  message("Repository species crosswalk updated and verified.")
  message("Assigned Art_tri_sub_tri speciesid: ", assigned_speciesid)
  message("Correction report written to: ", report_dir)

  invisible(list(
    assigned_speciesid = assigned_speciesid,
    summary = summary,
    report_dir = report_dir,
    crosswalk_backup = crosswalk_backup
  ))
}

Art_tri3_correction_run <- run_Art_tri3_correction()
