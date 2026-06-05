# Known Code Impacts

## Change ID:
Change 017 — Import Tracking and Provenance Framework

### SQL Change
Created a new import tracking and provenance framework for GRP imports. Added a composite uniqueness constraint to `grp.project(database, projectid)` and replaced the previous `import_object_map` model with project-level import tracking, artifact tracking, transformation tracking, crosswalks, and validation issue tracking.

### Likely Affected Code
- Excel → Input:
  - Future import preparation scripts must organize files as import artifacts rather than relying on a single source folder or object map.
  - Contributor identifiers may need to be preserved for crosswalk creation.

- Input → SQL:
  - New import workflows should populate:
    - `import_batch`
    - `import_project`
    - `import_artifact`
    - `import_transformation_step`
    - `import_transformation_step_artifact`
    - `project_object_crosswalk`
    - `import_validation_issue`
  - Code must use `(database, projectid)` as the project identity pair, not `projectid` alone.

- SQL views:
  - No current view updates required.

- QA/QC scripts:
  - QA/QC scripts should check that `database + projectid` resolves to one project.
  - QA/QC scripts should validate generic `grp_object_id` values in `project_object_crosswalk`.
  - QA/QC scripts should verify unresolved blocker/error issues before final import.

### Dependency Notes
The import framework now assumes:
- `grp.project(database, projectid)` is unique.
- `projectid` alone is not sufficient to identify a project.
- One import batch may include multiple projects.
- One project may have multiple import events over time.
- Files, code, mapping tables, transformation tables, and outputs are tracked as artifacts.
- Transformation steps are documented separately from artifacts.
- Contributor-to-GRP mappings needed for future imports are stored in `project_object_crosswalk`.
- Import problems are tracked in `import_validation_issue`.

### Required Testing
- [x] Confirm `grp.project(database, projectid)` unique constraint exists.
- [x] Confirm all new import/provenance tables exist.
- [x] Confirm composite foreign keys use `(database, projectid)`.
- [x] Confirm `import_object_map` was removed.
- [x] Confirm data dictionary entries match schema columns.
- [x] Confirm data dictionary display_order is sequential.
- [x] Confirm controlled vocabulary fields are documented.

### Actual Outcomes
The import tracking model was redesigned from an object-map structure to a provenance framework. The database can now track project-level import events, associated files/artifacts, transformation workflows, reusable contributor-to-GRP crosswalks, and validation issues.

The addition of the unique constraint on `grp.project(database, projectid)` supports composite foreign keys from the new import tables and formalizes the project identity model used by GRP imports.

No existing production import code required updates because the database is still in setup/import-framework development.

### Status
- Tested