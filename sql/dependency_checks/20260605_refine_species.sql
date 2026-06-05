-- =====================================================
-- Dependency Checks
-- Related Change ID: Change 018
-- Description: Populate species table with existing species data from relevant tables
-- =====================================================

-- -----------------------------------------------------
-- 1. Check species tables in SQL
-- -----------------------------------------------------

SELECT 
    column_name,
    table_name
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name ILIKE '%species%';

-- -----------------------------------------------------
-- 2. Check lookup values in lifespan
-- -----------------------------------------------------

SELECT *
FROM grp.lifespan;

-- -----------------------------------------------------
-- 3. Check whether species.speciesid is auto-generated
-- -----------------------------------------------------

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    is_identity,
    identity_generation
FROM information_schema.columns
WHERE table_schema = 'grp'
  AND table_name = 'species'
ORDER BY ordinal_position;

-- -----------------------------------------------------
-- 4. Check constraints on species-related tables
-- -----------------------------------------------------

SELECT
    conname AS constraint_name,
    contype AS constraint_type,
    conrelid::regclass AS table_name,
    pg_get_constraintdef(oid) AS constraint_definition
FROM pg_constraint
WHERE conrelid IN (
    'grp.species'::regclass,
    'grp.species_lifespan'::regclass,
    'grp.species_names'::regclass
)
ORDER BY conrelid::regclass::text, contype, conname;

-- -----------------------------------------------------
-- 5. See how species_lifespan is constrained
-- -----------------------------------------------------

SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_column,
    tc.constraint_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
 AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage ccu
  ON ccu.constraint_name = tc.constraint_name
 AND ccu.table_schema = tc.table_schema
WHERE tc.table_schema = 'grp'
  AND tc.table_name = 'species_lifespan'
  AND tc.constraint_type = 'FOREIGN KEY';

-- -----------------------------------------------------
-- 6. Check what full_species actually is doing
-- -----------------------------------------------------

SELECT
    viewname,
    definition
FROM pg_views
WHERE schemaname = 'grp'
  AND viewname = 'full_species';