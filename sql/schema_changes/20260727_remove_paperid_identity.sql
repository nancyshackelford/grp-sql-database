-- =====================================================
-- Change 020
-- Date: 2026-07-27
-- Description: Remove identity generation from
--              grp.paper.paperid
-- =====================================================

BEGIN;

-- paperid remains an integer, NOT NULL, and the primary key.
-- This removes only the GENERATED ALWAYS AS IDENTITY property.
-- New paper inserts must supply paperid explicitly.

ALTER TABLE grp.paper
ALTER COLUMN paperid
DROP IDENTITY;

COMMIT;