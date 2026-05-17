-- GRP SQL Database
-- Phase 0 diagnostics
-- Purpose: document database state before schema changes

-- 0. View database structure
SELECT 
    table_schema,
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY table_schema, table_name, ordinal_position;

-- 1. Check estimated row counts
SELECT 
    schemaname, 
    relname AS table_name, 
    n_live_tup AS estimated_rows
FROM pg_stat_user_tables
ORDER BY schemaname, relname;

-- 2. Check whether grp objects are tables or views
SELECT 
    table_schema, 
    table_name, 
    table_type
FROM information_schema.tables
WHERE table_schema = 'grp'
ORDER BY table_name;

-- 3. Export current column inventory
SELECT 
    table_schema, 
    table_name, 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY table_schema, table_name, ordinal_position;

-- 4. Inspect full_treatment view definition
SELECT definition
FROM pg_views
WHERE schemaname = 'grp'
AND viewname = 'full_treatment';
