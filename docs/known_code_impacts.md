# Known Code Impacts

Tracks known dependencies between:
- Excel → Input processing code
- Input → SQL upload code
- SQL schema structure
- SQL views

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
