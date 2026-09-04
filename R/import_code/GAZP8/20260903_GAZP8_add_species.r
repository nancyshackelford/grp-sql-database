## Add the two taxa required by the GAZP8 import and update the shared
## 20260903 framework species crosswalk with their generated Supabase IDs.
##
## Taxonomy was reviewed against Plants of the World Online on 2026-09-03:
##   * Erigeron simplex Greene is a synonym of Erigeron grandiflorus Hook.
##   * Packera multilobata (Torr. & A.Gray) W.A.Weber & A.Love is accepted.
##
## This script is safe to rerun. It reuses an exact existing taxon, but stops
## if either the reviewed taxonomy or proposed canonical species code conflicts
## with a different database record.

library(tidyverse)
library(DBI)
library(RPostgres)


# ---- Configuration -----------------------------------------------------

# Review the preview, then change this to TRUE to apply the database and file
# changes. The database inserts are committed before the local crosswalk is
# replaced. If the file update subsequently fails, rerunning the script is safe.
apply_changes <- TRUE

### Connect to Supabase database
password <- readLines("C:\\Users\\nshack\\OneDrive - University of Victoria\\Documents\\R\\GRP\\pword.csv")
service_role <- readLines("C:\\Users\\nshack\\OneDrive - University of Victoria\\Documents\\R\\GRP\\skey.csv")

crosswalk_file <- file.path(
  "R",
  "import_framework",
  "20260903_framework",
  "20260605_sp_crosswalk.csv"
)

### First round: Erigeron grandiflorus and Packera multilobata are added to the database and crosswalk.
new_taxa <- tribble(
  ~source_code, ~species_code, ~group, ~order, ~family, ~genus, ~species,
  ~subtype, ~subtype_name, ~lifeform, ~lifespan, ~canonical_name,
  "UN_ID_ERSI", "Eri_gra", "Angiosperms", "Asterales", "Asteraceae",
  "Erigeron", "grandiflorus", NA_character_, NA_character_, "forb",
  "perennial", "Erigeron grandiflorus",
  "UN_ID_PAMU", "Pac_mul", "Angiosperms", "Asterales", "Asteraceae",
  "Packera", "multilobata", NA_character_, NA_character_, "forb",
  "perennial", "Packera multilobata"
)

stopifnot(file.exists(crosswalk_file))


# ---- Connection --------------------------------------------------------
con <- dbConnect(
  Postgres(),
  host = "aws-1-ca-central-1.pooler.supabase.com",
  port = 6543,
  dbname = "postgres",
  user = "postgres.rudybfqutvodkakgctpo",
  password = password,
  sslmode = "require"
)

on.exit(dbDisconnect(con), add = TRUE)


# ---- Helpers -----------------------------------------------------------

read_matching_taxa <- function(con, taxon) {
  DBI::dbGetQuery(
    con,
    paste0(
      'SELECT speciesid, species_code, "group", "order", family, genus, ',
      'species, subtype, subtype_name, lifeform ',
      'FROM grp.species ',
      'WHERE species_code = $1 ',
      '   OR ("group" IS NOT DISTINCT FROM $2 ',
      '       AND "order" IS NOT DISTINCT FROM $3 ',
      '       AND family IS NOT DISTINCT FROM $4 ',
      '       AND genus IS NOT DISTINCT FROM $5 ',
      '       AND species IS NOT DISTINCT FROM $6 ',
      '       AND subtype IS NOT DISTINCT FROM $7 ',
      '       AND subtype_name IS NOT DISTINCT FROM $8) ',
      'ORDER BY speciesid'
    ),
    params = unname(list(
      taxon$species_code,
      taxon$group,
      taxon$order,
      taxon$family,
      taxon$genus,
      taxon$species,
      taxon$subtype,
      taxon$subtype_name
    ))
  ) |>
    as_tibble()
}


is_exact_taxon <- function(record, taxon) {
  identical(as.character(record$species_code[[1]]), taxon$species_code) &&
    identical(as.character(record$group[[1]]), taxon$group) &&
    identical(as.character(record$order[[1]]), taxon$order) &&
    identical(as.character(record$family[[1]]), taxon$family) &&
    identical(as.character(record$genus[[1]]), taxon$genus) &&
    identical(as.character(record$species[[1]]), taxon$species) &&
    identical(as.character(record$subtype[[1]]), taxon$subtype) &&
    identical(as.character(record$subtype_name[[1]]), taxon$subtype_name) &&
    identical(as.character(record$lifeform[[1]]), taxon$lifeform)
}


insert_or_get_taxon <- function(con, taxon) {
  matches <- read_matching_taxa(con, taxon)

  if (nrow(matches) > 1L) {
    print(matches)
    stop(
      "More than one database record matches ", taxon$canonical_name, ".",
      call. = FALSE
    )
  }

  if (nrow(matches) == 1L) {
    if (!is_exact_taxon(matches, taxon)) {
      print(matches)
      stop(
        "The existing record for ", taxon$canonical_name,
        " conflicts with the reviewed taxon definition.",
        call. = FALSE
      )
    }

    return(as.integer(matches$speciesid[[1]]))
  }

  inserted <- DBI::dbGetQuery(
    con,
    paste0(
      'INSERT INTO grp.species ',
      '(species_code, "group", "order", family, genus, species, subtype, ',
      'subtype_name, lifeform) ',
      'VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) ',
      'RETURNING speciesid'
    ),
    params = unname(list(
      taxon$species_code,
      taxon$group,
      taxon$order,
      taxon$family,
      taxon$genus,
      taxon$species,
      taxon$subtype,
      taxon$subtype_name,
      taxon$lifeform
    ))
  )

  as.integer(inserted$speciesid[[1]])
}


ensure_species_name <- function(con, speciesid, species_code, name) {
  existing <- DBI::dbGetQuery(
    con,
    paste0(
      "SELECT speciesid, species_code, name FROM grp.species_names ",
      "WHERE speciesid = $1 AND species_code = $2"
    ),
    params = list(speciesid, species_code)
  ) |>
    as_tibble()

  if (nrow(existing) > 1L) {
    stop("Duplicate grp.species_names key found.", call. = FALSE)
  }

  if (nrow(existing) == 1L) {
    if (!identical(as.character(existing$name[[1]]), name)) {
      print(existing)
      stop("The existing species name conflicts with the reviewed name.", call. = FALSE)
    }
    return(invisible(FALSE))
  }

  DBI::dbExecute(
    con,
    paste0(
      "INSERT INTO grp.species_names (speciesid, species_code, name) ",
      "VALUES ($1, $2, $3)"
    ),
    params = list(speciesid, species_code, name)
  )

  invisible(TRUE)
}


ensure_species_lifespan <- function(con, speciesid, lifespan) {
  DBI::dbExecute(
    con,
    paste0(
      "INSERT INTO grp.species_lifespan (speciesid, type) ",
      "VALUES ($1, $2) ON CONFLICT (speciesid, type) DO NOTHING"
    ),
    params = list(speciesid, lifespan)
  )

  invisible(TRUE)
}


build_updated_crosswalk <- function(crosswalk_file, resolved_taxa) {
  current <- readr::read_csv(crosswalk_file, show_col_types = FALSE) |>
    transmute(
      excel_speciesid = as.character(.data$excel_speciesid),
      sql_speciesid = as.integer(.data$sql_speciesid),
      sql_species_code = as.character(.data$sql_species_code)
    )

  additions <- resolved_taxa |>
    transmute(
      excel_speciesid = .data$source_code,
      sql_speciesid = as.integer(.data$speciesid),
      sql_species_code = .data$species_code
    )

  updated <- current |>
    filter(!.data$excel_speciesid %in% additions$excel_speciesid) |>
    bind_rows(additions) |>
    arrange(.data$excel_speciesid)

  conflicting_source_codes <- updated |>
    distinct(
      .data$excel_speciesid,
      .data$sql_speciesid,
      .data$sql_species_code
    ) |>
    count(.data$excel_speciesid, name = "n") |>
    filter(.data$n > 1L)

  if (nrow(conflicting_source_codes) > 0L) {
    print(conflicting_source_codes)
    stop("The updated crosswalk has conflicting source-code mappings.", call. = FALSE)
  }

  updated
}


# ---- Preview -----------------------------------------------------------

database_preview <- purrr::map_dfr(
  seq_len(nrow(new_taxa)),
  function(i) {
    taxon <- as.list(new_taxa[i, ])
    matches <- read_matching_taxa(con, taxon)

    tibble(
      source_code = taxon$source_code,
      canonical_name = taxon$canonical_name,
      species_code = taxon$species_code,
      database_status = case_when(
        nrow(matches) == 0L ~ "will_insert",
        nrow(matches) == 1L && is_exact_taxon(matches, taxon) ~ "already_exact",
        TRUE ~ "conflict"
      ),
      existing_speciesid = if (nrow(matches) == 1L) {
        as.integer(matches$speciesid[[1]])
      } else {
        NA_integer_
      }
    )
  }
)

print(database_preview)

if (any(database_preview$database_status == "conflict")) {
  stop("Resolve the reported database conflict before applying this script.", call. = FALSE)
}

if (!apply_changes) {
  stop(
    "Preview complete. Set apply_changes <- TRUE to insert the taxa and replace ",
    "the framework species crosswalk.",
    call. = FALSE
  )
}


# ---- Apply database changes -------------------------------------------

DBI::dbBegin(con)

resolved_taxa <- tryCatch(
  {
    resolved <- purrr::map_dfr(
      seq_len(nrow(new_taxa)),
      function(i) {
        taxon <- as.list(new_taxa[i, ])
        speciesid <- insert_or_get_taxon(con, taxon)

        ensure_species_name(
          con,
          speciesid,
          taxon$species_code,
          taxon$canonical_name
        )
        ensure_species_lifespan(con, speciesid, taxon$lifespan)

        new_taxa[i, ] |>
          mutate(speciesid = speciesid)
      }
    )

    DBI::dbCommit(con)
    resolved
  },
  error = function(e) {
    if (DBI::dbIsValid(con)) {
      try(DBI::dbRollback(con), silent = TRUE)
    }
    stop(conditionMessage(e), call. = FALSE)
  }
)


# ---- Verify committed database state ----------------------------------

verification <- DBI::dbGetQuery(
  con,
  paste0(
    'SELECT s.speciesid, s.species_code, s."group", s."order", s.family, ',
    's.genus, s.species, s.subtype, s.subtype_name, s.lifeform, ',
    'sl.type AS lifespan, sn.name ',
    'FROM grp.species s ',
    'JOIN grp.species_lifespan sl ON sl.speciesid = s.speciesid ',
    'JOIN grp.species_names sn ',
    '  ON sn.speciesid = s.speciesid AND sn.species_code = s.species_code ',
    'WHERE s.speciesid IN (',
    paste0("$", seq_along(resolved_taxa$speciesid), collapse = ", "),
    ') ',
    'ORDER BY s.speciesid'
  ),
  params = as.list(as.integer(resolved_taxa$speciesid))
) |>
  as_tibble()

if (
  nrow(verification) != nrow(new_taxa) ||
    !setequal(verification$speciesid, resolved_taxa$speciesid) ||
    any(verification$lifespan != "perennial")
) {
  print(verification)
  stop(
    "Database changes committed, but post-commit verification failed. ",
    "The local crosswalk was not replaced.",
    call. = FALSE
  )
}

print(verification)


# ---- Replace framework species crosswalk ------------------------------

updated_crosswalk <- build_updated_crosswalk(crosswalk_file, resolved_taxa)

temporary_crosswalk <- tempfile(
  pattern = "20260903_sp_crosswalk_",
  tmpdir = dirname(crosswalk_file),
  fileext = ".csv"
)

readr::write_csv(updated_crosswalk, temporary_crosswalk, na = "")

written_check <- readr::read_csv(temporary_crosswalk, show_col_types = FALSE)

expected_rows <- updated_crosswalk |>
  semi_join(
    resolved_taxa |>
      transmute(excel_speciesid = .data$source_code),
    by = "excel_speciesid"
  )

actual_rows <- written_check |>
  semi_join(
    resolved_taxa |>
      transmute(excel_speciesid = .data$source_code),
    by = "excel_speciesid"
  )

if (!identical(expected_rows, actual_rows)) {
  unlink(temporary_crosswalk)
  stop(
    "Database changes committed, but the temporary crosswalk failed ",
    "verification. The existing framework crosswalk was not replaced.",
    call. = FALSE
  )
}

copied <- file.copy(
  from = temporary_crosswalk,
  to = crosswalk_file,
  overwrite = TRUE,
  copy.mode = TRUE
)
unlink(temporary_crosswalk)

if (!copied) {
  stop(
    "Database changes committed, but the framework crosswalk could not be ",
    "replaced. Rerun this script after resolving the filesystem issue.",
    call. = FALSE
  )
}

final_crosswalk <- readr::read_csv(crosswalk_file, show_col_types = FALSE)
final_rows <- final_crosswalk |>
  filter(.data$excel_speciesid %in% resolved_taxa$source_code) |>
  arrange(.data$excel_speciesid)

expected_final_rows <- resolved_taxa |>
  transmute(
    excel_speciesid = .data$source_code,
    sql_speciesid = as.integer(.data$speciesid),
    sql_species_code = .data$species_code
  ) |>
  arrange(.data$excel_speciesid)

if (!identical(final_rows, expected_final_rows)) {
  stop(
    "Database changes committed and the crosswalk was replaced, but final ",
    "crosswalk verification failed.",
    call. = FALSE
  )
}

message("Added or verified the two GAZP8 taxa and replaced: ", crosswalk_file)
print(expected_final_rows)

#### Second round: Add Salsola tragus to the database and crosswalk. This taxon is required for GAZP8, but was not in the original import framework.

# The GAZP8 source code SATR represents Salsola tragus. During harmonization it
# was assigned the legacy code Sal_kal1, so that is the source-code key that
# must be replaced in the framework crosswalk.
apply_salsola_changes <- TRUE

salsola_taxon <- tribble(
  ~source_code, ~species_code, ~group, ~order, ~family, ~genus, ~species,
  ~subtype, ~subtype_name, ~lifeform, ~lifespan, ~canonical_name,
  "Sal_kal1", "Sal_tra", "Angiosperms", "Caryophyllales", "Amaranthaceae",
  "Salsola", "tragus", NA_character_, NA_character_, "forb", "annual",
  "Salsola tragus"
)


# ---- Preview Salsola tragus --------------------------------------------

salsola_preview <- purrr::map_dfr(
  seq_len(nrow(salsola_taxon)),
  function(i) {
    taxon <- as.list(salsola_taxon[i, ])
    matches <- read_matching_taxa(con, taxon)

    tibble(
      source_code = taxon$source_code,
      canonical_name = taxon$canonical_name,
      species_code = taxon$species_code,
      database_status = case_when(
        nrow(matches) == 0L ~ "will_insert",
        nrow(matches) == 1L && is_exact_taxon(matches, taxon) ~ "already_exact",
        TRUE ~ "conflict"
      ),
      existing_speciesid = if (nrow(matches) == 1L) {
        as.integer(matches$speciesid[[1]])
      } else {
        NA_integer_
      }
    )
  }
)

print(salsola_preview)

if (any(salsola_preview$database_status == "conflict")) {
  stop(
    "Resolve the reported Salsola tragus database conflict before applying.",
    call. = FALSE
  )
}

if (!apply_salsola_changes) {
  stop(
    "Salsola tragus preview complete. Set apply_salsola_changes <- TRUE to ",
    "update the database and framework crosswalk.",
    call. = FALSE
  )
}


# ---- Apply Salsola tragus database changes -----------------------------

DBI::dbBegin(con)

resolved_salsola <- tryCatch(
  {
    resolved <- purrr::map_dfr(
      seq_len(nrow(salsola_taxon)),
      function(i) {
        taxon <- as.list(salsola_taxon[i, ])
        speciesid <- insert_or_get_taxon(con, taxon)

        ensure_species_name(
          con,
          speciesid,
          taxon$species_code,
          taxon$canonical_name
        )
        ensure_species_lifespan(con, speciesid, taxon$lifespan)

        salsola_taxon[i, ] |>
          mutate(speciesid = speciesid)
      }
    )

    DBI::dbCommit(con)
    resolved
  },
  error = function(e) {
    if (DBI::dbIsValid(con)) {
      try(DBI::dbRollback(con), silent = TRUE)
    }
    stop(conditionMessage(e), call. = FALSE)
  }
)


# ---- Verify committed Salsola tragus state -----------------------------

salsola_verification <- DBI::dbGetQuery(
  con,
  paste0(
    'SELECT s.speciesid, s.species_code, s."group", s."order", s.family, ',
    's.genus, s.species, s.subtype, s.subtype_name, s.lifeform, ',
    'sl.type AS lifespan, sn.name ',
    'FROM grp.species s ',
    'JOIN grp.species_lifespan sl ON sl.speciesid = s.speciesid ',
    'JOIN grp.species_names sn ',
    '  ON sn.speciesid = s.speciesid AND sn.species_code = s.species_code ',
    'WHERE s.speciesid = $1'
  ),
  params = list(as.integer(resolved_salsola$speciesid[[1]]))
) |>
  as_tibble()

expected_salsola <- resolved_salsola |>
  transmute(
    speciesid = as.integer(.data$speciesid),
    species_code = .data$species_code,
    group = .data$group,
    order = .data$order,
    family = .data$family,
    genus = .data$genus,
    species = .data$species,
    subtype = .data$subtype,
    subtype_name = .data$subtype_name,
    lifeform = .data$lifeform,
    lifespan = .data$lifespan,
    name = .data$canonical_name
  )

if (!identical(salsola_verification, expected_salsola)) {
  print(salsola_verification)
  stop(
    "Salsola tragus was committed, but post-commit verification failed. ",
    "The framework crosswalk was not replaced.",
    call. = FALSE
  )
}

print(salsola_verification)


# ---- Replace the Sal_kal1 framework mapping ----------------------------

updated_salsola_crosswalk <- build_updated_crosswalk(
  crosswalk_file,
  resolved_salsola
)

temporary_salsola_crosswalk <- tempfile(
  pattern = "20260903_sp_crosswalk_salsola_",
  tmpdir = dirname(crosswalk_file),
  fileext = ".csv"
)

readr::write_csv(
  updated_salsola_crosswalk,
  temporary_salsola_crosswalk,
  na = ""
)

salsola_written_check <- readr::read_csv(
  temporary_salsola_crosswalk,
  show_col_types = FALSE
)

expected_salsola_crosswalk_row <- resolved_salsola |>
  transmute(
    excel_speciesid = .data$source_code,
    sql_speciesid = as.integer(.data$speciesid),
    sql_species_code = .data$species_code
  )

actual_salsola_crosswalk_row <- salsola_written_check |>
  filter(.data$excel_speciesid == salsola_taxon$source_code[[1]])

if (!identical(
  actual_salsola_crosswalk_row,
  expected_salsola_crosswalk_row
)) {
  unlink(temporary_salsola_crosswalk)
  stop(
    "The temporary Salsola tragus crosswalk failed verification.",
    call. = FALSE
  )
}

copied_salsola_crosswalk <- file.copy(
  from = temporary_salsola_crosswalk,
  to = crosswalk_file,
  overwrite = TRUE,
  copy.mode = TRUE
)
unlink(temporary_salsola_crosswalk)

if (!copied_salsola_crosswalk) {
  stop(
    "Salsola tragus was committed, but the framework crosswalk could not be ",
    "replaced. Rerun this section after resolving the filesystem issue.",
    call. = FALSE
  )
}

final_salsola_crosswalk_row <- readr::read_csv(
  crosswalk_file,
  show_col_types = FALSE
) |>
  filter(.data$excel_speciesid == salsola_taxon$source_code[[1]])

if (!identical(
  final_salsola_crosswalk_row,
  expected_salsola_crosswalk_row
)) {
  stop(
    "The framework crosswalk was replaced, but final Salsola tragus ",
    "verification failed.",
    call. = FALSE
  )
}

message(
  "Added or verified Salsola tragus and replaced its Sal_kal1 mapping in: ",
  crosswalk_file
)
print(final_salsola_crosswalk_row)
