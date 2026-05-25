# GRP SQL Database

Repository for development and maintenance of the Global Restore Project SQL database.

This repository tracks:
- SQL schema diagnostics
- schema modifications
- SQL views
- import workflow documentation
- known code dependencies and impacts
- future database migration decisions

---

# Repository Structure

## sql/
Executable SQL scripts.

Current contents:
- `00_phase0_diagnostics.sql`
- `01_schema_changes.sql`
- `02_view_updates.sql`
- `03_dependency_checks.sql`
- `04_import_tests.sql`
- `05_data_dictionary_population.sql`
- `06_lookup_population.sql`
- `07_view_dictionary_population.sql`

## docs/
Project documentation and migration tracking.

Current contents:
- `schema_change_log.md`
- `known_code_impacts.md`

---

# Workflow Philosophy

Changes to the database should:
1. Be documented before implementation
2. Be applied incrementally
3. Be tested after each change block
4. Include assessment of impacts on:
   - Excel → Input conversion code
   - Input → SQL upload code
   - SQL views

---

# Current Project Status

Phase 0 completed:
- database structure inspected
- row counts verified
- views identified
- GitHub repository initialized
- schema tracking infrastructure established

Phase 1 is completed and involved making structural changes:
- Add treatment notes (complete)
- Fix seed mixes (complete)
- Add import/conversion tracking (complete)
- Separate topsoil age and depth (complete)
- Rework project references (complete)
- Resolve availability (complete)
- Treatment vocabulary and treatment-detail refinements (complete)
- Site variable pruning (complete)
- Species trait simplification (complete)
- Update metadata (complete)

Phase 2 will involve testing and finalizing code:
- Input format → SQL
- Excel format → Input format

Phase 3 will be a project-by-project migration of the Excel database to the SQL database
- ~202 projects
  
Phase 4 will be to design access methods for public use
