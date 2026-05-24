-- =====================================================
-- View Dictionary Updates
-- Related Change ID: Change 014
-- Date: 2026-05-23
-- Description: Update view descriptions after splitting project data accessibility from paper/project metadata
-- =====================================================

UPDATE grp.view_dictionary
SET
    purpose = 'Provides publication/source metadata associated with projects through the project-paper relationship.',
    expected_row_grain = 'One row per project-paper relationship.',
    key_assumptions = 'Papers are standalone publication/source entities. Project-paper relationships may be many-to-many. Dataset accessibility is not paper metadata.',
    known_limitations = 'Does not include project dataset accessibility metadata. Data accessibility is stored in grp.project_data_accessibility and exposed through grp.full_project.',
    notes = 'Updated during Change 014 after moving dataset accessibility fields out of grp.paper.'
WHERE view_name = 'full_paper';


UPDATE grp.view_dictionary
SET
    purpose = 'Provides project-level metadata, including contributors, locations, vegetation metrics, and aggregated project dataset accessibility metadata.',
    expected_row_grain = 'One row per project.',
    key_assumptions = 'Project data accessibility is project-level metadata and may eventually include multiple records per project.',
    known_limitations = 'Data accessibility fields are aggregated from grp.project_data_accessibility, so multiple accessibility records will be collapsed into semicolon-separated values.',
    notes = 'Updated during Change 014 after moving dataset accessibility into grp.project_data_accessibility. Aggregation preserves one row per project.'
WHERE view_name = 'full_project';

-- =====================================================
-- Change 013
-- Date: 2026-05-22
-- Description: Create and populate view dictionary
-- =====================================================

INSERT INTO grp.view_dictionary (
    view_name,
    display_order,
    view_level,
    primary_table,
    is_denormalized,
    purpose,
    expected_row_grain,
    key_assumptions,
    known_limitations,
    notes
)
VALUES
('full_area', 1, 'reporting', 'area', TRUE,
 'Flattened area-level view for querying replicate areas with project/site context, parent block/subblock context, and associated treatment IDs.',
 'One row per non-block, non-subblock area.',
 'Area hierarchy uses parentid to infer block and subblock relationships. Treatment IDs are aggregated as text. Blocks and subblocks are excluded as primary rows.',
 'Does not return block or subblock areas as their own rows. Multiple area-treatment relationships are flattened into a comma-separated treatmentids field.',
 NULL),

('full_cultivar', 2, 'entity', 'cultivar', FALSE,
 'Cultivar view with linked species code and cultivar origin/location information.',
 'One row per cultivar.',
 'Each cultivar links to species through speciesid.',
 'Does not aggregate multiple species or other cultivar-related records.',
 NULL),

('full_individual', 3, 'reporting', 'individual', TRUE,
 'Individual plant view with project context, replicate area, species code, location, and initial measurement information.',
 'One row per individual-area-treatment/project association.',
 'Individuals are linked to project context through area_treatment using areaid. Species code is joined from species.',
 'If an area is linked to multiple treatments or projects, individual rows may be repeated across those associations.',
 NULL),

('full_paper', 4, 'reporting', 'paper', TRUE,
 'Paper/reference view with project association, author list, corresponding author details, citation/access fields, and project-paper notes.',
 'One row per project-paper relationship.',
 'Authors and corresponding authors are aggregated into semicolon-separated text fields.',
 'Author order and corresponding author details are flattened. A paper linked to multiple projects appears once per project-paper relationship.',
 NULL),

('full_project', 5, 'reporting', 'project', TRUE,
 'Project-level view with contributor, location, vegetation metric, community, reference, availability, and notes fields flattened for querying.',
 'One row per project, assuming joined project metadata aggregates cleanly.',
 'Contributors, contributor emails, locations, and vegetation metrics are aggregated into text fields.',
 'Multi-valued project metadata is flattened. Unexpected many-to-many combinations across contributors, locations, and vegmetrics could affect aggregation behavior.',
 NULL),

('full_seeding', 6, 'reporting', 'seeding', TRUE,
 'Seeding view with seed mix details, species/cultivar links, seeding rate, viability, pretreatment, origin/source, distance, and notes.',
 'One row per seeding record.',
 'Pretreatments are aggregated into comma-separated text. Seed mix, species, and cultivar are joined where available.',
 'Multiple pretreatments are flattened. Cultivar species relationship is not exposed except through cultivarid.',
 NULL),

('full_site', 7, 'reporting', 'site', TRUE,
 'Site-level view with project context, reference ecosystem, classification, soil, climate, disturbance, and invasive species information.',
 'Potentially one row per site, but row grain may expand when multiple classifications, soils, disturbances, or invasive species are present.',
 'Site is joined to project_site and several site detail tables. Invasive species are joined through site_invasive and species.',
 'This view may not be strictly one row per site if site detail tables contain multiple rows per site. Use cautiously for row counts.',
 NULL),

('full_species', 8, 'entity', 'species', TRUE,
 'Species view with taxonomy, species code, lifeform, and aggregated lifespan descriptions.',
 'One row per species.',
 'Species lifespan values are aggregated into semicolon-separated text and grouped by speciesid.',
 'Lifespan detail is flattened and not suitable for querying individual lifespan records without returning to species_lifespan.',
 NULL),

('full_treatment', 9, 'reporting', 'treatment', TRUE,
 'Treatment-level reporting view that flattens treatment timing and multiple treatment-detail tables into one queryable treatment record.',
 'Intended as one row per treatment, with project context from area_treatment.',
 'Many treatment detail tables are aggregated into semicolon- or comma-separated text fields. Project context is inferred through area_treatment.',
 'High-risk denormalized view. Multiple area_treatment links or multiple detail records may affect row grain or aggregation behavior. Future edits should be tested carefully.',
 NULL),

('full_veg_results', 10, 'reporting', 'veg_result', TRUE,
 'Vegetation results view with project context, replicate area, date/timing fields, species/cultivar/individual links, response level, metric, and notes.',
 'One row per vegetation result.',
 'Project context is inferred by joining veg_result areaid through area and project_site. Species and cultivar codes are joined where available.',
 'If area-to-project relationships are not one-to-one, vegetation result rows may be repeated across project associations.',
 NULL),

('treatments_by_area', 11, 'bridge', 'area_treatment', TRUE,
 'Area-treatment bridge/reporting view that links areaid and treatmentid with flattened treatment details from full_treatment.',
 'One row per area-treatment relationship.',
 'Uses area_treatment as the bridge table and pulls treatment detail fields from full_treatment.',
 'Inherits assumptions and limitations from full_treatment. Treatment details may be repeated across areas.',
 NULL);