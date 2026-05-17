# GRP SQL Schema Change Log

This document tracks all intentional schema changes to the GRP SQL database.

For each change:
- describe the reason
- note affected tables/views
- identify possible code impacts
- record testing performed

---

# Change 003 — Add import and source-to-GRP object tracking
Date: 2026-05-16

### Summary
Add administrative tracking tables to document meaningful processing/upload events and source-to-GRP object mappings.

### Motivation
The GRP workflow has multiple translation stages:

- contributor/raw source → Excel database
- Excel database → input format
- input format → SQL database

Important interpretation and ID-mapping decisions can be lost across these stages. This is especially risky when contributor treatments or plots are split, combined, or reinterpreted into GRP areas, treatments, seed mixes, or vegetation results.

### SQL Objects Affected
- Tables:
  - none modified

- Views:
  - none expected

- New tables:
  - `grp.import_batch`
  - `grp.import_object_map`

- Deprecated tables/columns:
  - none

### Upload / Code Impacts
- Excel → Input code:
  - future workflow should create/update import tracking records when durable transformations or ID mappings are created

- Input → SQL code:
  - future upload workflow should create import batch records and object mapping records during upload

- QA/QC impacts:
  - future QA should confirm source-to-GRP mappings are present for projects where future updates are expected

Dependency checks confirmed:
- proposed tables do not already exist
- `grp.project.database` and `grp.project.projectid` exist
- `grp.project.database` currently allows only `GRP` and `GAZP`

Before OM project records are inserted into `grp.project`, the existing `project.database_check` constraint will need to be updated to allow `OM`.

### SQL Change

```sql
-- Create table for recording meaningful processing/upload events
CREATE TABLE grp.import_batch (
    import_batchid integer NOT NULL,
    database text NOT NULL,
    projectid integer,
    source_folder text,
    source_file_list text,
    pipeline_stage_start text,
    pipeline_stage_end text,
    processed_by text,
    processed_date date,
    workflow_version text,
    notes text,
    CONSTRAINT import_batch_pkey PRIMARY KEY (import_batchid),
    CONSTRAINT import_batch_database_check
      CHECK (database IN ('GAZP', 'GRP', 'OM'))
);

-- Create table for mapping source/contributor objects to GRP SQL objects
CREATE TABLE grp.import_object_map (
    import_object_mapid integer NOT NULL,
    import_batchid integer NOT NULL,
    database text NOT NULL,
    projectid integer,
    source_layer text,
    source_object_type text,
    source_object_id text,
    source_object_label text,
    source_identifier_text text,
    grp_object_type text,
    grp_object_id integer,
    mapping_type text,
    mapping_notes text,
    CONSTRAINT import_object_map_pkey PRIMARY KEY (import_object_mapid),
    CONSTRAINT import_object_map_import_batchid_fkey
        FOREIGN KEY (import_batchid)
        REFERENCES grp.import_batch(import_batchid),
    CONSTRAINT import_object_map_database_check
      CHECK (database IN ('GAZP', 'GRP', 'OM'))
);
```

**Required View Updates**
 - [x] No view updates expected

**Testing Performed**
- [x] Checked proposed table names do not already exist
- [x] Checked referenced grp.project fields
- [x] Checked existing grp.project database constraints
- [x] Schema changes executed
- [x] Post-change structure validated

**Actual Outcome**
Created new administrative tracking tables:
- `grp.import_batch`
- `grp.import_object_map`

`grp.import_batch` records meaningful processing or upload events across the contributor/raw → Excel → input → SQL workflow.

`grp.import_object_map` records flexible mappings between source/contributor objects and GRP SQL objects.

Constraints confirmed:
- `grp.import_batch.import_batchid` is primary key
- `grp.import_object_map.import_object_mapid` is primary key
- `grp.import_object_map.import_batchid` references `grp.import_batch(import_batchid)`
- `database` values are limited to `GAZP`, `GRP`, and `OM` in both new tables

No view updates were required.

**Status**
- Implemented
- Tested

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
 - [x] Inspect full_seeding
 - [x] Inspect downstream impacts, if any

**Testing Performed**
- [x] Seed-related structure inspection completed
- [x] Seed/mix column search completed
- [x] Seed/mix view definition search completed
- [x] Foreign key relationship inspection involving grp.seeding completed
- [x] Schema changes executed
- [x] View updates completed
- [x] Post-change structure validated

**Actual Outcome**
Created new table:
- `grp.seed_mix`

New fields added:
- `grp.seeding.seed_mixid`
- `grp.seeding.notes`

New relationships added:
- foreign key from `grp.seed_mix.treatmentid` → `grp.treatment(treatmentid)`
- foreign key from `grp.seeding.seed_mixid` → `grp.seed_mix(seed_mixid)`

`grp.full_seeding` was rebuilt to expose:
- `seed_mixid`
- `mix_name`
- `mix_composition_status`
- `treated_richness`
- `seed_mix_notes`
- `legacy_mix_name`
- `seeding_notes`

Legacy structure preserved:
- `grp.seeding.mix` retained temporarily for backward compatibility and transition support

No additional seed/mix-related views required updating.

**Status**
- Implemented
- Tested

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
