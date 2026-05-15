-- =====================================================
-- Change 002 validation tests
-- Purpose: validate normalization of seed mix
-- Run after executing Change 002 and associated view updates.
-- =====================================================

-- Confirm `grp.seed_mix` table exists and `grp.seed_mix.seed_mixid` is primary key
SELECT *
    FROM grp.seed_mix
    LIMIT 5;

-- Confirm `grp.seed_mix.treatmentid` references `grp.treatment(treatmentid)`
SELECT
    tc.table_schema,
    tc.table_name,
    kcu.column_name,
    ccu.table_schema AS foreign_table_schema,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND (
    tc.table_name = 'seed_mix'
    OR ccu.table_name = 'seed_mix'
)
ORDER BY tc.table_name, kcu.column_name;

-- Confirm `grp.seeding.seed_mixid` and `grp.seeding.notes` columns exist
SELECT *
    FROM grp.seeding
    LIMIT 5;

-- Confirm `grp.seeding.seed_mixid` references `grp.seed_mix(seed_mixid)`
SELECT
    tc.table_schema,
    tc.table_name,
    kcu.column_name,
    ccu.table_schema AS foreign_table_schema,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND (
    tc.table_name = 'seeding'
    OR ccu.table_name = 'seeding'
)
ORDER BY tc.table_name, kcu.column_name;

-- =====================================================
-- View validation: grp.full_seeding
-- =====================================================

-- Confirm grp.full_seeding exposes new fields
SELECT 
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'full_seeding'
ORDER BY ordinal_position;

-- Confirm grp.full_seeding compiles
SELECT *
FROM grp.full_seeding
LIMIT 5;

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
