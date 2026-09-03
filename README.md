# GRP SQL Database

The Global Restore Project (GRP) database supports the storage, management, validation, and analysis of restoration project data from around the world.

This repository contains the SQL schema, metadata management tools, import workflows, migration history, and supporting documentation required to maintain and expand the database.

## Repository Purpose

This repository is used to:

- Develop and maintain the GRP database schema
- Track schema changes and migration history
- Manage lookup tables and metadata
- Build and test data import workflows
- Document code dependencies and database impacts
- Support deployment and maintenance through Supabase

## Repository Structure

```text
R/          R-based import and validation workflows
data/       Source files used during import development
docs/       Change documentation and project records
sql/        Executable SQL scripts
supabase/   Migration files and Supabase configuration
```

## Directory Overview

### R/

Contains R scripts used to support data imports and database maintenance.

- `R/import_code/` — project-specific import, transformation, and import-documentation workflows.
- `R/import_framework/` — immutable, dated versions of shared import code and overarching crosswalk tables.
- `R/import_code/import_framework_import/` — scripts that archive a framework version to Supabase Storage and register its provenance.
- `R/archives/source_drafts/` — historical copies of the former development files; these are retained for provenance, not used as the current framework.
- `R/audit_code/` — database and import-audit workflows.
- `R/supabase_correction_code/` — documented correction workflows applied after import.

Project folders under `R/import_code/` contain the applicable import and documentation scripts. For example, `GAZP1/` through `GAZP6/` contain the completed historical GAZP imports. GAZP8 is the first GAZP import developed after the shared framework was introduced. 

### Shared import framework

The versioned import-framework structure was introduced on 2026-09-03, between the GAZP6 and GAZP8 imports. Before this change, reusable import functions lived in `R/source_drafts/`, while the global species and cultivar crosswalks were stored separately. Those dependencies are now packaged together so that every import can identify and retain the exact shared code and lookup tables it used.

The first framework version is:

```text
R/import_framework/20260903_framework/
├── 20260612_import_registry.r
├── 20260620_import_helper_functions.r
├── 20260825_species_crosswalk_creation.R
├── 20260605_sp_crosswalk.csv
└── cultivar_crosswalk.csv
```

The dated directory is the framework version. Once used for an import, its contents should be treated as immutable. When shared code or an overarching crosswalk changes, copy the complete bundle into a new dated directory and make changes there. Do not overwrite an older version, because completed imports must remain reproducible against the dependencies they originally used.

For GAZP8 and later imports:

1. Set one framework directory near the beginning of the project import script.
2. Establish the database connection as `con` before sourcing the import registry, because the registry queries the live schema.
3. Source reusable code from that framework directory rather than from `R/source_drafts/` or `R/archives/`.
4. Read the global species and cultivar crosswalks from the same framework directory.
5. Record the exact framework version in the project import documentation's `workflow_version` and register the applicable framework files as shared code or lookup dependencies.
6. If a new framework version has not yet been archived, run its upload script and then its documentation script from `R/import_code/import_framework_import/`.

A project import should use paths like:

```r
framework_version <- "20260903_framework"
framework_dir <- file.path("R", "import_framework", framework_version)

# `con` must already be an open DBI connection before this line.
source(file.path(framework_dir, "20260612_import_registry.r"))
source(file.path(framework_dir, "20260620_import_helper_functions.r"))
source(file.path(framework_dir, "20260825_species_crosswalk_creation.R"))

species_crosswalk_file <- file.path(
  framework_dir,
  "20260605_sp_crosswalk.csv"
)
cultivar_crosswalk_file <- file.path(
  framework_dir,
  "cultivar_crosswalk.csv"
)
```

The three code files do not replace the project-specific import script. They provide shared schema inspection, staging and validation helpers, Supabase upload support, and species-resolution functions. Each project import must still define its own source files, project-specific transformations, reviewed mapping overrides, staging tables, validation decisions, and database-loading steps.

GAZP6 marks the end of the earlier structure and retains its original `R/source_drafts/` references as historical evidence of how that import ran. The old shared files have since moved to `R/archives/source_drafts/`. Do not use the archived directory as the dependency source for new imports; use a dated `R/import_framework/` version instead.

### data/

Stores source datasets used during import and validation workflows.

Raw source files are retained separately from database-ready outputs to maintain provenance and reproducibility.

### docs/

Documentation supporting database development and maintenance.

- `known_code_impacts/` — downstream impacts of schema changes.
- `lookup_table_changes/` — controlled vocabulary and lookup-table changes.
- `schema_change_log/` — formal structural database change documentation.
- `templates.md` — documentation templates.

### sql/

Executable SQL scripts organized by purpose.

- `data_import/` — data-loading and import workflows.
- `dependency_checks/` — schema dependency and impact checks.
- `diagnostics/` — database inspection and troubleshooting scripts.
- `import_tests/` — validation scripts used to confirm successful imports.
- `metadata_changes/` — metadata and data-dictionary updates.
- `schema_changes/` — table, constraint, and relationship changes.
- `view_updates/` — creation and maintenance of database views.

### supabase/

Supabase-specific infrastructure.

- `migrations/` — version-controlled migration files generated and applied through Supabase.

## Philosophy

All structural changes should follow a documented workflow:

Identify the required change.
Assess downstream impacts.
Document the proposed modification.
Implement the change.
Test affected functionality.
Update metadata and documentation.
Commit and merge through GitHub.

Documentation should accompany all significant schema, metadata, lookup-table, and workflow changes.

## Current Status

The database schema has been migrated to Supabase and is under active development.

Current priorities include:

GRP project imports
GAZP project imports
Import provenance tracking
Species vocabulary management
Validation and quality-control workflows
Ongoing schema refinement and documentation
Related Components

The broader GRP workflow includes:

Source data harmonization in R
Controlled vocabulary management
Import validation and staging
PostgreSQL/Supabase database infrastructure
Analysis and reporting workflows

This repository serves as the central location for database development, migration management, and import infrastructure.
