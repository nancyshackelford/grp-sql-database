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
