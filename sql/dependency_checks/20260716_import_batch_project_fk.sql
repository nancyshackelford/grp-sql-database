-- =====================================================
-- Dependency Checks
-- Related Change ID: Change 019
-- Description: Add the project foreign key to grp.import_batch
-- =====================================================

-- -----------------------------------------------------
-- 1. Confirm the required tables exist
-- -----------------------------------------------------

SELECT
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'grp'
  AND table_name IN ('import_batch', 'project')
ORDER BY table_name;

-- Expected: one row each for import_batch and project.


-- -----------------------------------------------------
-- 2. Confirm the required columns exist
-- -----------------------------------------------------

SELECT
    table_name,
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
  AND table_name IN ('import_batch', 'project')
  AND column_name IN ('database', 'projectid')
ORDER BY table_name, ordinal_position;

-- Expected:
-- import_batch.database
-- import_batch.projectid
-- project.database
-- project.projectid


-- -----------------------------------------------------
-- 3. Confirm the referencing and referenced column types match
-- -----------------------------------------------------

SELECT
    ib.column_name,
    ib.data_type AS import_batch_data_type,
    p.data_type AS project_data_type,
    CASE
        WHEN ib.data_type = p.data_type THEN 'PASS'
        ELSE 'FAIL'
    END AS result
FROM information_schema.columns ib
JOIN information_schema.columns p
  ON p.table_schema = 'grp'
 AND p.table_name = 'project'
 AND p.column_name = ib.column_name
WHERE ib.table_schema = 'grp'
  AND ib.table_name = 'import_batch'
  AND ib.column_name IN ('database', 'projectid')
ORDER BY ib.ordinal_position;

-- Expected: PASS for both columns.


-- -----------------------------------------------------
-- 4. Confirm grp.project has a unique or primary-key
--    constraint on (database, projectid)
-- -----------------------------------------------------

SELECT
    con.conname AS constraint_name,
    con.contype AS constraint_type,
    pg_get_constraintdef(con.oid) AS constraint_definition
FROM pg_constraint con
WHERE con.conrelid = 'grp.project'::regclass
  AND con.contype IN ('p', 'u')
  AND con.conkey = ARRAY[
      (
          SELECT attnum
          FROM pg_attribute
          WHERE attrelid = 'grp.project'::regclass
            AND attname = 'database'
            AND NOT attisdropped
      ),
      (
          SELECT attnum
          FROM pg_attribute
          WHERE attrelid = 'grp.project'::regclass
            AND attname = 'projectid'
            AND NOT attisdropped
      )
  ]::smallint[];

-- Expected: project_database_projectid_unique, or an equivalent
-- unique/primary-key constraint in the same column order.


-- -----------------------------------------------------
-- 5. Inspect existing foreign keys on grp.import_batch
-- -----------------------------------------------------

SELECT
    con.conname AS constraint_name,
    pg_get_constraintdef(con.oid) AS constraint_definition
FROM pg_constraint con
WHERE con.conrelid = 'grp.import_batch'::regclass
  AND con.contype = 'f'
ORDER BY con.conname;

-- Expected before the change: no project FK on import_batch.
-- If an equivalent FK already exists, stop and review before applying
-- the schema change.


-- -----------------------------------------------------
-- 6. Confirm the model used by grp.import_artifact
-- -----------------------------------------------------

SELECT
    con.conname AS constraint_name,
    pg_get_constraintdef(con.oid) AS constraint_definition
FROM pg_constraint con
WHERE con.conrelid = 'grp.import_artifact'::regclass
  AND con.contype = 'f'
  AND con.confrelid = 'grp.project'::regclass
ORDER BY con.conname;

-- Expected:
-- FOREIGN KEY (database, projectid)
-- REFERENCES grp.project(database, projectid)
-- ON UPDATE CASCADE
-- ON DELETE RESTRICT


-- -----------------------------------------------------
-- 7. Find orphaned populated project references
-- -----------------------------------------------------

SELECT
    ib.import_batchid,
    ib.database,
    ib.projectid
FROM grp.import_batch ib
LEFT JOIN grp.project p
  ON p.database = ib.database
 AND p.projectid = ib.projectid
WHERE ib.projectid IS NOT NULL
  AND p.projectid IS NULL
ORDER BY ib.import_batchid;

-- Expected: zero rows.
-- Any returned rows must be corrected before adding the FK.


-- -----------------------------------------------------
-- 8. Summarize rows that will and will not be validated
-- -----------------------------------------------------

SELECT
    COUNT(*) AS total_import_batches,
    COUNT(*) FILTER (
        WHERE projectid IS NULL
    ) AS batches_without_projectid,
    COUNT(*) FILTER (
        WHERE projectid IS NOT NULL
    ) AS batches_with_projectid
FROM grp.import_batch;

-- A null projectid remains permitted after the FK is added.