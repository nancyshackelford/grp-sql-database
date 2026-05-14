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

Phase 1 involves making structural changes:
- Add treatment notes (complete)
- Fix seed mixes
- Add import/conversion tracking
- Separate topsoil age and depth
- Rework project references
- Resolve availability
- Treatment vocabulary and treatment-detail refinements
- Site variable pruning
- Species trait simplification
- Input naming and mapping cleanup
- Update processing code and metadata
- Drop deprecated columns

Phase 2 will involve testing and finalizing stages:
- Input format to SQL
- Excel format to Input format

Phase 3 will be a project-by-project migration of the Excel database to the SQL database
Phase 4 will be to design access methods for public use
