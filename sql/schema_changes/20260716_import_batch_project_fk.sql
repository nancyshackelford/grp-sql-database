-- =====================================================
-- Change 019
-- Date: 2026-07-16
-- Description: Add project FK to grp.import_batch
-- =====================================================

BEGIN;

-- Project identity is defined by the combination of database and
-- projectid. This matches the FK used by grp.import_artifact and
-- the other project-specific import tracking tables.

ALTER TABLE grp.import_batch
ADD CONSTRAINT import_batch_project_fk
FOREIGN KEY (database, projectid)
REFERENCES grp.project(database, projectid)
ON UPDATE CASCADE
ON DELETE RESTRICT;

COMMIT;