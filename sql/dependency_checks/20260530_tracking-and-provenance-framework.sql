-- =====================================================
-- Dependency Checks
-- Related Change ID: Change 017
-- Description: Assess dependencies before redesigning import tracking and provenance framework
-- =====================================================

-- -----------------------------------------------------
-- 1. Confirm existing import tracking tables
-- -----------------------------------------------------

SELECT
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'grp'
AND table_name IN (
    'import_batch',
    'import_object_map'
)
ORDER BY table_name;


-- -----------------------------------------------------
-- 2. Confirm existing columns in import tracking tables
-- -----------------------------------------------------

SELECT
    table_name,
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name IN (
    'import_batch',
    'import_object_map'
)
ORDER BY table_name, ordinal_position;


-- -----------------------------------------------------
-- 3. Check constraints on existing import tracking tables
-- -----------------------------------------------------

SELECT
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    cc.check_clause
FROM information_schema.table_constraints AS tc
LEFT JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage AS ccu
    ON tc.constraint_name = ccu.constraint_name
    AND tc.table_schema = ccu.table_schema
LEFT JOIN information_schema.check_constraints AS cc
    ON tc.constraint_name = cc.constraint_name
    AND tc.constraint_schema = cc.constraint_schema
WHERE tc.table_schema = 'grp'
AND tc.table_name IN (
    'import_batch',
    'import_object_map'
)
ORDER BY tc.table_name, tc.constraint_type, tc.constraint_name;


-- -----------------------------------------------------
-- 4. Check whether import_object_map is referenced by foreign keys
-- -----------------------------------------------------

SELECT
    tc.table_schema,
    tc.table_name,
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_column
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON tc.constraint_name = ccu.constraint_name
    AND tc.table_schema = ccu.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_schema = 'grp'
AND ccu.table_name = 'import_object_map'
ORDER BY tc.table_name, tc.constraint_name;


-- -----------------------------------------------------
-- 5. Check whether import_batch is referenced by foreign keys
-- -----------------------------------------------------

SELECT
    tc.table_schema,
    tc.table_name,
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_column
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON tc.constraint_name = ccu.constraint_name
    AND tc.table_schema = ccu.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_schema = 'grp'
AND ccu.table_name = 'import_batch'
ORDER BY tc.table_name, tc.constraint_name;


-- -----------------------------------------------------
-- 6. Check views that depend on import tracking tables
-- -----------------------------------------------------

SELECT
    dependent_ns.nspname AS dependent_schema,
    dependent_view.relname AS dependent_view,
    source_ns.nspname AS source_schema,
    source_table.relname AS source_table
FROM pg_depend
JOIN pg_rewrite
    ON pg_depend.objid = pg_rewrite.oid
JOIN pg_class AS dependent_view
    ON pg_rewrite.ev_class = dependent_view.oid
JOIN pg_class AS source_table
    ON pg_depend.refobjid = source_table.oid
JOIN pg_namespace AS dependent_ns
    ON dependent_ns.oid = dependent_view.relnamespace
JOIN pg_namespace AS source_ns
    ON source_ns.oid = source_table.relnamespace
WHERE source_ns.nspname = 'grp'
AND source_table.relname IN (
    'import_batch',
    'import_object_map'
)
AND dependent_view.relkind = 'v'
ORDER BY source_table.relname, dependent_view.relname;

-- -----------------------------------------------------
-- 7. Check current row counts
-- -----------------------------------------------------

SELECT
    'import_batch' AS table_name,
    COUNT(*) AS row_count
FROM grp.import_batch

UNION ALL

SELECT
    'import_object_map' AS table_name,
    COUNT(*) AS row_count
FROM grp.import_object_map;


-- -----------------------------------------------------
-- 8. Check whether planned replacement table names already exist
-- -----------------------------------------------------

SELECT
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'grp'
AND table_name IN (
    'import_project',
    'import_artifact',
    'import_transformation_step',
    'import_validation_issue',
    'project_object_crosswalk'
)
ORDER BY table_name;
