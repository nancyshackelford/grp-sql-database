-- =====================================================
-- Change 005 dependency check
-- Purpose: Separate topsoil age and depth
-- Run before executing Change 005 in pgAdmin.
-- =====================================================

-- Inspect current treatment_medium structure
SELECT
  column_name,
  data_type,
  is_nullable,
  column_default,
  ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'treatment_medium'
ORDER BY ordinal_position;

-- Find dependent views using treatment_medium
SELECT
  table_schema,
  table_name,
  view_definition
FROM information_schema.views
WHERE view_definition ILIKE '%treatment_medium%';

-- Inspect full_treatment view
SELECT
  view_definition
FROM information_schema.views
WHERE table_schema = 'grp'
AND table_name = 'full_treatment';

-- =====================================================
-- Change 004 dependency check
-- Purpose: Check dependencies for adding data dictionary infrastructure
-- Run before executing Change 004 in pgAdmin.
-- =====================================================

-- Check whether data dictionary table already exists
SELECT 
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'grp'
AND table_name = 'data_dictionary';

-- Confirm import tracking tables exist before adding metadata rows for them
SELECT 
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'grp'
AND table_name IN ('import_batch', 'import_object_map')
ORDER BY table_name;

-- Confirm columns in import tracking tables before documenting them
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name IN ('import_batch', 'import_object_map')
ORDER BY table_name, ordinal_position;

-- =====================================================
-- Change 003 dependency check
-- Purpose: Check dependencies for adding import tracking tables
-- Run before executing Change 003 in pgAdmin.
-- =====================================================

-- Check whether proposed import tracking tables already exist
SELECT 
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'grp'
AND table_name IN ('import_batch', 'import_object_map')
ORDER BY table_name;

-- Confirm referenced project columns exist and inspect database constraint context
SELECT 
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'project'
AND column_name IN ('database', 'projectid')
ORDER BY ordinal_position;

-- Check constraints on grp.project related to database/projectid
SELECT
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    cc.check_clause
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
LEFT JOIN information_schema.check_constraints cc
    ON tc.constraint_name = cc.constraint_name
WHERE tc.table_schema = 'grp'
AND tc.table_name = 'project'
AND (
    kcu.column_name IN ('database', 'projectid')
    OR cc.check_clause ILIKE '%database%'
)
ORDER BY tc.constraint_type, tc.constraint_name;

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
