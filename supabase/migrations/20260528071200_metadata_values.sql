--
-- PostgreSQL database dump

-- Dumped from database version 14.17
-- Dumped by pg_dump version 17.6

-- Started on 2026-05-27 16:13:56

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 5354 (class 0 OID 27404)
-- Dependencies: 290
-- Data for Name: view_dictionary; Type: TABLE DATA; Schema: grp; Owner: postgres
--

INSERT INTO grp.view_dictionary VALUES ('full_area', 1, 'reporting', 'area', true, 'Flattened area-level view for querying replicate areas with project/site context, parent block/subblock context, and associated treatment IDs.', 'One row per non-block, non-subblock area.', 'Area hierarchy uses parentid to infer block and subblock relationships. Treatment IDs are aggregated as text. Blocks and subblocks are excluded as primary rows.', 'Does not return block or subblock areas as their own rows. Multiple area-treatment relationships are flattened into a comma-separated treatmentids field.', NULL);
INSERT INTO grp.view_dictionary VALUES ('full_cultivar', 2, 'entity', 'cultivar', false, 'Cultivar view with linked species code and cultivar origin/location information.', 'One row per cultivar.', 'Each cultivar links to species through speciesid.', 'Does not aggregate multiple species or other cultivar-related records.', NULL);
INSERT INTO grp.view_dictionary VALUES ('full_individual', 3, 'reporting', 'individual', true, 'Individual plant view with project context, replicate area, species code, location, and initial measurement information.', 'One row per individual-area-treatment/project association.', 'Individuals are linked to project context through area_treatment using areaid. Species code is joined from species.', 'If an area is linked to multiple treatments or projects, individual rows may be repeated across those associations.', NULL);
INSERT INTO grp.view_dictionary VALUES ('full_seeding', 6, 'reporting', 'seeding', true, 'Seeding view with seed mix details, species/cultivar links, seeding rate, viability, pretreatment, origin/source, distance, and notes.', 'One row per seeding record.', 'Pretreatments are aggregated into comma-separated text. Seed mix, species, and cultivar are joined where available.', 'Multiple pretreatments are flattened. Cultivar species relationship is not exposed except through cultivarid.', NULL);
INSERT INTO grp.view_dictionary VALUES ('full_site', 7, 'reporting', 'site', true, 'Site-level view with project context, reference ecosystem, classification, soil, climate, disturbance, and invasive species information.', 'Potentially one row per site, but row grain may expand when multiple classifications, soils, disturbances, or invasive species are present.', 'Site is joined to project_site and several site detail tables. Invasive species are joined through site_invasive and species.', 'This view may not be strictly one row per site if site detail tables contain multiple rows per site. Use cautiously for row counts.', NULL);
INSERT INTO grp.view_dictionary VALUES ('full_species', 8, 'entity', 'species', true, 'Species view with taxonomy, species code, lifeform, and aggregated lifespan descriptions.', 'One row per species.', 'Species lifespan values are aggregated into semicolon-separated text and grouped by speciesid.', 'Lifespan detail is flattened and not suitable for querying individual lifespan records without returning to species_lifespan.', NULL);
INSERT INTO grp.view_dictionary VALUES ('full_treatment', 9, 'reporting', 'treatment', true, 'Treatment-level reporting view that flattens treatment timing and multiple treatment-detail tables into one queryable treatment record.', 'Intended as one row per treatment, with project context from area_treatment.', 'Many treatment detail tables are aggregated into semicolon- or comma-separated text fields. Project context is inferred through area_treatment.', 'High-risk denormalized view. Multiple area_treatment links or multiple detail records may affect row grain or aggregation behavior. Future edits should be tested carefully.', NULL);
INSERT INTO grp.view_dictionary VALUES ('full_veg_results', 10, 'reporting', 'veg_result', true, 'Vegetation results view with project context, replicate area, date/timing fields, species/cultivar/individual links, response level, metric, and notes.', 'One row per vegetation result.', 'Project context is inferred by joining veg_result areaid through area and project_site. Species and cultivar codes are joined where available.', 'If area-to-project relationships are not one-to-one, vegetation result rows may be repeated across project associations.', NULL);
INSERT INTO grp.view_dictionary VALUES ('treatments_by_area', 11, 'bridge', 'area_treatment', true, 'Area-treatment bridge/reporting view that links areaid and treatmentid with flattened treatment details from full_treatment.', 'One row per area-treatment relationship.', 'Uses area_treatment as the bridge table and pulls treatment detail fields from full_treatment.', 'Inherits assumptions and limitations from full_treatment. Treatment details may be repeated across areas.', NULL);
INSERT INTO grp.view_dictionary VALUES ('full_paper', 4, 'reporting', 'paper', true, 'Provides publication/source metadata associated with projects through the project-paper relationship.', 'One row per project-paper relationship.', 'Papers are standalone publication/source entities. Project-paper relationships may be many-to-many. Dataset accessibility is not paper metadata.', 'Does not include project dataset accessibility metadata. Data accessibility is stored in grp.project_data_accessibility and exposed through grp.full_project.', 'Updated during Change 014 after moving dataset accessibility fields out of grp.paper.');
INSERT INTO grp.view_dictionary VALUES ('full_project', 5, 'reporting', 'project', true, 'Provides project-level metadata, including contributors, locations, vegetation metrics, and aggregated project dataset accessibility metadata.', 'One row per project.', 'Project data accessibility is project-level metadata and may eventually include multiple records per project.', 'Data accessibility fields are aggregated from grp.project_data_accessibility, so multiple accessibility records will be collapsed into semicolon-separated values.', 'Updated during Change 014 after moving dataset accessibility into grp.project_data_accessibility. Aggregation preserves one row per project.');


-- Completed on 2026-05-27 16:14:20

--
-- PostgreSQL database dump complete
--
