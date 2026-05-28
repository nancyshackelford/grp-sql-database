-- Import tests: populate classification lookup
-- Purpose: verify USDA/NatureServe classification lookup rows and FK relationship

-- 1) Confirm expected row count
SELECT
  COUNT(*) AS classification_row_count
FROM grp.classification;

-- Expected: 50


-- 2) Confirm key USDA/NatureServe hierarchy rows exist
SELECT *
FROM grp.classification
WHERE classificationid IN (
  '1.A.1',
  '2.C.5',
  '4.B.1',
  '7.D.2'
)
ORDER BY classificationid;

-- Expected:
-- 1.A.1 = Forest & Woodland / Tropical Forest & Woodland / Tropical Dry Forest & Woodland
-- 2.C.5 = Shrub & Herb Vegetation / Shrub & Herb Wetland / Salt Marsh
-- 4.B.1 = Polar & High Montane Scrub, Grassland & Barrens / Temperate to Polar Alpine & Tundra Vegetation / Temperate & Boreal Alpine Dwarf-shrub & Grassland
-- 7.D.2 = Agricultural & Developed Vegetation / Agricultural & Developed Aquatic Vegetation / Urban & Recreational Aquatic Vegetation


-- 3) Confirm no null IDs
SELECT *
FROM grp.classification
WHERE classificationid IS NULL;

-- Expected: zero rows


-- 4) Confirm no duplicate classification IDs
SELECT
  classificationid,
  COUNT(*) AS duplicate_count
FROM grp.classification
GROUP BY classificationid
HAVING COUNT(*) > 1;

-- Expected: zero rows


-- 5) Confirm former vocabulary CHECK constraints were removed
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
AND con.conname IN (
  'class_check',
  'subclass_check',
  'subsubclass_check'
);

-- Expected: zero rows


-- 6) Confirm primary key still exists on grp.classification.classificationid
SELECT
  tc.constraint_name,
  tc.constraint_type,
  kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
 AND tc.table_schema = kcu.table_schema
 AND tc.table_name = kcu.table_name
WHERE tc.table_schema = 'grp'
AND tc.table_name = 'classification'
AND tc.constraint_type = 'PRIMARY KEY'
AND kcu.column_name = 'classificationid';

-- Expected: classification_pkey / PRIMARY KEY / classificationid


-- 7) Confirm grp.site_classification has a foreign key to grp.classification.classificationid
SELECT
  tc.constraint_name,
  tc.constraint_type,
  tc.table_schema AS referencing_schema,
  tc.table_name AS referencing_table,
  kcu.column_name AS referencing_column,
  ccu.table_schema AS referenced_schema,
  ccu.table_name AS referenced_table,
  ccu.column_name AS referenced_column
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
AND tc.table_name = 'site_classification'
AND kcu.column_name = 'classificationid'
AND ccu.table_schema = 'grp'
AND ccu.table_name = 'classification'
AND ccu.column_name = 'classificationid';

-- Expected:
-- FK_Site_Classification.ClassificationID / FOREIGN KEY
-- referencing grp.site_classification.classificationid
-- referenced grp.classification.classificationid


-- 8) Confirm no orphaned site_classification records
SELECT
  sc.classificationid
FROM grp.site_classification sc
LEFT JOIN grp.classification c
  ON sc.classificationid = c.classificationid
WHERE c.classificationid IS NULL;

-- Expected: zero rows


-- 9) Confirm full_site view can still read classification dependency
SELECT *
FROM grp.full_site
LIMIT 5;

-- Expected: query runs successfully