# GRP SQL Schema Change Log

This document tracks all intentional schema changes to the GRP SQL database.

For each change:
- describe the reason
- note affected tables/views
- identify possible code impacts
- record testing performed

---

# Change 002 — Seed mix normalization
Date: 2026-05-15

### Summary
Normalize seed mix structure by separating mix-level metadata from species-level seeding records.

### Motivation
Current seed mix structure stores unknown or partially known seed mixes using fake species-style identifiers (e.g. `mix_5`, `mix_hay`, `mix_unknown`) within species-related workflows.

This structure creates semantic confusion between:
- actual species records
- unknown mixes
- hay/topsoil transfer treatments
- mix-level metadata

The current design works for fully known species compositions, but does not cleanly represent:
- unknown mixes
- partially known mixes
- combined known + unknown mixes
- mix richness metadata

### SQL Objects Affected
- Tables:
  - `grp.seeding`
  - `grp.seeding_pretreatment`

- Views:
  - `grp.full_seeding`

- New tables:
  - `grp.seed_mix`

- Deprecated tables/columns:
  - none

### Upload / Code Impacts
- Excel → Input code:
  - fake `mix_*` species handling will eventually need revision
  - mix-level metadata will eventually need dedicated handling

- Input → SQL code:
  - upload scripts will need to:
    - create `seed_mix` records
    - assign `seed_mixid`; will be non-nullable in 'grp.seeding'
    - preserve nullable `speciesid`
  - existing INSERT statements likely assume current `grp.seeding` structure

- QA/QC impacts:
  - future QA should confirm:
    - no orphaned `seed_mixid` values
    - no treatment mismatches between `grp.seeding` and `grp.seed_mix`
    - proper handling of unknown mixes

Foreign key inspection confirmed existing relationships involving:
- `grp.seeding.speciesid`
- `grp.seeding.cultivarid`
- `grp.seeding_pretreatment.seedingid`

Change 002 is intended to preserve existing species/cultivar relationships while adding seed mix normalization as an additive structure.

### SQL Change

```sql
-- Create seed mix table for treatment-specific seed/planting mix metadata
CREATE TABLE grp.seed_mix (
    seed_mixid integer NOT NULL,
    treatmentid integer NOT NULL,
    mix_name text,
    mix_composition_status text,
    treated_richness text,
    notes text,
    CONSTRAINT seed_mix_pkey PRIMARY KEY (seed_mixid),
    CONSTRAINT seed_mix_treatmentid_fkey
        FOREIGN KEY (treatmentid)
        REFERENCES grp.treatment(treatmentid)
);

-- Add required seed mix link to species-level seeding rows
ALTER TABLE grp.seeding
ADD COLUMN seed_mixid integer NOT NULL;

-- Add seed mix link to species-level seeding rows
ALTER TABLE grp.seeding
ADD CONSTRAINT seeding_seed_mixid_fkey
    FOREIGN KEY (seed_mixid)
    REFERENCES grp.seed_mix(seed_mixid);

-- Add optional notes field for species-level seeding rows
ALTER TABLE grp.seeding
ADD COLUMN notes text;
```

**Required View Updates**
 - [ ] Inspect full_seeding
 - [ ] Inspect downstream impacts, if any

**Testing Performed**
- [ ] Seed-related structure inspection completed
- [ ] Seed/mix column search completed
- [ ] Seed/mix view definition search completed
- [ ] Foreign key relationship inspection involving grp.seeding completed
- [ ] Schema changes executed
- [ ] View updates completed
- [ ] Post-change structure validated

**Actual Outcome**

**Status**
- Planned

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
