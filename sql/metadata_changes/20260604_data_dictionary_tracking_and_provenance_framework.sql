-- =====================================================
-- Data Dictionary Update
-- Related Change ID: Change 017
-- Description: Import tracking and provenance framework
-- =====================================================

-- Remove dictionary entries for dropped table
DELETE FROM grp.data_dictionary
WHERE table_name = 'import_object_map';

-- =====================================================
-- import_project
-- =====================================================

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
VALUES

('import_project','import_projectid',1,'integer','NO',
'Unique identifier for one project-specific contribution or import event.',
'One project may have multiple import events over time. Each import event receives a unique identifier.',
NULL,
'1',
NULL,
'Should be unique and never reused.',
NULL),

('import_project','import_batchid',2,'integer','NO',
'Identifier linking this project import event to a broader import batch.',
'Allows multiple projects to be processed together as part of a single import workflow.',
NULL,
'3',
NULL,
'Must reference an existing import_batch record.',
NULL),

('import_project','database',3,'text','NO',
'Source database or workflow family associated with the project import.',
'Combined with projectid to identify projects originating from different historical workflow systems.',
'GAZP; GRP; OM',
'GRP',
'GAZP = first-generation harmonized database. GRP = Emma-era workflow with transformation tracking. OM = Oak Meadow redevelopment workflow.',
'Should match controlled vocabulary and project source.',
NULL),

('import_project','projectid',4,'integer','YES',
'GRP project identifier associated with the import event.',
'May remain NULL during early staging before a project has been matched to a GRP project record.',
NULL,
'105',
NULL,
'If populated, should reference an existing project record.',
NULL),

('import_project','contribution_type',6,'text','YES',
'Type of contribution represented by the import event.',
'Describes why the import occurred and how it relates to previous project imports.',
'initial_import; additional_contribution; correction; reprocessing; test_import',
'additional_contribution',
NULL,
'Must match controlled vocabulary.',
NULL),

('import_project','contribution_period',7,'text','YES',
'Time period represented by the contributed data.',
'Records the monitoring years, field season, or temporal coverage represented by the imported contribution.',
NULL,
'2024 field season',
NULL,
'Should describe the data represented, not the date the files were received.',
NULL),

('import_project','documentation_tier',8,'text','YES',
'Level of workflow documentation and reproducibility available for the imported project.',
'Used to distinguish minimally documented legacy projects from fully reproducible workflows.',
'legacy_minimal; legacy_documented; transformation_documented; fully_reproducible',
'transformation_documented',
'Legacy GAZP and early GRP projects may not meet current documentation standards.',
'Must match controlled vocabulary.',
NULL),

('import_project','import_status',9,'text','YES',
'Current status of the project import workflow.',
'Tracks progress through staging, validation, and final import.',
'planned; staged; validated; imported; failed; skipped',
'validated',
NULL,
'Must match controlled vocabulary.',
NULL),

('import_project','import_started_at',10,'timestamp without time zone','YES',
'Timestamp when work began on the project import.',
'Used to track workflow duration and processing history.',
NULL,
'2026-05-30 09:00:00',
NULL,
'Should not occur after import_completed_at.',
NULL),

('import_project','import_completed_at',11,'timestamp without time zone','YES',
'Timestamp when work concluded on the project import.',
'May represent successful completion, failure, or abandonment of an import attempt.',
NULL,
'2026-05-30 14:00:00',
NULL,
'Should not occur before import_started_at.',
NULL),

('import_project','supersedes_import_projectid',12,'integer','YES',
'Identifier of an earlier import_project record replaced by this import event.',
'Supports correction workflows, reprocessing, and replacement contributions.',
NULL,
'12',
NULL,
'Should only reference a prior import_project record.',
NULL),

('import_project','is_current_version',13,'boolean','YES',
'Indicates whether this import event represents the current active version of the contributed data.',
'Older imports may remain in the database for provenance purposes but be marked as not current.',
'true; false',
'true',
NULL,
'Normally only one current version should exist for a given project contribution lineage.',
NULL),

('import_project','notes',14,'text','YES',
'Additional notes describing the import event.',
'Use for workflow context, decisions, caveats, or information not captured elsewhere.',
NULL,
'Pilot import used to test GRP provenance framework.',
NULL,
'Should not replace structured documentation stored elsewhere.',
NULL);

-- =====================================================
-- import_artifact
-- =====================================================

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
VALUES
('import_artifact','import_artifactid',1,'integer','NO',
'Unique identifier for one import artifact.',
'One row should represent one file or file-like provenance object.',
NULL,'1',
NULL,'Should be unique and never reused.',NULL),

('import_artifact','import_projectid',2,'integer','NO',
'Identifier linking the artifact to a specific project import event.',
'Use this as the main link between project-level import tracking and the files or provenance objects associated with that import.',
NULL,'12',
NULL,'Must reference an existing import_project record.',NULL),

('import_artifact','import_batchid',3,'integer','NO',
'Identifier linking the artifact to the broader import batch.',
'Allows artifacts to be grouped by the processing batch in which they were registered or used.',
NULL,'3',
NULL,'Must reference an existing import_batch record.',NULL),

('import_artifact','database',4,'text','NO',
'Source database or workflow family associated with the artifact.',
'Used with projectid to connect artifacts to the correct source project identity.',
'GAZP; GRP; OM','GRP',
'Older workflow families may have different documentation standards.',
'Should match the associated import_project database.',NULL),

('import_artifact','projectid',5,'integer','YES',
'Project identifier associated with the artifact within its source database.',
'May remain NULL during early staging before the artifact has been matched to a project record.',
NULL,'105',
NULL,'If populated, must align with the associated database and import_project.',NULL),

('import_artifact','artifact_type',6,'text','NO',
'General category of artifact.',
'Use this to distinguish raw files, harmonized files, code, mapping tables, transformation tables, outputs, metadata, notes, and other provenance materials.',
'raw_data; harmonized_data; transformation_code; mapping_table; transformation_table; processed_output; metadata; notes; other',
'transformation_table',
NULL,'Must match controlled vocabulary.',NULL),

('import_artifact','artifact_subtype',7,'text','YES',
'More specific classification of the artifact.',
'Use to identify domains or purposes such as species mapping, plot mapping, treatment mapping, trait transformation, or QA notes.',
NULL,'species_code_map',
NULL,'Should be consistent enough to support searching and filtering.',NULL),

('import_artifact','file_name',8,'text','YES',
'Name of the artifact file.',
'Record the exact file name where possible.',
NULL,'GRP_105_new_species_codes.csv',
NULL,'Should match the stored or received file name.',NULL),

('import_artifact','file_extension',9,'text','YES',
'File extension or file format.',
'Use to support filtering and file handling.',
NULL,'csv',
NULL,'Should match the actual file format.',NULL),

('import_artifact','file_path_or_storage_key',10,'text','YES',
'Path, URL key, or object storage key where the artifact can be located.',
'Use this to locate the file in Supabase Storage or another managed storage system.',
NULL,'grp-import-artifacts/GRP_105/GRP_105_new_species_codes.csv',
NULL,'Should be stable enough for future users to retrieve the artifact.',NULL),

('import_artifact','storage_bucket',11,'text','YES',
'Supabase storage bucket or equivalent storage grouping containing the artifact.',
'Use when artifacts are stored in object storage.',
NULL,'grp-import-artifacts',
NULL,'Should correspond to an actual storage bucket or managed storage location when used.',NULL),

('import_artifact','file_hash',12,'text','YES',
'Checksum or hash value for the artifact file.',
'Use for file fixity checks and to detect whether an artifact has changed.',
NULL,'sha256:abc123...',
NULL,'Should be generated consistently if used.',NULL),

('import_artifact','source_layer',13,'text','YES',
'Workflow layer represented by the artifact.',
'Use to describe whether the artifact belongs to raw, intermediate, harmonized, import-ready, or output stages.',
NULL,'intermediate',
NULL,'Should help reconstruct the artifact position in the workflow.',NULL),

('import_artifact','workflow_stage',14,'text','YES',
'Named workflow stage associated with the artifact.',
'Use to connect the artifact to a specific processing stage such as species standardization or treatment harmonization.',
NULL,'species_code_standardization',
NULL,'Should be used consistently within a project workflow.',NULL),

('import_artifact','created_by',15,'text','YES',
'Person or system that created the artifact, if known.',
'Use especially for transformation code, mapping tables, and processed outputs.',
NULL,'Emma',
NULL,'Do not invent if unknown.',NULL),

('import_artifact','created_date',16,'date','YES',
'Date the artifact was created, if known.',
'Use only when the date is known from reliable metadata or documentation.',
NULL,'2021-07-15',
NULL,'Should not imply precision when the date is approximate or unknown.',NULL),

('import_artifact','loaded_at',17,'timestamp without time zone','YES',
'Timestamp when the artifact was registered or loaded into the import tracking system.',
'Use to track when the database catalogue record was created or populated.',
NULL,'2026-05-30 10:00:00',
NULL,'Should reflect database registration/loading, not necessarily file creation.',NULL),

('import_artifact','notes',18,'text','YES',
'Additional notes about the artifact.',
'Use for interpretation, caveats, unresolved questions, or context not captured elsewhere.',
NULL,'Mapping table created during species harmonization.',
NULL,'Should not replace transformation step documentation or validation issue tracking.',NULL);

-- =====================================================
-- import_transformation_step
-- =====================================================

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
VALUES
('import_transformation_step','import_transformation_stepid',1,'integer','NO',
'Unique identifier for one documented transformation step.',
'One row should represent one ordered step in the workflow that converts contributed or raw data toward import-ready GRP data.',
NULL,'1',NULL,'Should be unique and never reused.',NULL),

('import_transformation_step','import_projectid',2,'integer','NO',
'Identifier linking the transformation step to a specific project import event.',
'Use this as the main project-level anchor for transformation workflow documentation.',
NULL,'12',NULL,'Must reference an existing import_project record.',NULL),

('import_transformation_step','import_batchid',3,'integer','NO',
'Identifier linking the transformation step to the broader import batch.',
'Allows transformation steps to be grouped by processing batch.',
NULL,'3',NULL,'Must reference an existing import_batch record.',NULL),

('import_transformation_step','database',4,'text','NO',
'Source database or workflow family associated with the transformation step.',
'Used with projectid to connect the transformation step to the correct source project identity.',
'GAZP; GRP; OM','GRP',NULL,'Should match the associated import_project database.',NULL),

('import_transformation_step','projectid',5,'integer','YES',
'Project identifier associated with the transformation step within its source database.',
'May remain NULL during early staging before the transformation workflow has been matched to a project record.',
NULL,'105',NULL,'If populated, must align with database and import_project.',NULL),

('import_transformation_step','step_order',6,'integer','NO',
'Order of the transformation step within the project import workflow.',
'Use sequential numbering to reconstruct the workflow from raw or contributed data to import-ready data.',
NULL,'1',NULL,'Must be greater than zero. Should normally be unique within one import_project workflow.',NULL),

('import_transformation_step','step_name',7,'text','NO',
'Short name for the transformation step.',
'Use concise names that identify the purpose of the step.',
NULL,'Standardize species codes',NULL,'Should be interpretable without opening the code file.',NULL),

('import_transformation_step','step_description',8,'text','YES',
'Description of what the transformation step does.',
'Use to summarize the step logic, including what it changes, what inputs it uses, and what outputs it creates.',
NULL,'Replaces contributor species codes with GRP-standard species codes using a mapping table.',
NULL,'Should be specific enough to support troubleshooting and reproducibility.',NULL),

('import_transformation_step','transformation_type',9,'text','YES',
'General category of transformation performed.',
'Use for filtering and summarizing workflow logic across projects.',
NULL,'identifier_crosswalk',
NULL,'Should be named consistently across projects where possible.',NULL),

('import_transformation_step','software_or_language',10,'text','YES',
'Software, programming language, or tool used for the transformation.',
'Use to support reproducibility and future maintenance of import workflows.',
NULL,'R',
NULL,'Should identify the main tool used, not every dependency.',NULL),

('import_transformation_step','notes',11,'text','YES',
'Additional notes about the transformation step.',
'Use for caveats, unresolved interpretation, missing code, or context not captured elsewhere.',
NULL,'Original code not found; mapping table preserved as artifact.',
NULL,'Should not replace artifact links or validation issue tracking.',NULL);

-- =====================================================
-- import_transformation_step_artifact
-- =====================================================

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
VALUES
('import_transformation_step_artifact','import_transformation_step_artifactid',1,'integer','NO',
'Unique identifier for one relationship between a transformation step and an import artifact.',
'Use this bridge table because one transformation step may use or create multiple artifacts, and one artifact may be involved in multiple steps.',
NULL,'1',NULL,'Should be unique and never reused.',NULL),

('import_transformation_step_artifact','import_transformation_stepid',2,'integer','NO',
'Identifier of the transformation step associated with the artifact.',
'Links an artifact to a specific ordered workflow step.',
NULL,'5',NULL,'Must reference an existing import_transformation_step record.',NULL),

('import_transformation_step_artifact','import_artifactid',3,'integer','NO',
'Identifier of the artifact associated with the transformation step.',
'Links files, code, mapping tables, outputs, metadata, or documentation to a workflow step.',
NULL,'42',NULL,'Must reference an existing import_artifact record.',NULL),

('import_transformation_step_artifact','artifact_role',4,'text','NO',
'Role of the artifact within the transformation step.',
'Use this to distinguish whether the artifact was an input, output, code file, lookup, mapping, documentation file, or other supporting object.',
'input; output; code; lookup; mapping; documentation; other',
'mapping',
NULL,'Must match controlled vocabulary.',NULL),

('import_transformation_step_artifact','notes',5,'text','YES',
'Additional notes about the artifact role in the transformation step.',
'Use when the relationship between the artifact and the step needs explanation.',
NULL,'Mapping file used to translate contributor plot codes to GRP area identifiers.',
NULL,'Should not duplicate the artifact description unless additional context is needed.',NULL);

-- =====================================================
-- project_object_crosswalk
-- =====================================================

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
VALUES
('project_object_crosswalk','project_object_crosswalkid',1,'integer','NO',
'Unique identifier for one contributor-to-GRP object mapping.',
'Use this table for reusable operational mappings needed for future contributions or repeat imports.',
NULL,'1',NULL,'Should be unique and never reused.',NULL),

('project_object_crosswalk','database',2,'text','NO',
'Source database or workflow family associated with the crosswalk.',
'Used with projectid to identify the correct project namespace for contributor object codes.',
'GAZP; GRP; OM','GRP',NULL,'Should match the associated project database.',NULL),

('project_object_crosswalk','projectid',3,'integer','NO',
'Project identifier associated with the crosswalk within its source database.',
'Contributor object codes are project-specific and should be interpreted within the database plus projectid namespace.',
NULL,'105',NULL,'Must align with database and reference an existing project identity.',NULL),

('project_object_crosswalk','import_projectid',4,'integer','YES',
'Project import event that created or updated the object mapping.',
'Use to trace the crosswalk back to the import event where it was established.',
NULL,'12',NULL,'Should reference import_project when known.',NULL),

('project_object_crosswalk','object_type',5,'text','NO',
'Type of contributor object being mapped.',
'Use to distinguish project, site, area, plot, subplot, treatment, species, sample, observation, or other object types.',
'project; site; area; plot; subplot; treatment; species; sample; observation; other',
'plot',
NULL,'Must match controlled vocabulary.',NULL),

('project_object_crosswalk','contributor_object_code',6,'text','NO',
'Original or contributor-facing object code.',
'Use this to match future contributed data back to the correct GRP object.',
NULL,'A12',NULL,'Should preserve contributor spelling and capitalization unless a separate standardized code is documented.',NULL),

('project_object_crosswalk','contributor_object_label',7,'text','YES',
'Contributor-facing object label or name.',
'Use when the source files include a descriptive label in addition to a code.',
NULL,'Plot A12 north meadow',
NULL,'Should not be used as the primary join key if contributor_object_code is available.',NULL),

('project_object_crosswalk','contributor_object_description',8,'text','YES',
'Description of the contributor object.',
'Use for additional context about the source object being mapped.',
NULL,'Permanent vegetation plot in restored meadow area.',
NULL,'Should not replace formal site or area descriptions in core GRP tables.',NULL),

('project_object_crosswalk','grp_object_type',9,'text','NO',
'Type of GRP object represented by the mapping target.',
'Use to clarify whether the contributor object maps to a GRP site, area, treatment, species, sample, observation, or other object.',
NULL,'area',
NULL,'Should correspond to the target table or object concept.',NULL),

('project_object_crosswalk','grp_object_id',10,'integer','YES',
'Identifier of the corresponding GRP object.',
'Use the relevant SQL identifier from the target table when available.',
NULL,'847',
NULL,'Because this is a generic target field, QA/QC must confirm it points to a valid object of the stated grp_object_type.',NULL),

('project_object_crosswalk','grp_object_code',11,'text','YES',
'GRP-facing stable object code, if one is used.',
'Use when a stable GRP code exists in addition to the numeric SQL identifier.',
NULL,'GRP105_AREA_01',
NULL,'Should remain stable once used for future imports.',NULL),

('project_object_crosswalk','valid_from',12,'date','YES',
'Date from which the mapping is considered valid.',
'Use when contributor codes or GRP mappings change over time.',
NULL,'2020-01-01',
NULL,'Should be earlier than or equal to valid_to when both are populated.',NULL),

('project_object_crosswalk','valid_to',13,'date','YES',
'Date until which the mapping is considered valid.',
'Use to close out superseded or time-limited mappings.',
NULL,'2024-12-31',
NULL,'Should be later than or equal to valid_from when both are populated.',NULL),

('project_object_crosswalk','is_current',14,'boolean','YES',
'Indicates whether this mapping is currently active.',
'Use false for superseded mappings while preserving historical traceability.',
'true; false',
'true',
NULL,'Only one current mapping should normally exist for the same project, object type, and contributor code.',NULL),

('project_object_crosswalk','created_at',15,'timestamp without time zone','YES',
'Timestamp when the crosswalk record was created.',
'Defaults to the time the row is inserted.',
NULL,'2026-05-30 10:00:00',
NULL,'Should reflect database record creation, not necessarily original data creation.',NULL),

('project_object_crosswalk','notes',16,'text','YES',
'Additional notes about the mapping.',
'Use for uncertainty, interpretation, or links to supporting artifacts.',
NULL,'Confirmed from Emma mapping table and harmonized project workbook.',
NULL,'Should not replace import artifact or transformation documentation.',NULL);

-- =====================================================
-- import_validation_issue
-- =====================================================

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
VALUES
('import_validation_issue','import_validation_issueid',1,'integer','NO',
'Unique identifier for one import validation issue.',
'One row should represent one warning, error, blocker, schema gap, or other issue encountered during import.',
NULL,'1',
NULL,'Should be unique and never reused.',NULL),

('import_validation_issue','import_batchid',2,'integer','NO',
'Identifier linking the issue to the import batch where it was detected.',
'Allows issues to be grouped and reviewed at the batch level.',
NULL,'3',
NULL,'Must reference an existing import_batch record.',NULL),

('import_validation_issue','import_projectid',3,'integer','YES',
'Identifier linking the issue to a specific project import event.',
'Use when the issue can be associated with a single project import.',
NULL,'12',
NULL,'Should reference an existing import_project record when known.',NULL),

('import_validation_issue','database',4,'text','NO',
'Source database or workflow family associated with the issue.',
'Used with projectid to identify the project namespace where the issue occurred.',
'GAZP; GRP; OM',
'GRP',
NULL,
'Should match the associated import project and source data.',NULL),

('import_validation_issue','projectid',5,'integer','YES',
'Project identifier associated with the issue within its source database.',
'May remain NULL when the issue occurs before project matching or assignment.',
NULL,
'105',
NULL,
'If populated, must align with database and project records.',NULL),

('import_validation_issue','import_artifactid',6,'integer','YES',
'Artifact associated with the issue.',
'Use when the issue can be traced to a specific file, code object, mapping table, or other artifact.',
NULL,
'42',
NULL,
'Should reference an existing import_artifact record when known.',NULL),

('import_validation_issue','source_file',7,'text','YES',
'Source file where the issue was detected.',
'Record the file name or source object that generated the issue.',
NULL,
'raw_vegetation.xlsx',
NULL,
'Should match the artifact or source file when available.',NULL),

('import_validation_issue','source_sheet',8,'text','YES',
'Worksheet, tab, or source subdivision where the issue was detected.',
'Useful for Excel-based workflows and multi-tab workbooks.',
NULL,
'Species',
NULL,
'Should match the source workbook structure.',NULL),

('import_validation_issue','source_row_number',9,'integer','YES',
'Row number where the issue was detected.',
'Use when a specific source row can be identified.',
NULL,
'347',
NULL,
'Should correspond to the original source file row numbering system.',NULL),

('import_validation_issue','source_column',10,'text','YES',
'Column where the issue was detected.',
'Use when a specific source field can be identified.',
NULL,
'species_code',
NULL,
'Should match the original source column name whenever possible.',NULL),

('import_validation_issue','target_table',11,'text','YES',
'GRP table affected by the issue.',
'Use when the issue occurs during loading, transformation, or validation against a target table.',
NULL,
'species',
NULL,
'Should match an existing GRP table when applicable.',NULL),

('import_validation_issue','target_column',12,'text','YES',
'GRP column affected by the issue.',
'Use when the issue can be linked to a specific target field.',
NULL,
'speciesid',
NULL,
'Should match an existing GRP column when applicable.',NULL),

('import_validation_issue','issue_type',13,'text','NO',
'Category of validation issue.',
'Use standardized categories to support QA/QC reporting and workflow improvement.',
'missing_required_value; lookup_mismatch; species_code_not_found; duplicate_key; date_parse_error; schema_gap; unmapped_object; unexpected_value; data_type_mismatch; referential_integrity_issue; other',
'lookup_mismatch',
NULL,
'Must match controlled vocabulary.',NULL),

('import_validation_issue','issue_severity',14,'text','NO',
'Severity level of the issue.',
'Use to distinguish informational findings from blockers that prevent import.',
'info; warning; error; blocker',
'warning',
NULL,
'Must match controlled vocabulary.',NULL),

('import_validation_issue','raw_value',15,'text','YES',
'Original value that triggered the issue.',
'Use to preserve problematic values for troubleshooting and resolution.',
NULL,
'PSEUMEN',
NULL,
'Should capture the original value exactly when practical.',NULL),

('import_validation_issue','suggested_resolution',16,'text','YES',
'Suggested approach for resolving the issue.',
'Use for automated recommendations, reviewer guidance, or workflow documentation.',
NULL,
'Map contributor code PSEUMEN to PSEUMEN_TRI.',
NULL,
'Should not imply that the resolution has been accepted or applied.',NULL),

('import_validation_issue','resolved',17,'boolean','YES',
'Indicates whether the issue has been resolved.',
'Use to support tracking of outstanding and completed QA/QC work.',
'true; false',
'false',
NULL,
'Should only be marked true when resolution has been completed and verified.',NULL),

('import_validation_issue','resolved_at',18,'timestamp without time zone','YES',
'Timestamp when the issue was resolved.',
'Use when resolution tracking is required.',
NULL,
'2026-06-01 14:30:00',
NULL,
'Should normally be populated when resolved = true.',NULL),

('import_validation_issue','resolution_notes',19,'text','YES',
'Description of how the issue was resolved.',
'Use to document decisions, corrections, mappings, or workflow changes applied during resolution.',
NULL,
'Species code added to lookup table and validated.',
NULL,
'Should provide enough detail for future reviewers to understand the resolution.',NULL),

('import_validation_issue','notes',20,'text','YES',
'Additional notes about the issue.',
'Use for context, interpretation, uncertainty, or reviewer comments.',
NULL,
'Contributor documentation suggests this may be a legacy code.',
NULL,
'Should not replace structured issue fields when those fields are available.',NULL);