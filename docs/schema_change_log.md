# GRP SQL Schema Change Log

This document tracks all intentional schema changes to the GRP SQL database.

For each change:
- describe the reason
- note affected tables/views
- identify possible code impacts
- record testing performed

---

# Change 001
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
- [ ] Inspect `full_treatment`
- [ ] Inspect `treatments_by_area`
- [ ] Check whether other treatment-related views should expose notes

**Testing Performed**
- [x] View dependency check completed
- [x] Pre-change treatment structure inspection completed
- [x] Foreign key relationship inspection completed
- [ ] Schema change executed
- [ ] Views updated
- [ ] Post-change structure validated

**Status**
- Planned
