-- =====================================================
-- Change 001
-- Date: 2026-05-14
-- Description: Add general notes column to treatment table
-- =====================================================

ALTER TABLE grp.treatment
ADD COLUMN notes text;
