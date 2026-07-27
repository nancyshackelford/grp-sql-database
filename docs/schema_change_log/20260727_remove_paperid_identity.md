## Change ID:
Change 020
20260727_remove_paperid_identity

Date:
2026-07-27

### Summary
Removed PostgreSQL identity generation from `grp.paper.paperid`. The column remains a non-null integer primary key, but new paper records must now supply `paperid` explicitly.

### Motivation
Paper identifiers need to be assigned by the paper import workflow rather than generated automatically by PostgreSQL.

The existing `GENERATED ALWAYS AS IDENTITY` property prevents normal inserts from supplying an explicit `paperid` unless they use `OVERRIDING SYSTEM VALUE`. Removing the identity property allows the import workflow to provide the intended identifier directly.

### SQL Objects Affected
- Tables:
  - `grp.paper`

- Referencing tables:
  - `grp.paper_author`
  - `grp.project_paper`

- Views:
  - None

- New tables:
  - None

- Deprecated tables/columns:
  - None

### Upload / Code Impacts
- Excel → Input code:
  - Paper inputs must contain or derive a valid `paperid`.
  - Paper identifiers must be unique across the entire `grp.paper` table.

- Input → SQL code:
  - Paper insert workflows must explicitly populate `paperid`.
  - Inserts that omit `paperid` will fail because the column remains `NOT NULL` and will no longer have an identity-generated value.
  - Code should not use `OVERRIDING SYSTEM VALUE` after this change.
  - Code assigning new identifiers must avoid collisions with existing `paperid` values.

- QA/QC impacts:
  - QA/QC scripts should confirm that every proposed paper record has a non-null integer `paperid`.
  - QA/QC scripts should confirm that proposed identifiers do not duplicate existing values.
  - Existing foreign-key validation for `paper_author` and `project_paper` remains unchanged.

### SQL Change
```sql
ALTER TABLE grp.paper
ALTER COLUMN paperid
DROP IDENTITY;
```

### Required View Updates
None required.

### Testing Performed
- [X] Confirmed grp.paper.paperid is currently an identity column.
- [X] Confirmed its identity generation mode is ALWAYS.
- [X] Confirmed paperid is the primary key for grp.paper.
- [X] Confirmed existing paperid values are unique and non-null.
- [X] Removed identity generation from grp.paper.paperid.
- [X] Confirmed paperid remains an integer.
- [X] Confirmed paperid remains NOT NULL.
- [X] Confirmed paperid remains the primary key.
- [X] Confirmed the column no longer has an identity or sequence default.
- [X] Confirmed foreign keys from paper_author and project_paper remain valid.
- [X] Confirmed no view updates are required.

Local database mirroring was not performed. Dependency checks, diagnostics, and import tests are provided for execution against the connected Supabase database.

### Actual Outcomes
Identity generation was successfully removed from `grp.paper.paperid`. The column remains a non-null integer primary key, but new paper records must now supply `paperid` explicitly.

Existing paper identifiers were preserved, and the foreign-key relationships from `grp.paper_author` and `grp.project_paper` remain valid. No view or data dictionary updates were required.

### Status
- Implemented
- Tested