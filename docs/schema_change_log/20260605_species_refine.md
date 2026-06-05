## Change ID:
Change 018
20260605_speciesid_autogenerate_lifespan_type_refine

Date:
2026-06-05

### Summary
Updated the species schema by converting `species.speciesid` to an auto-generated identity column and renaming `species_lifespan.description` to `type` for consistency with lookup table conventions used elsewhere in the database.

### Motivation
The `species` table was newly created and contained no records, making it an appropriate time to implement automatic primary key generation. The `species_lifespan` join table used a column named `description` to store lifespan categories, which was inconsistent with the referenced lookup table (`lifespan.type`) and with naming conventions used throughout the schema.

### SQL Objects Affected
- Tables:
  - grp.species
  - grp.species_lifespan
  - grp.data_dictionary

- Views:
  - grp.full_species

- New tables:
  - None

- Deprecated tables/columns:
  - grp.species_lifespan.description

### Upload / Code Impacts
- Excel → Input code:
  - No impacts expected. Species IDs should no longer be supplied during import.
  - Lifespan imports should populate `type` rather than `description`.

- Input → SQL code:
  - Species import workflows should rely on PostgreSQL identity generation for `speciesid`.
  - Any insert statements referencing `species_lifespan.description` must be updated to `species_lifespan.type`.

- QA/QC impacts:
  - Validation scripts should verify identity generation for `species.speciesid`.
  - Validation scripts should reference `species_lifespan.type`.

### SQL Change
- Added identity generation to `grp.species.speciesid`.
- Renamed `grp.species_lifespan.description` to `type`.
- Rebuilt `grp.full_species` to aggregate values from `species_lifespan.type`.
- Updated relevant data dictionary entries.

### Required View Updates
- [x] Rebuilt `grp.full_species` to reference `species_lifespan.type`.

### Testing Performed
- [x] Verified `species.speciesid` is configured as an identity column.
- [x] Verified data dictionary updates for `species.speciesid`.
- [x] Verified data dictionary updates for `species_lifespan.type`.
- [x] Verified `full_species` view definition references `species_lifespan.type`.
- [x] Verified `full_species` row count matches `species` row count.

### Actual Outcomes
All schema modifications were applied successfully.

- `species.speciesid` was converted to an auto-generated identity column.
- `species_lifespan.description` was renamed to `type`.
- The foreign key constraint was updated to reference `species_lifespan.type`.
- The `full_species` view was rebuilt to aggregate lifespan values from `species_lifespan.type`.
- Data dictionary entries were updated to reflect the new column name and identity-based primary key generation.

All import tests completed successfully. Row counts and view functionality were verified, and no unexpected impacts were identified.

### Status
- Implemented
- Tested