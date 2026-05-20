-- =====================================================
-- Change 010
-- Date: 2026-05-20
-- Description: Change database constraint to include "OM"
-- =====================================================

-- Drop CHECK constraint in grp.project
ALTER TABLE grp.project
  DROP CONSTRAINT database_check;

-- Add new CHECK constraint
ALTER TABLE grp.project
  ADD CONSTRAINT database_check
    CHECK (database IN ('GAZP', 'GRP', 'OM'));

-- =====================================================
-- Change 009
-- Date: 2026-05-20
-- Description: Species trait simplification
-- =====================================================

-- Drop full_species view
DROP VIEW IF EXISTS grp.full_species;

-- Drop low-priority trait columns from grp.species.
-- Target dropped columns: seed_mass, path, raunkiaer, woodiness, nfixer.
ALTER TABLE grp.species
  DROP COLUMN seed_mass,
  DROP COLUMN path,
  DROP COLUMN raunkiaer,
  DROP COLUMN woodiness,
  DROP COLUMN nfixer;

-- Insert unknown species row.
INSERT INTO grp.species (
  speciesid,
  "group",
  "order",
  family,
  genus,
  species,
  subtype,
  subtype_name,
  lifeform,
  species_code
)
VALUES
(1, NULL, NULL, NULL, 'Unknown', 'unknown', NULL, NULL, NULL, 'Unk_spp');

-- =====================================================
-- Change 008
-- Date: 2026-05-19
-- Description: Streamline site table
-- =====================================================

-- Drop dependent view
DROP VIEW IF EXISTS grp.full_site;

-- Alter existing site table by dropping unwanted columns
ALTER TABLE grp.site
  DROP COLUMN landcover,
  DROP COLUMN growing_season_start,
  DROP COLUMN growing_season_end,
  DROP COLUMN elevation,
  DROP COLUMN slope,
  DROP COLUMN aspect,
  DROP COLUMN annual_precip_contributor,
  DROP COLUMN annual_temp_contributor,
  DROP COLUMN mean_diurnal_range,
  DROP COLUMN isothermality,
  DROP COLUMN temp_seasonality,
  DROP COLUMN max_temp_warmest_month,
  DROP COLUMN max_temp_coldest_month,
  DROP COLUMN temp_range,
  DROP COLUMN mean_temp_wettest_quarter,
  DROP COLUMN mean_temp_driest_quarter,
  DROP COLUMN mean_temp_warmest_quarter,
  DROP COLUMN mean_temp_coldest_quarter,
  DROP COLUMN wettest_month_precip,
  DROP COLUMN driest_month_precip,
  DROP COLUMN precip_seasonality,
  DROP COLUMN wettest_quarter_precip,
  DROP COLUMN driest_quarter_precip,
  DROP COLUMN warmest_quarter_precip,
  DROP COLUMN coldest_quarter_precip;

-- =====================================================
-- Change 007
-- Date: 2026-05-19
-- Description: Enhance treatment - grazing, mowing, cover crop
-- =====================================================

-- Create mowing table
CREATE TABLE grp.treatment_mowing (
  mowingid integer GENERATED ALWAYS AS IDENTITY, 
  treatmentid integer NOT NULL,
  mowing_type text NOT NULL,
  height_class text,
  amount numeric,
  units text,
  notes text,
  
  CONSTRAINT mowing_pkey PRIMARY KEY (mowingid),
  CONSTRAINT fk_mowing_treatment_trtid 
    FOREIGN KEY (treatmentid)
    REFERENCES grp.treatment(treatmentid)
);

-- Create cover crop table
CREATE TABLE grp.treatment_cover_crop (
  covercropid integer GENERATED ALWAYS AS IDENTITY,
  treatmentid integer NOT NULL,
  speciesid integer NOT NULL,
  amount numeric,
  units text,
  notes text,
  
  CONSTRAINT cover_crop_pk PRIMARY KEY (covercropid),
  CONSTRAINT fk_cover_crop_treatment_trtid
    FOREIGN KEY (treatmentid)
    REFERENCES grp.treatment(treatmentid),
  CONSTRAINT fk_cover_crop_species_speciesid
    FOREIGN KEY (speciesid)
    REFERENCES grp.species(speciesid)
);

-- Add notes column to grazing table
ALTER TABLE grp.treatment_grazer
  ADD COLUMN notes text;
  
-- Drop maintenance_mowing from treatment
ALTER TABLE grp.treatment
  DROP COLUMN maintenance_mowing;

-- =====================================================
-- Change 006
-- Date: 2026-05-18
-- Description: Normalize paper/publication structure
-- =====================================================

-- Drop and rebuild the current paper-related structure because the database is currently empty.
DROP VIEW IF EXISTS grp.full_paper;
DROP TABLE IF EXISTS grp.paper_author;
DROP TABLE IF EXISTS grp.paper;

-- Recreate paper table
CREATE TABLE grp.paper (
  paperid integer GENERATED ALWAYS AS IDENTITY,
  publication_year integer,
  publication_title text,
  publication_journal text,
  publication_doi text,
  publication_url text,
  data_citation text,
  creativecommons_license text,
  use_conditions text,
  date_received date,
  CONSTRAINT paper_pkey PRIMARY KEY (paperid),
  CONSTRAINT publication_doi_unique UNIQUE (publication_doi)
);
  
-- Create project_paper table
CREATE TABLE grp.project_paper (
  database text NOT NULL,
  projectid integer NOT NULL,
  paperid integer NOT NULL,
  notes text,

  CONSTRAINT project_paper_pkey 
    PRIMARY KEY (database, projectid, paperid),

  CONSTRAINT fk_project_paper_project
    FOREIGN KEY (database, projectid)
    REFERENCES grp.project(database, projectid),

  CONSTRAINT fk_project_paper_paper
    FOREIGN KEY (paperid)
    REFERENCES grp.paper(paperid)
);

-- Recreate paper_author table
CREATE TABLE grp.paper_author (
  paperid integer NOT NULL,
  author_contributorid integer NOT NULL,
  is_corresponding_author boolean,
  
  CONSTRAINT pk_paper_author
    PRIMARY KEY (paperid, author_contributorid),
  
  CONSTRAINT fk_paper_author_paper
    FOREIGN KEY (paperid)
    REFERENCES grp.paper(paperid),
    
  CONSTRAINT fk_paper_author_author
    FOREIGN KEY (author_contributorid)
    REFERENCES grp.author_contributor(author_contributorid)
);

-- =====================================================
-- Change 005
-- Date: 2026-05-18
-- Description: Add depth to growth medium
-- =====================================================

-- Add two columns to treatment_medium: depth and units
ALTER TABLE grp.treatment_medium
  ADD COLUMN growth_medium_depth numeric,
  ADD COLUMN growth_medium_depth_units text;


-- =====================================================
-- Change 004
-- Date: 2026-05-17
-- Description: Add data dictionary infrastructure
-- =====================================================

-- Create table for storing schema metadata and workflow guidance
CREATE TABLE grp.data_dictionary (
    dictionaryid integer NOT NULL,
    table_name text NOT NULL,
    column_name text NOT NULL,
    display_order integer,
    data_type text NOT NULL,
    is_nullable text NOT NULL,
    definition text NOT NULL,
    workflow_notes text,
    allowed_values text,
    example text,
    legacy_notes text,
    qa_qc_notes text,
    external_source_notes text,
    CONSTRAINT data_dictionary_pkey PRIMARY KEY (dictionaryid),
    CONSTRAINT data_dictionary_unique
        UNIQUE (table_name, column_name),
    CONSTRAINT data_dictionary_is_nullable_check
        CHECK (is_nullable IN ('YES', 'NO'))
);

-- Populate metadata for import tracking tables
INSERT INTO grp.data_dictionary (
    dictionaryid,
    table_name,
    column_name,
    display_order,
    data_type,
    is_nullable,
    definition,
    workflow_notes,
    allowed_values,
    example,
    legacy_notes,
    qa_qc_notes,
    external_source_notes
)
VALUES

-- =====================================================
-- grp.import_batch
-- =====================================================

(1, 'import_batch', 'import_batchid', 1, 'integer', 'NO',
 'Unique identifier for one meaningful processing or upload event.',
 'Create one batch when a project undergoes a durable workflow step that future users may need to reconstruct.',
 NULL,
 '1',
 NULL,
 'Should be unique and never reused.',
 NULL),

(2, 'import_batch', 'database', 2, 'text', 'NO',
 'Database/workflow family associated with the processing batch.',
 'Use this to distinguish historical and current workflow streams.',
 'GAZP; GRP; OM',
 'OM',
 'GAZP = first-generation data; GRP = Emma-era workflow; OM = Oak Meadow redevelopment workflow.',
 'Must match allowed database CHECK constraint.',
 NULL),

(3, 'import_batch', 'projectid', 3, 'integer', 'YES',
 'GRP project identifier associated with the batch, if known.',
 'May remain blank during early processing stages before a SQL project record exists.',
 NULL,
 '14',
 NULL,
 'If populated, should correspond to the correct GRP project.',
 NULL),

(4, 'import_batch', 'source_folder', 4, 'text', 'YES',
 'Folder location or project folder used for the processing batch.',
 'Use as a breadcrumb trail to locate source materials later.',
 NULL,
 'OM/raw_files/2026_initial_processing',
 NULL,
 'Should be specific enough to relocate the source material.',
 NULL),

(5, 'import_batch', 'source_file_list', 5, 'text', 'YES',
 'List of source files used in the processing batch.',
 'Use semicolon-separated file names when multiple files were involved.',
 NULL,
 'treatments.xlsx; monitoring_2026.csv',
 NULL,
 'Should include all files needed to reconstruct the workflow step.',
 NULL),

(6, 'import_batch', 'pipeline_stage_start', 6, 'text', 'YES',
 'Starting workflow stage for the processing batch.',
 'Describes where the data existed before this processing step.',
 'contributor_raw; excel_database; input_format; sql_database',
 'contributor_raw',
 NULL,
 'Use consistent values across projects.',
 NULL),

(7, 'import_batch', 'pipeline_stage_end', 7, 'text', 'YES',
 'Ending workflow stage for the processing batch.',
 'Describes where the data existed after this processing step.',
 'excel_database; input_format; sql_database',
 'input_format',
 NULL,
 'Use consistent values across projects.',
 NULL),

(8, 'import_batch', 'processed_by', 8, 'text', 'YES',
 'Person responsible for the processing batch.',
 'Use a real name or consistent initials.',
 NULL,
 'Nancy',
 NULL,
 NULL,
 NULL),

(9, 'import_batch', 'processed_date', 9, 'date', 'YES',
 'Date the processing batch occurred or was recorded.',
 'Use the date when the durable processing decision or upload occurred.',
 NULL,
 '2026-05-16',
 NULL,
 'Use YYYY-MM-DD format.',
 NULL),

(10, 'import_batch', 'workflow_version', 10, 'text', 'YES',
 'Workflow or script version used during processing.',
 'Use readable workflow labels rather than only numeric versions.',
 NULL,
 'v2026_seedmix_revision',
 NULL,
 'Should help future users understand which workflow logic was applied.',
 NULL),

(11, 'import_batch', 'notes', 11, 'text', 'YES',
 'General notes about the processing batch.',
 'Use for interpretation decisions, warnings, or unusual workflow details.',
 NULL,
 'Contributor treatment T1 split into four GRP treatment events.',
 NULL,
 'Do not use as a substitute for object-level mapping details.',
 NULL),

-- =====================================================
-- grp.import_object_map
-- =====================================================

(12, 'import_object_map', 'import_object_mapid', 1, 'integer', 'NO',
 'Unique identifier for one source-to-GRP object mapping record.',
 'Each row represents one mapping between a source object and a GRP SQL object.',
 NULL,
 '1',
 NULL,
 'Should be unique and never reused.',
 NULL),

(13, 'import_object_map', 'import_batchid', 2, 'integer', 'NO',
 'Identifier for the processing batch where this mapping was created.',
 'Links the mapping record to the relevant import batch.',
 NULL,
 '1',
 NULL,
 'Must reference an existing import_batchid.',
 NULL),

(14, 'import_object_map', 'database', 3, 'text', 'NO',
 'Database/workflow family associated with the mapping.',
 'Should generally match the database value used in the related import batch.',
 'GAZP; GRP; OM',
 'OM',
 NULL,
 'Must match allowed database CHECK constraint.',
 NULL),

(15, 'import_object_map', 'projectid', 4, 'integer', 'YES',
 'GRP project identifier associated with the mapping, if known.',
 'May remain blank during early workflow stages before SQL project creation.',
 NULL,
 '14',
 NULL,
 'If populated, should correspond to the correct GRP project.',
 NULL),

(16, 'import_object_map', 'source_layer', 5, 'text', 'YES',
 'Workflow layer where the source object originated.',
 'Distinguishes contributor, Excel, and input-format workflow layers.',
 'contributor_raw; excel_database; input_format',
 'contributor_raw',
 NULL,
 'Use consistent values across projects.',
 NULL),

(17, 'import_object_map', 'source_object_type', 6, 'text', 'YES',
 'Type of source object being mapped.',
 'Use ecological/workflow terms such as treatment, plot, replicate, seed_mix, or veg_record.',
 NULL,
 'contributor_treatment',
 NULL,
 'Should describe the kind of thing represented in the source data.',
 NULL),

(18, 'import_object_map', 'source_object_id', 7, 'text', 'YES',
 'Original source ID or code, if one exists.',
 'Preserve contributor or workflow IDs exactly where possible.',
 NULL,
 'T1',
 NULL,
 'Avoid silently changing source identifiers.',
 NULL),

(19, 'import_object_map', 'source_object_label', 8, 'text', 'YES',
 'Human-readable source label.',
 'Use when a descriptive source name exists in addition to an ID.',
 NULL,
 'Seeded and mowed treatment',
 NULL,
 NULL,
 NULL),

(20, 'import_object_map', 'source_identifier_text', 9, 'text', 'YES',
 'Composite identifier used when no single source ID is sufficient.',
 'Build from the fields required to uniquely identify the source object.',
 NULL,
 'treatment=T1; plot=Plot 4; block=B; year=2021',
 NULL,
 'Should remain readable to future restoration researchers.',
 NULL),

(21, 'import_object_map', 'grp_object_type', 10, 'text', 'YES',
 'Type of GRP SQL object created or linked.',
 'Use GRP object terms such as treatment, area, seed_mix, seeding, or veg_result.',
 NULL,
 'treatment',
 NULL,
 'Should identify which GRP object/table the mapping references.',
 NULL),

(22, 'import_object_map', 'grp_object_id', 11, 'integer', 'YES',
 'GRP SQL identifier for the mapped object.',
 'Stores the relevant SQL identifier for the GRP object.',
 NULL,
 '104',
 NULL,
 'Interpret together with grp_object_type.',
 NULL),

(23, 'import_object_map', 'mapping_type', 12, 'text', 'YES',
 'Relationship between the source object and the GRP object.',
 'Documents whether objects were preserved, split, combined, derived, or uncertain.',
 'one_to_one; split; combined; derived; uncertain',
 'split',
 NULL,
 'Use split when one contributor object becomes multiple GRP objects.',
 NULL),

(24, 'import_object_map', 'mapping_notes', 13, 'text', 'YES',
 'Explanation of the mapping decision.',
 'Use for ecological interpretation, uncertainty, treatment splitting, or workflow warnings.',
 NULL,
 'Contributor treatment T1 included seeding in 2019 and mowing in 2020-2022, so it was split into multiple GRP treatment events.',
 NULL,
 'Should explain decisions that cannot be reconstructed from IDs alone.',
 NULL);

-- =====================================================
-- Change 003
-- Date: 2026-05-16
-- Description: Add import and source-to-GRP object tracking
-- =====================================================

-- Create table for recording meaningful processing/upload events
CREATE TABLE grp.import_batch (
    import_batchid integer NOT NULL,
    database text NOT NULL,
    projectid integer,
    source_folder text,
    source_file_list text,
    pipeline_stage_start text,
    pipeline_stage_end text,
    processed_by text,
    processed_date date,
    workflow_version text,
    notes text,
    CONSTRAINT import_batch_pkey PRIMARY KEY (import_batchid),
    CONSTRAINT import_batch_database_check
      CHECK (database IN ('GAZP', 'GRP', 'OM'))
);

-- Create table for mapping source/contributor objects to GRP SQL objects
CREATE TABLE grp.import_object_map (
    import_object_mapid integer NOT NULL,
    import_batchid integer NOT NULL,
    database text NOT NULL,
    projectid integer,
    source_layer text,
    source_object_type text,
    source_object_id text,
    source_object_label text,
    source_identifier_text text,
    grp_object_type text,
    grp_object_id integer,
    mapping_type text,
    mapping_notes text,
    CONSTRAINT import_object_map_pkey PRIMARY KEY (import_object_mapid),
    CONSTRAINT import_object_map_import_batchid_fkey
        FOREIGN KEY (import_batchid)
        REFERENCES grp.import_batch(import_batchid),
    CONSTRAINT import_object_map_database_check
      CHECK (database IN ('GAZP', 'GRP', 'OM'))
);

-- =====================================================
-- Change 002
-- Date:2026-05-15 (initiate)
-- Description: Normalize seed mix structure
-- =====================================================

-- Create seed mix table for treatment-specific seed/planting mix metadata
CREATE TABLE grp.seed_mix (
    seed_mixid integer NOT NULL,
    treatmentid integer NOT NULL,
    mix_name text,
    mix_composition_status text,
    treated_richness text,
    notes text,
    CONSTRAINT seed_mix_pkey PRIMARY KEY (seed_mixid),
    CONSTRAINT seed_mix_treatmentid_fkey
        FOREIGN KEY (treatmentid)
        REFERENCES grp.treatment(treatmentid)
);

-- Add required seed mix link to species-level seeding rows
ALTER TABLE grp.seeding
ADD COLUMN seed_mixid integer NOT NULL;

-- Add seed mix link to species-level seeding rows
ALTER TABLE grp.seeding
ADD CONSTRAINT seeding_seed_mixid_fkey
    FOREIGN KEY (seed_mixid)
    REFERENCES grp.seed_mix(seed_mixid);

-- Add optional notes field for species-level seeding rows
ALTER TABLE grp.seeding
ADD COLUMN notes text;

-- =====================================================
-- Change 001
-- Date: 2026-05-14
-- Description: Add general notes column to treatment table
-- =====================================================

ALTER TABLE grp.treatment
ADD COLUMN notes text;
