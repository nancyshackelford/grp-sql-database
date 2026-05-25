-- =====================================================
-- Import Tests 015
-- Related Change ID: Change 015
-- Date: 2026-05-25
-- Description: Test creating mowing lookup table and renaming mowing_type
-- =====================================================

-- Check treatment_mowing has type and no longer has mowing_type
SELECT
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'treatment_mowing'
ORDER BY ordinal_position;

-- Check mowing lookup table exists
SELECT
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'grp'
AND table_name = 'mowing';

-- Check mowing lookup table structure
SELECT
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'mowing'
ORDER BY ordinal_position;

-- Check mowing lookup values were inserted
SELECT *
FROM grp.mowing
ORDER BY type;

-- Check full_treatment compiles and still exposes mowing_type
SELECT *
FROM grp.full_treatment
LIMIT 5;

-- Check treatments_by_area compiles and still exposes mowing_type
SELECT *
FROM grp.treatments_by_area
LIMIT 5;

-- Check view columns for mowing outputs
SELECT
    table_name,
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name IN ('full_treatment', 'treatments_by_area')
AND column_name ILIKE '%mowing%'
ORDER BY table_name, ordinal_position;

-- Check view definitions now source m.type, not m.mowing_type
SELECT
    schemaname,
    viewname,
    definition
FROM pg_views
WHERE schemaname = 'grp'
AND viewname IN ('full_treatment', 'treatments_by_area')
AND definition ILIKE '%m.type%';

-- Check no remaining view definition references m.mowing_type
SELECT
    schemaname,
    viewname,
    definition
FROM pg_views
WHERE schemaname = 'grp'
AND viewname IN ('full_treatment', 'treatments_by_area')
AND definition ILIKE '%m.mowing_type%';

-- Check data_dictionary treatment_mowing entry was corrected
SELECT
    table_name,
    column_name,
    display_order,
    data_type,
    is_nullable,
    definition,
    workflow_notes,
    allowed_values
FROM grp.data_dictionary
WHERE table_name = 'treatment_mowing'
AND column_name IN ('mowing_type', 'type')
ORDER BY column_name;

-- Check data_dictionary entries for new mowing lookup table
SELECT
    table_name,
    column_name,
    display_order,
    data_type,
    is_nullable,
    definition,
    workflow_notes,
    allowed_values,
    example,
    qa_qc_notes
FROM grp.data_dictionary
WHERE table_name = 'mowing'
ORDER BY display_order, column_name;

-- =====================================================
-- Import Tests 014
-- Related Change ID: Change 014
-- Date: 2026-05-23
-- Description: Test split of project data accessibility from paper/project metadata
-- =====================================================

-- Check project_data_accessibility table exists.
SELECT
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'grp'
AND table_name = 'project_data_accessibility';


-- Check expected columns exist in project_data_accessibility.
SELECT
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'project_data_accessibility'
ORDER BY ordinal_position;


-- Check primary key and foreign key constraints on project_data_accessibility.
SELECT
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
LEFT JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_schema = 'grp'
AND tc.table_name = 'project_data_accessibility'
ORDER BY
    tc.constraint_type,
    tc.constraint_name;


-- Check dropped columns are no longer present in paper.
SELECT
    column_name
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'paper'
AND column_name IN (
    'data_citation',
    'creativecommons_license',
    'use_conditions',
    'date_received'
);


-- Check publication DOI and publication URL remain in paper.
SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'paper'
AND column_name IN (
    'publication_doi',
    'publication_url'
)
ORDER BY column_name;


-- Check dropped availability column is no longer present in project.
SELECT
    column_name
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'project'
AND column_name = 'availability';


-- Check full_paper view exists and compiles.
SELECT *
FROM grp.full_paper
LIMIT 10;


-- Check full_paper no longer includes dataset accessibility fields.
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'full_paper'
AND column_name IN (
    'received',
    'citation',
    'license',
    'conditions',
    'data_citation',
    'data_doi',
    'data_url',
    'creativecommons_license',
    'use_conditions',
    'date_received'
)
ORDER BY column_name;


-- Check full_project view exists and compiles.
SELECT *
FROM grp.full_project
LIMIT 10;


-- Check full_project includes aggregated dataset accessibility fields.
SELECT
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'full_project'
AND column_name IN (
    'availability',
    'data_citation',
    'data_doi',
    'data_url',
    'creativecommons_license',
    'use_conditions',
    'first_date_received',
    'latest_date_received',
    'data_accessibility_notes'
)
ORDER BY column_name;


-- Check data dictionary entries exist for project_data_accessibility.
SELECT
    table_name,
    column_name,
    display_order,
    data_type,
    is_nullable,
    definition
FROM grp.data_dictionary
WHERE table_name = 'project_data_accessibility'
ORDER BY display_order;


-- Check data dictionary entries were removed for dropped paper/project columns.
SELECT
    table_name,
    column_name
FROM grp.data_dictionary
WHERE (table_name = 'paper'
    AND column_name IN (
        'data_citation',
        'creativecommons_license',
        'use_conditions',
        'date_received'
    ))
OR (table_name = 'project'
    AND column_name = 'availability')
ORDER BY
    table_name,
    column_name;


-- Check paper publication DOI/URL dictionary notes were updated.
SELECT
    table_name,
    column_name,
    workflow_notes,
    legacy_notes,
    external_source_notes
FROM grp.data_dictionary
WHERE table_name = 'paper'
AND column_name IN (
    'publication_doi',
    'publication_url'
)
ORDER BY column_name;


-- Check view dictionary entries were updated for full_paper and full_project.
SELECT
    view_name,
    purpose,
    expected_row_grain,
    key_assumptions,
    known_limitations,
    notes
FROM grp.view_dictionary
WHERE view_name IN (
    'full_paper',
    'full_project'
)
ORDER BY view_name;

-- =====================================================
-- Import Tests for Schema Change 013
-- Date: 2026-05-22
-- Description: Validate creation and population of view_dictionary
-- =====================================================

-- Check that grp.view_dictionary exists
SELECT
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'grp'
AND table_name = 'view_dictionary';

-- Check columns and column order in grp.view_dictionary
SELECT
    ordinal_position,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'view_dictionary'
ORDER BY ordinal_position;

-- Check that all expected views were inserted into grp.view_dictionary
SELECT
    *
FROM grp.view_dictionary
ORDER BY display_order;

-- =====================================================
-- Change 012 import tests
-- Date: 2026-05-22
-- Description: Support for data_dictionary creation
-- =====================================================

-- Confirm `definition` and `notes` columns exist-in all targeted lookup tables.
-- Confirm lookup tables were populated with expected controlled vocabulary values.
-- Confirm `grp.lifespan.description` has been renamed to `type`.
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

-- Confirm data dictionary entries were added 
SELECT *
FROM grp.data_dictionary
WHERE table_name = 'application_method';

-- Confirm data dictionary entry was updated
SELECT *
FROM grp.data_dictionary
WHERE table_name = 'lifespan';

-- =====================================================
-- Change 011 import tests
-- Date: 2026-05-20
-- Description: Support for data_dictionary creation
-- =====================================================

-- Check inserted data_dictionary rows
SELECT *
FROM grp.data_dictionary
WHERE table_name = 'area';

-- Check dictionaryid identity status
SELECT
    column_name,
    column_default,
    is_identity,
    identity_generation
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'data_dictionary'
AND column_name = 'dictionaryid';

-- =====================================================
-- Change 010 import tests
-- Purpose: Change database constraint to include "OM"
-- Run after executing Change 010 in pgAdmin.
-- =====================================================

-- Confirm `database_check` allows `'OM'` and confirm existing values (`'GRP'`, `'GAZP'`) remain valid
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

-- Check full_project still compiles
SELECT 
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'full_project'
ORDER BY ordinal_position;

SELECT *
FROM grp.full_project
LIMIT 5;

-- =====================================================
-- Change 009 import tests
-- Purpose: Species trait simplification
-- Run after executing Change 009 in pgAdmin.
-- =====================================================

-- Check columns in species have been dropped
SELECT
  column_name
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'species';

-- Check unknown has been added as row 1
SELECT *
FROM grp.species
WHERE speciesid = 1;

-- Check full_species view has columns and compiles
SELECT 
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'full_species'
ORDER BY ordinal_position;

SELECT *
FROM grp.full_species
LIMIT 5;

-- Check that dependencies on speciesid are still intact
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
-- Change 008 import tests
-- Purpose: Validate site table refinement
-- Run after executing Change 008 in pgAdmin.
-- =====================================================

-- Confirm removed columns no longer exist in grp.site
SELECT
    column_name
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'site'
ORDER BY ordinal_position;

-- Confirm grp.full_site no longer exists prior to rebuild
SELECT
    table_schema,
    table_name
FROM information_schema.views
WHERE table_schema = 'grp'
AND table_name = 'full_site';

-- Check full_site compiles and includes new treatment fields
SELECT 
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'full_site'
ORDER BY ordinal_position;

SELECT *
FROM grp.full_site
LIMIT 5;

-- =====================================================
-- Change 007 import tests
-- Purpose: Validate treatment refinement
-- Run after executing Change 007 in pgAdmin.
-- =====================================================

-- Check structure of treatment_mowing
SELECT
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default,
  ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'treatment_mowing'
ORDER BY ordinal_position;

-- Check structure of treatment_cover_crop
SELECT
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default,
  ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'treatment_cover_crop'
ORDER BY ordinal_position;

-- Check maintenance_mowing was dropped from treatment
SELECT
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default,
  ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'treatment'
AND column_name = 'maintenance_mowing';

-- Check notes was added to treatment_grazer
SELECT
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default,
  ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'treatment_grazer'
ORDER BY ordinal_position;

-- Check full_treatment compiles and includes new treatment fields
SELECT 
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'full_treatment'
ORDER BY ordinal_position;

SELECT *
FROM grp.full_treatment
LIMIT 5;

-- Check treatments_by_area compiles and includes new treatment fields
SELECT 
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'treatments_by_area'
ORDER BY ordinal_position;

SELECT *
FROM grp.treatments_by_area
LIMIT 5;

-- =====================================================
-- Change 006 import tests
-- Purpose: Validate normalization of paper/publication
-- Run after executing Change 006 in pgAdmin.
-- =====================================================

-- Check new paper-related objects exist
SELECT
  table_schema,
  table_name,
  table_type
FROM information_schema.tables
WHERE table_schema = 'grp'
AND table_name ILIKE '%paper%'
ORDER BY table_name;
  
-- Check new paper structure
  -- Look for paper identity/autogenerated ID default
SELECT
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default,
  is_identity,
  identity_generation,
  ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'paper'
ORDER BY ordinal_position;

-- Check new project_paper structure
SELECT
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default,
  ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'project_paper'
ORDER BY ordinal_position;

-- Check new paper_author structure
SELECT
  table_name,
  column_name,
  data_type,
  is_nullable,
  column_default,
  ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'paper_author'
ORDER BY ordinal_position;

-- Check new paper primary key
SELECT
    tc.table_schema,
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
WHERE tc.constraint_type = 'PRIMARY KEY'
AND tc.table_schema = 'grp'
AND tc.table_name = 'paper'
ORDER BY tc.table_name, tc.constraint_name, kcu.column_name;

-- Check new project_paper primary key
SELECT
  tc.table_schema,
  tc.table_name,
  tc.constraint_name,
  tc.constraint_type,
  kcu.column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
WHERE tc.constraint_type = 'PRIMARY KEY'
AND tc.table_schema = 'grp'
AND tc.table_name = 'project_paper'
ORDER BY tc.table_name, tc.constraint_name, kcu.column_name;

-- Check new paper_author primary key
SELECT
  tc.table_schema,
  tc.table_name,
  tc.constraint_name,
  tc.constraint_type,
  kcu.column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
WHERE tc.constraint_type = 'PRIMARY KEY'
AND tc.table_schema = 'grp'
AND tc.table_name = 'paper_author'
ORDER BY tc.table_name, tc.constraint_name, kcu.column_name;

-- Check existing constraints on paper, project_paper, and paper_author
-- Look for: 
  -- new paper DOI uniqueness constraint, 
  -- project_paper foreign key to project,
  -- project_paper foreign key to paper
  -- paper_author foreign key to paper
  -- paper_author foreign key to author_contributor
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
    AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage AS ccu
    ON tc.constraint_name = ccu.constraint_name
    AND tc.table_schema = ccu.table_schema
WHERE tc.table_schema = 'grp'
AND tc.table_name IN ('paper', 'project_paper', 'paper_author')
ORDER BY tc.constraint_type, tc.constraint_name, kcu.column_name;

-- Check structure of full_paper
SELECT 
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'full_paper'
ORDER BY ordinal_position;

-- Confirm grp.full_paper compiles successfully
SELECT *
FROM grp.full_paper
LIMIT 5;

-- =====================================================
-- Change 005 import tests
-- Purpose: Validate addition of growth medium depth
-- Run after executing Change 005 in pgAdmin.
-- =====================================================

-- Confirm additional columns
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

-- Confirm addition to full_treatment
SELECT 
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'full_treatment'
ORDER BY ordinal_position;

-- Confirm queryable in full_treatment
SELECT
    growth_medium_depth,
    growth_medium_depth_units
FROM grp.full_treatment
LIMIT 5;

-- Confirm addition to treatments_by_area
SELECT 
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'treatments_by_area'
ORDER BY ordinal_position;

-- Confirm queryable in treatments_by_area
SELECT
    growth_medium_depth,
    growth_medium_depth_units
FROM grp.treatments_by_area
LIMIT 5;

-- =====================================================
-- Change 004 import tests
-- Purpose: Validate data dictionary infrastructure
-- Run after executing Change 004 in pgAdmin.
-- =====================================================

-- Confirm data_dictionary table exists
SELECT
  table_schema,
  table_name,
  table_type
FROM information_schema.tables
WHERE table_schema = 'grp'
AND table_name = 'data_dictionary';

-- Confirm expected columns exist in grp.data_dictionary
SELECT
  column_name,
  data_type,
  is_nullable,
  ordinal_position
FROM information_schema.columns
WHERE table_name = 'data_dictionary'
ORDER BY ordinal_position;

-- Confirm primary key, unique constraint, and CHECK constraint exist
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
LEFT JOIN information_schema.constraint_column_usage AS ccu
    ON tc.constraint_name = ccu.constraint_name
LEFT JOIN information_schema.check_constraints AS cc
    ON tc.constraint_name = cc.constraint_name
WHERE tc.table_schema = 'grp'
AND tc.table_name = 'data_dictionary'
ORDER BY tc.table_name, tc.constraint_type, tc.constraint_name;

-- Confirm metadata rows were inserted
SELECT *
  FROM grp.data_dictionary
  LIMIT 5;

-- Confirm expected row count
SELECT COUNT(*) AS row_count
  FROM grp.data_dictionary;

-- Inspect inserted metadata rows for import_batch
SELECT *
  FROM grp.data_dictionary
  WHERE table_name = 'import_batch'
  ORDER BY display_order;

-- Inspect inserted metadata rows for import_object_map
SELECT *
  FROM grp.data_dictionary
  WHERE table_name = 'import_object_map'
  ORDER BY display_order;
  
-- =====================================================
-- Change 003 validation tests
-- Purpose: validate addition of import and source-to-GRP object tracking
-- Run after executing Change 003; no associated view updates.
-- =====================================================

-- Confirm `import_batch` and `import_object_map` tables exist
SELECT 
  table_schema,
  table_name,
  table_type
FROM information_schema.tables
WHERE table_schema = 'grp'
AND table_name IN ('import_batch', 'import_object_map');

-- Confirm `import_batch` and `import_object_map` column names
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

-- Check `import_batch` and `import_object_map` constraints
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
LEFT JOIN information_schema.constraint_column_usage AS ccu
    ON tc.constraint_name = ccu.constraint_name
LEFT JOIN information_schema.check_constraints AS cc
    ON tc.constraint_name = cc.constraint_name
WHERE tc.table_schema = 'grp'
AND tc.table_name IN ('import_batch', 'import_object_map')
ORDER BY tc.table_name, tc.constraint_type, tc.constraint_name;


-- =====================================================
-- Change 002 validation tests
-- Purpose: validate normalization of seed mix
-- Run after executing Change 002 and associated view updates.
-- =====================================================

-- Confirm `grp.seed_mix` table exists and `grp.seed_mix.seed_mixid` is primary key
SELECT *
    FROM grp.seed_mix
    LIMIT 5;

-- Confirm `grp.seed_mix.treatmentid` references `grp.treatment(treatmentid)`
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
    tc.table_name = 'seed_mix'
    OR ccu.table_name = 'seed_mix'
)
ORDER BY tc.table_name, kcu.column_name;

-- Confirm `grp.seeding.seed_mixid` and `grp.seeding.notes` columns exist
SELECT *
    FROM grp.seeding
    LIMIT 5;

-- Confirm `grp.seeding.seed_mixid` references `grp.seed_mix(seed_mixid)`
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
-- View validation: grp.full_seeding
-- =====================================================

-- Confirm grp.full_seeding exposes new fields
SELECT 
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'full_seeding'
ORDER BY ordinal_position;

-- Confirm grp.full_seeding compiles
SELECT *
FROM grp.full_seeding
LIMIT 5;

-- =====================================================
-- Change 001 validation tests
-- Purpose: validate treatment notes schema and view updates
-- Run after executing Change 001 and associated view updates.
-- =====================================================

-- Confirm notes column exists in grp.treatment
SELECT 
    column_name,
    data_type,
    is_nullable,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'treatment'
ORDER BY ordinal_position;

-- =====================================================
-- View validation: grp.full_treatment
-- =====================================================

-- Confirm treatment_notes appears in grp.full_treatment
SELECT 
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'full_treatment'
ORDER BY ordinal_position;

-- Confirm grp.full_treatment compiles successfully
SELECT *
FROM grp.full_treatment
LIMIT 5;

-- =====================================================
-- View validation: grp.treatments_by_area
-- =====================================================

-- Confirm treatment_notes appears in grp.treatments_by_area
SELECT 
    column_name,
    data_type,
    ordinal_position
FROM information_schema.columns
WHERE table_schema = 'grp'
AND table_name = 'treatments_by_area'
ORDER BY ordinal_position;

-- Confirm grp.treatments_by_area compiles successfully
SELECT *
FROM grp.treatments_by_area
LIMIT 5;
