/* ============================================================
   Data dictionary updates: new lifeform lookup table
   ============================================================ */


/* 1. Insert dictionary entry for lifeform.type */

INSERT INTO grp.data_dictionary (
    table_name,
    column_name,
    data_type,
    is_nullable,
    definition,
    workflow_notes,
    allowed_values,
    example,
    legacy_notes,
    qa_qc_notes,
    external_source_notes,
    display_order
)
SELECT
    'lifeform',
    'type',
    'text',
    'NO',
    'Primary lookup value describing the growth form or organism form assigned to a species.',
    'Used as the lookup target for grp.species.lifeform. Source values that combine lifespan and lifeform should be split before import.',
    'shrub; tree; forb; moss; grass; fungus; fern; lichen; liverwort; palm; vine; succulent',
    'forb',
    NULL,
    'Referenced by grp.species.lifeform. Values must be present here before they can be used in the species table.',
    NULL,
    1
WHERE NOT EXISTS (
    SELECT 1
    FROM grp.data_dictionary
    WHERE table_name = 'lifeform'
      AND column_name = 'type'
);


/* 2. Insert dictionary entry for lifeform.definition */

INSERT INTO grp.data_dictionary (
    table_name,
    column_name,
    data_type,
    is_nullable,
    definition,
    workflow_notes,
    allowed_values,
    example,
    legacy_notes,
    qa_qc_notes,
    external_source_notes,
    display_order
)
SELECT
    'lifeform',
    'definition',
    'text',
    'YES',
    'Definition of the lifeform lookup value.',
    'Used to clarify interpretation of lifeform categories during import, QA/QC, and analysis.',
    NULL,
    'Herbaceous flowering plant that is not a grass, sedge, or rush.',
    NULL,
    'Review definitions if additional lifeform categories are added.',
    NULL,
    2
WHERE NOT EXISTS (
    SELECT 1
    FROM grp.data_dictionary
    WHERE table_name = 'lifeform'
      AND column_name = 'definition'
);


/* 3. Insert dictionary entry for lifeform.notes */

INSERT INTO grp.data_dictionary (
    table_name,
    column_name,
    data_type,
    is_nullable,
    definition,
    workflow_notes,
    allowed_values,
    example,
    legacy_notes,
    qa_qc_notes,
    external_source_notes,
    display_order
)
SELECT
    'lifeform',
    'notes',
    'text',
    'YES',
    'Additional notes about use, interpretation, or limits of the lifeform lookup value.',
    'Use for implementation notes, category caveats, or source-data interpretation issues.',
    NULL,
    'Use lifespan table to distinguish annual, biennial, or perennial forb records.',
    NULL,
    'Review notes when reconciling source values that combine lifespan and lifeform.',
    NULL,
    3
WHERE NOT EXISTS (
    SELECT 1
    FROM grp.data_dictionary
    WHERE table_name = 'lifeform'
      AND column_name = 'notes'
);


/* 4. Update species.lifeform dictionary entry */

UPDATE grp.data_dictionary
SET
    definition = 'Lifeform category assigned to the species.',
    workflow_notes = 'Must match an existing value in grp.lifeform.type. Source values that combine lifespan and lifeform should be split before import, with lifespan stored in grp.species_lifespan.type.',
    allowed_values = 'Values from grp.lifeform.type.',
    example = 'forb',
    qa_qc_notes = 'Foreign key constrained to grp.lifeform(type). Check source data for combined values such as annual forb or perennial grass before import.'
WHERE table_name = 'species'
  AND column_name = 'lifeform';