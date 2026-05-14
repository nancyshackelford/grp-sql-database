-- =====================================================
-- Change 001 validation tests
-- Purpose: validate treatment notes schema and view updates
-- Run after executing Change 001 and associated view updates.
-- =====================================================

-- Confirm notes column exists in grp.treatment
SELECT 
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'treatment'
ORDER BY ordinal_position;

-- =====================================================
-- View validation: grp.full_treatment
-- =====================================================

-- Confirm treatment_notes appears in grp.full_treatment
SELECT 
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'full_treatment'
ORDER BY ordinal_position;

-- Confirm grp.full_treatment compiles successfully
SELECT *
FROM grp.full_treatment
LIMIT 5;

-- =====================================================
-- View validation: grp.treatments_by_area
-- =====================================================

-- Confirm treatment_notes appears in grp.treatments_by_area
SELECT 
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'treatments_by_area'
ORDER BY ordinal_position;

-- Confirm grp.treatments_by_area compiles successfully
SELECT *
FROM grp.treatments_by_area
LIMIT 5;
