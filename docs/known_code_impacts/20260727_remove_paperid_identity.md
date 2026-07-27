## Change ID:
20260727_remove_paperid_identity

### SQL Change
Removed identity generation from `grp.paper.paperid`. The column remains the non-null integer primary key for `grp.paper`, but its value must now be supplied explicitly when a paper is inserted.

### Likely Affected Code
- Excel → Input:
  - Paper inputs that previously omitted `paperid`.
  - Workflows that generate or assign paper identifiers before upload.
  - Validation code for paper identifier completeness and uniqueness.

- Input → SQL:
  - Scripts that insert records into `grp.paper`.
  - Scripts that relied on `INSERT ... RETURNING paperid` to receive a database-generated identifier.
  - Scripts that used `OVERRIDING SYSTEM VALUE` to insert explicit paper identifiers.
  - Scripts that create related `paper_author` or `project_paper` records using a newly generated paper identifier.

- SQL views:
  - No current view updates required.

- QA/QC scripts:
  - Validation that `paperid` is present for every incoming paper.
  - Validation that incoming identifiers do not duplicate existing `grp.paper.paperid` values.
  - Validation that paper identifiers used by related records exist in `grp.paper`.

### Dependency Notes
- `paperid` remains globally unique through `grp.paper_pkey`.
- `paperid` remains non-null.
- Existing records and their identifiers are not changed by dropping identity generation.
- Foreign keys from `grp.paper_author.paperid` and `grp.project_paper.paperid` remain in place.
- Inserts that omit `paperid` will fail after the change.
- The paper import workflow becomes responsible for assigning collision-free identifiers.
- Workflows that assign identifiers using `MAX(paperid) + 1` may produce collisions when imports run concurrently and should not be used without an appropriate locking or allocation process.
- Existing code expecting PostgreSQL to return a newly generated `paperid` must be revised.

### Required Testing
- [X] Confirm `grp.paper.paperid` is currently generated as an identity.
- [X] Confirm all existing `paperid` values are non-null and unique.
- [X] Confirm paper import code can supply explicit identifiers.
- [X] Confirm identity generation has been removed.
- [X] Confirm `paperid` remains the primary key.
- [X] Confirm explicit, unused `paperid` values are accepted.
- [X] Confirm duplicate `paperid` values remain rejected.
- [X] Confirm omitted `paperid` values are rejected.
- [X] Confirm existing paper-author and project-paper relationships remain valid.
- [X] Confirm no view changes are required.

### Actual Outcomes
The paper import workflow must now provide an explicit, globally unique `paperid` when inserting a record into `grp.paper`. Code can no longer rely on PostgreSQL to generate and return the identifier automatically.

Existing paper, paper-author, and project-paper records were unaffected. No additional code, view, or data dictionary impacts were identified during testing.

### Status
- Implemented
- Tested