-- =====================================================
-- Species Table Refinement
-- Change 018: Species table refinement
-- Date: 2026-06-05
-- Purpose: Add lifeform lookup table and replace lifeform constraint with FK
-- =====================================================

-- Create lifeform lookup table

CREATE TABLE IF NOT EXISTS grp.lifeform (
    type text PRIMARY KEY,
    definition text,
    notes text
);

INSERT INTO grp.lifeform (type, definition, notes)
VALUES
    ('shrub', NULL, NULL),
    ('tree', NULL, NULL),
    ('forb', NULL, NULL),
    ('moss', NULL, NULL),
    ('grass', NULL, NULL),
    ('fungus', NULL, NULL),
    ('fern', NULL, NULL),
    ('lichen', NULL, NULL),
    ('liverwort', NULL, NULL),
    ('palm', NULL, NULL),
    ('vine', NULL, NULL),
    ('succulent', NULL, NULL)
ON CONFLICT (type) DO NOTHING;

-- Replace lifeform constraint with look up FK

ALTER TABLE grp.species
DROP CONSTRAINT IF EXISTS lifeform_check;

ALTER TABLE grp.species
ADD CONSTRAINT "FK_Species.Lifeform"
FOREIGN KEY (lifeform)
REFERENCES grp.lifeform(type);