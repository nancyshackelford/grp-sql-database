-- =====================================================
-- Import Tests
-- Related Change ID: Change 017
-- Description: Test import tracking and provenance framework
-- =====================================================


-- =====================================================
-- Stage 1 Tests: import_project
-- =====================================================

-- Check import_project table exists
SELECT
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'grp'
AND table_name = 'import_project';


-- Check import_project columns
SELECT
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'import_project'
ORDER BY ordinal_position;


-- Check import_project constraints
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
AND tc.table_name = 'import_project'
ORDER BY tc.constraint_type, tc.constraint_name;


-- Check import_project indexes
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'grp'
AND tablename = 'import_project'
ORDER BY indexname;

 
-- =====================================================
-- Stage 2 Tests: import_artifact
-- =====================================================

-- Check import_artifact table exists
SELECT
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'grp'
AND table_name = 'import_artifact';


-- Check import_artifact columns
SELECT
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'import_artifact'
ORDER BY ordinal_position;


-- Check import_artifact constraints
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
AND tc.table_name = 'import_artifact'
ORDER BY tc.constraint_type, tc.constraint_name;


-- Check import_artifact indexes
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'grp'
AND tablename = 'import_artifact'
ORDER BY indexname;


-- Check import_artifact table comment
SELECT
    obj_description('grp.import_artifact'::regclass, 'pg_class') AS table_comment;
 
-- =====================================================
-- Stage 3 Tests: import_transformation_step and bridge table
-- =====================================================

-- Check transformation tracking tables exist
SELECT
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'grp'
AND table_name IN (
    'import_transformation_step',
    'import_transformation_step_artifact'
)
ORDER BY table_name;


-- Check transformation tracking columns
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name IN (
    'import_transformation_step',
    'import_transformation_step_artifact'
)
ORDER BY table_name, ordinal_position;


-- Check transformation tracking constraints
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
    'import_transformation_step',
    'import_transformation_step_artifact'
)
ORDER BY tc.table_name, tc.constraint_type, tc.constraint_name;


-- Check transformation tracking indexes
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'grp'
AND tablename IN (
    'import_transformation_step',
    'import_transformation_step_artifact'
)
ORDER BY tablename, indexname;


-- Check transformation tracking table comments
SELECT
    'import_transformation_step' AS table_name,
    obj_description('grp.import_transformation_step'::regclass, 'pg_class') AS table_comment

UNION ALL

SELECT
    'import_transformation_step_artifact' AS table_name,
    obj_description('grp.import_transformation_step_artifact'::regclass, 'pg_class') AS table_comment;
 
-- =====================================================
-- Stage 4 Tests: project_object_crosswalk
-- =====================================================

-- Check project_object_crosswalk table exists
SELECT
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'grp'
AND table_name = 'project_object_crosswalk';


-- Check project_object_crosswalk columns
SELECT
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'project_object_crosswalk'
ORDER BY ordinal_position;


-- Check project_object_crosswalk constraints
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
AND tc.table_name = 'project_object_crosswalk'
ORDER BY tc.constraint_type, tc.constraint_name;


-- Check project_object_crosswalk indexes
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'grp'
AND tablename = 'project_object_crosswalk'
ORDER BY indexname;


-- Check project_object_crosswalk table comment
SELECT
    obj_description('grp.project_object_crosswalk'::regclass, 'pg_class') AS table_comment;
 
-- =====================================================
-- Stage 5 Tests: import_validation_issue
-- =====================================================

-- Check import_validation_issue table exists
SELECT
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'grp'
AND table_name = 'import_validation_issue';


-- Check import_validation_issue columns
SELECT
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'import_validation_issue'
ORDER BY ordinal_position;


-- Check import_validation_issue constraints
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
AND tc.table_name = 'import_validation_issue'
ORDER BY tc.constraint_type, tc.constraint_name;


-- Check import_validation_issue indexes
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'grp'
AND tablename = 'import_validation_issue'
ORDER BY indexname;


-- Check import_validation_issue table comment
SELECT
    obj_description('grp.import_validation_issue'::regclass, 'pg_class') AS table_comment;
 

-- Check import_object_map table existence
SELECT
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'grp'
AND table_name = 'import_object_map';

-- =====================================================
-- Final Framework Tests
-- =====================================================

-- Check all expected import/provenance tables exist
SELECT
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'grp'
AND table_name IN (
    'import_batch',
    'import_project',
    'import_artifact',
    'import_transformation_step',
    'import_transformation_step_artifact',
    'project_object_crosswalk',
    'import_validation_issue',
    'import_object_map'
)
ORDER BY table_name;


-- Check row counts in new framework tables
SELECT 'import_project' AS table_name, COUNT(*) AS row_count
FROM grp.import_project

UNION ALL

SELECT 'import_artifact' AS table_name, COUNT(*) AS row_count
FROM grp.import_artifact

UNION ALL

SELECT 'import_transformation_step' AS table_name, COUNT(*) AS row_count
FROM grp.import_transformation_step

UNION ALL

SELECT 'import_transformation_step_artifact' AS table_name, COUNT(*) AS row_count
FROM grp.import_transformation_step_artifact

UNION ALL

SELECT 'project_object_crosswalk' AS table_name, COUNT(*) AS row_count
FROM grp.project_object_crosswalk

UNION ALL

SELECT 'import_validation_issue' AS table_name, COUNT(*) AS row_count
FROM grp.import_validation_issue;


-- Confirm import_object_map still exists but is no longer the core future model
SELECT
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'grp'
AND table_name = 'import_object_map';

-- =====================================================
-- Data Dictionary Validation
-- Change 017 – Import Tracking and Provenance Framework
-- =====================================================


-- -----------------------------------------------------
-- 1. Verify removed table documentation is gone
-- -----------------------------------------------------

SELECT *
FROM grp.data_dictionary
WHERE table_name = 'import_object_map';


-- -----------------------------------------------------
-- 2. Verify new table entry counts
-- -----------------------------------------------------

SELECT
    table_name,
    COUNT(*) AS dictionary_entries
FROM grp.data_dictionary
WHERE table_name IN (
    'import_project',
    'import_artifact',
    'import_transformation_step',
    'import_transformation_step_artifact',
    'project_object_crosswalk',
    'import_validation_issue'
)
GROUP BY table_name
ORDER BY table_name;


-- Expected:
-- import_project = 13
-- import_artifact = 18
-- import_transformation_step = 11
-- import_transformation_step_artifact = 5
-- project_object_crosswalk = 16
-- import_validation_issue = 20


-- -----------------------------------------------------
-- 3. Check display_order sequence integrity
-- -----------------------------------------------------

WITH ordered AS (
    SELECT
        table_name,
        column_name,
        display_order,
        ROW_NUMBER() OVER (
            PARTITION BY table_name
            ORDER BY display_order
        ) AS expected_order
    FROM grp.data_dictionary
    WHERE table_name IN (
        'import_project',
        'import_artifact',
        'import_transformation_step',
        'import_transformation_step_artifact',
        'project_object_crosswalk',
        'import_validation_issue'
    )
)
SELECT *
FROM ordered
WHERE display_order <> expected_order;


-- Should return zero rows.


-- -----------------------------------------------------
-- 4. Check for duplicate entries
-- -----------------------------------------------------

SELECT
    table_name,
    column_name,
    COUNT(*) AS duplicate_count
FROM grp.data_dictionary
WHERE table_name IN (
    'import_project',
    'import_artifact',
    'import_transformation_step',
    'import_transformation_step_artifact',
    'project_object_crosswalk',
    'import_validation_issue'
)
GROUP BY table_name, column_name
HAVING COUNT(*) > 1;


-- Should return zero rows.


-- -----------------------------------------------------
-- 5. Verify every schema column has a dictionary entry
-- -----------------------------------------------------

SELECT
    c.table_name,
    c.column_name
FROM information_schema.columns c
LEFT JOIN grp.data_dictionary d
    ON c.table_name = d.table_name
   AND c.column_name = d.column_name
WHERE c.table_schema = 'grp'
AND c.table_name IN (
    'import_project',
    'import_artifact',
    'import_transformation_step',
    'import_transformation_step_artifact',
    'project_object_crosswalk',
    'import_validation_issue'
)
AND d.column_name IS NULL
ORDER BY c.table_name, c.ordinal_position;


-- Should return zero rows.


-- -----------------------------------------------------
-- 6. Verify every dictionary entry exists in schema
-- -----------------------------------------------------

SELECT
    d.table_name,
    d.column_name
FROM grp.data_dictionary d
LEFT JOIN information_schema.columns c
    ON d.table_name = c.table_name
   AND d.column_name = c.column_name
   AND c.table_schema = 'grp'
WHERE d.table_name IN (
    'import_project',
    'import_artifact',
    'import_transformation_step',
    'import_transformation_step_artifact',
    'project_object_crosswalk',
    'import_validation_issue'
)
AND c.column_name IS NULL
ORDER BY d.table_name, d.display_order;


-- Should return zero rows.


-- -----------------------------------------------------
-- 7. Check required documentation fields populated
-- -----------------------------------------------------

SELECT
    table_name,
    column_name
FROM grp.data_dictionary
WHERE table_name IN (
    'import_project',
    'import_artifact',
    'import_transformation_step',
    'import_transformation_step_artifact',
    'project_object_crosswalk',
    'import_validation_issue'
)
AND (
    definition IS NULL
    OR workflow_notes IS NULL
);


-- Should return zero rows.


-- -----------------------------------------------------
-- 8. Check controlled vocab fields documented
-- -----------------------------------------------------

SELECT
    table_name,
    column_name,
    allowed_values
FROM grp.data_dictionary
WHERE table_name IN (
    'import_project',
    'import_artifact',
    'import_transformation_step_artifact',
    'project_object_crosswalk',
    'import_validation_issue'
)
AND column_name IN (
    'contribution_type',
    'documentation_tier',
    'import_status',
    'artifact_type',
    'artifact_role',
    'object_type',
    'issue_type',
    'issue_severity'
)
ORDER BY table_name, column_name;


-- Manual review:
-- confirm allowed_values matches CHECK constraints.


-- -----------------------------------------------------
-- 9. Summary table
-- -----------------------------------------------------

SELECT
    table_name,
    COUNT(*) AS column_count,
    MIN(display_order) AS min_order,
    MAX(display_order) AS max_order
FROM grp.data_dictionary
WHERE table_name IN (
    'import_project',
    'import_artifact',
    'import_transformation_step',
    'import_transformation_step_artifact',
    'project_object_crosswalk',
    'import_validation_issue'
)
GROUP BY table_name
ORDER BY table_name;