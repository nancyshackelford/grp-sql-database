## Change ID:
20260605_speciesid_autogenerate_lifespan_type_refine

### SQL Change
Added identity generation to `species.speciesid` and renamed `species_lifespan.description` to `type`.

### Likely Affected Code
- Excel → Input:
  - Species import templates.
  - Species lifespan import templates.

- Input → SQL:
  - Species insertion scripts.
  - Species lifespan insertion scripts.

- SQL views:
  - `grp.full_species`

- QA/QC scripts:
  - Species schema validation scripts.
  - Data dictionary validation scripts.
  - View validation scripts.

### Dependency Notes
- Import code should not manually assign `speciesid`.
- Import code should expect PostgreSQL to generate species identifiers automatically.
- Any code referencing `species_lifespan.description` must be updated to `species_lifespan.type`.
- `full_species` depends on aggregation of values stored in `species_lifespan.type`.
- Lifespan values must exist in `grp.lifespan(type)`.

### Required Testing
- [x] Confirm identity generation on `species.speciesid`.
- [x] Confirm `species_lifespan.type` exists.
- [x] Confirm foreign key references `grp.lifespan(type)`.
- [x] Confirm `full_species` executes successfully.
- [x] Confirm data dictionary reflects schema changes.

### Actual Outcomes

All identified dependencies were reviewed and updated.

- Species imports no longer require manual population of `speciesid`.
- References to `species_lifespan.description` were replaced with `species_lifespan.type`.
- The `full_species` view was updated and validated.
- Data dictionary entries were updated and verified.

All testing completed successfully with expected results. No additional code impacts were identified during implementation.

### Status
- Fixed
- Tested