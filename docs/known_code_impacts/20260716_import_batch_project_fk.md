
## Change ID:
20260716_import_batch_project_fk

### SQL Change
Added a composite foreign key from `grp.import_batch(database, projectid)` to `grp.project(database, projectid)`, matching the project foreign key relationship used by `grp.import_artifact`.

### Likely Affected Code
- Excel → Input:
  - No impacts expected.

- Input → SQL:
  - Scripts that populate `grp.import_batch.projectid`.
  - Import documentation scripts that update an import batch after a project ID has been generated.
  - Any script that inserts an import batch with a populated `projectid` before the corresponding `grp.project` record exists.

- SQL views:
  - No current view updates required.

- QA/QC scripts:
  - Import batch referential-integrity checks.
  - Validation of database/project identifier combinations.

### Dependency Notes
- `grp.project(database, projectid)` must remain unique.
- Project identity is the combination of `database` and `projectid`; `projectid` alone is not sufficient.
- A populated `grp.import_batch.projectid` must identify a project in the same database recorded in `grp.import_batch.database`.
- A null `projectid` remains permitted and is not rejected by the foreign key.
- Existing orphaned import batch references must be corrected before the constraint is added.
- Updating a referenced project identity will cascade to `grp.import_batch`.
- Deleting a project referenced by `grp.import_batch` will be restricted.

### Required Testing
- [X] Confirm `grp.project(database, projectid)` is unique.
- [X] Confirm no existing import batch project references are orphaned.
- [X] Confirm `import_batch_project_fk` exists.
- [X] Confirm the FK references `grp.project(database, projectid)`.
- [X] Confirm null `projectid` values remain valid.
- [X] Confirm valid database/project combinations are accepted.
- [X] Confirm invalid database/project combinations are rejected.
- [X] Confirm no view changes are required.

### Actual Outcomes
The new foreign key constraint was reviewed against the identified import and documentation workflows.

Existing code may continue creating multiple import batches for the same project, and batches may still be created with a null projectid. When projectid is populated, the (database, projectid) combination must reference an existing row in grp.project.

No existing code changes, view updates, or data dictionary updates were required. No additional code impacts were identified during testing.

### Status
- Implemented
- Tested