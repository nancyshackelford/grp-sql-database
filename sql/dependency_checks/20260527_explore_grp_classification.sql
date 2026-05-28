SELECT 'STEP 1 - COLUMN STRUCTURE' AS section;

SELECT
  column_name,
  ordinal_position,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'classification'
ORDER BY ordinal_position;

SELECT 'STEP 2 - ROW COUNT' AS section;

SELECT COUNT(*) AS exact_row_count
FROM grp.classification;

SELECT 'STEP 3 - CURRENT ROWS' AS section;

SELECT *
FROM grp.classification
ORDER BY 1;

SELECT 'STEP 4 - CONSTRAINTS' AS section;

SELECT
  tc.constraint_name,
  tc.constraint_type,
  kcu.column_name
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
 AND tc.table_schema = kcu.table_schema
 AND tc.table_name = kcu.table_name
WHERE tc.table_schema = 'grp'
AND tc.table_name = 'classification'
ORDER BY tc.constraint_type, tc.constraint_name, kcu.ordinal_position;

SELECT 'STEP 5 - FOREIGN KEYS ON CLASSIFICATION' AS section;

SELECT
  tc.constraint_name,
  kcu.column_name,
  ccu.table_schema AS referenced_table_schema,
  ccu.table_name AS referenced_table_name,
  ccu.column_name AS referenced_column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
 AND tc.table_schema = kcu.table_schema
 AND tc.table_name = kcu.table_name
JOIN information_schema.constraint_column_usage ccu
  ON ccu.constraint_name = tc.constraint_name
 AND ccu.constraint_schema = tc.constraint_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_schema = 'grp'
AND tc.table_name = 'classification';

SELECT 'STEP 6 - FOREIGN KEYS POINTING TO CLASSIFICATION' AS section;

SELECT
  tc.table_schema AS referencing_schema,
  tc.table_name AS referencing_table,
  kcu.column_name AS referencing_column,
  tc.constraint_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
 AND tc.table_schema = kcu.table_schema
 AND tc.table_name = kcu.table_name
JOIN information_schema.constraint_column_usage ccu
  ON ccu.constraint_name = tc.constraint_name
 AND ccu.constraint_schema = tc.constraint_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
AND ccu.table_schema = 'grp'
AND ccu.table_name = 'classification'
ORDER BY referencing_schema, referencing_table, referencing_column;

SELECT 'STEP 7 - CHECK CONSTRAINTS' AS section;

SELECT
  con.conname AS constraint_name,
  pg_get_constraintdef(con.oid) AS definition
FROM pg_constraint con
JOIN pg_class rel
  ON rel.oid = con.conrelid
JOIN pg_namespace nsp
  ON nsp.oid = rel.relnamespace
WHERE nsp.nspname = 'grp'
AND rel.relname = 'classification'
AND con.contype = 'c';

SELECT 'STEP 8 - INDEXES' AS section;

SELECT
  indexname,
  indexdef
FROM pg_indexes
WHERE schemaname = 'grp'
AND tablename = 'classification';

SELECT 'STEP 9 - VIEWS USING CLASSIFICATION' AS section;

SELECT
  view_schema,
  view_name,
  table_schema,
  table_name
FROM information_schema.view_table_usage
WHERE table_schema = 'grp'
AND table_name = 'classification'
ORDER BY view_schema, view_name;

SELECT 'STEP 10 - TRIGGERS' AS section;

SELECT
  tgname AS trigger_name,
  pg_get_triggerdef(t.oid) AS definition
FROM pg_trigger t
JOIN pg_class c
  ON t.tgrelid = c.oid
JOIN pg_namespace n
  ON c.relnamespace = n.oid
WHERE n.nspname = 'grp'
AND c.relname = 'classification'
AND NOT t.tgisinternal;
