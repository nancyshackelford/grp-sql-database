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
