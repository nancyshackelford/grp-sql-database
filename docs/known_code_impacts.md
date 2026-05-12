# Known Code Impacts

Tracks known dependencies between:
- Excel → Input processing code
- Input → SQL upload code
- SQL schema structure
- SQL views

---

# Tracking Template

## Change ID:

### SQL Change
Short description.

### Likely Affected Code
- Excel → Input:
- Input → SQL:
- SQL views:
- QA/QC scripts:

### Dependency Notes
Describe assumptions the code currently makes.

Examples:
- expects column name `species`
- expects `treatmentid` uniqueness
- expects lookup table to exist
- assumes one row per treatment
- assumes no NULL values

### Required Testing
- [ ]

### Status
- Identified
- Investigating
- Fixed
- Tested
