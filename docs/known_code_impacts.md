# Known Code Impacts

Tracks known dependencies between:
- Excel → Input processing code
- Input → SQL upload code
- SQL schema structure
- SQL views

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
- Create dedicated `grp.seed_mix` table
- Add `seed_mixid` to `grp.seeding`
- Preserve `treatmentid` in `grp.seeding`
- Preserve nullable `speciesid`
- Separate:
  - known species compositions
  - unknown mixes
  - mix-level metadata
- Preserve direct linkage between `grp.seeding` and `grp.treatment`

### Required Testing
- [x] Confirm `grp.seed_mix` table exists
- [x] Confirm `grp.seed_mix.seed_mixid` is primary key
- [x] Confirm `grp.seed_mix.treatmentid` references `grp.treatment(treatmentid)`
- [x] Confirm `grp.seeding.seed_mixid` column exists
- [x] Confirm `grp.seeding.seed_mixid` references `grp.seed_mix(seed_mixid)`
- [x] Confirm `grp.seeding.notes` column exists
- [ ] Confirm `grp.full_seeding` compiles successfully after view update
- [ ] Confirm `grp.full_seeding` exposes seed mix fields
- [ ] Check for orphaned `seeding.seed_mixid` values after future upload
- [ ] Check for treatment mismatch between `grp.seeding.treatmentid` and `grp.seed_mix.treatmentid` after future upload
- [ ] Inspect Input → SQL upload code for assumptions about old `grp.seeding` structure
- [ ] Inspect Excel → Input code for fake `mix_*` species handling

### Actual Outcome

### Status
- Planned

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
