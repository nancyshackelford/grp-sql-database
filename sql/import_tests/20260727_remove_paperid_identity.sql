-- =====================================================
-- Import Tests
-- Related Change ID: Change 020
-- Description: Validate removal of paperid identity
--              generation
-- =====================================================

-- -----------------------------------------------------
-- 1. Confirm identity generation has been removed
-- -----------------------------------------------------

SELECT
    column_name,
    data_type,
    is_nullable,
    column_default,
    is_identity,
    identity_generation,
    CASE
        WHEN data_type = 'integer'
         AND is_nullable = 'NO'
         AND column_default IS NULL
         AND is_identity = 'NO'
         AND identity_generation IS NULL
        THEN 'PASS'
        ELSE 'FAIL'
    END AS result
FROM information_schema.columns
WHERE table_schema = 'grp'
  AND table_name = 'paper'
  AND column_name = 'paperid';

-- Expected:
-- data_type: integer
-- is_nullable: NO
-- column_default: null
-- is_identity: NO
-- identity_generation: null
-- result: PASS


-- -----------------------------------------------------
-- 2. Confirm the internal identity flag is empty
-- -----------------------------------------------------

SELECT
    att.attname AS column_name,
    att.attidentity AS identity_code,
    CASE
        WHEN att.attidentity = '' THEN 'PASS'
        ELSE 'FAIL'
    END AS result
FROM pg_attribute att
WHERE att.attrelid = 'grp.paper'::regclass
  AND att.attname = 'paperid'
  AND NOT att.attisdropped;

-- Expected: PASS.


-- -----------------------------------------------------
-- 3. Confirm paperid remains the primary key
-- -----------------------------------------------------

SELECT
    con.conname AS constraint_name,
    con.convalidated AS is_validated,
    pg_get_constraintdef(con.oid) AS constraint_definition,
    CASE
        WHEN con.contype = 'p'
         AND con.convalidated
         AND pg_get_constraintdef(con.oid) = 'PRIMARY KEY (paperid)'
        THEN 'PASS'
        ELSE 'FAIL'
    END AS result
FROM pg_constraint con
WHERE con.conrelid = 'grp.paper'::regclass
  AND con.conname = 'paper_pkey';

-- Expected: PASS.


-- -----------------------------------------------------
-- 4. Confirm existing identifiers remain valid
-- -----------------------------------------------------

SELECT
    COUNT(*) AS total_papers,
    COUNT(paperid) AS populated_paperids,
    COUNT(DISTINCT paperid) AS distinct_paperids,
    CASE
        WHEN COUNT(*) = COUNT(paperid)
         AND COUNT(paperid) = COUNT(DISTINCT paperid)
        THEN 'PASS'
        ELSE 'FAIL'
    END AS result
FROM grp.paper;

-- Expected: PASS.


-- -----------------------------------------------------
-- 5. Confirm foreign keys referencing paper remain
--    present and validated
-- -----------------------------------------------------

SELECT
    con.conrelid::regclass AS referencing_table,
    con.conname AS constraint_name,
    con.convalidated AS is_validated,
    pg_get_constraintdef(con.oid) AS constraint_definition,
    CASE
        WHEN con.convalidated THEN 'PASS'
        ELSE 'FAIL'
    END AS result
FROM pg_constraint con
WHERE con.contype = 'f'
  AND con.confrelid = 'grp.paper'::regclass
ORDER BY con.conrelid::regclass::text, con.conname;


-- -----------------------------------------------------
-- 6. Confirm paper_author references remain valid
-- -----------------------------------------------------

SELECT
    COUNT(*) AS orphaned_paper_author_rows,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END AS result
FROM grp.paper_author pa
LEFT JOIN grp.paper p
  ON p.paperid = pa.paperid
WHERE p.paperid IS NULL;


-- -----------------------------------------------------
-- 7. Confirm project_paper references remain valid
-- -----------------------------------------------------

SELECT
    COUNT(*) AS orphaned_project_paper_rows,
    CASE
        WHEN COUNT(*) = 0 THEN 'PASS'
        ELSE 'FAIL'
    END AS result
FROM grp.project_paper pp
LEFT JOIN grp.paper p
  ON p.paperid = pp.paperid
WHERE p.paperid IS NULL;


-- -----------------------------------------------------
-- 8. Confirm paperid documentation remains accurate
-- -----------------------------------------------------

SELECT
    table_name,
    column_name,
    data_type,
    is_nullable,
    definition,
    workflow_notes,
    qa_qc_notes
FROM grp.data_dictionary
WHERE table_name = 'paper'
  AND column_name = 'paperid';

-- Expected: documentation describes paperid as unique and non-null
-- without stating that PostgreSQL automatically generates it.