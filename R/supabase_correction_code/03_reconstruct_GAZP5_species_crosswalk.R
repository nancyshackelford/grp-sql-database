# Reconstruct a standalone, project-specific GAZP5 species crosswalk.
#
# This script makes no changes to Supabase or Supabase Storage. It uses:
#   * the archived historical GRP species table for original taxonomic meaning;
#   * the GAZP5 harmonized workbook for project usage and seeding context;
#   * the corrected global species crosswalk for forward mappings; and
#   * a read-only live Supabase query for current accepted taxonomic records.
#
# Outputs:
#   crosswalk_tables/GAZP/GAZP5/GAZP5_species_crosswalk.csv
#   docs/supabase_correction_reports/<datestamp>_GAZP5_species_crosswalk_build/
#
# The later 04_ workflow will upload and register approved correction artifacts.
# It must use explicit datestamps because this archival process will recur. This
# script deliberately does not populate grp.project_object_crosswalk.

suppressPackageStartupMessages({
  library(DBI)
  library(RPostgres)
  library(openxlsx)
  library(readr)
  library(dplyr)
  library(purrr)
  library(tibble)
  library(tidyr)
  library(stringr)
})

if (!requireNamespace("digest", quietly = TRUE)) {
  stop("Package 'digest' is required to calculate artifact hashes.", call. = FALSE)
}


# ---- Configuration -----------------------------------------------------

database_name <- "GAZP"
projectid <- 5L
project_code <- "GAZP5"
reviewed_by <- "Nancy Shackelford"
review_date <- as.Date("2026-08-14")

overwrite_output <- FALSE

# These are source mixture placeholders, not taxonomic identifiers. They are
# retained in seed_mix/seeding provenance with a missing speciesid and must not
# be forced through the species crosswalk.
non_taxonomic_source_codes <- c("mix_unknown")

historical_species_path <- paste0(
  "data/harmonized/GRP_archives/",
  "species_long_traits3-2021-October-26.xlsx"
)
harmonized_workbook_path <- "data/harmonized/GAZP/GAZP5/GAZP5.xlsx"
global_species_crosswalk_path <- "crosswalk_tables/20260605_sp_crosswalk.csv"
output_path <- "crosswalk_tables/GAZP/GAZP5/GAZP5_species_crosswalk.csv"
report_root <- "docs/supabase_correction_reports"

run_timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
generated_at_utc <- format(
  as.POSIXct(Sys.time(), tz = "UTC"),
  "%Y-%m-%dT%H:%M:%SZ",
  tz = "UTC"
)
report_dir <- file.path(
  report_root,
  paste0(run_timestamp, "_GAZP5_species_crosswalk_build")
)


# ---- Connection --------------------------------------------------------

connect_to_supabase_read_only <- function() {
  password <- readLines(
    "C:/Users/nshack/OneDrive - University of Victoria/Documents/R/GRP/pword.csv",
    warn = FALSE
  )[1]

  if (is.na(password) || !nzchar(password)) {
    stop("The Supabase password file is empty.", call. = FALSE)
  }

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


# ---- General helpers ---------------------------------------------------

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

normalize_text <- function(x) {
  value <- stringr::str_squish(as.character(x))
  value[value %in% c("", "NA", "NaN", "NULL")] <- NA_character_
  value
}

normalize_source_code <- function(x) {
  normalize_text(x)
}

normalize_historical_subtype <- function(x) {
  value <- stringr::str_to_lower(normalize_text(x))
  case_when(
    value %in% c("subsp", "subsp.", "ssp", "ssp.", "subspecies") ~
      "subspecies",
    value %in% c("var", "var.", "variety") ~ "variety",
    is.na(value) ~ NA_character_,
    TRUE ~ value
  )
}

subtype_abbreviation <- function(x) {
  case_when(
    x == "subspecies" ~ "subsp.",
    x == "variety" ~ "var.",
    is.na(x) ~ NA_character_,
    TRUE ~ x
  )
}

compose_scientific_name <- function(genus, species, subtype, subtype_name) {
  subtype_label <- subtype_abbreviation(subtype)
  purrr::pmap_chr(
    list(genus, species, subtype_label, subtype_name),
    function(g, s, st, sn) {
      parts <- c(g, s)
      if (!is.na(st) && !is.na(sn)) parts <- c(parts, st, sn)
      paste(parts[!is.na(parts) & nzchar(parts)], collapse = " ")
    }
  )
}

collapse_sorted <- function(x) {
  values <- sort(unique(normalize_text(x)))
  values <- values[!is.na(values)]
  if (length(values) == 0L) NA_character_ else paste(values, collapse = ";")
}

sha256_file <- function(path) {
  digest::digest(file = path, algo = "sha256", serialize = FALSE)
}


# ---- Historical species vocabulary -----------------------------------

read_historical_species <- function() {
  require_file(historical_species_path, "Historical GRP species workbook")

  historical <- openxlsx::read.xlsx(
    historical_species_path,
    sheet = 1,
    check.names = FALSE,
    detectDates = FALSE
  )
  require_columns(
    historical,
    c(
      "speciesid", "group", "order", "family", "genus", "species",
      "sub_type", "name", "lifeform", "seedmass", "path", "raunkiaer",
      "woodiness", "nfix", "lifespan"
    ),
    "Historical GRP species workbook"
  )

  historical <- historical |>
    transmute(
      source_speciesid = normalize_source_code(.data$speciesid),
      historical_group = normalize_text(.data$group),
      historical_order = normalize_text(.data$order),
      historical_family = normalize_text(.data$family),
      historical_genus = normalize_text(.data$genus),
      historical_species = normalize_text(.data$species),
      historical_subtype = normalize_historical_subtype(.data$sub_type),
      historical_subtype_name = normalize_text(.data$name),
      historical_lifeform = normalize_text(.data$lifeform),
      historical_seedmass = suppressWarnings(as.numeric(.data$seedmass)),
      historical_pathway = normalize_text(.data$path),
      historical_raunkiaer = normalize_text(.data$raunkiaer),
      historical_woodiness = normalize_text(.data$woodiness),
      historical_nfix = normalize_text(.data$nfix),
      historical_lifespan = normalize_text(.data$lifespan)
    ) |>
    mutate(
      historical_scientific_name = compose_scientific_name(
        .data$historical_genus,
        .data$historical_species,
        .data$historical_subtype,
        .data$historical_subtype_name
      )
    )

  duplicates <- historical |>
    filter(!is.na(.data$source_speciesid)) |>
    count(.data$source_speciesid) |>
    filter(.data$n != 1L)
  if (nrow(duplicates) > 0L) {
    stop("Historical species codes are not unique.", call. = FALSE)
  }

  historical
}


# ---- GAZP5 project species usage --------------------------------------

read_sheet_if_present <- function(workbook, sheet_name) {
  if (!sheet_name %in% openxlsx::getSheetNames(workbook)) return(NULL)
  openxlsx::read.xlsx(
    workbook,
    sheet = sheet_name,
    check.names = FALSE,
    detectDates = FALSE
  )
}

read_gazp5_usage <- function() {
  require_file(harmonized_workbook_path, "GAZP5 harmonized workbook")
  sheets <- openxlsx::getSheetNames(harmonized_workbook_path)

  usage_parts <- list()

  for (sheet_name in intersect(c("vegresults", "trtrates", "cultivars"), sheets)) {
    data <- read_sheet_if_present(harmonized_workbook_path, sheet_name)
    if (!"speciesid" %in% names(data)) next
    usage_parts[[length(usage_parts) + 1L]] <- data |>
      transmute(
        source_table = sheet_name,
        source_column = "speciesid",
        source_speciesid = normalize_source_code(.data$speciesid)
      )
  }

  if ("site" %in% sheets) {
    site <- read_sheet_if_present(harmonized_workbook_path, "site")
    if ("invasivespe" %in% names(site)) {
      usage_parts[[length(usage_parts) + 1L]] <- site |>
        transmute(
          source_table = "site",
          source_column = "invasivespe",
          source_speciesid = normalize_source_code(.data$invasivespe)
        )
    }
  }

  usage_all <- bind_rows(usage_parts) |>
    filter(!is.na(.data$source_speciesid)) |>
    filter(!.data$source_speciesid %in% c("unknown", "Unknown"))

  excluded_non_taxonomic <- usage_all |>
    filter(.data$source_speciesid %in% non_taxonomic_source_codes) |>
    count(
      .data$source_table,
      .data$source_column,
      .data$source_speciesid,
      name = "source_rows"
    ) |>
    mutate(
      exclusion_reason = paste0(
        "Unknown-composition seed-mix placeholder; importer retains the mix ",
        "with speciesid missing rather than inventing a taxon."
      )
    )

  unexpected_placeholder_use <- excluded_non_taxonomic |>
    filter(
      .data$source_speciesid != "mix_unknown" |
        .data$source_table != "trtrates" |
        .data$source_column != "speciesid"
    )
  if (nrow(unexpected_placeholder_use) > 0L) {
    stop("A non-taxonomic placeholder appears in an unexpected source location.",
         call. = FALSE)
  }

  mix_unknown_rows <- excluded_non_taxonomic |>
    filter(.data$source_speciesid == "mix_unknown") |>
    summarise(rows = sum(.data$source_rows)) |>
    pull(.data$rows)
  if (length(mix_unknown_rows) != 1L || mix_unknown_rows != 3L) {
    stop("GAZP5 mix_unknown row count differs from the reviewed source state.",
         call. = FALSE)
  }

  usage <- usage_all |>
    filter(!.data$source_speciesid %in% non_taxonomic_source_codes)

  if (nrow(usage) == 0L) {
    stop("No GAZP5 source species codes were found.", call. = FALSE)
  }

  usage_summary <- usage |>
    group_by(.data$source_speciesid) |>
    summarise(
      source_tables = collapse_sorted(.data$source_table),
      source_columns = collapse_sorted(.data$source_column),
      source_occurrences = n(),
      .groups = "drop"
    )

  trtrates <- read_sheet_if_present(harmonized_workbook_path, "trtrates")
  require_columns(
    trtrates,
    c("treatmentid", "speciesid", "rate", "unit"),
    "GAZP5 trtrates sheet"
  )
  treatment_rate_context <- trtrates |>
    transmute(
      source_treatmentid = normalize_text(.data$treatmentid),
      source_speciesid = normalize_source_code(.data$speciesid),
      match_rate = suppressWarnings(as.numeric(.data$rate)),
      match_unit = normalize_text(.data$unit)
    ) |>
    filter(
      !is.na(.data$source_speciesid),
      !.data$source_speciesid %in% non_taxonomic_source_codes
    ) |>
    distinct()

  list(
    usage = usage,
    summary = usage_summary,
    treatment_rate_context = treatment_rate_context,
    excluded_non_taxonomic = excluded_non_taxonomic
  )
}


# ---- Corrected global forward mapping ---------------------------------

read_global_species_crosswalk <- function() {
  require_file(global_species_crosswalk_path, "Global species crosswalk")
  crosswalk <- readr::read_csv(
    global_species_crosswalk_path,
    show_col_types = FALSE
  )
  require_columns(
    crosswalk,
    c("excel_speciesid", "sql_speciesid", "sql_species_code"),
    "Global species crosswalk"
  )

  crosswalk |>
    transmute(
      source_speciesid = normalize_source_code(.data$excel_speciesid),
      supabase_speciesid = as.integer(.data$sql_speciesid),
      supabase_species_code = normalize_text(.data$sql_species_code)
    )
}


# ---- Read current accepted Supabase taxonomy --------------------------

read_live_taxonomy <- function(con, speciesids) {
  ids <- sort(unique(as.integer(speciesids)))
  ids <- ids[!is.na(ids)]
  if (length(ids) == 0L) stop("No Supabase species IDs were supplied.", call. = FALSE)

  id_sql <- paste(DBI::dbQuoteLiteral(con, ids), collapse = ", ")
  taxonomy <- DBI::dbGetQuery(
    con,
    paste0(
      "SELECT speciesid, species_code, \"group\", \"order\", family, genus, ",
      "species, subtype, subtype_name, lifeform\n",
      "FROM grp.species\n",
      "WHERE speciesid IN (", id_sql, ")"
    )
  ) |>
    as_tibble() |>
    transmute(
      supabase_speciesid = as.integer(.data$speciesid),
      live_species_code = normalize_text(.data$species_code),
      supabase_group = normalize_text(.data$group),
      supabase_order = normalize_text(.data$order),
      supabase_family = normalize_text(.data$family),
      supabase_genus = normalize_text(.data$genus),
      supabase_species = normalize_text(.data$species),
      supabase_subtype = normalize_text(.data$subtype),
      supabase_subtype_name = normalize_text(.data$subtype_name),
      supabase_lifeform = normalize_text(.data$lifeform)
    ) |>
    mutate(
      supabase_scientific_name = compose_scientific_name(
        .data$supabase_genus,
        .data$supabase_species,
        .data$supabase_subtype,
        .data$supabase_subtype_name
      )
    )

  missing <- setdiff(ids, taxonomy$supabase_speciesid)
  if (length(missing) > 0L) {
    stop(
      "Mapped Supabase species IDs do not exist: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  taxonomy
}


read_live_gazp5_seeding <- function(con, speciesids) {
  ids <- sort(unique(as.integer(speciesids)))
  id_sql <- paste(DBI::dbQuoteLiteral(con, ids), collapse = ", ")

  DBI::dbGetQuery(
    con,
    paste0(
      "SELECT DISTINCT se.speciesid, se.rate, se.unit\n",
      "FROM grp.seeding se\n",
      "WHERE se.speciesid IN (", id_sql, ")\n",
      "  AND EXISTS (\n",
      "    SELECT 1 FROM grp.area_treatment at\n",
      "    WHERE at.treatmentid = se.treatmentid\n",
      "      AND at.database = 'GAZP' AND at.projectid = 5\n",
      "  )"
    )
  ) |>
    as_tibble() |>
    transmute(
      supabase_speciesid = as.integer(.data$speciesid),
      match_rate = as.numeric(.data$rate),
      match_unit = normalize_text(.data$unit)
    ) |>
    distinct()
}


# ---- Human-reviewed decisions -----------------------------------------

reviewed_decisions <- tribble(
  ~source_speciesid, ~review_status, ~mapping_status,
  ~taxonomic_change_type, ~source_concept_distinct,
  ~related_source_speciesid, ~decision_note,
  "Ach_mil", "human_reviewed", "accepted_as_mapped", "none", FALSE, NA,
  "Reviewed after reconstruction audit; current accepted mapping retained.",
  "Ely_lan", "human_reviewed", "accepted_as_mapped", "none", FALSE, NA,
  "Reviewed after reconstruction audit; current accepted mapping retained.",
  "Art_tri3", "human_reviewed", "corrected_taxon", "database_taxon_corrected",
  TRUE, "Art_tri",
  paste0(
    "Historical source is Artemisia tridentata subsp. tridentata. Supabase ",
    "was corrected on 2026-08-14 to Art_tri_sub_tri / speciesid 7171."
  ),
  "Vic_sat", "human_reviewed", "accepted_as_mapped", "none", FALSE, NA,
  "Reviewed after reconstruction audit; current accepted mapping retained.",
  "Pse_rup1", "human_reviewed", "historical_concept_collapsed",
  "historical_subspecies_collapsed", TRUE, "Pse_rup",
  paste0(
    "Historical source is Pseudosclerochloa rupestris subsp. canbyi. The ",
    "subspecies is no longer retained in the central taxonomy; GAZP5 treated ",
    "Pse_rup1 and Pse_rup as distinct seed-mix concepts."
  ),
  "Kra_cer1", "human_reviewed", "regional_concept_collapsed",
  "regional_subspecies_collapsed", TRUE, "Kra_cer",
  paste0(
    "Historical source is Krascheninnikovia ceratoides subsp. lanata. The ",
    "regional subspecies concept is preserved here but not added to the ",
    "central accepted taxonomy."
  ),
  "Pse_rup", "human_reviewed", "accepted_as_mapped", "none", TRUE,
  "Pse_rup1",
  "Species-level source concept retained and distinguished from Pse_rup1."
)


# ---- Build mapping and contextual rules -------------------------------

classify_automated_taxonomic_change <- function(data) {
  data |>
    mutate(
      historical_matches_current =
        coalesce(.data$historical_genus == .data$supabase_genus, FALSE) &
        coalesce(.data$historical_species == .data$supabase_species, FALSE) &
        coalesce(
          (.data$historical_subtype == .data$supabase_subtype) |
            (is.na(.data$historical_subtype) & is.na(.data$supabase_subtype)),
          FALSE
        ) &
        coalesce(
          (.data$historical_subtype_name == .data$supabase_subtype_name) |
            (is.na(.data$historical_subtype_name) &
               is.na(.data$supabase_subtype_name)),
          FALSE
        ),
      automated_taxonomic_change = case_when(
        .data$historical_matches_current ~ "none",
        !is.na(.data$historical_subtype) & is.na(.data$supabase_subtype) ~
          "source_infraspecific_concept_collapsed",
        TRUE ~ "current_taxonomy_differs_from_historical_source"
      ),
      automated_mapping_status = case_when(
        .data$historical_matches_current ~ "exact_current_taxon",
        .data$automated_taxonomic_change ==
          "source_infraspecific_concept_collapsed" ~
          "historical_concept_collapsed",
        TRUE ~ "taxonomic_change_requires_review"
      ),
      automated_review_status = case_when(
        .data$historical_matches_current ~ "automated_exact_match",
        TRUE ~ "automated_flagged_for_future_review"
      )
    )
}


validate_pse_context <- function(base_mapping, treatment_context, live_seeding) {
  pse_map <- base_mapping |>
    filter(.data$source_speciesid %in% c("Pse_rup", "Pse_rup1")) |>
    select(.data$source_speciesid, .data$supabase_speciesid)

  if (nrow(pse_map) != 2L || n_distinct(pse_map$supabase_speciesid) != 1L) {
    stop("Pse_rup and Pse_rup1 do not share exactly one Supabase species ID.",
         call. = FALSE)
  }

  source_context <- treatment_context |>
    filter(.data$source_speciesid %in% c("Pse_rup", "Pse_rup1")) |>
    left_join(pse_map, by = "source_speciesid") |>
    select(
      .data$source_speciesid,
      .data$supabase_speciesid,
      .data$match_rate,
      .data$match_unit
    ) |>
    distinct()

  ambiguous <- source_context |>
    count(.data$supabase_speciesid, .data$match_rate, .data$match_unit) |>
    filter(.data$n > 1L)
  if (nrow(ambiguous) > 0L) {
    stop(
      "Pse_rup/Pse_rup1 rate and unit combinations overlap; treatment-specific ",
      "exceptions are required before this crosswalk can be written.",
      call. = FALSE
    )
  }

  sql_id <- unique(pse_map$supabase_speciesid)
  live_context <- live_seeding |>
    filter(.data$supabase_speciesid == sql_id) |>
    distinct(.data$supabase_speciesid, .data$match_rate, .data$match_unit)

  missing_live <- anti_join(
    source_context,
    live_context,
    by = c("supabase_speciesid", "match_rate", "match_unit")
  )
  unexplained_live <- anti_join(
    live_context,
    source_context,
    by = c("supabase_speciesid", "match_rate", "match_unit")
  )
  if (nrow(missing_live) > 0L || nrow(unexplained_live) > 0L) {
    stop(
      "Pse_rup/Pse_rup1 source and Supabase rate/unit contexts do not reconcile.",
      call. = FALSE
    )
  }

  source_context
}


build_species_crosswalk <- function(usage, historical, global_map, taxonomy,
                                    live_seeding) {
  base <- usage$summary |>
    left_join(historical, by = "source_speciesid") |>
    left_join(global_map, by = "source_speciesid") |>
    left_join(taxonomy, by = "supabase_speciesid")

  missing_historical <- base |>
    filter(is.na(.data$historical_genus) | is.na(.data$historical_species))
  missing_mapping <- base |>
    filter(is.na(.data$supabase_speciesid) | is.na(.data$supabase_species_code))
  missing_taxonomy <- base |>
    filter(is.na(.data$supabase_genus) | is.na(.data$supabase_species))

  if (nrow(missing_historical) > 0L) {
    stop(
      "GAZP5 codes missing from historical species artifact: ",
      paste(missing_historical$source_speciesid, collapse = ", "),
      call. = FALSE
    )
  }
  if (nrow(missing_mapping) > 0L) {
    stop(
      "GAZP5 codes missing from corrected global species crosswalk: ",
      paste(missing_mapping$source_speciesid, collapse = ", "),
      call. = FALSE
    )
  }
  if (nrow(missing_taxonomy) > 0L) {
    stop("A mapped live Supabase taxon is incomplete.", call. = FALSE)
  }

  code_disagreement <- base |>
    filter(.data$supabase_species_code != .data$live_species_code)
  if (nrow(code_disagreement) > 0L) {
    stop(
      "Global crosswalk and live Supabase species codes disagree for: ",
      paste(code_disagreement$source_speciesid, collapse = ", "),
      call. = FALSE
    )
  }

  base <- base |>
    classify_automated_taxonomic_change() |>
    left_join(reviewed_decisions, by = "source_speciesid") |>
    mutate(
      review_status = coalesce(
        .data$review_status,
        .data$automated_review_status
      ),
      mapping_status = coalesce(
        .data$mapping_status,
        .data$automated_mapping_status
      ),
      taxonomic_change_type = coalesce(
        .data$taxonomic_change_type,
        .data$automated_taxonomic_change
      ),
      source_concept_distinct = coalesce(
        .data$source_concept_distinct,
        FALSE
      )
    )

  pse_context <- validate_pse_context(
    base,
    usage$treatment_rate_context,
    live_seeding
  )

  collisions <- base |>
    group_by(.data$supabase_speciesid) |>
    summarise(
      source_code_count = n_distinct(.data$source_speciesid),
      source_codes = collapse_sorted(.data$source_speciesid),
      .groups = "drop"
    ) |>
    filter(.data$source_code_count > 1L)

  unexpected_collisions <- collisions |>
    filter(.data$source_codes != "Pse_rup;Pse_rup1")
  if (nrow(unexpected_collisions) > 0L) {
    stop(
      "Additional project-level reverse-mapping collisions require review: ",
      paste(unexpected_collisions$source_codes, collapse = " | "),
      call. = FALSE
    )
  }

  ordinary <- base |>
    filter(!.data$source_speciesid %in% c("Pse_rup", "Pse_rup1")) |>
    mutate(
      crosswalk_row_type = "default",
      rule_source_table = "all_relevant_tables",
      reverse_mapping_rule = "supabase_speciesid",
      match_rate = NA_real_,
      match_unit = NA_character_,
      contextual_rule_validated = TRUE
    )

  contextual <- pse_context |>
    left_join(base, by = c("source_speciesid", "supabase_speciesid")) |>
    mutate(
      crosswalk_row_type = "contextual",
      rule_source_table = "trtrates",
      reverse_mapping_rule = "supabase_speciesid_rate_unit",
      contextual_rule_validated = TRUE
    )

  historical_hash <- sha256_file(historical_species_path)
  harmonized_hash <- sha256_file(harmonized_workbook_path)
  global_crosswalk_hash <- sha256_file(global_species_crosswalk_path)

  bind_rows(ordinary, contextual) |>
    transmute(
      database = database_name,
      projectid = projectid,
      project_code = project_code,
      crosswalk_row_type,
      rule_source_table,
      source_tables,
      source_columns,
      source_speciesid,
      source_occurrences,
      historical_group,
      historical_order,
      historical_family,
      historical_genus,
      historical_species,
      historical_subtype,
      historical_subtype_name,
      historical_scientific_name,
      historical_lifeform,
      historical_seedmass,
      historical_pathway,
      historical_raunkiaer,
      historical_woodiness,
      historical_nfix,
      historical_lifespan,
      supabase_speciesid,
      supabase_species_code,
      supabase_group,
      supabase_order,
      supabase_family,
      supabase_genus,
      supabase_species,
      supabase_subtype,
      supabase_subtype_name,
      supabase_scientific_name,
      supabase_lifeform,
      mapping_status,
      taxonomic_change_type,
      source_concept_distinct,
      related_source_speciesid,
      reverse_mapping_rule,
      match_rate,
      match_unit,
      contextual_rule_validated,
      review_status,
      reviewed_by = if_else(
        .data$review_status == "human_reviewed",
        reviewed_by,
        NA_character_
      ),
      review_date = if_else(
        .data$review_status == "human_reviewed",
        as.character(review_date),
        NA_character_
      ),
      decision_note,
      historical_artifact_file = basename(historical_species_path),
      historical_artifact_path = historical_species_path,
      historical_artifact_sha256 = historical_hash,
      historical_artifact_datestamp = "2021-10-26",
      harmonized_artifact_file = basename(harmonized_workbook_path),
      harmonized_artifact_sha256 = harmonized_hash,
      global_crosswalk_file = basename(global_species_crosswalk_path),
      global_crosswalk_sha256 = global_crosswalk_hash,
      generated_at_utc
    ) |>
    arrange(
      .data$source_speciesid,
      .data$rule_source_table,
      .data$match_unit,
      .data$match_rate
    )
}


# ---- Final validation and local reporting ------------------------------

validate_final_crosswalk <- function(crosswalk, usage) {
  missing_codes <- setdiff(
    usage$summary$source_speciesid,
    unique(crosswalk$source_speciesid)
  )
  extra_codes <- setdiff(
    unique(crosswalk$source_speciesid),
    usage$summary$source_speciesid
  )
  if (length(missing_codes) > 0L || length(extra_codes) > 0L) {
    stop("Final crosswalk does not exactly cover GAZP5 source species codes.",
         call. = FALSE)
  }

  duplicate_rows <- crosswalk |>
    count(
      .data$source_speciesid,
      .data$rule_source_table,
      .data$supabase_speciesid,
      .data$match_rate,
      .data$match_unit
    ) |>
    filter(.data$n > 1L)
  if (nrow(duplicate_rows) > 0L) {
    stop("Duplicate final crosswalk rules were produced.", call. = FALSE)
  }

  art <- crosswalk |>
    filter(.data$source_speciesid == "Art_tri3") |>
    distinct(.data$supabase_speciesid, .data$supabase_species_code)
  if (
    nrow(art) != 1L ||
    art$supabase_speciesid[[1]] != 7171L ||
    art$supabase_species_code[[1]] != "Art_tri_sub_tri"
  ) {
    stop("Art_tri3 does not resolve uniquely to 7171 / Art_tri_sub_tri.",
         call. = FALSE)
  }

  pse <- crosswalk |>
    filter(.data$source_speciesid %in% c("Pse_rup", "Pse_rup1"))
  if (
    nrow(pse) == 0L ||
    any(pse$reverse_mapping_rule != "supabase_speciesid_rate_unit") ||
    any(!pse$contextual_rule_validated)
  ) {
    stop("Pse_rup/Pse_rup1 contextual rules are incomplete.", call. = FALSE)
  }

  invisible(TRUE)
}


write_local_outputs <- function(crosswalk, usage) {
  if (file.exists(output_path) && !isTRUE(overwrite_output)) {
    stop(
      "Output already exists. Review it or set overwrite_output <- TRUE: ",
      output_path,
      call. = FALSE
    )
  }

  dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
  dir.create(report_dir, recursive = TRUE, showWarnings = FALSE)

  readr::write_csv(crosswalk, output_path, na = "")

  output_check <- readr::read_csv(output_path, show_col_types = FALSE)
  if (nrow(output_check) != nrow(crosswalk) ||
      !identical(names(output_check), names(crosswalk))) {
    stop("Written GAZP5 species crosswalk failed read-back verification.",
         call. = FALSE)
  }

  summary <- crosswalk |>
    summarise(
      project_code = first(.data$project_code),
      source_species_codes = n_distinct(.data$source_speciesid),
      crosswalk_rows = n(),
      default_rules = sum(.data$crosswalk_row_type == "default"),
      contextual_rules = sum(.data$crosswalk_row_type == "contextual"),
      human_reviewed_codes = n_distinct(
        .data$source_speciesid[.data$review_status == "human_reviewed"]
      ),
      automated_flagged_codes = n_distinct(
        .data$source_speciesid[
          .data$review_status == "automated_flagged_for_future_review"
        ]
      ),
      output_sha256 = sha256_file(output_path),
      generated_at_utc = first(.data$generated_at_utc)
    )

  flagged <- crosswalk |>
    filter(.data$review_status == "automated_flagged_for_future_review") |>
    distinct(
      .data$source_speciesid,
      .data$historical_scientific_name,
      .data$supabase_scientific_name,
      .data$mapping_status,
      .data$taxonomic_change_type
    )

  readr::write_csv(
    summary,
    file.path(report_dir, "GAZP5_species_crosswalk_summary.csv"),
    na = ""
  )
  readr::write_csv(
    flagged,
    file.path(report_dir, "GAZP5_species_taxonomy_flags_for_future_review.csv"),
    na = ""
  )
  readr::write_csv(
    usage$summary,
    file.path(report_dir, "GAZP5_source_species_usage_summary.csv"),
    na = ""
  )
  readr::write_csv(
    usage$excluded_non_taxonomic,
    file.path(report_dir, "GAZP5_non_taxonomic_species_placeholders.csv"),
    na = ""
  )

  report_lines <- c(
    "# GAZP5 species crosswalk build",
    "",
    paste0("Run datestamp: `", run_timestamp, "`"),
    paste0("Generated at UTC: `", generated_at_utc, "`"),
    "Outcome: `LOCAL_BUILD_WRITTEN_AND_VERIFIED`",
    "",
    paste0("Output: `", output_path, "`"),
    paste0("Historical evidence: `", historical_species_path, "`"),
    paste0("Historical artifact SHA-256: `", sha256_file(historical_species_path), "`"),
    paste0("Output SHA-256: `", sha256_file(output_path), "`"),
    "",
    "No Supabase database, Storage, import-documentation, or",
    "project_object_crosswalk changes were made by this script.",
    "The three mix_unknown trtrates rows were explicitly validated and excluded",
    "as unknown-composition seed-mix placeholders, not species identifiers.",
    "",
    "## Summary",
    "",
    paste(capture.output(print(summary, n = Inf)), collapse = "\n")
  )
  writeLines(
    report_lines,
    file.path(report_dir, "GAZP5_species_crosswalk_build_report.md"),
    useBytes = TRUE
  )

  list(summary = summary, flagged = flagged)
}


# ---- Run ---------------------------------------------------------------

run_GAZP5_species_crosswalk_build <- function() {
  message("Reading historical GRP species vocabulary ...")
  historical <- read_historical_species()

  message("Reading GAZP5 source species usage ...")
  usage <- read_gazp5_usage()

  message("Reading corrected global species crosswalk ...")
  global_map <- read_global_species_crosswalk()

  project_mapping <- usage$summary |>
    left_join(global_map, by = "source_speciesid")
  missing_forward <- project_mapping |>
    filter(is.na(.data$supabase_speciesid))
  if (nrow(missing_forward) > 0L) {
    stop(
      "GAZP5 codes missing from global crosswalk: ",
      paste(missing_forward$source_speciesid, collapse = ", "),
      call. = FALSE
    )
  }

  con <- connect_to_supabase_read_only()
  on.exit({
    if (DBI::dbIsValid(con)) DBI::dbDisconnect(con)
  }, add = TRUE)

  message("Reading current Supabase species taxonomy and GAZP5 seeding context ...")
  taxonomy <- read_live_taxonomy(con, project_mapping$supabase_speciesid)
  live_seeding <- read_live_gazp5_seeding(
    con,
    project_mapping$supabase_speciesid
  )

  message("Building project-specific species mappings and reverse rules ...")
  crosswalk <- build_species_crosswalk(
    usage,
    historical,
    global_map,
    taxonomy,
    live_seeding
  )
  validate_final_crosswalk(crosswalk, usage)

  message("Writing and verifying local repository outputs ...")
  reports <- write_local_outputs(crosswalk, usage)

  print(reports$summary, n = Inf)
  if (nrow(reports$flagged) > 0L) {
    message(
      "Automated taxonomy differences remain flagged for future human review: ",
      nrow(reports$flagged)
    )
  }
  message("GAZP5 species crosswalk written to: ", output_path)
  message("Build report written to: ", report_dir)
  message("STOP: no Supabase upload or documentation registration was performed.")

  invisible(list(
    crosswalk = crosswalk,
    summary = reports$summary,
    flagged = reports$flagged,
    output_path = output_path,
    report_dir = report_dir
  ))
}

GAZP5_species_crosswalk_build <- run_GAZP5_species_crosswalk_build()
