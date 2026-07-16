-- =====================================================
-- Change 019 Diagnostics
-- Purpose: Diagnose failures when adding or validating
--          grp.import_batch project referential integrity
-- =====================================================

-- -----------------------------------------------------
-- 1. Inspect import_batch structure
-- -----------------------------------------------------

SELECT
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
  AND table_name = 'import_batch'
ORDER BY ordinal_position;


-- -----------------------------------------------------
-- 2. Inspect all import_batch constraints
-- -----------------------------------------------------

SELECT
    con.conname AS constraint_name,
    con.contype AS constraint_type,
    con.convalidated AS is_validated,
    pg_get_constraintdef(con.oid) AS constraint_definition
FROM pg_constraint con
WHERE con.conrelid = 'grp.import_batch'::regclass
ORDER BY con.contype, con.conname;


-- -----------------------------------------------------
-- 3. Inspect the referenced project uniqueness constraint
-- -----------------------------------------------------

SELECT
    con.conname AS constraint_name,
    con.contype AS constraint_type,
    pg_get_constraintdef(con.oid) AS constraint_definition
FROM pg_constraint con
WHERE con.conrelid = 'grp.project'::regclass
  AND con.contype IN ('p', 'u')
ORDER BY con.conname;


-- -----------------------------------------------------
-- 4. List orphaned import_batch project references
-- -----------------------------------------------------

SELECT
    ib.import_batchid,
    ib.database,
    ib.projectid,
    ib.processed_date,
    ib.workflow_version
FROM grp.import_batch ib
LEFT JOIN grp.project p
  ON p.database = ib.database
 AND p.projectid = ib.projectid
WHERE ib.projectid IS NOT NULL
  AND p.projectid IS NULL
ORDER BY ib.database, ib.projectid, ib.import_batchid;


-- -----------------------------------------------------
-- 5. Identify projectid values associated with multiple
--    database values
-- -----------------------------------------------------

SELECT
    projectid,
    COUNT(DISTINCT database) AS database_count,
    ARRAY_AGG(DISTINCT database ORDER BY database) AS databases
FROM grp.project
WHERE projectid IS NOT NULL
GROUP BY projectid
HAVING COUNT(DISTINCT database) > 1
ORDER BY projectid;

-- Returned rows demonstrate why projectid alone is not a sufficient
-- project identifier.


-- -----------------------------------------------------
-- 6. Compare project references across import tables
-- -----------------------------------------------------

SELECT
    'import_batch' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE projectid IS NOT NULL) AS populated_projectids
FROM grp.import_batch

UNION ALL

SELECT
    'import_artifact',
    COUNT(*),
    COUNT(*) FILTER (WHERE projectid IS NOT NULL)
FROM grp.import_artifact

ORDER BY table_name;


-- -----------------------------------------------------
-- 7. Inspect the exact import_artifact FK used as the model
-- -----------------------------------------------------

SELECT
    con.conname AS constraint_name,
    con.convalidated AS is_validated,
    pg_get_constraintdef(con.oid) AS constraint_definition
FROM pg_constraint con
WHERE con.conrelid = 'grp.import_artifact'::regclass
  AND con.confrelid = 'grp.project'::regclass
  AND con.contype = 'f'
ORDER BY con.conname;