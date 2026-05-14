# GRP SQL Schema Change Log

This document tracks all intentional schema changes to the GRP SQL database.

For each change:
- describe the reason
- note affected tables/views
- identify possible code impacts
- record testing performed

---

# Change 001 - Add treatment notes column
Date: 2026-05-14

### Summary
Add a general `notes` column to `grp.treatment`.

### Motivation
Current treatment structure lacks a flexible field for storing uncommon or complex treatment details that do not fit existing treatment subtype tables.

Examples include:
- unusual mowing details
- grazing context
- passive dispersal notes
- topsoil detail context
- restoration implementation notes

### SQL Objects Affected
- Tables:
  - `grp.treatment`

- Views:
  - `grp.full_treatment`
  - `grp.treatments_by_area`
  - possible downstream impacts to:
    - `grp.full_area`
    - `grp.full_seeding`
    - `grp.full_individual`

- New tables:
  - none

- Deprecated tables/columns:
  - none

### Upload / Code Impacts
- Excel → Input code:
  - no expected immediate impact

- Input → SQL code:
  - upload scripts may assume exact existing treatment column structure
  - INSERT statements need inspection later

- QA/QC impacts:
  - future QA should confirm notes appear correctly in affected views
 
Foreign key inspection confirmed multiple treatment-detail tables reference `grp.treatment(treatmentid)`. Change 001 does not alter `treatmentid`, so relationship breakage is not expected.

### SQL Change

```sql
ALTER TABLE grp.treatment
ADD COLUMN notes text;
```

---

**Required View Updates**
- [x] Inspect `full_treatment`
- [x] Inspect `treatments_by_area`
- [x] Inspected `full_area`; no update needed. View only aggregates treatment IDs by area and does not expose treatment details.
- [x] Inspected `full_seeding`; no update needed. View is focused on seeding details and only carries `treatmentid` as a relationship field.
- [x] Inspected `full_individual`; no update needed. View is focused on individual records and uses `area_treatment` only for project context.

### Testing Performed
- [x] View dependency check completed
- [x] Pre-change treatment structure inspection completed
- [x] Foreign key relationship inspection completed
- [x] Schema change executed
- [x] `full_treatment` updated and validated
- [x] `treatments_by_area` updated and validated
- [x] Other flagged views inspected
- [x] Post-change structure validated

---
### Actual Outcome
`notes text` was successfully added to `grp.treatment`.

`grp.full_treatment` was updated to expose:
- `treatment.notes AS treatment_notes`

`grp.treatments_by_area` was updated to pass through:
- `full_treatment.treatment_notes`

Other views inspected:
- `full_area`: no update needed
- `full_seeding`: no update needed
- `full_individual`: no update needed

**Status**
- Implemented
- Tested
