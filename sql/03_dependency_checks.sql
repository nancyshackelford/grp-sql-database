-- =====================================================
-- Change 002 dependency check
-- Purpose: Check dependencies for seed mix normalization
-- Run before executing Change 002 in pgAdmin.
-- Save outputs/interpretation in docs/schema_change_log.md.
-- =====================================================

-- Check current structure of seed-related tables
SELECT 
    table_schema, 
    table_name, 
    column_name, 
    data_type, 
    is_nullable, 
    column_default, 
    ordinal_position
    FROM information_schema.columns 
    WHERE table_schema = 'grp' 
    AND ( 
    table_name = 'seeding' 
    OR table_name = 'full_seeding' 
    OR table_name = 'seeding_pretreatment')
    ORDER BY table_name, ordinal_position;

-- Find tables/views with seed/mix-related columns 
SELECT
    table_schema,
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
    FROM information_schema.columns
    WHERE table_schema = 'grp'
    AND (
    table_name ILIKE '%seed%'
    OR column_name ILIKE '%seed%'
    OR table_name ILIKE '%mix%'
    OR column_name ILIKE '%mix%')
    ORDER BY table_name, ordinal_position;

-- Identify views that mention seed/mix-related content
SELECT 
    schemaname,
    viewname
    FROM pg_views
    WHERE schemaname = 'grp'
    AND (
    definition ILIKE '%seed%'
    OR definition ILIKE '%mix%')
    ORDER BY viewname;

-- Check foreign keys / relationships involving seed/mix-related content
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
-- Change 001 dependency check
-- Purpose: Check dependencies for adding a treatment notes column
-- Run before executing Change 001 in pgAdmin.
-- Save outputs/interpretation in docs/schema_change_log.md.
-- =====================================================

-- Identify views that mention treatment-related tables/fields
SELECT 
    schemaname,
    viewname
FROM pg_views
WHERE schemaname = 'grp'
AND definition ILIKE '%treatment%';

-- Check columns in grp.treatment
SELECT 
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'treatment'
ORDER BY ordinal_position;

-- Check foreign keys / relationships involving treatment
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
    tc.table_name = 'treatment'
    OR ccu.table_name = 'treatment'
)
ORDER BY tc.table_name, kcu.column_name;
