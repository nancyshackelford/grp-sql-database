# GRP SQL Schema Change Log

This document tracks all intentional schema changes to the GRP SQL database.

For each change:
- describe the reason
- note affected tables/views
- identify possible code impacts
- record testing performed

---

# GRP SQL Schema Change Log

## Change ID:
Change 016

Date:
2026-05-24

### Summary
Rename `grp.treatment_mowing.mowing_type` to `type`, create a new `grp.mowing` lookup table, recreate dependent views, and update related data dictionary entries.

### Motivation
Most treatment detail tables use a standardized internal column name of `type`. `grp.treatment_mowing` was inconsistent with this convention by using `mowing_type`. This change improves schema consistency across treatment detail tables while preserving the more descriptive output name `mowing_type` within denormalized views.

A new `grp.mowing` lookup table was also added to provide a controlled vocabulary structure for mowing treatment categories.

### SQL Objects Affected
- Tables:
  - `grp.treatment_mowing`
  - `grp.data_dictionary`

- Views:
  - `grp.full_treatment`
  - `grp.treatments_by_area`

- New tables:
  - `grp.mowing`

- Deprecated tables/columns:
  - `grp.treatment_mowing.mowing_type`

### Upload / Code Impacts
- Excel → Input code:
  - Input templates and preprocessing scripts referencing `mowing_type` must now use `type`

- Input → SQL code:
  - INSERT statements targeting `grp.treatment_mowing` must reference `type`
  - Controlled vocabulary logic may now optionally validate against `grp.mowing`

- QA/QC impacts:
  - QA/QC scripts referencing `mowing_type` require updating
  - Lookup-table validation checks can now include `grp.mowing`

### SQL Change
```sql
ALTER TABLE grp.treatment_mowing
RENAME COLUMN mowing_type TO type;

CREATE TABLE grp.mowing (
    type text PRIMARY KEY,
    definition text,
    notes text
);

INSERT INTO grp.mowing (
    type,
    definition,
    notes
)
VALUES
    ('present', 'Vegetation was mowed.', NULL),
    ('mulch', 'Vegetation was mowed and biomass left on site.', NULL),
    ('removal', 'Vegetation was cut and removed as hay or biomass.', NULL),
    ('flail', 'Vegetation was mowed using a flail mower.', NULL);
```

### Required View Updates
- [x] Recreate `grp.full_treatment`
- [x] Recreate `grp.treatments_by_area`
- [x] Update references from `m.mowing_type` to `m.type`

### Testing Performed
- [x] Checked updated structure of `grp.treatment_mowing`
- [x] Confirmed `grp.mowing` exists
- [x] Confirmed `grp.mowing` values were inserted
- [x] Confirmed `grp.full_treatment` compiles successfully
- [x] Confirmed `grp.treatments_by_area` compiles successfully
- [x] Confirmed updated view definitions reference `m.type`
- [x] Confirmed data dictionary updates were applied successfully

### Actual Outcomes

Schema changes were implemented successfully without affecting overall treatment view structure or denormalized output formatting.

`grp.treatment_mowing` now follows the same internal naming convention as other treatment detail tables that use a standardized `type` field.

The new `grp.mowing` lookup table is functioning as the controlled vocabulary source for mowing treatment categories.

View recreation completed successfully and downstream view outputs remained stable, including continued exposure of the `mowing_type` column name in denormalized views.

Data dictionary updates compiled successfully after correcting INSERT statements to rely on the auto-generated `dictionaryid` sequence.

Import tests confirmed:
- successful column rename
- successful lookup table creation and population
- successful recompilation of dependent views
- successful data dictionary updates
- absence of remaining `m.mowing_type` references in updated view definitions

No additional view dictionary updates were required because view purpose, grain, and output structure remained unchanged.

### Status
- Implemented
- Tested

---

# GRP SQL Schema Change Log

## Change ID: Change 014
Date: 2026-05-23

### Summary
Created `grp.project_data_accessibility` and moved project dataset accessibility metadata out of paper/project metadata.

### Motivation
Dataset accessibility describes whether and how the underlying project data can be accessed. This is distinct from publication access. Papers remain standalone publication/source entities linked to projects through `grp.project_paper`.

### SQL Objects Affected
- Tables:
  - `grp.paper`
  - `grp.project`
- Views:
  - `grp.full_paper`
  - `grp.full_project`
- New tables:
  - `grp.project_data_accessibility`
- Deprecated tables/columns:
  - `grp.paper.data_citation`
  - `grp.paper.creativecommons_license`
  - `grp.paper.use_conditions`
  - `grp.paper.date_received`
  - `grp.project.availability`

### Upload / Code Impacts
- Excel → Input code: Dataset accessibility fields must map to `grp.project_data_accessibility`.
- Input → SQL code: Import scripts must insert accessibility metadata by `projectid`.
- QA/QC impacts: Tests must confirm data accessibility fields are no longer stored in `paper` or `project`.

### SQL Change
```sql
-- See sql/01_schema_changes.sql, sql/02_view_updates.sql,
-- and sql/05_data_dictionary_population.sql for Change 014.
```

### Required View Updates
- [x] Recreate grp.full_paper without dataset accessibility fields.
- [x] Recreate grp.full_project with aggregated dataset accessibility fields.

### Testing Performed
- [x] Confirmed new table exists.
- [x] Confirmed expected columns and constraints.
- [x] Confirmed dropped columns are absent.
- [x] Confirmed both affected views compile.
- [x] Confirmed dictionary updates.

### Actual Outcomes
No unexpected code impacts were identified during testing. The main confirmed impact is that future import and QA/QC code must treat dataset accessibility as project-level metadata stored in `grp.project_data_accessibility`, not as publication metadata in `grp.paper` or core project metadata in `grp.project`.

The addition of `database` to `grp.project_data_accessibility` clarified that project references use the composite project key rather than `projectid` alone. View code was updated accordingly so accessibility records join and aggregate by both `database` and `projectid`.

Tests confirmed that `grp.full_paper` no longer exposes data accessibility fields, while `grp.full_project` exposes aggregated accessibility fields and remains one row per project. Future code should use `grp.project_data_accessibility` directly for detailed access records, or `grp.full_project` for project-level summaries.


### Status
- Implemented
- Tested

---

## Change ID: Change 013
Date: 2026-05-22

### Summary
Added a new `grp.view_dictionary` table to document GRP SQL views intended for direct querying by humans or downstream code.

### Motivation
GRP views are becoming important interface layers for querying, documentation, import checking, and future collaboration. Several views now include denormalization, aggregation, hierarchy interpretation, and grain assumptions. A lightweight view dictionary provides human-readable documentation of each view’s purpose, expected row grain, assumptions, and limitations without attempting full SQL lineage tracking.

### SQL Objects Affected
- Tables:
  - `grp.view_dictionary`
- Views:
  - None changed
- New tables:
  - `grp.view_dictionary`
- Deprecated tables/columns:
  - None

### Upload / Code Impacts
- Excel → Input code:
  - No direct impact expected.
- Input → SQL code:
  - No direct impact expected unless future upload or QA/QC scripts choose to reference `grp.view_dictionary`.
- QA/QC impacts:
  - Adds a new documentation table that can support future QA/QC checks of expected view grain, purpose, and limitations.

### SQL Change
```sql
-- See sql/01_schema_changes.sql
-- See sql/07_view_dictionary_population.sql
```

### Required View Updates
- [ ] None expected.

### Testing Performed
- [ ] Check whether grp.view_dictionary already exists.
- [ ] Check that all documented views currently exist in grp.

### Actual Outcomes
`grp.view_dictionary` was successfully created and populated with documentation entries for all current GRP analytical/query views.

The new table:
- establishes lightweight human-readable documentation for GRP SQL views
- documents intended row grain, assumptions, limitations, and denormalization behavior
- introduces a consistent metadata structure for future analytical/reporting views

No existing views, tables, imports, or upload workflows were modified by this change.

Dependency checks confirmed:
- `grp.view_dictionary` did not previously exist
- all documented views existed prior to population

Import tests confirmed:
- the table structure was created as expected
- all expected columns were present in the intended order
- all expected view documentation rows were successfully inserted

No unexpected impacts or dependency issues were identified.

### Status
- Implemented
- Tested

---

## Change ID: Change 013
Date: 2026-05-22

### Summary
Added metadata fields to controlled lookup tables, renamed the lifespan lookup value column, populated lookup vocabulary tables, and updated the data dictionary to reflect the new and renamed fields.

### Motivation
The lookup tables needed clearer internal documentation so controlled vocabulary values could be interpreted consistently during data entry, upload, QA/QC, and future database maintenance. Adding `definition` and `notes` fields makes the lookup tables more self-documenting. Renaming `lifespan.description` to `type` clarifies that the column stores a lifespan category rather than a prose description.

### SQL Objects Affected
- Tables:
  - `grp.application_method`
  - `grp.bed_material`
  - `grp.bed_prep`
  - `grp.disturbance`
  - `grp.erosion_control`
  - `grp.fertilization`
  - `grp.grazer`
  - `grp.growth_medium`
  - `grp.herbicide`
  - `grp.invasion_control`
  - `grp.lifespan`
  - `grp.pretreatment`
  - `grp.vegmetric`
  - `grp.data_dictionary`
- Views:
  - No view changes expected unless direct dependencies are identified.
- New tables:
  - None.
- Deprecated tables/columns:
  - `grp.lifespan.description` renamed to `grp.lifespan.type`.

### Upload / Code Impacts
- Excel → Input code: Lookup validation and reference materials may need to account for populated lookup tables and their definitions/notes.
- Input → SQL code: Any code referencing `grp.lifespan.description` must be updated to `grp.lifespan.type`.
- QA/QC impacts: QA/QC checks should confirm expected lookup values, new metadata columns, and updated data dictionary records.

### SQL Change
```sql
-- See:
-- sql/01_schema_changes.sql
-- sql/05_data_dictionary_population.sql
-- sql/06_lookup_population.sql
```
### Required View Updates
- [x] None expected unless dependency checks identify direct lookup table references in existing views.

### Testing Performed
- [x] Dependency checks run to identify whether targeted lookup tables are referenced in existing views.
- [x] Dependency checks run to review current lookup table structure and contents prior to change.

### Actual Outcomes

Dependency checks were completed before implementation and did not identify any blockers. Phase 13 code was drafted across `sql/01_schema_changes.sql`, `sql/01b_lookup_population.sql`, and `sql/05_data_dictionary_population.sql`. The change remains focused on lookup table cleanup, controlled vocabulary population, and data dictionary updates.

### Status
- Implemented
- Tested

---

## Change ID: 010
Date: 2026-05-20

### Summary
Populated `grp.data_dictionary` with table and column metadata for the finalized GRP schema and updated `grp.data_dictionary.dictionaryid` to auto-generate values.

### Motivation
Phase 12 documents the database structure before processing code is rewritten. The database needed internal metadata describing table/column meanings, workflow notes, legacy assumptions, QA/QC expectations, and external-source notes. During population, `dictionaryid` was found not to auto-generate, so the column was updated to support ongoing metadata entry.

### SQL Objects Affected
- Tables:
  - `grp.data_dictionary`
- Views:
  - None
- New tables:
  - None
- Deprecated tables/columns:
  - None

### Upload / Code Impacts
- Excel → Input code:
  - Future import code should use `grp.data_dictionary` as a reference for expected field meanings, legacy mappings, QA/QC expectations, and controlled vocabulary handling.
- Input → SQL code:
  - Code that inserts into `grp.data_dictionary` no longer needs to supply `dictionaryid`.
  - Processing-code rewrites should align with documented table/column definitions.
- QA/QC impacts:
  - QA/QC scripts can use `grp.data_dictionary` to check nullable status, expected values, lookup-table relationships, external-source assumptions, and legacy field mappings.

### SQL Change
```
-- Data dictionary population completed in:
-- sql/05_data_dictionary_population.sql
See 05_data_dictionary_population
```
### Required View Updates
- [x] None required.

### Testing Performed
- [x] Confirmed dictionaryid identity status.
- [x] Inserted data dictionary rows without manually supplying dictionaryid.
- [x] Checked representative inserted rows in grp.data_dictionary.
- [x] Confirmed table-by-table metadata entries were accepted by existing constraints.

### Actual Outcomes

grp.data_dictionary.dictionaryid now auto-generates values. Metadata rows were added for base tables, lookup tables, join tables, treatment tables, vegetation results, and the data dictionary itself. Views were not modified. Several future cleanup items were identified but intentionally deferred, including lookup-table standardization, possible dataset/source-access restructuring separate from paper, and selected vocabulary/documentation refinements.

### Status
- Implemented

---

## Change ID: Change 009
Date: 2026-05-19

### Summary
Simplify species trait storage by retaining only core maintained species traits and removing low-priority trait fields from `grp.species`. This change retains `lifeform` and lifespan information while dropping `seed_mass`, `path`, `raunkiaer`, `woodiness`, and `nfixer`. It also adds an explicit unknown species row using `speciesid = 1`.

### Motivation
Several species trait fields created long-term maintenance obligations without being central to the intended GRP analyses. `seed_mass` was based on a past snapshot of an external database and would require ongoing provenance/version tracking to remain reliable. `path`, `woodiness`, and `nfixer` are externally retrievable or partially redundant with other fields. `raunkiaer` is ecologically meaningful but required curated derivation decisions and is not currently central enough to justify continued maintenance.

The retained fields are those most likely to support practical filtering and interpretation: `lifeform` in `grp.species` and lifespan values through `grp.species_lifespan`.

### SQL Objects Affected
- Tables:
  - `grp.species`
  - `grp.species_lifespan`
- Views:
  - `grp.full_species`
- New tables:
  - None
- Deprecated tables/columns:
  - `grp.species.seed_mass`
  - `grp.species.path`
  - `grp.species.raunkiaer`
  - `grp.species.woodiness`
  - `grp.species.nfixer`

### Upload / Code Impacts
- Excel → Input code: Species import code must stop expecting or importing the dropped trait fields. Unknown or unresolved species should be mapped to `speciesid = 1` where appropriate.
- Input → SQL code: Species upload scripts must insert only the retained fields and continue using `speciesid` as the relational identifier.
- QA/QC impacts: QA/QC scripts that reference the dropped trait columns must be removed or revised. Tests should confirm the unknown species row exists, the dropped columns are absent, and `grp.full_species` compiles after being recreated.

### SQL Change
```sql
-- Drop full_species view
DROP VIEW IF EXISTS grp.full_species;

-- Drop low-priority trait columns from grp.species.
-- Target dropped columns: seed_mass, path, raunkiaer, woodiness, nfixer.
ALTER TABLE grp.species
  DROP COLUMN seed_mass,
  DROP COLUMN path,
  DROP COLUMN raunkiaer,
  DROP COLUMN woodiness,
  DROP COLUMN nfixer;

-- Insert unknown species row.
INSERT INTO grp.species (
  speciesid,
  "group",
  "order",
  family,
  genus,
  species,
  subtype,
  subtype_name,
  lifeform,
  species_code
)
VALUES
(1, 'unknown', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 'Unk_spp');
```

### Required View Updates
- [x] Recreate grp.full_species without seed_mass, path, raunkiaer, woodiness, or nfixer.

###Testing Performed
- [x] Confirmed dropped trait columns are no longer present in grp.species.
- [x] Confirmed speciesid = 1 exists in grp.species as the unknown species row.
- [x] Confirmed grp.full_species compiles and returns expected retained columns.
- [x] Confirmed existing foreign key dependencies on grp.species.speciesid remain intact.

### Actual Outcomes
Implemented successfully. The low-priority trait columns `seed_mass`, `path`, `raunkiaer`, `woodiness`, and `nfixer` were removed from `grp.species`. The retained species trait structure now focuses on `lifeform` in `grp.species` and lifespan information through `grp.species_lifespan`.

The `grp.full_species` view was recreated successfully without the dropped trait columns. The view now returns species taxonomy, aggregated lifespan, and `lifeform`.

An unknown species row was added using `speciesid = 1` and `species_code = 'Unk_spp'`. This provides a stable placeholder for unresolved or unknown species during future imports.

No lifespan row was added for the unknown species record. This is acceptable because `grp.full_species` uses a left join from `grp.species` to `grp.species_lifespan`.

### Status
- Tested

---

## Change ID:
Change 008

Date: 2026-05-19

### Summary
Remove stale and externally derived environmental covariate columns from `grp.site` and recreate `grp.full_site` accordingly.

### Motivation
GRP is shifting away from maintaining a large internal repository of externally derived environmental covariates. Most removed variables can be independently downloaded or regenerated from external spatial datasets. The goal is to retain only a small set of interpretable and broadly useful site descriptors while reducing long-term maintenance burden and versioning complexity.

### SQL Objects Affected
- Tables:
  - `grp.site`
- Views:
  - `grp.full_site`
- New tables:
  - None
- Deprecated tables/columns:
  - `landcover`
  - `growing_season_start`
  - `growing_season_end`
  - `elevation`
  - `slope`
  - `aspect`
  - `annual_precip_contributor`
  - `annual_temp_contributor`
  - `mean_diurnal_range`
  - `isothermality`
  - `temp_seasonality`
  - `max_temp_warmest_month`
  - `max_temp_coldest_month`
  - `temp_range`
  - `mean_temp_wettest_quarter`
  - `mean_temp_driest_quarter`
  - `mean_temp_warmest_quarter`
  - `mean_temp_coldest_quarter`
  - `wettest_month_precip`
  - `driest_month_precip`
  - `precip_seasonality`
  - `wettest_quarter_precip`
  - `driest_quarter_precip`
  - `warmest_quarter_precip`
  - `coldest_quarter_precip`

### Upload / Code Impacts
- Excel → Input code:
  - Future upload templates should remove deprecated environmental covariate fields.
- Input → SQL code:
  - Any import code referencing removed `grp.site` columns must be updated.
- QA/QC impacts:
  - QA scripts checking removed environmental variables will require updates.

### SQL Change
```sql
-- Drop dependent view
DROP VIEW IF EXISTS grp.full_site;

-- Alter existing site table by dropping unwanted columns
ALTER TABLE grp.site
  DROP COLUMN landcover,
  DROP COLUMN growing_season_start,
  DROP COLUMN growing_season_end,
  DROP COLUMN elevation,
  DROP COLUMN slope,
  DROP COLUMN aspect,
  DROP COLUMN annual_precip_contributor,
  DROP COLUMN annual_temp_contributor,
  DROP COLUMN mean_diurnal_range,
  DROP COLUMN isothermality,
  DROP COLUMN temp_seasonality,
  DROP COLUMN max_temp_warmest_month,
  DROP COLUMN max_temp_coldest_month,
  DROP COLUMN temp_range,
  DROP COLUMN mean_temp_wettest_quarter,
  DROP COLUMN mean_temp_driest_quarter,
  DROP COLUMN mean_temp_warmest_quarter,
  DROP COLUMN mean_temp_coldest_quarter,
  DROP COLUMN wettest_month_precip,
  DROP COLUMN driest_month_precip,
  DROP COLUMN precip_seasonality,
  DROP COLUMN wettest_quarter_precip,
  DROP COLUMN driest_quarter_precip,
  DROP COLUMN warmest_quarter_precip,
  DROP COLUMN coldest_quarter_precip;
```

### Required View Updates
- [x] Recreate grp.full_site without removed grp.site columns

### Testing Performed
- [x] Confirm `grp.full_site` dependency identified before schema change
- [x] Confirm removed columns no longer exist in `grp.site`
- [x] Confirm retained columns still exist in `grp.site`
- [x] Confirm `grp.full_site` recreates successfully
- [x] Confirm `grp.full_site` includes expected retained fields

### Actual Outcomes
- All targeted environmental covariate columns were successfully removed from grp.site.
- grp.full_site was successfully recreated using the updated schema.
- No additional dependent views were identified.
- Retained site identifiers and summary climate variables remained intact.
- Soil, classification, disturbance, reference ecosystem, and invasive metadata remained available through linked tables and joins in grp.full_site.

### Status
- Implemented
- Tested

---

## Change ID: Change 008
Date: 2026-05-18

### Summary
Refine treatment structure by adding detail tables for mowing and cover crops, adding a notes column to grazing treatments, and removing the former `maintenance_mowing` boolean from the main treatment table.

### Motivation
Mowing and cover crops require more structured detail than can be represented by a simple treatment-level flag or notes field. Mowing may include height class, numeric height, units, and notes. Cover crops may include species identity and seeding rate. Grazing requires a notes field to store details such as animal type where available.

This change keeps treatment structure analytical without overbuilding specialized fields for rare treatment details.

### SQL Objects Affected
- Tables:
  - `grp.treatment`
  - `grp.treatment_grazer`
- Views:
  - `grp.full_treatment`
  - `grp.treatments_by_area`
- New tables:
  - `grp.treatment_mowing`
  - `grp.treatment_cover_crop`
- Deprecated tables/columns:
  - `grp.treatment.maintenance_mowing`

### Upload / Code Impacts
- Excel → Input code: Mowing and cover crop data will need to be routed into their respective detail tables.
- Input → SQL code: Import code must stop using `grp.treatment.maintenance_mowing`.
- QA/QC impacts: Tests should confirm table creation, FK structure, removal of `maintenance_mowing`, and successful view recompilation.

### SQL Change
```sql
-- Create mowing table
CREATE TABLE grp.treatment_mowing (
  mowingid integer GENERATED ALWAYS AS IDENTITY, 
  treatmentid integer NOT NULL,
  mowing_type text NOT NULL,
  height_class text,
  amount numeric,
  units text,
  notes text,
  
  CONSTRAINT mowing_pkey PRIMARY KEY (mowingid),
  CONSTRAINT fk_mowing_treatment_trtid 
    FOREIGN KEY (treatmentid)
    REFERENCES grp.treatment(treatmentid)
);

-- Create cover crop table
CREATE TABLE grp.treatment_cover_crop (
  covercropid integer GENERATED ALWAYS AS IDENTITY,
  treatmentid integer NOT NULL,
  speciesid integer NOT NULL,
  amount numeric,
  units text,
  notes text,
  
  CONSTRAINT cover_crop_pk PRIMARY KEY (covercropid),
  CONSTRAINT fk_cover_crop_treatment_trtid
    FOREIGN KEY (treatmentid)
    REFERENCES grp.treatment(treatmentid),
  CONSTRAINT fk_cover_crop_species_speciesid
    FOREIGN KEY (speciesid)
    REFERENCES grp.species(speciesid)
);

-- Add notes column to grazing table
ALTER TABLE grp.treatment_grazer
  ADD COLUMN notes text;
  
-- Drop maintenance_mowing from treatment
ALTER TABLE grp.treatment
  DROP COLUMN maintenance_mowing;
```

### Required View Updates
- [x] Update grp.full_treatment
- [x] Update grp.treatments_by_area

### Testing Performed
- [x] Dependency check confirmed speciesid datatype.
- [x] Dependency check confirmed grp.treatment_grazer.notes does not already exist.
- [x] Dependency check confirmed maintenance_mowing appears only in expected treatment views.
- [x] Confirmed structure of grp.treatment_mowing
- [x] Confirmed structure of grp.treatment_cover_crop
- [x] Confirmed removal of maintenance_mowing
- [x] Confirmed successful recompilation of treatment reporting views

### Actual Outcomes
All schema changes and view updates executed successfully.

The database now stores mowing as structured treatment detail data rather than a boolean field.

Cover crop treatments are now represented separately from restoration target seeding and require species linkage through speciesid.

A controlled placeholder species record will be required in grp.species before future cover crop imports begin.

No unexpected dependency or recompilation issues occurred during implementation or testing.

### Status
- Tested

---

## Change ID: 006

Date: 2026-05-17

### Summary
Normalize the GRP paper/publication structure by replacing the current project-specific paper table design with a global paper table and separate linking tables for project-paper and paper-author relationships.

### Motivation
The existing structure stores paper records using a composite identity of `database + projectid + paperid`, meaning `paperid` is project-specific rather than globally unique. This limits the database’s ability to represent many-to-many relationships between projects and publications. A normalized structure is needed so that one paper can be linked to multiple projects, and one project can be linked to multiple papers.

### SQL Objects Affected
- Tables:
  - `grp.paper`
  - `grp.paper_author`

- Views:
  - `grp.full_paper`

- New tables:
  - `grp.paper`
  - `grp.project_paper`
  - `grp.paper_author`

- Deprecated tables/columns:
  - Old `grp.paper` structure with `database`, `projectid`, and project-specific `paperid`
  - Old `grp.paper_author` structure with `database`, `projectid`, and project-specific `paperid`

### Upload / Code Impacts
- Excel → Input code:
  - Existing paper/publication input structure may need to be staged before loading.
  - Paper IDs should no longer be supplied as project-specific IDs from Excel.

- Input → SQL code:
  - Paper metadata must be inserted into `grp.paper`.
  - Project-paper links must be inserted into `grp.project_paper`.
  - Paper-author links must be inserted into `grp.paper_author`.

- QA/QC impacts:
  - Tests should confirm unique paper records, valid project-paper links, valid paper-author links, and correct DOI handling.

### SQL Change
```sql
-- See sql/01_schema_changes.sql for planned schema changes.
```

### Required View Updates
Rebuild grp.full_paper to use normalized paper structure.
Confirm grp.full_paper preserves needed flattened output fields.

### Testing Performed
- [x] Ran dependency checks for existing paper-related objects.
- [x] Confirmed current paper structure.
- [x] Confirmed current paper_author structure.
- [x] Confirmed current constraints on paper and paper_author.
- [x] Confirmed only grp.full_paper directly depends on paper-related tables.
- [x] Confirmed grp.author_contributor is also used by grp.project_contributor and grp.full_project.
- [x] Confirmed grp.project uses composite key database + projectid.
- [x] Run planned schema change in pgAdmin.
- [x] Confirm new tables and constraints.
- [x] Rebuild and test grp.full_paper.
- [x] Run paper import tests.

### Actual Outcomes
Implemented successfully. The old `grp.full_paper` view was dropped, the old `grp.paper` and `grp.paper_author` tables were rebuilt into a normalized structure, and the new `grp.project_paper` linking table was added.

The rebuilt structure now uses:
- `grp.paper` for global publication records
- `grp.project_paper` for project-publication links
- `grp.paper_author` for publication-author links

`grp.full_paper` was recreated successfully from the normalized tables. The view compiled and its structure was checked.

### Status
- Implemented
- Tested

---

## Change ID: 005
Phase 5 — Separate topsoil age and growth medium depth

Date:
2026-05-17

### Summary
Added structured fields for growth medium depth and units to `grp.treatment_medium` and updated `grp.full_treatment` to expose them.

### Motivation
The schema previously stored `top_soil_age` as a structured numeric field but had no equivalent structure for growth medium depth/thickness measurements. This created a risk that depth values would be inconsistently stored in notes or omitted entirely.

The update separates:
- topsoil age (a material-specific temporal property)
from
- growth medium depth (a generalized dimensional property)

This improves queryability and semantic clarity.

### SQL Objects Affected
- Tables:
  - `grp.treatment_medium`
- Views:
  - `grp.full_treatment`
- New tables:
  - None
- Deprecated tables/columns:
  - None

### Upload / Code Impacts
- Excel → Input code:
  - Treatment medium templates may require new depth and depth-units columns.
- Input → SQL code:
  - Import scripts may require updates to insert the new fields.
- QA/QC impacts:
  - Future validation may need to confirm value/unit pairing consistency.

### SQL Change
```sql
ALTER TABLE grp.treatment_medium
    ADD COLUMN growth_medium_depth numeric,
    ADD COLUMN growth_medium_depth_units text;

see 02_view_updates for updates to grp.full_treatment and grp.treatments_by_area
```

### Actual Outcomes
#### Additional Dependencies Identified During Implementation
Initial dependency checks identified `grp.full_treatment` as dependent on `grp.treatment_medium`. During implementation, an additional downstream dependency was identified:
- `grp.treatments_by_area` depends on `grp.full_treatment`

This required ordered view recreation rather than isolated replacement of `grp.full_treatment`.

#### Final SQL Objects Affected
- Tables:
  - `grp.treatment_medium`
- Views:
  - `grp.full_treatment`
  - `grp.treatments_by_area`

### Final Testing Performed
- [x] ALTER TABLE executed successfully
- [x] Dependent views dropped successfully
- [x] `grp.full_treatment` recreated successfully
- [x] `grp.treatments_by_area` recreated successfully
- [x] New columns visible in `information_schema.columns`
- [x] New fields accessible from `grp.full_treatment`
- [x] New fields accessible from `grp.treatments_by_area`

### Final Status
- Implemented
- Tested

---

# Change 004 — Add data dictionary infrastructure
Date: 2026-05-17

### Summary
Create an in-database data dictionary table for storing column-level metadata, workflow guidance, allowed values, QA/QC notes, legacy notes, and external-source notes.

### Motivation
The database needs human-readable metadata that explains not only technical structure, but also ecological meaning and workflow interpretation. This pilot data dictionary begins with the stable import tracking tables.

### SQL Objects Affected
- Tables:
  - none modified

- Views:
  - none expected

- New tables:
  - `grp.data_dictionary`

- Deprecated tables/columns:
  - none

### Upload / Code Impacts
- Excel → Input code:
  - no immediate impact

- Input → SQL code:
  - no immediate impact

- QA/QC impacts:
  - future QA can compare `grp.data_dictionary` against `information_schema.columns` to find undocumented or stale fields

### SQL Change

```sql
-- see sql/01_schema_changes.sql Change 004
```

### Required View Updates
- [x] No view updates expected

### Testing Performed
- [x] Dependency checks completed
- [x] Schema change executed
- [x] Metadata rows inserted
- [x] Post-change structure validated

### Actual Outcome
Created new metadata infrastructure table:
- `grp.data_dictionary`

The table stores:
- technical schema metadata
- workflow guidance
- allowed values
- examples
- legacy notes
- QA/QC notes
- external source notes

The following constraints were successfully implemented:
- primary key on `dictionaryid`
- unique constraint on `(table_name, column_name)`
- CHECK constraint limiting `is_nullable` to `YES` or `NO`

Initial metadata population inserted 24 rows documenting:
- `grp.import_batch`
- `grp.import_object_map`

Stored metadata now includes:
- data types
- nullability
- workflow guidance
- provenance interpretation guidance
- mapping interpretation guidance
- examples and QA/QC expectations

No existing ecological backbone tables or views were modified.

### Status
- Implemented
- Tested

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

### Required View Updates
- [x] No view updates expected

### Testing Performed
- [x] Checked proposed table names do not already exist
- [x] Checked referenced grp.project fields
- [x] Checked existing grp.project database constraints
- [x] Schema changes executed
- [x] Post-change structure validated

### Actual Outcome
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

### Status
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

### Required View Updates
 - [x] Inspect full_seeding
 - [x] Inspect downstream impacts, if any

### Testing Performed
- [x] Seed-related structure inspection completed
- [x] Seed/mix column search completed
- [x] Seed/mix view definition search completed
- [x] Foreign key relationship inspection involving grp.seeding completed
- [x] Schema changes executed
- [x] View updates completed
- [x] Post-change structure validated

### Actual Outcome
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

### Status
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

### Required View Updates
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

## Status
- Implemented
- Tested
