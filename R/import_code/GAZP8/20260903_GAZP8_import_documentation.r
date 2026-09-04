## This script creates the import documentation for GAZP8 after import from
## the harmonized Excel workbook into the GRP PostgreSQL database.
## Entries are created for five tables: import_batch, import_project,
## import_artifact, import_transformation_step, and
## import_transformation_step_artifact.

## project_object_crosswalk is not populated by this workflow. The generated
## harmonized-to-SQL and project species crosswalks are registered as artifacts
## until a standardized project_object_crosswalk loading workflow is available.
## import_validation_issue is also outside the current documentation workflow.

# Libraries
library(tidyverse)
library(DBI)
library(RPostgres)
library(glue)

# Connect to the database
password <- readLines(
  "C:\\Users\\nshack\\OneDrive - University of Victoria\\Documents\\R\\GRP\\pword.csv"
)

con <- dbConnect(
  Postgres(),
  host = "aws-1-ca-central-1.pooler.supabase.com",
  port = 6543,
  dbname = "postgres",
  user = "postgres.rudybfqutvodkakgctpo",
  password = password,
  sslmode = "require"
)

# ---- set baselines ----
database <- "GAZP"
projectid <- 8
supabase_extension <- "GAZP/GAZP8"
import <- "GAZP8"
version <- 1
name <- "Nancy Shackelford"
date_start <- as.Date("2026-09-03")
date_end <- as.Date("2026-09-03")

# ---- Supabase file names ----
harmonized <- "GAZP/GAZP8/harmonized/GAZP8.xlsx"
source_cover_classes <- "GAZP/GAZP8/source/Cover_classes.csv"
source_report <- "GAZP/GAZP8/source/Final_Report_Jan2017_for_Conservation_Registry.pdf"
source_plots_csv <- "GAZP/GAZP8/source/PineRidgeStudyPlots.csv"
source_plots_xlsx <- "GAZP/GAZP8/source/PineRidgeStudyPlots.xlsx"
source_seed_data <- "GAZP/GAZP8/source/Seed_data.csv"
code <- "GAZP/GAZP8/code/20260903_GAZP8_import.r"
species_addition_code <- "GAZP/GAZP8/code/20260903_GAZP8_add_species.r"
crosswalk <- "GAZP/GAZP8/crosswalks/GAZP8_harmonized-SQL_crosswalk.csv"
species_crosswalk <- "GAZP/GAZP8/crosswalks/GAZP8_species_crosswalk.csv"
excluded_vegresults <- "GAZP/GAZP8/crosswalks/GAZP8_excluded_vegresults.csv"

# ---- document import ----
tryCatch(
  {
    dbBegin(con)

    batch_id <- dbGetQuery(
      con,
      glue::glue_sql("
        INSERT INTO grp.import_batch (
          database,
          projectid,
          source_folder,
          source_file_list,
          workflow_version,
          processed_by,
          processed_date,
          pipeline_stage_start,
          pipeline_stage_end,
          notes
        )
        VALUES (
          {database},
          {projectid},
          {paste0('Supabase Storage: grp-import-artifacts/', supabase_extension)},
          {paste(
            harmonized,
            source_cover_classes,
            source_report,
            source_plots_csv,
            source_plots_xlsx,
            source_seed_data,
            code,
            species_addition_code,
            crosswalk,
            species_crosswalk,
            excluded_vegresults,
            sep = ', '
          )},
          {paste0(import, '_v', version)},
          {name},
          {date_end},
          'GAZP8 harmonized data',
          'GAZP8 SQL imported data',
          'Initial import of the Pine Ridge native-winner seeding trial, including reviewed species decisions, blocked experimental structure, treatment corrections, and explicit source-data discrepancies.'
        )
        RETURNING import_batchid;
      ", .con = con)
    )$import_batchid

    import_project_id <- dbGetQuery(
      con,
      glue::glue_sql("
        INSERT INTO grp.import_project (
          import_batchid,
          database,
          projectid,
          contribution_type,
          contribution_period,
          documentation_tier,
          import_status,
          import_started_at,
          import_completed_at,
          is_current_version,
          notes
        )
        VALUES (
          {batch_id},
          {database},
          {projectid},
          'initial_import',
          'Plot treatments applied in November 2012; monitoring in October 2012, May 2013, and June 2014; an area-wide aerial seed application occurred in February 2013.',
          'fully_reproducible',
          'imported',
          CURRENT_TIMESTAMP,
          CURRENT_TIMESTAMP,
          TRUE,
          'First import of GAZP8 into Supabase SQL. The project contains one Colorado grassland site and a three-block experimental seeding design. Sixteen replicate units absent from one treatment-block combination were retained as source missingness and were not synthesized.'
        )
        RETURNING import_projectid;
      ", .con = con)
    )$import_projectid

    artifacts <- tibble::tribble(
      ~artifact_type, ~artifact_subtype, ~file_name, ~file_extension,
      ~file_path_or_storage_key, ~source_layer, ~workflow_stage, ~notes,

      "harmonized_data", "GAZP8", "GAZP8.xlsx", "xlsx",
      harmonized, "legacy Excel database", "input",
      "Harmonized GAZP8 workbook used as the structured SQL-import input.",

      "metadata", "GAZP8 cover classes", "Cover_classes.csv", "csv",
      source_cover_classes, "original contributor documentation", "input",
      "Cover-class definitions supplied with the Pine Ridge monitoring data.",

      "metadata", "GAZP8 project report",
      "Final_Report_Jan2017_for_Conservation_Registry.pdf", "pdf",
      source_report, "original project documentation", "input",
      "Final project report describing the Pine Ridge fire, experimental design, seeding treatments, and monitoring.",

      "raw_data", "GAZP8 Pine Ridge data CSV", "PineRidgeStudyPlots.csv", "csv",
      source_plots_csv, "original contributor data", "input",
      "Original exported Pine Ridge study-plot data.",

      "raw_data", "GAZP8 Pine Ridge workbook", "PineRidgeStudyPlots.xlsx", "xlsx",
      source_plots_xlsx, "original contributor data", "input",
      "Original Pine Ridge workbook containing design, treatment, and monitoring information.",

      "raw_data", "GAZP8 seed data", "Seed_data.csv", "csv",
      source_seed_data, "original contributor data", "input",
      "Detailed source seed-mixture compositions used as the authoritative species lists during import.",

      "transformation_code", "R import script", "20260903_GAZP8_import.r", "r",
      code, "R transformation workflow", "transform/load",
      "R script used to stage, validate, load, and archive the GAZP8 import.",

      "transformation_code", "GAZP8 species additions",
      "20260903_GAZP8_add_species.r", "r",
      species_addition_code, "R taxonomy workflow", "transform/validate",
      "R script used to add or verify Erigeron grandiflorus, Packera multilobata, and Salsola tragus and update the shared species crosswalk.",

      "mapping_table", "GAZP8 harmonized-to-SQL crosswalk",
      "GAZP8_harmonized-SQL_crosswalk.csv", "csv",
      crosswalk, "GAZP8 import crosswalk", "output",
      "Crosswalk linking source treatments, blocks, and replicate units to generated GRP SQL identifiers.",

      "mapping_table", "GAZP8 species crosswalk",
      "GAZP8_species_crosswalk.csv", "csv",
      species_crosswalk, "GAZP8 reviewed species crosswalk", "output",
      "Complete reviewed project species inventory, including source corrections, infraspecific mappings, unknown-taxon decisions, and accepted exclusions.",

      "processed_output", "GAZP8 excluded vegetation observations",
      "GAZP8_excluded_vegresults.csv", "csv",
      excluded_vegresults, "GAZP8 exclusion audit", "output",
      "Audit copy of non-taxonomic or uninterpretable vegetation records excluded from SQL vegetation results. These include bare ground, fine debris, total cover, triticale seed, biocrust, and source codes whose meaning could not be established."
    )

    artifacts_to_write <- artifacts |>
      mutate(
        import_projectid = import_project_id,
        import_batchid = batch_id,
        database = database,
        projectid = projectid,
        storage_bucket = "grp-import-artifacts",
        created_by = name,
        created_date = Sys.Date(),
        loaded_at = Sys.time()
      ) |>
      select(
        import_projectid,
        import_batchid,
        database,
        projectid,
        artifact_type,
        artifact_subtype,
        file_name,
        file_extension,
        file_path_or_storage_key,
        storage_bucket,
        source_layer,
        workflow_stage,
        created_by,
        created_date,
        loaded_at,
        notes
      )

    dbWriteTable(
      con,
      Id(schema = "grp", table = "import_artifact"),
      artifacts_to_write,
      append = TRUE,
      row.names = FALSE
    )

    steps <- tibble::tribble(
      ~step_order, ~step_name, ~step_description, ~transformation_type,
      ~software_or_language, ~notes,

      1L, "Read and reconcile source material",
      "Loaded the harmonized workbook and reviewed it against the original workbook, exported data, seed table, cover-class definitions, and final report.",
      "data ingestion", "R/manual review",
      "Source materials disagreed on some treatment descriptions and seed-mixture richness values; reviewed decisions were recorded in the harmonized data, staged-table notes, and crosswalk artifacts.",

      2L, "Resolve project species",
      "Inventoried taxa, applied reviewed project overrides and exclusions, updated accepted taxonomy, and resolved species identifiers before staging species-bearing tables.",
      "taxonomy resolution", "R/manual review",
      "Reviewed decisions included Achillea millefolium var. occidentalis and Elymus elymoides subsp. elymoides mappings; correction of PASM and SATR-derived codes; genus-level Festuca retention; separate unknown SAVE and SETE observations; and preservation of distinct unidentified forb occurrences.",

      3L, "Build experimental structure and treatments",
      "Generated site-block parent areas and nested replicate areas, generated treatment identifiers, and routed treatment details into GRP treatment tables.",
      "data transformation", "R",
      "Blocks were identified by site and source block. Sixteen absent replicate units were treated as missing source data. Plot seeding was recorded as hand broadcast; the later area-wide aerial seeding was retained separately in other-treatment information.",

      4L, "Build seeding and vegetation results",
      "Created seed-mixture, seeding, and vegetation-result staging tables and linked them to reviewed taxa, treatments, areas, and monitoring dates.",
      "data transformation", "R",
      "Detailed seed data were retained as authoritative: 12 and 23 species were staged where the report narrative instead described 14 and 21. Non-taxonomic vegetation records were excluded, and repeated unidentified forbs were kept as distinct source-taxon occurrences.",

      5L, "Generate crosswalks and validate staging",
      "Created identifier and species crosswalks and validated staged tables against schema, vocabulary, lookup, uniqueness, and referential-integrity requirements.",
      "crosswalk generation and validation", "R",
      "The workflow stopped on unresolved taxa, ambiguous mappings, missing relationships, invalid vocabularies, and partially populated block assignments.",

      6L, "Load staging tables into GRP database",
      "Imported validated staging tables into the GRP PostgreSQL database in dependency-aware order.",
      "database load", "R/PostgreSQL",
      "The load was executed within a database transaction to preserve referential integrity.",

      7L, "Archive import artifacts",
      "Uploaded source files, harmonized data, transformation code, crosswalks, and the exclusion audit to Supabase Storage.",
      "artifact archival", "R/Supabase Storage",
      "Artifacts were retained to support reproducibility, provenance review, auditing, and future re-import workflows.",

      8L, "Register import provenance",
      "Recorded import metadata, artifacts, transformation steps, and their relationships in the GRP import-tracking tables.",
      "provenance documentation", "R/PostgreSQL",
      "Provides a persistent record of the source evidence, reviewed decisions, transformations, and outputs used for GAZP8."
    )

    steps_to_write <- steps |>
      mutate(
        import_projectid = import_project_id,
        import_batchid = batch_id,
        database = database,
        projectid = projectid
      ) |>
      select(
        import_projectid,
        import_batchid,
        database,
        projectid,
        step_order,
        step_name,
        step_description,
        transformation_type,
        software_or_language,
        notes
      )

    dbWriteTable(
      con,
      Id(schema = "grp", table = "import_transformation_step"),
      steps_to_write,
      append = TRUE,
      row.names = FALSE
    )

    artifact_ids <- dbGetQuery(
      con,
      glue::glue_sql("
        SELECT import_artifactid, file_name
        FROM grp.import_artifact
        WHERE import_batchid = {batch_id}
          AND import_projectid = {import_project_id};
      ", .con = con)
    )

    step_ids <- dbGetQuery(
      con,
      glue::glue_sql("
        SELECT import_transformation_stepid, step_order, step_name
        FROM grp.import_transformation_step
        WHERE import_batchid = {batch_id}
          AND import_projectid = {import_project_id};
      ", .con = con)
    )

    step_artifact_plan <- tibble::tribble(
      ~step_order, ~file_name, ~artifact_role, ~notes,

      1L, "GAZP8.xlsx", "input", "Harmonized workbook read as the structured import input.",
      1L, "Cover_classes.csv", "input", "Source cover-class definitions used during source review.",
      1L, "Final_Report_Jan2017_for_Conservation_Registry.pdf", "input", "Project report used to review design, treatments, and seed-mixture descriptions.",
      1L, "PineRidgeStudyPlots.csv", "input", "Original exported study data retained for comparison.",
      1L, "PineRidgeStudyPlots.xlsx", "input", "Original workbook used to review design, treatments, and monitoring records.",
      1L, "Seed_data.csv", "input", "Detailed source seed table used to establish staged mixture composition.",

      2L, "20260903_GAZP8_import.r", "code", "Import script containing reviewed project species overrides and exclusions.",
      2L, "20260903_GAZP8_add_species.r", "code", "Code used to add or verify taxa required by GAZP8.",
      2L, "GAZP8_species_crosswalk.csv", "mapping", "Reviewed project species mappings used by species-bearing staging tables.",
      2L, "GAZP8_excluded_vegresults.csv", "output", "Audit records supporting reviewed vegetation exclusions.",

      3L, "20260903_GAZP8_import.r", "code", "Code used to generate areas, treatments, and their relationships.",
      3L, "GAZP8_harmonized-SQL_crosswalk.csv", "mapping", "Block, replicate, and treatment identifier mappings.",

      4L, "20260903_GAZP8_import.r", "code", "Code used to stage seeding and vegetation-result records.",
      4L, "Seed_data.csv", "input", "Authoritative detailed seed-mixture compositions.",
      4L, "Final_Report_Jan2017_for_Conservation_Registry.pdf", "documentation", "Narrative source whose seed-richness discrepancies were recorded in staged notes.",

      5L, "20260903_GAZP8_import.r", "code", "Code used to generate crosswalks and validate staged tables.",
      5L, "GAZP8_harmonized-SQL_crosswalk.csv", "mapping", "Validated source-to-SQL identifier crosswalk.",
      5L, "GAZP8_species_crosswalk.csv", "lookup", "Validated reviewed species crosswalk.",

      6L, "20260903_GAZP8_import.r", "code", "Code used to load validated staging tables transactionally.",
      8L, "20260903_GAZP8_import.r", "code", "Import code referenced while registering provenance."
    )

    archive_links <- artifacts |>
      transmute(
        step_order = 7L,
        file_name,
        artifact_role = case_when(
          artifact_type == "transformation_code" ~ "code",
          artifact_type == "mapping_table" ~ "mapping",
          artifact_type == "processed_output" ~ "output",
          artifact_type == "metadata" ~ "documentation",
          TRUE ~ "input"
        ),
        notes = "Artifact archived to Supabase Storage as part of the GAZP8 import record."
      )

    step_artifact_links <- bind_rows(step_artifact_plan, archive_links) |>
      left_join(step_ids, by = "step_order") |>
      left_join(artifact_ids, by = "file_name") |>
      select(
        import_transformation_stepid,
        import_artifactid,
        artifact_role,
        notes
      )

    missing_links <- step_artifact_links |>
      filter(is.na(import_transformation_stepid) | is.na(import_artifactid))

    if (nrow(missing_links) > 0L) {
      print(missing_links)
      stop("Some step-artifact links could not be resolved.", call. = FALSE)
    }

    dbWriteTable(
      con,
      Id(schema = "grp", table = "import_transformation_step_artifact"),
      step_artifact_links,
      append = TRUE,
      row.names = FALSE
    )

    dbCommit(con)
  },
  error = function(e) {
    dbRollback(con)
    stop(e)
  }
)
