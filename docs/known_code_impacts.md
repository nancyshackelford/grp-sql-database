# Known Code Impacts

Tracks known dependencies between:
- Excel → Input processing code
- Input → SQL upload code
- SQL schema structure
- SQL views

---

## Change ID: Change 013

### SQL Change
Tidy and populate controlled lookup tables by adding `definition` and `notes` columns, renaming `grp.lifespan.description` to `type`, populating lookup values, and adding corresponding data dictionary entries.

### Likely Affected Code
- Excel → Input: May need updates where lookup table definitions or notes are referenced, displayed, or validated.
- Input → SQL: May need updates if lifespan values currently map to `description` rather than `type`.
- SQL views: No direct view changes expected unless dependency checks identify direct references to modified lookup table structures.
- QA/QC scripts: May need updates to include `definition`, `notes`, and `lifespan.type` in lookup/data dictionary checks.

### Dependency Notes
This change assumes lookup tables can store controlled vocabulary metadata directly through nullable `definition` and `notes` fields. It also assumes `lifespan.description` is better represented as `lifespan.type`, because the field stores the controlled lookup value rather than explanatory prose. Lookup table population and data dictionary population are now separated into dedicated SQL files for readability and future maintenance.

### Required Testing
- [x] Confirm `definition` and `notes` columns exist in all targeted lookup tables.
- [x] Confirm `grp.lifespan.description` has been renamed to `type`.
- [X] Confirm lookup tables were populated with expected controlled vocabulary values.
- [x] Confirm data dictionary entries were added or updated for the new/renamed fields.

### Actual Outcomes

Dependency checks found no issues requiring view updates before implementation. Lookup table structure and contents were reviewed before the change. The planned code was separated into dedicated files for schema changes, lookup table population, and data dictionary population, improving maintainability without changing the conceptual scope of Change 012.

### Status
- Implemented
- Tested

---

## Known code impacts
## Change ID: 010

### SQL Change
Populated `grp.data_dictionary` with metadata for GRP schema tables and changed `dictionaryid` to auto-generate values.

### Likely Affected Code
- Excel → Input:
  - Future mapping from Excel-era fields to SQL fields should reference `legacy_notes` and `workflow_notes`.
- Input → SQL:
  - Inserts into `grp.data_dictionary` should omit `dictionaryid`.
  - Processing-code rewrites should use documented target fields rather than older Excel naming conventions.
- SQL views:
  - No immediate view changes.
- QA/QC scripts:
  - QA/QC scripts can be expanded to compare schema columns against `grp.data_dictionary`.
  - Scripts can use `allowed_values`, `qa_qc_notes`, and lookup-table notes to guide validation.

### Dependency Notes
The workflow now assumes:
- `grp.data_dictionary.dictionaryid` auto-generates.
- `table_name` + `column_name` uniquely identifies each documented field.
- Lookup-table vocabularies are generally maintained in lookup tables rather than duplicated in `allowed_values`.
- `allowed_values` is mainly used where SQL CHECK constraints or stable value sets are important.
- `legacy_notes` preserves Excel-era field mappings.
- `external_source_notes` records dependencies such as CHELSA, World Plant List, TRY, USDA, or other external data sources.

### Required Testing
- [x] Confirm `dictionaryid` auto-generates.
- [x] Confirm inserted metadata rows appear correctly.
- [x] Confirm no view updates are required.
- [x] Confirm future inserts can omit `dictionaryid`.

### Actual Outcomes
The metadata population was completed successfully. The data dictionary now documents the core schema, including table meanings, field definitions, workflow assumptions, lookup-table relationships, legacy Excel mappings, QA/QC expectations, and external-source dependencies. No processing code was changed during this phase, but the populated dictionary establishes the documented SQL target for future code rewrites.

### Status
- Implemented

---

# Known Code Impacts

## Change ID:
Change 010

### SQL Change
Expand the `grp.project.database` CHECK constraint to allow `'OM'` as a valid database value.

### Likely Affected Code
- Excel → Input:
  - Oak Meadow project records can now use `'OM'` as the database identifier.
- Input → SQL:
  - Import workflows inserting into `grp.project` must recognize `'OM'` as a valid database value.
- SQL views:
  - No expected impacts.
- QA/QC scripts:
  - Validation scripts checking allowed database values should include `'OM'`.

### Dependency Notes
- `grp.project.database` currently restricts values using the `database_check` CHECK constraint.
- `grp.import_batch` and `grp.import_object_map` already allow `'OM'`.
- No additional CHECK constraints were identified on other `grp` tables containing a `database` column.
- No structural schema changes are being made.

### Required Testing
- [x] Confirm `database_check` allows `'OM'`
- [x] Confirm existing values (`'GRP'`, `'GAZP'`) remain valid
- [x] Confirm `grp.full_project` still compiles

### Actual Outcomes
The `grp.project.database` CHECK constraint now accepts `'OM'` as a valid database value.

Post-change checks confirmed that no additional `grp` tables with a `database` column contain conflicting CHECK constraints restricting `'OM'`.

No impacts to existing SQL views were identified. `grp.full_project` compiled and queried successfully after the constraint update.

No additional upload or QA/QC code changes were required at this stage.

### Status
- Implemented
- Tested
---

## Change ID: Change 009

### SQL Change
Simplify species trait storage by dropping low-priority trait columns from `grp.species`: `seed_mass`, `path`, `raunkiaer`, `woodiness`, and `nfixer`. Retain `lifeform` in `grp.species` and retain lifespan information through `grp.species_lifespan`. Add an explicit unknown species row using `speciesid = 1`.

### Likely Affected Code
- Excel → Input: Species import code must stop expecting or importing `seed_mass`, `path`, `raunkiaer`, `woodiness`, and `nfixer`. Unknown or unresolved species should be mapped to `speciesid = 1` where appropriate.
- Input → SQL: Any species upload scripts must insert only the retained species fields and must continue to support `speciesid` as the relational identifier.
- SQL views: `grp.full_species` must be recreated without the dropped trait columns.
- QA/QC scripts: Any checks that reference the dropped trait columns must be removed or revised.

### Dependency Notes
Subspecies and varieties will continue to receive unique `speciesid` values rather than being collapsed into the parent species. Higher-level analyses that need to group a parent species with its subtypes should use shared taxonomic fields such as `genus` and `species`. A future schema enhancement may add a `parent_speciesid` field or taxonomic rollup view to support this more explicitly.

The `grp.full_species` view currently depends on the dropped trait columns and must be recreated. The `grp.species_lifespan` table does not require every `speciesid` to have a matching lifespan row because `grp.full_species` uses a left join.

### Required Testing
- [x] Confirm dropped trait columns are no longer present in `grp.species`.
- [x] Confirm `speciesid = 1` exists in `grp.species` as the unknown species row.
- [x] Confirm `grp.full_species` compiles and returns expected retained columns.
- [x] Confirm existing foreign key dependencies on `grp.species.speciesid` remain intact.

### Actual Outcomes
The species trait simplification was implemented. The low-priority trait columns `seed_mass`, `path`, `raunkiaer`, `woodiness`, and `nfixer` were dropped from `grp.species`. The `grp.full_species` view was recreated without those fields and now retains species taxonomy, aggregated lifespan, and `lifeform`.

An explicit unknown species row was added using `speciesid = 1` and `species_code = 'Unk_spp'`. The initial insert was reviewed and corrected to ensure the unknown row represents unknown species information cleanly.

No change was made to the structure of `grp.species_lifespan`. Because `grp.full_species` uses a left join, the unknown species row does not require a corresponding lifespan row.

Subspecies and varieties remain represented as distinct `speciesid` values. A future enhancement may add `parent_speciesid` or a taxonomic rollup view to support querying a parent species together with all associated subtypes.

### Status
- Tested

---

## Change ID:
Change 008

### SQL Change
Removed stale and externally derived environmental covariate columns from `grp.site`.

### Likely Affected Code
- Excel → Input:
  - Future site upload templates should no longer include removed environmental covariate fields.
- Input → SQL:
  - Any import scripts mapping removed `grp.site` columns will require updates.
- SQL views:
  - `grp.full_site`
- QA/QC scripts:
  - Any QA scripts checking removed environmental variables will require updates.

### Dependency Notes
- `grp.full_site` depended on `grp.site`.
- Existing `grp.full_site` definition selected columns removed from `grp.site`.
- Core site identifiers and retained climate variables remained unchanged.
- Reference ecosystem, classification, soil, disturbance, and invasive metadata are stored in separate linked tables and were unaffected by this change.

### Required Testing
- [x] Confirm removed columns no longer exist in `grp.site`
- [x] Confirm `grp.full_site` recreates successfully
- [x] Confirm retained columns still appear correctly in `grp.full_site`

### Actual Outcomes
- All targeted environmental covariate columns were successfully removed from `grp.site`.
- Retained columns (`siteid`, `name`, `latitude`, `longitude`, `aridity`, `annual_temp`, `annual_precip`) remained intact.
- `grp.full_site` was successfully recreated without references to removed columns.
- View compiled successfully and retained expected linked metadata fields.

### Status
- Fixed
- Tested

---

## Change ID: Change 007

### SQL Change
Added structured treatment detail tables for mowing and cover crops, added notes to grazing treatments, and removed `maintenance_mowing` from `grp.treatment`.

### Likely Affected Code
- Excel → Input:
  - Mowing data must now import into `grp.treatment_mowing`
  - Cover crop data must now import into `grp.treatment_cover_crop`
  - Grazing detail notes can now import into `grp.treatment_grazer.notes`
- Input → SQL:
  - Import scripts must no longer write to `grp.treatment.maintenance_mowing`
  - Cover crop imports now require valid `speciesid`
- SQL views:
  - `grp.full_treatment`
  - `grp.treatments_by_area`
- QA/QC scripts:
  - Any checks expecting mowing as a boolean field in `grp.treatment`
  - Any checks assuming cover crops are absent from treatment structure

### Dependency Notes
Mowing is now stored in a structured detail table linked by `treatmentid`, consistent with irrigation, fertilization, herbicide, and growth medium treatments.

`grp.treatment_cover_crop.speciesid` is now required (`NOT NULL`). The `grp.species` table must contain a controlled placeholder species record representing unknown species identity (planned as `speciesid = 1`) before cover crop data imports begin.

Existing code may assume mowing is stored directly in `grp.treatment` as `maintenance_mowing`.

### Required Testing
- [x] Confirm `grp.treatment_mowing` structure
- [x] Confirm `grp.treatment_cover_crop` structure
- [x] Confirm `maintenance_mowing` was removed from `grp.treatment`
- [x] Confirm `notes` was added to `grp.treatment_grazer`
- [x] Confirm `grp.full_treatment` compiles and includes new treatment fields
- [x] Confirm `grp.treatments_by_area` compiles and includes new treatment fields

### Actual Outcomes
All schema changes executed successfully.

`maintenance_mowing` was successfully removed from `grp.treatment` and replaced with the structured `grp.treatment_mowing` table.

`grp.treatment_cover_crop` was created with required `speciesid` linkage to `grp.species`.

`grp.full_treatment` and `grp.treatments_by_area` were successfully rebuilt and now expose mowing and cover crop detail fields.

No unexpected dependency failures or import test issues were observed.

### Status
- Tested

---

# Known Code Impacts

## Change ID: 006

### SQL Change Short description.
Normalize the paper/publication structure by replacing project-specific paper records with a global `paper` table, a `project_paper` linking table, and a simplified `paper_author` linking table.

### Likely Affected Code
– Excel → Input:
- Paper/publication inputs will need to stop assuming `paperid` is project-specific.
- Paper import workflow will need to handle SQL-generated global `paperid` values.
- Existing flattened paper sheets may need staging/import logic before loading into normalized tables.

- Input → SQL:
- Existing import code that inserts directly into `grp.paper` will need to be updated.
- Project-paper relationships will need to be inserted into `grp.project_paper`.
- Paper-author relationships will need to be inserted into the rebuilt `grp.paper_author`.

- SQL views:
- `grp.full_paper` must be rebuilt from the new normalized structure.
- No other paper-related views were identified in dependency checks.

- QA/QC scripts:
- QA/QC should be updated to check paper uniqueness, project-paper links, author-paper links, and DOI handling after import.

### Dependency Notes
Current SQL structure assumes:
- `paperid` is only unique within `database + projectid`.
- `grp.paper` stores project-specific paper records.
- `grp.paper_author` links authors using `database + projectid + paperid`.
- `grp.full_paper` joins paper and author information using the old composite project-paper identity.
- `grp.author_contributor` is shared with `grp.project_contributor` and `grp.full_project` and should not be changed in this phase.
- `grp.project` uses a composite primary key: `database + projectid`.

### Required Testing
- [x] Confirm existing paper-related objects.
- [x] Confirm existing `grp.paper` structure.
- [x] Confirm existing `grp.paper_author` structure.
- [x] Confirm existing constraints on `grp.paper` and `grp.paper_author`.
- [x] Confirm dependencies involving `grp.paper`, `grp.paper_author`, and `grp.full_paper`.
- [x] Confirm dependencies involving `grp.author_contributor`.
- [x] Confirm `grp.project` primary key structure.
- [x] Confirm new `grp.paper` table exists with global identity `paperid`.
- [x] Confirm new `grp.project_paper` table exists with correct primary key and foreign keys.
- [x] Confirm new `grp.paper_author` table exists with correct primary key and foreign keys.
- [x] Confirm rebuilt `grp.full_paper` returns expected flattened output.
- [x] Confirm import tests can load paper records, project-paper links, and paper-author links.

### Actual Outcomes
Implemented. The old project-specific paper structure was replaced with a normalized paper/publication structure:
- `grp.paper`
- `grp.project_paper`
- `grp.paper_author`

`grp.full_paper` was recreated successfully and compiled using the new normalized tables. Structure checks confirmed the expected rebuilt view.

### Status
- Fixed
- Tested

---

## Change 005 — Separate topsoil age and growth medium depth
Date: 2026-05-18

### SQL Change
Added structured depth fields to `grp.treatment_medium`:
- `growth_medium_depth`
- `growth_medium_depth_units`

Updated `grp.full_treatment` view to expose the new fields.

### Likely Affected Code
- Excel → Input:
  - Treatment medium import sheets/templates may require new columns for depth and depth units.
- Input → SQL:
  - Import scripts inserting into `grp.treatment_medium` may require updates to map the new fields.
- SQL views:
  - `grp.full_treatment`
- QA/QC scripts:
  - Future validation scripts may need to check for paired value/unit consistency.

### Dependency Notes
- Existing workflows assume growth medium depth is either absent or stored in notes.
- `grp.full_treatment` aggregates treatment medium fields using `string_agg()`.
- Numeric fields in the view currently require explicit casting before aggregation.
- `top_soil_age` remains conceptually distinct from growth medium depth.

### Newly Identified Dependencies
- `grp.treatments_by_area` depends on `grp.full_treatment`
- Recreating `grp.full_treatment` therefore required ordered view recreation:
  1. drop `grp.treatments_by_area`
  2. drop `grp.full_treatment`
  3. recreate `grp.full_treatment`
  4. recreate `grp.treatments_by_area`

### Actual Outcomes
- Added:
  - `growth_medium_depth numeric`
  - `growth_medium_depth_units text`
  to `grp.treatment_medium`
- Updated `grp.full_treatment` to expose both new fields.
- Updated `grp.treatments_by_area` to expose both new fields.
- Existing view functionality remained intact after recreation.

### Testing Performed
- [x] ALTER TABLE executed successfully
- [x] `grp.full_treatment` view dropped successfully
- [x] `grp.treatments_by_area` view dropped successfully
- [x] `grp.full_treatment` recreated successfully
- [x] `grp.treatments_by_area` recreated successfully
- [x] New columns visible in `information_schema.columns`
- [x] New fields query successfully from `grp.full_treatment`
- [x] New fields query successfully from `grp.treatments_by_area`
- [x] Existing `full_treatment` fields remain accessible

### Status
- Implemented
- Tested

---

# Change 004 — Add data dictionary infrastructure
Date: 2026-05-17

### Dependency Notes
Change 004 adds an administrative metadata table and does not modify ecological backbone tables.

The first populated metadata records document:
- `grp.import_batch`
- `grp.import_object_map`

The data dictionary stores both technical and human-facing metadata, including:
- data type
- nullability
- definitions
- workflow notes
- allowed values
- examples
- legacy notes
- QA/QC notes
- external source notes

### Expected Code Impacts
- No immediate upload-code impact.
- Future R tools may query `grp.data_dictionary` to generate user-facing metadata.
- Future QA/QC scripts may compare `grp.data_dictionary` with `information_schema.columns`.

### Expected Structural Changes
- Create `grp.data_dictionary`
- Populate initial metadata for import tracking tables
- Enforce uniqueness of `table_name` + `column_name`
- Constrain `is_nullable` to `YES` or `NO`

### Required Testing
- [x] Confirm `grp.data_dictionary` table exists
- [x] Confirm primary key exists on `dictionaryid`
- [x] Confirm unique constraint exists on `table_name` + `column_name`
- [x] Confirm `is_nullable` CHECK constraint exists
- [x] Confirm metadata rows inserted for `grp.import_batch`
- [x] Confirm metadata rows inserted for `grp.import_object_map`
- [x] Confirm expected row count is 24
- [ ] Later: compare data dictionary entries against `information_schema.columns`

### Actual Outcome
`grp.data_dictionary` was successfully added as an in-database metadata and workflow documentation system.

Initial implementation documents:
- `grp.import_batch`
- `grp.import_object_map`

The metadata system now stores:
- column definitions
- technical data types
- nullability
- workflow interpretation guidance
- allowed values
- examples
- legacy notes
- QA/QC expectations
- external source update notes

Current implementation uses:
- one row per documented column
- a unique `(table_name, column_name)` constraint
- controlled `YES`/`NO` values for nullability tracking

The data dictionary is intended to support:
- future contributor onboarding
- future R metadata tools
- QA/QC automation
- schema transparency
- long-term workflow reproducibility

No upload workflows or ecological tables were modified during Change 004.

Future planned work:
- expand metadata coverage to additional tables after schema stabilization
- compare `grp.data_dictionary` against `information_schema.columns` for QA/QC
- potentially generate contributor-facing metadata exports from the SQL database

### Status
- Implemented
- Tested

---

# Change 003 — Add import and source-to-GRP object tracking
Date: 2026-05-16

### Dependency Notes
Change 003 adds administrative tracking tables rather than modifying ecological backbone tables.

An import batch is one meaningful processing or upload event that creates durable transformations, reinterpretations, mappings, or SQL insertions related to a project’s data workflow.

Import/provenance tracking should be updated whenever a processing stage creates durable transformations, reinterpretations, or ID mappings that future uploads may depend on.

This does not mean every tiny file edit needs a batch. It means meaningful workflow transitions should be recorded, such as:
- contributor/raw source → Excel interpretation
- Excel → input conversion
- input → SQL upload
- corrected re-upload after schema change
- reinterpretation of treatment/plot structure
- addition of a new monitoring year

### Expected Code Impacts
- Excel → Input code may eventually need to create or export import tracking information for contributor-to-Excel and Excel-to-input transformations.
- Input → SQL upload code will eventually need to insert records into:
  - `grp.import_batch`
  - `grp.import_object_map`
- OM workflow should use these tables as a case-study record of each processing stage.
- Existing GRP/GAZP historical data may only be backfilled where previous mapping documentation exists.

### Expected Structural Changes
- Create `grp.import_batch`
- Create `grp.import_object_map`
- Use `database` values:
  - `GAZP`
  - `GRP`
  - `OM`
- Link `grp.import_object_map.import_batchid` to `grp.import_batch.import_batchid`
- Store source/provenance paths and object mappings as text-based tracking fields

### Required Testing
- [x] Confirm `grp.import_batch` table exists
- [x] Confirm `grp.import_object_map` table exists
- [x] Confirm primary keys exist on both new tables
- [x] Confirm `grp.import_object_map.import_batchid` references `grp.import_batch(import_batchid)`
- [x] Confirm database CHECK constraints allow `GAZP`, `GRP`, and `OM`
- [x] Confirm no view updates are required
- [ ] Later: test sample OM processing batch record
- [ ] Later: test one-to-many mapping from contributor treatment to multiple GRP treatment IDs

### Actual Outcome
`grp.import_batch` and `grp.import_object_map` were successfully added as administrative provenance-tracking tables.

`grp.import_batch` now provides a structured record of meaningful processing/upload events across the workflow:

- contributor/raw source
- Excel database
- input format
- SQL database

`grp.import_object_map` now provides flexible source-to-GRP object mapping capable of representing:
- one-to-one mappings
- split mappings
- combined mappings
- derived/interpreted mappings
- uncertain mappings

Current implementation:
- uses text-based provenance and identifier fields for flexibility
- allows `GAZP`, `GRP`, and `OM` as controlled database values
- links object mappings to import batches through `import_batchid`

No ecological backbone tables or views were modified during Change 003.

Future workflow expectation:
- import/provenance tracking should be updated whenever a processing stage creates durable transformations, reinterpretations, or ID mappings that future uploads may depend on.

Remaining future work:
- update `project.database_check` before OM project insertion
- integrate provenance tracking into Excel → Input workflow
- integrate provenance tracking into Input → SQL upload workflow
- build metadata documentation defining:
  - import batches
  - mapping types
  - source object rules
  - identifier construction guidance
  
### Status
- Implemented
- Tested

---

# Change 002 — Seed mix normalization
Date: 2026-05-15

### Dependency Notes
- `grp.seeding` currently stores both:
  - species-level seeding records
  - unknown mix placeholders
- `speciesid` is nullable in `grp.seeding`
- `mix` is currently stored as free text
- `grp.full_seeding` is a species-level reporting view built directly from `grp.seeding`
- `grp.seeding_pretreatment` links pretreatment records to individual seeding rows through `seedingid`
- `seedingid` appears to represent one species-level seeding row within a treatment event

Column search for `seed` and `mix` found no additional seed mix structures beyond:
- `grp.seeding`
- `grp.full_seeding`
- `grp.seeding_pretreatment`
The only additional matches were `seed_mass` in species-related views/tables, which is a species trait and not part of seed mix normalization.

View definition search for `seed` or `mix` identified:
- `grp.full_seeding`
- `grp.full_species`
`grp.full_species` appears relevant only because of `seed_mass`, which is a species trait and not part of seed mix normalization.
Expected view update:
- `grp.full_seeding`

Foreign key check for `grp.seeding` found existing relationships involving:
- `grp.seeding.speciesid`
- `grp.seeding.cultivarid`
- `grp.seeding_pretreatment.seedingid`

Change 002 should not modify existing `speciesid`, `cultivarid`, or `seedingid` relationships. The planned `seed_mixid` relationship is additive.

### Expected Code Impacts
- Upload code currently likely assumes:
  - one-table representation of seed mixes
  - fake mix identifiers may enter species-related workflows
- Input → SQL upload scripts will need updating to:
  - create `seed_mix` records
  - assign `seed_mixid`
  - preserve nullable `speciesid`
- `grp.seeding.seed_mixid` will be required (`NOT NULL`)
- Input → SQL upload order must ensure:
  1. treatment exists
  2. seed_mix record exists
  3. seed_mixid is assigned before inserting seeding rows
- `grp.full_seeding` will require restructuring to expose seed mix information

### Expected Structural Changes
- Separate:
  - known species compositions
  - unknown mixes
  - mix-level metadata

- Preserve legacy `grp.seeding.mix` column temporarily for backward compatibility
- Until `grp.seeding.mix` is deprecated, populate it with the same value as `grp.seed_mix.mix_name` for compatibility with older views/code.
- Expose legacy mix field in `grp.full_seeding` as `legacy_mix_name`
- Future migration may deprecate or remove `grp.seeding.mix`

### Required Testing
- [x] Confirm `grp.seed_mix` table exists
- [x] Confirm `grp.seed_mix.seed_mixid` is primary key
- [x] Confirm `grp.seed_mix.treatmentid` references `grp.treatment(treatmentid)`
- [x] Confirm `grp.seeding.seed_mixid` column exists
- [x] Confirm `grp.seeding.seed_mixid` references `grp.seed_mix(seed_mixid)`
- [x] Confirm `grp.seeding.notes` column exists
- [x] Confirm `grp.full_seeding` compiles successfully after view update
- [x] Confirm `grp.full_seeding` exposes seed mix fields
- [ ] Check for orphaned `seeding.seed_mixid` values after future upload
- [ ] Check for treatment mismatch between `grp.seeding.treatmentid` and `grp.seed_mix.treatmentid` after future upload
- [ ] Inspect Input → SQL upload code for assumptions about old `grp.seeding` structure
- [ ] Inspect Excel → Input code for fake `mix_*` species handling

### Actual Outcome
`grp.seed_mix` was successfully added as a new relational table for mix-level seed metadata.

`grp.seeding` now requires:
- `seed_mixid`
- species-level seeding rows to belong to a seed mix structure

Existing relationships involving:
- `speciesid`
- `cultivarid`
- `seedingid`

were preserved without modification.

`grp.full_seeding` now exposes both:
- normalized seed mix fields
- legacy mix information (`legacy_mix_name`)

Current transition structure intentionally preserves:
- `grp.seeding.mix`
- duplicated temporary mix naming between:
  - `grp.seeding.mix`
  - `grp.seed_mix.mix_name`

This redundancy is temporary and intended to support backward compatibility during upload-code transition.

Remaining future work:
- inspect Excel → Input code for fake `mix_*` handling
- inspect Input → SQL upload order and ID assignment logic
- determine whether legacy `grp.seeding.mix` can eventually be deprecated

### Status
- Implemented

---

# Change 001 — Add treatment notes column
Date: 2026-05-14

### SQL Change
Add `notes text` column to `grp.treatment`.

### Likely Affected Code
- Excel → Input:
  - No expected impact yet.
  - Future input structure may eventually expose treatment notes.

- Input → SQL:
  - Upload code may assume the exact existing `grp.treatment` column structure.
  - Need to inspect INSERT statements later.

- SQL views:
  - `full_treatment`
  - `treatments_by_area`
  - `full_area`
  - `full_seeding`
  - `full_individual`

- QA/QC scripts:
  - Future QA should confirm treatment notes appear correctly in views.

### Dependency Notes
- Dependency check searched GRP view definitions for the word `treatment`.
 
Expected impact is low because:
- change is additive
- no columns are being removed or renamed

Views are unlikely to break, but will not automatically expose the new column.

- Current `grp.treatment` structure inspected before migration. No existing general treatment notes field exists.

Potential upload-code risk:
Input → SQL upload scripts may assume exact column count/order for `grp.treatment`.
Need to inspect INSERT statements later.

- Foreign key check confirmed treatment-detail tables depend on `grp.treatment(treatmentid)`. Because Change 001 only adds `notes text` and does not modify `treatmentid`, no foreign-key relationship impact is expected.

### Required Testing
- [x] Confirm `grp.treatment.notes` column exists
- [x] Inspect `full_treatment`
- [x] Check whether affected views should expose treatment notes

---
### Actual Outcome
No foreign key relationship issues observed.

Views updated:
- `grp.full_treatment`
- `grp.treatments_by_area`

Views inspected with no update needed:
- `grp.full_area`
- `grp.full_seeding`
- `grp.full_individual`

Remaining code risk:
- Input → SQL upload code may assume the old `grp.treatment` column count/order.
- Later inspection should check whether upload code uses explicit column names in `INSERT INTO grp.treatment (...)`.

### Status
- Implemented
- Tested
