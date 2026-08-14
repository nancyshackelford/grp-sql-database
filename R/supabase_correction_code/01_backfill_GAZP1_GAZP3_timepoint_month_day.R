# Backfill missing month and day values on grp.veg_result for GAZP1-3.
#
# COMPLETED CORRECTION: The apply run at 2026-08-14 11:23:03 committed and
# passed live read-back verification. It populated month on 1,282 veg_result
# rows: 625 for GAZP1, 576 for GAZP2, and 81 for GAZP3, representing 20, 72,
# and 9 source treatment/timepoint keys respectively. The harmonized timepoint
# sheets contained no day values for these projects, so no day values were
# changed. Evidence is stored under docs/supabase_correction_reports/
# 20260814_112303_GAZP1_GAZP3_timepoint_month_day_apply. The control below has
# been reset to FALSE to make any future rerun preview-only by default.
#
# The original harmonized timepoints sheets are authoritative for this repair.
# Source treatmentid + tsr is translated to Supabase areaid with the repository
# project crosswalks, then applied to every matching veg_result row. The script
# defaults to PREVIEW ONLY. Set apply_changes to TRUE only after reviewing the
# generated preview files in docs/supabase_correction_reports.
#
# This correction changes only missing month/day values. It never changes year,
# time_since_restoration, identifiers, or already-populated conflicting values.

suppressPackageStartupMessages({
  library(DBI)
  library(RPostgres)
  library(openxlsx)
  library(readr)
  library(dplyr)
  library(purrr)
  library(tibble)
  library(stringr)
})


# ---- Operator control --------------------------------------------------

apply_changes <- FALSE

schema_name <- "grp"
database_name <- "GAZP"
project_codes <- c("GAZP1", "GAZP2", "GAZP3")
projectids <- c(GAZP1 = 1L, GAZP2 = 2L, GAZP3 = 3L)

expected_month_keys <- c(GAZP1 = 20L, GAZP2 = 72L, GAZP3 = 9L)

harmonized_workbooks <- c(
  GAZP1 = "data/harmonized/GAZP/GAZP1/GAZP1.xlsx",
  GAZP2 = "data/harmonized/GAZP/GAZP2/GAZP2.xlsx",
  GAZP3 = "data/harmonized/GAZP/GAZP3/GAZP3.xlsx"
)

project_crosswalks <- c(
  GAZP1 = "crosswalk_tables/GAZP/GAZP1/GAZP1_harmonized-SQL_crosswalk.csv",
  GAZP2 = "crosswalk_tables/GAZP/GAZP2/GAZP2_harmonized-SQL_crosswalk.csv",
  GAZP3 = "crosswalk_tables/GAZP/GAZP3/GAZP3_harmonized-SQL_crosswalk.csv"
)

report_root <- "docs/supabase_correction_reports"
run_timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
run_mode <- if (isTRUE(apply_changes)) "apply" else "preview"
report_dir <- file.path(
  report_root,
  paste0(run_timestamp, "_GAZP1_GAZP3_timepoint_month_day_", run_mode)
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


# ---- Validation helpers ------------------------------------------------

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

normalize_source_id <- function(x) {
  value <- stringr::str_trim(as.character(x))
  value[value %in% c("", "NA", "NaN")] <- NA_character_
  value
}

integer_or_na <- function(x, description) {
  source_value <- stringr::str_trim(as.character(x))
  source_value[source_value %in% c("", "NA", "NaN")] <- NA_character_
  numeric_value <- suppressWarnings(as.numeric(source_value))
  bad <- !is.na(source_value) & is.na(numeric_value)
  non_integer <- !is.na(numeric_value) & numeric_value != floor(numeric_value)

  if (any(bad | non_integer)) {
    stop(description, " contains non-integer values.", call. = FALSE)
  }

  as.integer(numeric_value)
}

first_present_integer <- function(x) {
  value <- unique(x[!is.na(x)])
  if (length(value) == 0L) NA_integer_ else value[[1]]
}

sql_integer_list <- function(con, values) {
  values <- unique(as.integer(values))
  values <- values[!is.na(values)]
  if (length(values) == 0L) {
    stop("Cannot construct an SQL list from zero IDs.", call. = FALSE)
  }
  paste(DBI::dbQuoteLiteral(con, values), collapse = ", ")
}


# ---- Load authoritative source timepoints ------------------------------

read_source_timepoints <- function(project_code) {
  path <- unname(harmonized_workbooks[[project_code]])
  current_projectid <- unname(projectids[[project_code]])
  require_file(path, paste0(project_code, " harmonized workbook"))

  source <- openxlsx::read.xlsx(
    path,
    sheet = "timepoints",
    check.names = FALSE,
    detectDates = FALSE
  )
  require_columns(
    source,
    c("treatmentid", "tsr", "month", "day"),
    paste0(project_code, " timepoints sheet")
  )

  source <- source |>
    transmute(
      project_code = .env$project_code,
      projectid = .env$current_projectid,
      source_treatmentid = normalize_source_id(.data$treatmentid),
      tsr = integer_or_na(.data$tsr, paste0(.env$project_code, " tsr")),
      source_month = integer_or_na(
        .data$month,
        paste0(.env$project_code, " month")
      ),
      source_day = integer_or_na(
        .data$day,
        paste0(.env$project_code, " day")
      )
    )

  if (any(is.na(source$source_treatmentid)) || any(is.na(source$tsr))) {
    stop(
      project_code,
      " has a missing treatmentid or tsr in its timepoints sheet.",
      call. = FALSE
    )
  }

  conflicts <- source |>
    group_by(.data$source_treatmentid, .data$tsr) |>
    summarise(
      month_values = n_distinct(.data$source_month, na.rm = TRUE),
      day_values = n_distinct(.data$source_day, na.rm = TRUE),
      .groups = "drop"
    ) |>
    filter(.data$month_values > 1L | .data$day_values > 1L)

  if (nrow(conflicts) > 0L) {
    stop(
      project_code,
      " has conflicting month/day values for the same treatmentid + tsr.",
      call. = FALSE
    )
  }

  source <- source |>
    group_by(
      .data$project_code,
      .data$projectid,
      .data$source_treatmentid,
      .data$tsr
    ) |>
    summarise(
      source_month = first_present_integer(.data$source_month),
      source_day = first_present_integer(.data$source_day),
      .groups = "drop"
    )

  bad_month <- source |>
    filter(!is.na(.data$source_month) & !between(.data$source_month, 1L, 12L))
  bad_day <- source |>
    filter(!is.na(.data$source_day) & !between(.data$source_day, 1L, 31L))

  if (nrow(bad_month) > 0L || nrow(bad_day) > 0L) {
    stop(project_code, " has a month/day outside its valid range.", call. = FALSE)
  }

  actual_month_keys <- sum(!is.na(source$source_month))
  expected <- unname(expected_month_keys[[project_code]])
  if (!identical(as.integer(actual_month_keys), as.integer(expected))) {
    stop(
      project_code,
      " has ",
      actual_month_keys,
      " populated month keys; expected ",
      expected,
      ".",
      call. = FALSE
    )
  }

  source
}


# ---- Load source-treatment to Supabase-area mappings -------------------

read_area_crosswalk <- function(project_code) {
  path <- unname(project_crosswalks[[project_code]])
  current_projectid <- unname(projectids[[project_code]])
  require_file(path, paste0(project_code, " harmonized-SQL crosswalk"))

  crosswalk <- readr::read_csv(path, show_col_types = FALSE)
  require_columns(
    crosswalk,
    c("database", "projectid", "object_type", "source_treatmentid", "areaid"),
    paste0(project_code, " harmonized-SQL crosswalk")
  )

  result <- crosswalk |>
    filter(.data$object_type == "plot") |>
    transmute(
      project_code = .env$project_code,
      projectid = as.integer(.data$projectid),
      source_treatmentid = normalize_source_id(.data$source_treatmentid),
      areaid = as.integer(.data$areaid)
    ) |>
    distinct()

  expected_projectid <- current_projectid
  if (
    nrow(result) == 0L ||
    any(is.na(result$source_treatmentid)) ||
    any(is.na(result$areaid)) ||
    !identical(unique(result$projectid), expected_projectid)
  ) {
    stop(project_code, " has an invalid plot-area crosswalk.", call. = FALSE)
  }

  result
}


# ---- Read and validate live Supabase targets ---------------------------

read_live_results <- function(con, areaids) {
  schema <- as.character(DBI::dbQuoteIdentifier(con, schema_name))
  areas <- sql_integer_list(con, areaids)
  database <- as.character(DBI::dbQuoteLiteral(con, database_name))
  projects <- sql_integer_list(con, unname(projectids))

  sql <- paste0(
    "SELECT vr.veg_resultid, vr.areaid, vr.time_since_restoration, ",
    "vr.year, vr.month, vr.day, scoped.database, scoped.projectid\n",
    "FROM ", schema, ".veg_result vr\n",
    "JOIN (\n",
    "  SELECT DISTINCT database, projectid, areaid\n",
    "  FROM ", schema, ".area_treatment\n",
    "  WHERE database = ", database, "\n",
    "    AND projectid IN (", projects, ")\n",
    ") scoped USING (areaid)\n",
    "WHERE vr.areaid IN (", areas, ")"
  )

  DBI::dbGetQuery(con, sql) |>
    as_tibble() |>
    mutate(
      veg_resultid = as.integer(.data$veg_resultid),
      areaid = as.integer(.data$areaid),
      time_since_restoration = as.integer(.data$time_since_restoration),
      projectid = as.integer(.data$projectid),
      month = as.integer(.data$month),
      day = as.integer(.data$day)
    )
}


build_correction_plan <- function(source_timepoints, area_map, live_results) {
  source_area <- source_timepoints |>
    left_join(
      area_map,
      by = c("project_code", "projectid", "source_treatmentid"),
      relationship = "many-to-many"
    )

  missing_area <- source_area |>
    filter(is.na(.data$areaid))
  if (nrow(missing_area) > 0L) {
    stop(
      "Some source timepoints have no Supabase area mapping. See in-memory ",
      "object `missing_area` while debugging.",
      call. = FALSE
    )
  }

  duplicate_scope <- live_results |>
    count(.data$veg_resultid) |>
    filter(.data$n != 1L)
  if (nrow(duplicate_scope) > 0L) {
    stop(
      "A live veg_result belongs to more than one selected project scope.",
      call. = FALSE
    )
  }

  plan <- source_area |>
    left_join(
      live_results,
      by = c(
        "projectid",
        "areaid",
        "tsr" = "time_since_restoration"
      )
    )

  missing_live <- plan |>
    filter(is.na(.data$veg_resultid))
  if (nrow(missing_live) > 0L) {
    stop(
      "Some source treatmentid + tsr + areaid combinations have no live ",
      "veg_result rows.",
      call. = FALSE
    )
  }

  wrong_database <- plan |>
    filter(.data$database != database_name)
  if (nrow(wrong_database) > 0L) {
    stop("A correction target belongs to the wrong database.", call. = FALSE)
  }

  conflicts <- plan |>
    filter(
      (!is.na(.data$source_month) & !is.na(.data$month) &
         .data$source_month != .data$month) |
        (!is.na(.data$source_day) & !is.na(.data$day) &
           .data$source_day != .data$day)
    )
  if (nrow(conflicts) > 0L) {
    stop(
      "Live Supabase contains non-missing month/day values that conflict with ",
      "the harmonized source. No changes were made.",
      call. = FALSE
    )
  }

  plan <- plan |>
    transmute(
      project_code,
      projectid,
      source_treatmentid,
      tsr,
      source_month,
      source_day,
      supabase_areaid = .data$areaid,
      supabase_veg_resultid = .data$veg_resultid,
      current_year = .data$year,
      current_month = .data$month,
      proposed_month = .data$source_month,
      month_action = case_when(
        is.na(.data$source_month) ~ "source_missing_leave_unchanged",
        is.na(.data$month) ~ "update_missing",
        .data$month == .data$source_month ~ "already_correct",
        TRUE ~ "conflict"
      ),
      current_day = .data$day,
      proposed_day = .data$source_day,
      day_action = case_when(
        is.na(.data$source_day) ~ "source_missing_leave_unchanged",
        is.na(.data$day) ~ "update_missing",
        .data$day == .data$source_day ~ "already_correct",
        TRUE ~ "conflict"
      )
    ) |>
    distinct()

  conflicting_targets <- plan |>
    group_by(.data$supabase_veg_resultid) |>
    summarise(
      month_values = n_distinct(.data$proposed_month, na.rm = TRUE),
      day_values = n_distinct(.data$proposed_day, na.rm = TRUE),
      .groups = "drop"
    ) |>
    filter(.data$month_values > 1L | .data$day_values > 1L)
  if (nrow(conflicting_targets) > 0L) {
    stop("A veg_result received conflicting proposed values.", call. = FALSE)
  }

  plan |>
    arrange(
      .data$projectid,
      .data$source_treatmentid,
      .data$tsr,
      .data$supabase_areaid,
      .data$supabase_veg_resultid
    )
}


# ---- Reports -----------------------------------------------------------

summarise_plan <- function(plan) {
  plan |>
    group_by(.data$project_code) |>
    summarise(
      source_timepoint_keys = n_distinct(
        paste(.data$source_treatmentid, .data$tsr, sep = "|")
      ),
      supabase_rows = n_distinct(.data$supabase_veg_resultid),
      month_rows_to_update = sum(.data$month_action == "update_missing"),
      month_rows_already_correct = sum(.data$month_action == "already_correct"),
      month_source_missing = sum(
        .data$month_action == "source_missing_leave_unchanged"
      ),
      day_rows_to_update = sum(.data$day_action == "update_missing"),
      day_rows_already_correct = sum(.data$day_action == "already_correct"),
      day_source_missing = sum(
        .data$day_action == "source_missing_leave_unchanged"
      ),
      .groups = "drop"
    )
}

write_reports <- function(plan, summary, outcome) {
  dir.create(report_dir, recursive = TRUE, showWarnings = FALSE)

  readr::write_csv(
    plan,
    file.path(report_dir, "timepoint_month_day_correction_rows.csv"),
    na = ""
  )
  readr::write_csv(
    summary,
    file.path(report_dir, "timepoint_month_day_correction_summary.csv"),
    na = ""
  )

  report_lines <- c(
    "# GAZP1-3 timepoint month/day correction",
    "",
    paste0("Run timestamp: `", run_timestamp, "`"),
    paste0("Mode: `", run_mode, "`"),
    paste0("Outcome: `", outcome, "`"),
    "",
    "The authoritative values came from the original harmonized timepoints sheets.",
    "Source treatmentid + tsr was mapped to areaid with the repository project crosswalks.",
    "Only missing grp.veg_result month/day values were eligible for update.",
    "Existing conflicting values cause the script to stop without committing.",
    "",
    "## Summary",
    "",
    paste(capture.output(print(summary, n = Inf)), collapse = "\n"),
    "",
    if (isTRUE(apply_changes)) {
      "The transaction was committed only after live read-back verification."
    } else {
      "Preview only: no Supabase values were changed. Set apply_changes <- TRUE only after reviewing the CSV files."
    }
  )
  writeLines(
    report_lines,
    file.path(report_dir, "correction_report.md"),
    useBytes = TRUE
  )
}


# ---- Transactional update ---------------------------------------------

apply_correction <- function(con, plan) {
  update_rows <- plan |>
    filter(
      .data$month_action == "update_missing" |
        .data$day_action == "update_missing"
    ) |>
    transmute(
      veg_resultid = as.integer(.data$supabase_veg_resultid),
      expected_current_month = as.integer(.data$current_month),
      expected_current_day = as.integer(.data$current_day),
      proposed_month = as.integer(.data$proposed_month),
      proposed_day = as.integer(.data$proposed_day)
    ) |>
    distinct()

  if (nrow(update_rows) == 0L) {
    message("No missing month/day values require an update.")
    return(invisible(TRUE))
  }

  DBI::dbWithTransaction(con, {
    # Re-read the live rows inside the transaction and rebuild the plan so a
    # database change made after preview cannot be silently overwritten.
    locked_ids <- sql_integer_list(con, update_rows$veg_resultid)
    schema <- as.character(DBI::dbQuoteIdentifier(con, schema_name))
    lock_sql <- paste0(
      "SELECT veg_resultid, month, day FROM ", schema, ".veg_result ",
      "WHERE veg_resultid IN (", locked_ids, ") FOR UPDATE"
    )
    locked <- DBI::dbGetQuery(con, lock_sql) |>
      as_tibble() |>
      mutate(
        veg_resultid = as.integer(.data$veg_resultid),
        month = as.integer(.data$month),
        day = as.integer(.data$day)
      )

    locked_check <- update_rows |>
      left_join(locked, by = "veg_resultid")

    month_changed <- xor(
      is.na(locked_check$expected_current_month),
      is.na(locked_check$month)
    ) | (
      !is.na(locked_check$expected_current_month) &
        !is.na(locked_check$month) &
        locked_check$expected_current_month != locked_check$month
    )
    day_changed <- xor(
      is.na(locked_check$expected_current_day),
      is.na(locked_check$day)
    ) | (
      !is.na(locked_check$expected_current_day) &
        !is.na(locked_check$day) &
        locked_check$expected_current_day != locked_check$day
    )

    if (
      nrow(locked) != nrow(update_rows) ||
      any(month_changed | day_changed)
    ) {
      stop(
        "A target changed after preview or could not be locked; rolling back.",
        call. = FALSE
      )
    }

    DBI::dbWriteTable(
      con,
      "timepoint_month_day_correction",
      update_rows |>
        select(.data$veg_resultid, .data$proposed_month, .data$proposed_day),
      temporary = TRUE,
      overwrite = TRUE,
      row.names = FALSE
    )

    update_sql <- paste0(
      "UPDATE ", schema, ".veg_result AS vr\n",
      "SET month = CASE\n",
      "      WHEN vr.month IS NULL THEN fix.proposed_month\n",
      "      ELSE vr.month\n",
      "    END,\n",
      "    day = CASE\n",
      "      WHEN vr.day IS NULL THEN fix.proposed_day\n",
      "      ELSE vr.day\n",
      "    END\n",
      "FROM timepoint_month_day_correction AS fix\n",
      "WHERE vr.veg_resultid = fix.veg_resultid\n",
      "  AND ((vr.month IS NULL AND fix.proposed_month IS NOT NULL)\n",
      "    OR (vr.day IS NULL AND fix.proposed_day IS NOT NULL))"
    )
    rows_updated <- DBI::dbExecute(con, update_sql)

    if (!identical(as.integer(rows_updated), as.integer(nrow(update_rows)))) {
      stop(
        "Updated ", rows_updated, " rows; expected ", nrow(update_rows),
        ". Rolling back.",
        call. = FALSE
      )
    }

    verify_sql <- paste0(
      "SELECT veg_resultid, month, day FROM ", schema, ".veg_result ",
      "WHERE veg_resultid IN (", locked_ids, ")"
    )
    verified <- DBI::dbGetQuery(con, verify_sql) |>
      as_tibble() |>
      transmute(
        veg_resultid = as.integer(.data$veg_resultid),
        stored_month = as.integer(.data$month),
        stored_day = as.integer(.data$day)
      )

    check <- update_rows |>
      left_join(verified, by = "veg_resultid")
    month_failed <- !is.na(check$proposed_month) &
      (is.na(check$stored_month) | check$stored_month != check$proposed_month)
    day_failed <- !is.na(check$proposed_day) &
      (is.na(check$stored_day) | check$stored_day != check$proposed_day)

    if (any(month_failed | day_failed)) {
      stop("Post-update verification failed; rolling back.", call. = FALSE)
    }
  })

  invisible(TRUE)
}


# ---- Run ---------------------------------------------------------------

run_timepoint_correction <- function() {
  message("Loading authoritative GAZP1-3 timepoint values ...")
  source_timepoints <- purrr::map_dfr(project_codes, read_source_timepoints)

  message("Loading project area crosswalks ...")
  area_map <- purrr::map_dfr(project_codes, read_area_crosswalk)

  con <- connect_to_supabase()
  on.exit({
    if (DBI::dbIsValid(con)) {
      DBI::dbDisconnect(con)
    }
  }, add = TRUE)

  message("Reading live Supabase veg_result rows ...")
  live_results <- read_live_results(con, area_map$areaid)

  message("Building and validating the correction plan ...")
  correction_plan <- build_correction_plan(
    source_timepoints,
    area_map,
    live_results
  )
  correction_summary <- summarise_plan(correction_plan)

  print(correction_summary, n = Inf)

  if (isTRUE(apply_changes)) {
    message("APPLY MODE: beginning validated transaction ...")
    apply_correction(con, correction_plan)
    outcome <- "COMMITTED_AND_VERIFIED"
    message("Correction committed and verified.")
  } else {
    outcome <- "PREVIEW_ONLY_NO_DATABASE_CHANGES"
    message("PREVIEW ONLY: no Supabase values were changed.")
  }

  write_reports(correction_plan, correction_summary, outcome)
  message("Correction report written to: ", report_dir)

  invisible(list(
    correction_plan = correction_plan,
    correction_summary = correction_summary,
    outcome = outcome,
    report_dir = report_dir
  ))
}

correction_run <- run_timepoint_correction()
