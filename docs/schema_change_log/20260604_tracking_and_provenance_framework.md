# GRP SQL Schema Change Log

## Change ID:
Change 017 — Import Tracking and Provenance Framework

Date:
2026-06-04

### Summary
Created a new import tracking and provenance framework to support GRP data imports, future contributor updates, transformation documentation, artifact tracking, crosswalk reuse, and validation issue tracking.

### Motivation
The previous import tracking model did not adequately support the full GRP import workflow. GRP imports need to track not only final harmonized data, but also raw files, code, mapping tables, transformation tables, processed outputs, validation issues, and future data contributions.

This change also formalizes that project identity is based on the combination of `database` and `projectid`, rather than `projectid` alone.

### SQL Objects Affected
- Tables:
  - `grp.project`
  - `grp.import_batch`
  - `grp.data_dictionary`

- Views:
  - None

- New tables:
  - `grp.import_project`
  - `grp.import_artifact`
  - `grp.import_transformation_step`
  - `grp.import_transformation_step_artifact`
  - `grp.project_object_crosswalk`
  - `grp.import_validation_issue`

- Deprecated tables/columns:
  - `grp.import_object_map` removed
  - `grp.import_batch.projectid` removed from the new import tracking model

### Upload / Code Impacts
- Excel → Input code:
  - Import workflows should prepare project-level import records and artifact inventories.
  - Source files, mapping tables, transformation tables, code, metadata, and outputs should be registered in `import_artifact`.

- Input → SQL code:
  - Import scripts must use `(database, projectid)` as the project identity pair.
  - Import scripts should create `import_project` records before registering artifacts or validation issues.
  - GRP-style documented workflows should populate transformation step tables and link artifacts to those steps.

- QA/QC impacts:
  - QA/QC scripts should check unresolved validation issues.
  - QA/QC scripts should validate crosswalk target IDs.
  - QA/QC scripts should confirm schema-to-data-dictionary alignment after changes.

### SQL Change
```sql
-- See migration files for Change 017:
-- 1. Add UNIQUE constraint to grp.project(database, projectid)
-- 2. Create grp.import_project
-- 3. Create grp.import_artifact
-- 4. Create grp.import_transformation_step
-- 5. Create grp.import_transformation_step_artifact
-- 6. Create grp.project_object_crosswalk
-- 7. Create grp.import_validation_issue
-- 8. Drop grp.import_object_map
-- 9. Update grp.data_dictionary
```

### Required View Updates
- [x] None required

### Testing Performed
- [x] Verified new tables exist.
- [x] Verified grp.project(database, projectid) unique constraint exists.
- [x] Verified foreign key relationships.
- [x] Verified controlled vocabulary CHECK constraints.
- [x] Verified indexes.
- [x] Verified import_object_map removal.
- [x] Verified data dictionary entry counts.
- [x] Verified data dictionary display_order sequence.
- [x] Verified schema columns match data dictionary entries.
- [x] Verified no extra data dictionary entries remain for removed columns/tables.

### Actual Outcomes

The new framework was implemented and tested. The database now supports batch-level import tracking, project-level import events, artifact/provenance inventories, transformation step documentation, artifact-to-step relationships, reusable project object crosswalks, and structured validation issue tracking.

The project table now includes a unique constraint on (database, projectid), allowing import tables to reference project identity correctly using the composite key.

import_object_map was removed because reusable mappings are now handled by project_object_crosswalk, while source mapping files and transformation documentation are tracked through import_artifact and import_transformation_step.

### Status
- Tested