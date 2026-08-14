# Configuration for the read-only Supabase export and reconstruction audit.
#
# This file contains configuration only. It does not connect to Supabase,
# query the database, or write any output.

audit_config <- list(
  # Database scope ---------------------------------------------------------
  schema = "grp",
  source_database = "GAZP",
  projectids = c(1L, 2L, 3L, 5L),

  # Snapshot used by reconstruction and audit scripts. Change this value
  # explicitly when a newer raw Supabase snapshot should become the source.
  active_snapshot = "2026-08-13",

  # Repository locations --------------------------------------------------
  paths = list(
    raw_supabase_root = "data/supabase_snapshots",
    reconstructed_root = "data/reconstructed",
    harmonized_root = "data/harmonized/GAZP",
    crosswalk_root = "crosswalk_tables/GAZP",
    audit_report_root = "docs/audit_reports"
  ),

  # Crosswalks are read from the repository. They are not downloaded from
  # Supabase and are not copied into raw Supabase snapshot directories.
  project_crosswalks = c(
    GAZP1 = "crosswalk_tables/GAZP/GAZP1/GAZP1_harmonized-SQL_crosswalk.csv",
    GAZP2 = "crosswalk_tables/GAZP/GAZP2/GAZP2_harmonized-SQL_crosswalk.csv",
    GAZP3 = "crosswalk_tables/GAZP/GAZP3/GAZP3_harmonized-SQL_crosswalk.csv",
    GAZP5 = "crosswalk_tables/GAZP/GAZP5/GAZP5_harmonized-SQL_crosswalk.csv"
  ),

  harmonized_workbooks = c(
    GAZP1 = "data/harmonized/GAZP/GAZP1/GAZP1.xlsx",
    GAZP2 = "data/harmonized/GAZP/GAZP2/GAZP2.xlsx",
    GAZP3 = "data/harmonized/GAZP/GAZP3/GAZP3.xlsx",
    GAZP5 = "data/harmonized/GAZP/GAZP5/GAZP5.xlsx"
  ),

  # Base tables populated directly or indirectly by the GAZP imports. The
  # export script will use table-specific joins to restrict these records to
  # the configured projects; not every table contains database/projectid.
  export_tables = list(
    project_backbone = c(
      "project",
      "project_data_accessibility",
      "location",
      "project_location",
      "site",
      "project_site",
      "paper",
      "paper_author",
      "project_paper",
      "author_contributor",
      "project_contributor",
      "project_vegmetric"
    ),

    site_attributes = c(
      "site_classification",
      "site_disturbance",
      "site_ref_ecosystem",
      "site_soil",
      "site_invasive"
    ),

    experimental_structure = c(
      "area",
      "treatment",
      "area_treatment"
    ),

    treatment_details = c(
      "treatment_application",
      "treatment_cover_crop",
      "treatment_erosion",
      "treatment_fertilization",
      "treatment_grazer",
      "treatment_herbicide",
      "treatment_invasion",
      "treatment_irrigation",
      "treatment_material",
      "treatment_medium",
      "treatment_mowing",
      "treatment_prep"
    ),

    seeding_and_planting = c(
      "seed_mix",
      "seeding",
      "seeding_pretreatment"
    ),

    results = "veg_result",

    # These global vocabulary records are required to translate SQL species
    # and cultivar IDs during reconstruction. The export should retain only
    # records referenced by the selected GAZP projects.
    reconstruction_vocabularies = c(
      "species",
      "species_names",
      "cultivar"
    )
  ),

  # Explicit exclusions make the audit boundary visible. Reporting views are
  # also excluded from the raw snapshot because they derive from base tables.
  excluded_tables = c(
    "data_dictionary",
    "view_dictionary",
    "individual",
    "import_batch",
    "import_object_map",
    "import_project",
    "import_artifact",
    "import_transformation_step",
    "import_transformation_step_artifact",
    "project_object_crosswalk",
    "import_validation_issue"
  ),

  excluded_views = c(
    "full_area",
    "full_cultivar",
    "full_individual",
    "full_paper",
    "full_project",
    "full_seeding",
    "full_site",
    "full_species",
    "full_treatment",
    "full_veg_results",
    "treatments_by_area"
  ),

  # Raw snapshot behaviour ------------------------------------------------
  snapshot = list(
    date_format = "%Y-%m-%d",
    file_prefix = "grp_",
    file_extension = ".csv",
    overwrite_existing_snapshot = FALSE,
    include_empty_tables = TRUE,
    write_schema_metadata = TRUE,
    write_manifest = TRUE,
    calculate_sha256 = TRUE,
    transaction_isolation = "REPEATABLE READ"
  ),

  # Environment-variable names only. Credentials are never stored here.
  connection = list(
    host_env = "SUPABASE_DB_HOST",
    port_env = "SUPABASE_DB_PORT",
    dbname_env = "SUPABASE_DB_NAME",
    user_env = "SUPABASE_DB_USER",
    password_env = "SUPABASE_DB_PASSWORD",
    default_port = 5432L,
    default_dbname = "postgres",
    sslmode = "require"
  )
)

# Convenient flattened vector for iteration and validation in later scripts.
audit_config$export_table_names <- unique(
  unname(unlist(audit_config$export_tables, use.names = FALSE))
)
