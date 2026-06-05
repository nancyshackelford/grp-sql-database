-- =====================================================
-- Species Table Refinement
-- Change 018: Species table refinement
-- Date: 2026-06-05
-- Purpose: Add lifeform lookup table definitions
-- =====================================================

-- Populate definition and notes for grp.lifeform 

UPDATE grp.lifeform
SET
    definition = CASE type
        WHEN 'shrub' THEN 'Woody perennial plant with multiple stems and generally shorter stature than a tree.'
        WHEN 'tree' THEN 'Woody perennial plant with one or more main stems and generally taller stature.'
        WHEN 'forb' THEN 'Herbaceous flowering plant that is not a grass, sedge, or rush.'
        WHEN 'moss' THEN 'Non-vascular bryophyte plant, typically low-growing and spore-producing.'
        WHEN 'grass' THEN 'Graminoid plant in the grass family, Poaceae.'
        WHEN 'fungus' THEN 'Non-photosynthetic organism in the kingdom Fungi.'
        WHEN 'fern' THEN 'Vascular, spore-producing plant without seeds or flowers.'
        WHEN 'lichen' THEN 'Composite organism formed by a fungus living in association with photosynthetic partners.'
        WHEN 'liverwort' THEN 'Non-vascular bryophyte plant, typically flattened or leafy and spore-producing.'
        WHEN 'palm' THEN 'Woody monocot plant in the palm family, Arecaceae.'
        WHEN 'vine' THEN 'Plant with a climbing, trailing, or twining growth form.'
        WHEN 'succulent' THEN 'Plant with thickened tissues adapted for water storage.'
    END,
    notes = CASE type
        WHEN 'grass' THEN 'Use for grasses only; other graminoids may require separate categories if present in source data.'
        WHEN 'forb' THEN 'Use lifespan table to distinguish annual, biennial, or perennial forb records.'
        WHEN 'tree' THEN 'Use for woody taxa treated as trees in source data.'
        WHEN 'shrub' THEN 'Use for woody taxa treated as shrubs in source data.'
        ELSE NULL
    END
WHERE type IN (
    'shrub',
    'tree',
    'forb',
    'moss',
    'grass',
    'fungus',
    'fern',
    'lichen',
    'liverwort',
    'palm',
    'vine',
    'succulent'
);