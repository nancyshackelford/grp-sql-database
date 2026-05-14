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
