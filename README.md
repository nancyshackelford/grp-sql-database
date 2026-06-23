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
GRP_SQL/
│
├── R/
│   ├── import_code/
│   │   ├── GAZP1/
│   │   ├── species_import/
│   │   └── source_drafts/
│   │
│   └── crosswalk_tables/
│       ├── GAZP/
│       └── *.csv
│
├── data/
│   └── source/
│       └── GAZP/
│
├── docs/
│   ├── known_code_impacts/
│   ├── lookup_table_changes/
│   ├── schema_change_log/
│   └── templates.md
│
├── sql/
│   ├── data_import/
│   ├── dependency_checks/
│   ├── diagnostics/
│   ├── import_tests/
│   ├── metadata_changes/
│   ├── schema_changes/
│   └── view_updates/
│
├── supabase/
│   └── migrations/
│
├── .gitignore
└── README.md

## Directory Overview
R/

Contains R scripts used to support data imports and database maintenance.

R/import_code/

Import and transformation workflows.

GAZP1/ – Global Arid Zone Project import scripts
species_import/ – Species vocabulary import workflows
source_drafts/ – Development and prototype code
R/crosswalk_tables/

Reference tables used to harmonize source data with database vocabularies.

data/

Stores source datasets used during import and validation workflows.

Raw source files are retained separately from database-ready outputs to maintain provenance and reproducibility.

docs/

Documentation supporting database development and maintenance.

known_code_impacts/ – downstream impacts of schema changes
lookup_table_changes/ – controlled vocabulary and lookup-table changes
schema_change_log/ – formal structural database change documentation
templates.md – documentation templates
sql/

Executable SQL scripts organized by purpose.

data_import/ – data loading and import workflows
dependency_checks/ – schema dependency and impact checks
diagnostics/ – database inspection and troubleshooting scripts
import_tests/ – validation scripts used to confirm successful imports
metadata_changes/ – metadata and data dictionary updates
schema_changes/ – table, constraint, and relationship changes
view_updates/ – creation and maintenance of database views
supabase/

Supabase-specific infrastructure.

migrations/ – version-controlled migration files generated and applied through Supabase
Database Change Workflow

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
