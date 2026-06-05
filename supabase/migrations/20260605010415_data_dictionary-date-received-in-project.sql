INSERT INTO grp.data_dictionary (
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
VALUES (
    'project',
    'date_received',
    6,
    'date',
    'YES',
    'Date the project dataset was received by the GRP database workflow.',
    'Use to distinguish legacy datasets from newer contributions and to track when data entered the GRP data management process.',
    NULL,
    '2024-03-15',
    'Many legacy projects will use approximate dates representing broader collection periods rather than actual receipt dates.',
    'Should reflect the best available estimate of when the dataset entered GRP stewardship. May be approximate for historical imports.',
    'For historical imports, GAZP projects may be assigned a generalized date range representing 2018–2019 acquisition and GRP projects may be assigned a generalized date range representing 2020–2024 acquisition.'
);