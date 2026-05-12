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
