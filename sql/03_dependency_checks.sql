-- =====================================================
-- Change 012 dependency check
-- Date: 2026-05-21
-- Description: Update lookup tables
-- =====================================================

-- Check whether any listed lookup tables are referenced by views
SELECT 
    schemaname,
    viewname
FROM pg_views
WHERE schemaname = 'grp'
AND (
    definition ILIKE '%grp.application_method%'
    OR definition ILIKE '%grp.bed_material%'
    OR definition ILIKE '%grp.bed_prep%'
    OR definition ILIKE '%grp.disturbance%'
    OR definition ILIKE '%grp.erosion_control%'
    OR definition ILIKE '%grp.fertilization%'
    OR definition ILIKE '%grp.grazer%'
    OR definition ILIKE '%grp.growth_medium%'
    OR definition ILIKE '%grp.herbicide%'
    OR definition ILIKE '%grp.invasion_control%'
    OR definition ILIKE '%grp.lifespan%'
    OR definition ILIKE '%grp.pretreatment%'
    OR definition ILIKE '%grp.vegmetric%'
);

-- Check current column structure for all listed lookup tables
SELECT
	table_name,
	column_name,
	data_type,
	column_default
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name IN (
	'application_method',
	'bed_material',
	'bed_prep',
	'disturbance',
	'erosion_control',
	'fertilization',
	'grazer',
	'growth_medium',
	'herbicide',
	'invasion_control',
	'lifespan',
	'pretreatment',
	'vegmetric'
)
ORDER BY table_name;

-- Check current contents of listed lookup tables
SELECT * FROM grp.application_method;
SELECT * FROM grp.bed_material;
SELECT * FROM grp.bed_prep;
SELECT * FROM grp.disturbance;
SELECT * FROM grp.erosion_control;
SELECT * FROM grp.fertilization;
SELECT * FROM grp.grazer;
SELECT * FROM grp.growth_medium;
SELECT * FROM grp.herbicide;
SELECT * FROM grp.invasion_control;
SELECT * FROM grp.lifespan;
SELECT * FROM grp.pretreatment;
SELECT * FROM grp.vegmetric;

-- =====================================================
-- Change 011 dependency check
-- Date: 2026-05-20
-- Description: Support for data_dictionary creation
-- =====================================================

-- Check constraints on table
SELECT
    con.conname AS constraint_name,
    con.contype AS constraint_type,
    pg_get_constraintdef(con.oid) AS constraint_definition
FROM pg_constraint con
JOIN pg_class rel
    ON rel.oid = con.conrelid
JOIN pg_namespace nsp
    ON nsp.oid = rel.relnamespace
WHERE nsp.nspname = 'grp'
AND rel.relname = 'area_treatment'
ORDER BY
    con.contype,
    con.conname;

-- Check foreign keys from table to other tables
SELECT
    tc.constraint_name,
    kcu.column_name AS column_name,
    ccu.table_schema AS referenced_schema,
    ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_column
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_schema = 'grp'
AND tc.table_name = 'area_treatment'
ORDER BY
    tc.constraint_name,
    kcu.column_name;
    
-- Check foreign keys from other tables to table
SELECT
    tc.table_schema AS referencing_schema,
    tc.table_name AS referencing_table,
    kcu.column_name AS referencing_column,
    ccu.table_schema AS referenced_schema,
    ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_column,
    tc.constraint_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
AND ccu.table_schema = 'grp'
AND ccu.table_name = 'area_treatment'
ORDER BY
    referencing_schema,
    referencing_table,
    referencing_column;

-- Check dictionaryid default and identity status
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default,
    is_identity,
    identity_generation
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'data_dictionary'
AND column_name = 'dictionaryid';

-- Check current maximum dictionaryid
SELECT MAX(dictionaryid) AS max_dictionaryid
FROM grp.data_dictionary;

-- =====================================================
-- Change 010 dependency check
-- Purpose: Change database constraint to include "OM"
-- Run before executing Change 010 in pgAdmin.
-- =====================================================

-- Check current constraint definition for grp.project.database
SELECT
    con.conname AS constraint_name,
    pg_get_constraintdef(con.oid) AS constraint_definition
FROM pg_constraint con
JOIN pg_class rel
    ON rel.oid = con.conrelid
JOIN pg_namespace nsp
    ON nsp.oid = rel.relnamespace
WHERE nsp.nspname = 'grp'
AND rel.relname = 'project'
AND con.contype = 'c'
ORDER BY con.conname;

-- Check whether database is referenced in views
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
JOIN pg_namespace dependent_ns
    ON dependent_view.relnamespace = dependent_ns.oid
JOIN pg_namespace source_ns
    ON source_table.relnamespace = source_ns.oid
WHERE source_ns.nspname = 'grp'
AND source_table.relname = 'project'
ORDER BY dependent_schema, dependent_view;

-- Check CHECK constraints on all grp tables with a database column
SELECT
    nsp.nspname AS table_schema,
    rel.relname AS table_name,
    con.conname AS constraint_name,
    pg_get_constraintdef(con.oid) AS constraint_definition
FROM pg_class rel
JOIN pg_namespace nsp
    ON nsp.oid = rel.relnamespace
JOIN pg_attribute att
    ON att.attrelid = rel.oid
LEFT JOIN pg_constraint con
    ON con.conrelid = rel.oid
    AND con.contype = 'c'
WHERE nsp.nspname = 'grp'
AND rel.relkind = 'r'
AND att.attname = 'database'
AND att.attisdropped = false
ORDER BY rel.relname, con.conname;

-- =====================================================
-- Change 009 dependency check
-- Purpose: Species trait simplification
-- Run before executing Change 009 in pgAdmin.
-- =====================================================

-- Check existing columns in grp.species before editing.
SELECT 
    table_schema,
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'species';

-- Check structure of species_lifespan
SELECT 
    table_schema,
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'species_lifespan';

-- Check full_species view.
SELECT 
    view_definition
FROM information_schema.views
WHERE table_schema = 'grp'
AND table_name = 'full_species';

-- Check dependencies on species table
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
JOIN pg_namespace dependent_ns
    ON dependent_view.relnamespace = dependent_ns.oid
JOIN pg_namespace source_ns
    ON source_table.relnamespace = source_ns.oid
WHERE source_ns.nspname = 'grp'
AND source_table.relname = 'species'
ORDER BY dependent_schema, dependent_view;

-- Check dependencies in other tables
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
AND ccu.table_schema = 'grp'
AND ccu.table_name = 'species'
ORDER BY tc.table_name;

-- =====================================================
-- Change 008 dependency check
-- Purpose: Streamline site table
-- Run before executing Change 008 in pgAdmin.
-- =====================================================

-- Confirm which views depend on grp.site
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
JOIN pg_namespace dependent_ns
    ON dependent_view.relnamespace = dependent_ns.oid
JOIN pg_namespace source_ns
    ON source_table.relnamespace = source_ns.oid
WHERE source_ns.nspname = 'grp'
AND source_table.relname = 'site'
ORDER BY dependent_schema, dependent_view;

-- Confirm final current column list for grp.site before planning the drop
SELECT
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default,
  ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'site'
ORDER BY ordinal_position;

-- =====================================================
-- Change 007 dependency check
-- Purpose: Enhance treatment - grazing, mowing, cover crop
-- Run before executing Change 007 in pgAdmin.
-- =====================================================

-- Find dependent views using mowing
SELECT
  table_schema,
  table_name,
  view_definition
FROM information_schema.views
WHERE view_definition ILIKE '%mowing%';

-- =====================================================
-- Change 006 dependency check
-- Purpose: Normalize paper/publication structure
-- Run before executing Change 006 in pgAdmin.
-- =====================================================

-- Check existing paper-related objects
SELECT 
    table_schema, 
    table_name, 
    table_type
FROM information_schema.tables
WHERE table_schema = 'grp'
AND table_name ILIKE '%paper%'
ORDER BY table_name;

-- Check existing paper and paper_author structure
SELECT
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default,
  ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name ILIKE '%paper%'
ORDER BY table_name, ordinal_position;

-- Check existing constraints on paper and paper_author
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
AND tc.table_name IN ('paper', 'paper_author')
ORDER BY tc.constraint_type, tc.constraint_name;

-- Check existing dependencies on paper, paper_author, and full_paper
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
    tc.table_name IN ('paper', 'paper_author', 'full_paper')
    OR ccu.table_name IN ('paper', 'paper_author', 'full_paper')
)
ORDER BY tc.table_name, kcu.column_name;

-- Check project primary key structure
SELECT
    tc.table_schema,
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_schema AS foreign_table_schema,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'PRIMARY KEY'
AND (
    tc.table_name = 'project'
    OR ccu.table_name = 'project'
)
ORDER BY tc.table_name, tc.constraint_name, kcu.column_name;

-- Check existing paper row counts
SELECT COUNT(*) AS row_count
  FROM grp.paper;

-- Check current full_paper view definition
SELECT
  view_definition
FROM information_schema.views
WHERE table_schema = 'grp'
AND table_name = 'full_paper';

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

-- Look at other views dependent on full_treatment
SELECT
  view_definition
FROM information_schema.views
WHERE table_schema = 'grp'
  AND table_name = 'treatments_by_area';

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
