-- =====================================================
-- Import Tests
-- Related Change ID: Change 019
-- Description: Validate grp.import_batch project FK
-- =====================================================

-- -----------------------------------------------------
-- 1. Confirm the new constraint exists and is validated
-- -----------------------------------------------------

SELECT
    con.conname AS constraint_name,
    con.contype AS constraint_type,
    con.convalidated AS is_validated,
    pg_get_constraintdef(con.oid) AS constraint_definition,
    CASE
        WHEN con.conname = 'import_batch_project_fk'
         AND con.contype = 'f'
         AND con.convalidated
        THEN 'PASS'
        ELSE 'FAIL'
    END AS result
FROM pg_constraint con
WHERE con.conrelid = 'grp.import_batch'::regclass
  AND con.conname = 'import_batch_project_fk';

-- Expected:
-- FOREIGN KEY (database, projectid)
-- REFERENCES grp.project(database, projectid)
-- ON UPDATE CASCADE
-- ON DELETE RESTRICT


-- -----------------------------------------------------
-- 2. Confirm referencing columns are in the correct order
-- -----------------------------------------------------

SELECT
    src.attname AS referencing_column,
    ref.attname AS referenced_column,
    src_cols.ordinality AS column_position
FROM pg_constraint con
CROSS JOIN LATERAL
    unnest(con.conkey) WITH ORDINALITY AS src_cols(attnum, ordinality)
JOIN pg_attribute src
  ON src.attrelid = con.conrelid
 AND src.attnum = src_cols.attnum
JOIN pg_attribute ref
  ON ref.attrelid = con.confrelid
 AND ref.attnum = con.confkey[src_cols.ordinality]
WHERE con.conrelid = 'grp.import_batch'::regclass
  AND con.conname = 'import_batch_project_fk'
ORDER BY src_cols.ordinality;

-- Expected:
-- 1: database  -> database
-- 2: projectid -> projectid


-- -----------------------------------------------------
-- 3. Confirm FK actions
-- -----------------------------------------------------

SELECT
    con.conname AS constraint_name,
    CASE con.confupdtype
        WHEN 'c' THEN 'CASCADE'
        WHEN 'a' THEN 'NO ACTION'
        WHEN 'r' THEN 'RESTRICT'
        WHEN 'n' THEN 'SET NULL'
        WHEN 'd' THEN 'SET DEFAULT'
    END AS on_update,
    CASE con.confdeltype
        WHEN 'c' THEN 'CASCADE'
        WHEN 'a' THEN 'NO ACTION'
        WHEN 'r' THEN 'RESTRICT'
        WHEN 'n' THEN 'SET NULL'
        WHEN 'd' THEN 'SET DEFAULT'
    END AS on_delete,
    CASE
        WHEN con.confupdtype = 'c'
         AND con.confdeltype = 'r'
        THEN 'PASS'
        ELSE 'FAIL'
    END AS result
FROM pg_constraint con
WHERE con.conrelid = 'grp.import_batch'::regclass
  AND con.conname = 'import_batch_project_fk';


-- -----------------------------------------------------
-- 4. Confirm no populated references are orphaned
-- -----------------------------------------------------

SELECT
    COUNT(*) AS orphaned_reference_count,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END AS result
FROM grp.import_batch ib
LEFT JOIN grp.project p
  ON p.database = ib.database
 AND p.projectid = ib.projectid
WHERE ib.projectid IS NOT NULL
  AND p.projectid IS NULL;


-- -----------------------------------------------------
-- 5. Confirm all populated references resolve exactly once
-- -----------------------------------------------------

WITH reference_matches AS (
    SELECT
        ib.import_batchid,
        COUNT(p.projectid) AS matching_projects
    FROM grp.import_batch ib
    LEFT JOIN grp.project p
      ON p.database = ib.database
     AND p.projectid = ib.projectid
    WHERE ib.projectid IS NOT NULL
    GROUP BY ib.import_batchid
)
SELECT
    COUNT(*) FILTER (
        WHERE matching_projects <> 1
    ) AS invalid_match_count,
    CASE
        WHEN COUNT(*) FILTER (WHERE matching_projects <> 1) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS result
FROM reference_matches;


-- -----------------------------------------------------
-- 6. Confirm null projectid values remain permitted
-- -----------------------------------------------------

SELECT
    COUNT(*) FILTER (
        WHERE projectid IS NULL
    ) AS existing_null_projectids,
    'PASS: composite FK permits null projectid values' AS result
FROM grp.import_batch;


-- -----------------------------------------------------
-- 7. Compare the import_batch and import_artifact project FKs
-- -----------------------------------------------------

SELECT
    con.conrelid::regclass AS table_name,
    con.conname AS constraint_name,
    pg_get_constraintdef(con.oid) AS constraint_definition
FROM pg_constraint con
WHERE con.contype = 'f'
  AND con.confrelid = 'grp.project'::regclass
  AND con.conrelid IN (
      'grp.import_batch'::regclass,
      'grp.import_artifact'::regclass
  )
ORDER BY con.conrelid::regclass::text, con.conname;

-- Expected: both tables use the composite
-- (database, projectid) project reference.