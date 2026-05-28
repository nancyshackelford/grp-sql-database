# GRP Lookup Table Change Log

## Associated migration code:
'20260528080000_populate-classification-lookup.sql'

Date:
2026-05-28

### Summary
Populated `grp.classification` with USDA/NatureServe Level 1–3 vegetation formation classifications from Appendix B of USDA Forest Service RMRS-GTR-346 (2016). Removed redundant CHECK constraints that duplicated controlled vocabulary enforcement already provided by the lookup table itself.

### Motivation
The `grp.classification` lookup table previously existed structurally but contained no records. Classification terms were intended to align with the USDA/NatureServe vegetation formation hierarchy, but the absence of lookup rows prevented consistent classification assignment and validation through foreign key relationships.

Existing CHECK constraints on `class`, `subclass`, and `subsubclass` partially duplicated the intended lookup vocabulary and conflicted with official USDA/NatureServe terminology. Because the lookup table itself now functions as the controlled vocabulary source, these constraints were removed to reduce brittleness and improve future maintainability.

### SQL Objects Affected
- Tables:
  - `grp.classification`

- Views:
  - None required

- Constraints removed:
  - `class_check`
- `subclass_check`
- `subsubclass_check`

- Foreign key relationships confirmed:
  - `grp.site_classification.classificationid`
→ `grp.classification.classificationid`

### Upload / Code Impacts
- Excel → Input code:
  - Future uploads referencing classification IDs must use USDA/NatureServe Level 3 IDs (e.g., `1.A.1`, `2.C.5`).

- Input → SQL code:
  - Classification import workflows can now validate against populated lookup values using FK relationships rather than hard-coded vocabulary checks.

- QA/QC impacts:
  - Controlled vocabulary enforcement now occurs through lookup-table membership rather than CHECK constraints.
- Future vocabulary additions can be implemented through lookup inserts without requiring schema edits.

### Reference Source
Faber-Langendoen et al. 2016. USDA Forest Service RMRS-GTR-346, Appendix B, Level 1–3 vegetation formation hierarchy.

### Classification ID Strategy
`classificationid` values use compact hierarchical USDA/NatureServe codes:
  
- `1.A.1`
- `2.C.5`
- `4.B.1`

This preserves stable FK references while allowing terminology updates if future standards evolve.

### Scope Notes
This change populated vegetated Level 1–3 formation units only.

Non-vegetated classes listed on page 193 of the source reference were intentionally excluded because:
  - they do not follow the same hierarchical coding structure
- they may warrant separate handling within the GRP schema
- their inclusion strategy has not yet been finalized

### SQL Change
```sql
-- Removed redundant vocabulary CHECK constraints
ALTER TABLE grp.classification
DROP CONSTRAINT IF EXISTS class_check;

ALTER TABLE grp.classification
DROP CONSTRAINT IF EXISTS subclass_check;

ALTER TABLE grp.classification
DROP CONSTRAINT IF EXISTS subsubclass_check;

-- Inserted 49 USDA/NatureServe classification rows
-- See migration:
  -- populate-classification-lookup.sql
```

### Required View Updates
- [x] None required

### Testing Performed
- [x] Confirmed 49 classification rows inserted successfully
- [x] Confirmed no duplicate classificationid values
- [x] Confirmed no NULL classification IDs
- [x] Confirmed primary key remained intact
- [x] Confirmed removal of obsolete CHECK constraints
- [x] Confirmed FK relationship between grp.site_classification.classificationid and grp.classification.classificationid
- [x] Confirmed no orphaned site_classification records
- [x] Confirmed grp.full_site remained queryable

### Actual Outcomes

The lookup table population completed successfully and inserted 49 USDA/NatureServe vegetation formation classifications.

The previous CHECK constraints were removed without impacting FK integrity or downstream view functionality.

The database now uses the lookup table itself as the authoritative controlled vocabulary source for vegetation classification hierarchy values.

### Status
- Implemented
- Tested