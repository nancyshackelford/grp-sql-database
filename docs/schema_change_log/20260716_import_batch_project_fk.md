## Change ID:
Change 019
20260716_import_batch_project_fk

Date:
2026-07-16

### Summary
Added a composite foreign key constraint from `grp.import_batch(database, projectid)` to `grp.project(database, projectid)`. This applies the same project foreign key relationship already used by `grp.import_artifact` and other import tracking tables.

### Motivation
`grp.import_batch` contains `database` and `projectid` columns but did not enforce that populated project identifiers correspond to an existing project record.

The import tracking and provenance framework established that project identity is based on the combination of `database` and `projectid`, rather than `projectid` alone. Adding this constraint prevents import batch records from referencing a project identifier that does not exist for the specified database.

### SQL Objects Affected
- Tables:
  - `grp.import_batch`

- Referenced tables:
  - `grp.project`

- Views:
  - None

- New tables:
  - None

- Deprecated tables/columns:
  - None

### Upload / Code Impacts
- Excel → Input code:
  - No impacts expected.

- Input → SQL code:
  - Import workflows may continue leaving `projectid` null when a batch is created before its project is known.
  - When `projectid` is populated, the combination of `database` and `projectid` must already exist in `grp.project`.
  - Code that inserts an invalid database/project combination will now fail with a foreign key violation.

- QA/QC impacts:
  - QA/QC scripts should confirm that populated `import_batch` project references resolve to an existing row in `grp.project`.
  - Existing orphaned references must be resolved before the constraint can be added.

### SQL Change
```sql
ALTER TABLE grp.import_batch
ADD CONSTRAINT import_batch_project_fk
FOREIGN KEY (database, projectid)
REFERENCES grp.project(database, projectid)
ON UPDATE CASCADE
ON DELETE RESTRICT;
```

### Required View Updates
None required

### Testing Performed
- [X] Confirmed grp.project(database, projectid) has the required unique constraint.
- [X] Confirmed no existing grp.import_batch rows contain orphaned project references.
- [X] Added import_batch_project_fk.
- [X] Confirmed the foreign key uses (database, projectid) in the correct order.
- [X] Confirmed ON UPDATE CASCADE.
- [X] Confirmed ON DELETE RESTRICT.
- [X] Confirmed batches with a null projectid remain permitted.
- [X] Confirmed valid populated project references pass validation.
- [X] Confirmed invalid populated project references are rejected.

### Actual Outcomes
The composite foreign key constraint was successfully added from grp.import_batch(database, projectid) to grp.project(database, projectid).
Existing import_batch records with populated project identifiers were confirmed to reference valid projects. Multiple import batches may continue to reference the same project, while invalid database and project ID combinations are now rejected.
Import batches with a null projectid remain permitted. No view or data dictionary updates were required, and no unexpected code impacts were identified.

### Status
- Implemented
- Tested