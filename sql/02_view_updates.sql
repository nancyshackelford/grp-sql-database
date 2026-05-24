-- =====================================================
-- View Update 009
-- Related Change ID: Change 014
-- Date: 2026-05-23
-- Description: Update project and paper views after splitting project data accessibility from paper/project metadata
-- =====================================================

-- Drop views before recreating them.
DROP VIEW IF EXISTS grp.full_paper;
DROP VIEW IF EXISTS grp.full_project;


-- =====================================================
-- full_paper
-- Publication/source metadata only.
-- Dataset accessibility metadata has been removed.
-- =====================================================

CREATE VIEW grp.full_paper AS
SELECT
    pp.database,
    pp.projectid,
    p.paperid,
    a.authors,
    p.publication_year AS year,
    p.publication_title AS title,
    p.publication_journal AS journal,
    p.publication_doi AS doi,
    p.publication_url AS url,
    ca.corresponding_author,
    ca.email,
    pp.notes AS project_paper_notes
FROM grp.project_paper pp
LEFT JOIN grp.paper p
    ON pp.paperid = p.paperid
LEFT JOIN (
    SELECT
        pa.paperid,
        string_agg(
            (ac.given_name || ' '::text || ac.surname),
            '; '::text
            ORDER BY ac.surname, ac.given_name
        ) AS authors
    FROM grp.paper_author pa
    LEFT JOIN grp.author_contributor ac
        ON pa.author_contributorid = ac.author_contributorid
    GROUP BY pa.paperid
) a
    ON p.paperid = a.paperid
LEFT JOIN (
    SELECT
        pa.paperid,
        string_agg(
            (ac.given_name || ' '::text || ac.surname),
            '; '::text
            ORDER BY ac.surname, ac.given_name
        ) AS corresponding_author,
        string_agg(
            ac.email,
            '; '::text
            ORDER BY ac.surname, ac.given_name
        ) AS email
    FROM grp.paper_author pa
    LEFT JOIN grp.author_contributor ac
        ON pa.author_contributorid = ac.author_contributorid
    WHERE pa.is_corresponding_author = true
    GROUP BY pa.paperid
) ca
    ON p.paperid = ca.paperid
ORDER BY
    pp.database DESC,
    pp.projectid,
    p.paperid;


-- =====================================================
-- full_project
-- One row per project.
-- Dataset accessibility metadata aggregated from
-- grp.project_data_accessibility.
-- =====================================================

CREATE VIEW grp.full_project AS
SELECT
    project.database,
    project.projectid,
    project.type,
    c.contributor,
    c.contributor_email,
    l.continent,
    l.country,
    l.state,
    string_agg(project_vegmetric.type, '; '::text) AS vegmetric,
    project.community,
    project.reference,

    pda.availability,
    pda.data_citation,
    pda.data_doi,
    pda.data_url,
    pda.creativecommons_license,
    pda.use_conditions,
    pda.first_date_received,
    pda.latest_date_received,
    pda.data_accessibility_notes,

    project.notes

FROM grp.project

LEFT JOIN grp.project_vegmetric
    ON project.database = project_vegmetric.database
    AND project.projectid = project_vegmetric.projectid

LEFT JOIN (
    SELECT
        project_contributor.database,
        project_contributor.projectid,
        string_agg(
            (author_contributor.given_name || ' '::text || author_contributor.surname),
            '; '::text
        ) AS contributor,
        string_agg(
            author_contributor.email,
            '; '::text
        ) AS contributor_email
    FROM grp.project_contributor
    LEFT JOIN grp.author_contributor
        USING (author_contributorid)
    GROUP BY
        project_contributor.database,
        project_contributor.projectid
) c
    ON project.database = c.database
    AND project.projectid = c.projectid

LEFT JOIN (
    SELECT
        project_location.database,
        project_location.projectid,
        string_agg(location.continent, '; '::text) AS continent,
        string_agg(location.country, '; '::text) AS country,
        string_agg(location.state, '; '::text) AS state
    FROM grp.project_location
    LEFT JOIN grp.location
        USING (locationid)
    GROUP BY
        project_location.database,
        project_location.projectid
) l
    ON project.database = l.database
    AND project.projectid = l.projectid

LEFT JOIN (
    SELECT
        database,
        projectid,

        string_agg(
            availability,
            '; '::text
            ORDER BY data_accessibilityid
        ) AS availability,

        string_agg(
            data_citation,
            '; '::text
            ORDER BY data_accessibilityid
        ) AS data_citation,

        string_agg(
            data_doi,
            '; '::text
            ORDER BY data_accessibilityid
        ) AS data_doi,

        string_agg(
            data_url,
            '; '::text
            ORDER BY data_accessibilityid
        ) AS data_url,

        string_agg(
            creativecommons_license,
            '; '::text
            ORDER BY data_accessibilityid
        ) AS creativecommons_license,

        string_agg(
            use_conditions,
            '; '::text
            ORDER BY data_accessibilityid
        ) AS use_conditions,

        MIN(date_received) AS first_date_received,
        MAX(date_received) AS latest_date_received,

        string_agg(
            data_accessibility_notes,
            '; '::text
            ORDER BY data_accessibilityid
        ) AS data_accessibility_notes

    FROM grp.project_data_accessibility

    GROUP BY
        database,
        projectid

) pda
    ON project.database = pda.database
    AND project.projectid = pda.projectid

GROUP BY
    project.database,
    project.projectid,
    project.type,
    c.contributor,
    c.contributor_email,
    l.continent,
    l.country,
    l.state,

    project.community,
    project.reference,

    pda.availability,
    pda.data_citation,
    pda.data_doi,
    pda.data_url,
    pda.creativecommons_license,
    pda.use_conditions,
    pda.first_date_received,
    pda.latest_date_received,
    pda.data_accessibility_notes,

    project.notes

ORDER BY
    project.database,
    project.projectid;

-- =====================================================
-- View Update 008
-- Related Change ID: Change 009
-- Date: 2026-05-19
-- Description: Simplify species traits in full_species
-- =====================================================

-- Drop dependent view first.
DROP VIEW IF EXISTS grp.full_species;

CREATE VIEW grp.full_species AS
SELECT
    species.speciesid,
    species.species_code,
    species."group",
    species."order",
    species.family,
    species.genus,
    species.species,
    species.subtype,
    species.subtype_name,
    string_agg(species_lifespan.description, '; ') AS lifespan,
    species.lifeform
FROM grp.species
LEFT JOIN grp.species_lifespan
    USING (speciesid)
GROUP BY species.speciesid
ORDER BY species.speciesid;

-- =====================================================
-- View Update 007
-- Related Change ID: Change 008
-- Date: 2026-05-19
-- Description: Recreate full_site after pruning stale/external site variables
-- =====================================================

-- Phase 9 view update: Recreate full_site without dropped grp.site columns.
CREATE VIEW grp.full_site AS
SELECT
    ps.database,
    ps.projectid,
    site.siteid,
    site.name,
    site.latitude,
    site.longitude,
    rf.description AS ref_ecosystem,
    c.class,
    c.subclass,
    c.subsubclass,
    s.sand,
    s.silt,
    s.clay,
    s.description,
    s.depth,
    site.aridity,
    site.annual_temp,
    site.annual_precip,
    d.type AS disturbance,
    spec.invasives,
    spec.invasive_lifeform
FROM grp.site
LEFT JOIN grp.project_site ps
    ON site.siteid = ps.siteid
LEFT JOIN grp.site_ref_ecosystem rf
    ON site.siteid = rf.siteid
LEFT JOIN (
    SELECT
        site_classification.siteid,
        classification.class,
        classification.subclass,
        classification.subsubclass
    FROM grp.site_classification
    LEFT JOIN grp.classification
        USING (classificationid)
) c
    ON site.siteid = c.siteid
LEFT JOIN grp.site_soil s
    ON site.siteid = s.siteid
LEFT JOIN grp.site_disturbance d
    ON site.siteid = d.siteid
LEFT JOIN (
    SELECT
        site_invasive.siteid,
        species.species_code AS invasives,
        species.lifeform AS invasive_lifeform
    FROM grp.site_invasive
    LEFT JOIN grp.species
        USING (speciesid)
) spec
    ON site.siteid = spec.siteid;

-- =====================================================
-- View Update 006
-- Related Change ID: Change 008
-- Date: 2026-05-18
-- Description: Replace maintenance_mowing boolean with structured mowing table
-- =====================================================

-- Phase 8 view updates
-- Drop dependent view first, then parent view.
-- Recreate parent view first, then dependent view.

DROP VIEW IF EXISTS grp.treatments_by_area;
DROP VIEW IF EXISTS grp.full_treatment;

CREATE VIEW grp.full_treatment AS
 SELECT DISTINCT at.database,
    at.projectid,
    treatment.treatmentid,
    treatment.year,
    treatment.month,
    treatment.day,
    treatment.weeks_since_restoration,
    treatment.other_treatment,
    a.application_method,
    bm.bed_material,
    bp.bed_prep,
    e.erosion_control,
    string_agg(f.type, '; '::text) AS fertilization_type,
    string_agg(((f.amount)::character varying)::text, '; '::text) AS fertilization_amount,
    string_agg(f.units, '; '::text) AS fertilization_units,
    string_agg(f.notes, '; '::text) AS fertilization_info,
    treatment.grading,
    g.grazer,
    string_agg(g.notes, '; '::text) AS grazer_notes,
    string_agg(gm.type, '; '::text) AS growth_medium,
    string_agg(((gm.top_soil_age)::character varying)::text, '; '::text) AS top_soil_age,
    string_agg(((gm.growth_medium_depth)::character varying)::text, '; '::text) AS growth_medium_depth,
    string_agg(gm.growth_medium_depth_units, '; '::text) AS growth_medium_depth_units,
    string_agg(gm.notes, '; '::text) AS growth_medium_info,
    string_agg(h.type, '; '::text) AS herbicide_type,
    string_agg(h.chemical, '; '::text) AS herbicide_chemical,
    string_agg(((h.amount)::character varying)::text, '; '::text) AS herbicide_amount,
    string_agg(h.units, '; '::text) AS herbicide_units,
    i.invasion_control,
    string_agg(ir.type, '; '::text) AS irrigation_type,
    string_agg(((ir.amount)::character varying)::text, '; '::text) AS irrigation_amount,
    string_agg(ir.units, '; '::text) AS irrigation_units,
    string_agg(ir.notes, '; '::text) AS irrigation_info,
    string_agg(m.mowing_type, '; '::text) AS mowing_type,
    string_agg(m.height_class, '; '::text) AS mowing_height_class,
    string_agg(((m.amount)::character varying)::text, '; '::text) AS mowing_amount,
    string_agg(m.units, '; '::text) AS mowing_units,
    string_agg(m.notes, '; '::text) AS mowing_notes,
    string_agg(((cc.speciesid)::character varying)::text, '; '::text) AS cover_crop_speciesid,
    string_agg(((cc.amount)::character varying)::text, '; '::text) AS cover_crop_amount,
    string_agg(cc.units, '; '::text) AS cover_crop_units,
    string_agg(cc.notes, '; '::text) AS cover_crop_notes,
    treatment.shelter,
    treatment.maintenance_fire,
    treatment.notes AS treatment_notes
   FROM (((((((((((((grp.treatment
     LEFT JOIN ( SELECT area_treatment.database,
            area_treatment.projectid,
            area_treatment.treatmentid,
            areaid,
            area.siteid
           FROM (grp.area_treatment
             LEFT JOIN grp.area USING (areaid))) at USING (treatmentid))
     LEFT JOIN ( SELECT treatment_application.treatmentid,
            string_agg(treatment_application.type, '; '::text) AS application_method
           FROM grp.treatment_application
          GROUP BY treatment_application.treatmentid) a USING (treatmentid))
     LEFT JOIN ( SELECT treatment_material.treatmentid,
            string_agg(treatment_material.type, ', '::text) AS bed_material
           FROM grp.treatment_material
          GROUP BY treatment_material.treatmentid) bm USING (treatmentid))
     LEFT JOIN ( SELECT treatment_prep.treatmentid,
            string_agg(treatment_prep.type, ', '::text) AS bed_prep
           FROM grp.treatment_prep
          GROUP BY treatment_prep.treatmentid) bp USING (treatmentid))
     LEFT JOIN ( SELECT treatment_erosion.treatmentid,
            string_agg(treatment_erosion.type, ', '::text) AS erosion_control
           FROM grp.treatment_erosion
          GROUP BY treatment_erosion.treatmentid) e USING (treatmentid))
     LEFT JOIN ( SELECT treatment_fertilization.treatmentid,
            treatment_fertilization.type,
            treatment_fertilization.amount,
            treatment_fertilization.units,
            treatment_fertilization.notes
           FROM grp.treatment_fertilization
          GROUP BY treatment_fertilization.notes, treatment_fertilization.treatmentid, treatment_fertilization.type, treatment_fertilization.amount, treatment_fertilization.units) f USING (treatmentid))
     LEFT JOIN ( SELECT treatment_medium.treatmentid,
            treatment_medium.type,
            treatment_medium.top_soil_age,
            treatment_medium.growth_medium_depth,
            treatment_medium.growth_medium_depth_units,
            treatment_medium.notes
           FROM grp.treatment_medium
          GROUP BY treatment_medium.treatmentid, treatment_medium.notes, treatment_medium.type, treatment_medium.top_soil_age, treatment_medium.growth_medium_depth, treatment_medium.growth_medium_depth_units) gm USING (treatmentid))
     LEFT JOIN ( SELECT treatment_grazer.treatmentid,
            string_agg(treatment_grazer.type, ', '::text) AS grazer,
            string_agg(treatment_grazer.notes, '; '::text) AS notes
           FROM grp.treatment_grazer
          GROUP BY treatment_grazer.treatmentid) g USING (treatmentid))
     LEFT JOIN ( SELECT treatment_herbicide.treatmentid,
            treatment_herbicide.type,
            treatment_herbicide.chemical,
            treatment_herbicide.amount,
            treatment_herbicide.units
           FROM grp.treatment_herbicide
          GROUP BY treatment_herbicide.treatmentid, treatment_herbicide.type, treatment_herbicide.chemical, treatment_herbicide.amount, treatment_herbicide.units) h USING (treatmentid))
     LEFT JOIN ( SELECT treatment_invasion.treatmentid,
            string_agg(treatment_invasion.type, ', '::text) AS invasion_control
           FROM grp.treatment_invasion
          GROUP BY treatment_invasion.treatmentid) i USING (treatmentid))
     LEFT JOIN grp.treatment_irrigation ir USING (treatmentid))
     LEFT JOIN grp.treatment_mowing m USING (treatmentid))
     LEFT JOIN grp.treatment_cover_crop cc USING (treatmentid))
  GROUP BY treatment.treatmentid, treatment.notes, at.database, at.projectid, at.areaid, at.siteid, a.application_method, bm.bed_material, bp.bed_prep, e.erosion_control, g.grazer, i.invasion_control;

CREATE VIEW grp.treatments_by_area AS
 SELECT area_treatment.areaid,
    area_treatment.treatmentid,
    full_treatment.year,
    full_treatment.month,
    full_treatment.day,
    full_treatment.weeks_since_restoration,
    full_treatment.other_treatment,
    full_treatment.application_method,
    full_treatment.bed_material,
    full_treatment.bed_prep,
    full_treatment.erosion_control,
    full_treatment.fertilization_type,
    full_treatment.fertilization_amount,
    full_treatment.fertilization_units,
    full_treatment.fertilization_info,
    full_treatment.grading,
    full_treatment.grazer,
    full_treatment.grazer_notes,
    full_treatment.growth_medium,
    full_treatment.top_soil_age,
    full_treatment.growth_medium_depth,
    full_treatment.growth_medium_depth_units,
    full_treatment.growth_medium_info,
    full_treatment.herbicide_type,
    full_treatment.herbicide_chemical,
    full_treatment.herbicide_amount,
    full_treatment.herbicide_units,
    full_treatment.invasion_control,
    full_treatment.irrigation_type,
    full_treatment.irrigation_amount,
    full_treatment.irrigation_units,
    full_treatment.irrigation_info,
    full_treatment.mowing_type,
    full_treatment.mowing_height_class,
    full_treatment.mowing_amount,
    full_treatment.mowing_units,
    full_treatment.mowing_notes,
    full_treatment.cover_crop_speciesid,
    full_treatment.cover_crop_amount,
    full_treatment.cover_crop_units,
    full_treatment.cover_crop_notes,
    full_treatment.shelter,
    full_treatment.maintenance_fire,
    full_treatment.treatment_notes
   FROM (grp.full_treatment
     RIGHT JOIN grp.area_treatment USING (treatmentid))
  ORDER BY area_treatment.areaid, full_treatment.weeks_since_restoration;

-- =====================================================
-- View Update 005
-- Related Change ID: Change 006
-- Date: 2026-05-18
-- Description: Recreate full_paper using normalized paper structure
-- =====================================================

-- Phase 6 view updates
-- Rebuild full_paper after normalizing paper/publication tables.
-- full_paper now joins:
--   project_paper -> paper
--   paper_author -> author_contributor

DROP VIEW IF EXISTS grp.full_paper;

CREATE VIEW grp.full_paper AS
SELECT
    pp.database,
    pp.projectid,
    p.paperid,
    a.authors,
    p.publication_year AS year,
    p.publication_title AS title,
    p.publication_journal AS journal,
    p.publication_doi AS doi,
    p.publication_url AS url,
    ca.corresponding_author,
    ca.email,
    p.date_received AS received,
    p.data_citation AS citation,
    p.creativecommons_license AS license,
    p.use_conditions AS conditions,
    pp.notes AS project_paper_notes
FROM grp.project_paper AS pp
LEFT JOIN grp.paper AS p
    ON pp.paperid = p.paperid
LEFT JOIN (
    SELECT
        pa.paperid,
        string_agg(
            (ac.given_name || ' ' || ac.surname),
            '; '
            ORDER BY ac.surname, ac.given_name
        ) AS authors
    FROM grp.paper_author AS pa
    LEFT JOIN grp.author_contributor AS ac
        ON pa.author_contributorid = ac.author_contributorid
    GROUP BY pa.paperid
) AS a
    ON p.paperid = a.paperid
LEFT JOIN (
    SELECT
        pa.paperid,
        string_agg(
            (ac.given_name || ' ' || ac.surname),
            '; '
            ORDER BY ac.surname, ac.given_name
        ) AS corresponding_author,
        string_agg(
            ac.email,
            '; '
            ORDER BY ac.surname, ac.given_name
        ) AS email
    FROM grp.paper_author AS pa
    LEFT JOIN grp.author_contributor AS ac
        ON pa.author_contributorid = ac.author_contributorid
    WHERE pa.is_corresponding_author = true
    GROUP BY pa.paperid
) AS ca
    ON p.paperid = ca.paperid
ORDER BY
    pp.database DESC,
    pp.projectid,
    p.paperid;

-- =====================================================
-- View Update 004
-- Related Change ID: Change 005
-- Date: 2026-05-18
-- Description: Add growth medium depth to full_treatment
-- =====================================================

-- Phase 5 view updates
-- Separate topsoil age and growth medium depth
-- Drop dependent view first, then parent view.
-- Recreate parent view first, then dependent view.

DROP VIEW IF EXISTS grp.treatments_by_area;
DROP VIEW IF EXISTS grp.full_treatment;

CREATE VIEW grp.full_treatment AS
SELECT DISTINCT
    at.database,
    at.projectid,
    treatment.treatmentid,
    treatment.year,
    treatment.month,
    treatment.day,
    treatment.weeks_since_restoration,
    treatment.other_treatment,
    a.application_method,
    bm.bed_material,
    bp.bed_prep,
    e.erosion_control,
    string_agg(f.type, '; '::text) AS fertilization_type,
    string_agg(((f.amount)::character varying)::text, '; '::text) AS fertilization_amount,
    string_agg(f.units, '; '::text) AS fertilization_units,
    string_agg(f.notes, '; '::text) AS fertilization_info,
    treatment.grading,
    g.grazer,
    string_agg(gm.type, '; '::text) AS growth_medium,
    string_agg(((gm.top_soil_age)::character varying)::text, '; '::text) AS top_soil_age,
    string_agg(((gm.growth_medium_depth)::character varying)::text, '; '::text) AS growth_medium_depth,
    string_agg(gm.growth_medium_depth_units, '; '::text) AS growth_medium_depth_units,
    string_agg(gm.notes, '; '::text) AS growth_medium_info,
    string_agg(h.type, '; '::text) AS herbicide_type,
    string_agg(h.chemical, '; '::text) AS herbicide_chemical,
    string_agg(((h.amount)::character varying)::text, '; '::text) AS herbicide_amount,
    string_agg(h.units, '; '::text) AS herbicide_units,
    i.invasion_control,
    string_agg(ir.type, '; '::text) AS irrigation_type,
    string_agg(((ir.amount)::character varying)::text, '; '::text) AS irrigation_amount,
    string_agg(ir.units, '; '::text) AS irrigation_units,
    string_agg(ir.notes, '; '::text) AS irrigation_info,
    treatment.shelter,
    treatment.maintenance_fire,
    treatment.maintenance_mowing,
    treatment.notes AS treatment_notes
FROM (((((((((((grp.treatment
    LEFT JOIN (
        SELECT
            area_treatment.database,
            area_treatment.projectid,
            area_treatment.treatmentid,
            areaid,
            area.siteid
        FROM (
            grp.area_treatment
            LEFT JOIN grp.area USING (areaid)
        )
    ) at USING (treatmentid))

    LEFT JOIN (
        SELECT
            treatment_application.treatmentid,
            string_agg(treatment_application.type, '; '::text) AS application_method
        FROM grp.treatment_application
        GROUP BY treatment_application.treatmentid
    ) a USING (treatmentid))

    LEFT JOIN (
        SELECT
            treatment_material.treatmentid,
            string_agg(treatment_material.type, ', '::text) AS bed_material
        FROM grp.treatment_material
        GROUP BY treatment_material.treatmentid
    ) bm USING (treatmentid))

    LEFT JOIN (
        SELECT
            treatment_prep.treatmentid,
            string_agg(treatment_prep.type, ', '::text) AS bed_prep
        FROM grp.treatment_prep
        GROUP BY treatment_prep.treatmentid
    ) bp USING (treatmentid))

    LEFT JOIN (
        SELECT
            treatment_erosion.treatmentid,
            string_agg(treatment_erosion.type, ', '::text) AS erosion_control
        FROM grp.treatment_erosion
        GROUP BY treatment_erosion.treatmentid
    ) e USING (treatmentid))

    LEFT JOIN (
        SELECT
            treatment_fertilization.treatmentid,
            treatment_fertilization.type,
            treatment_fertilization.amount,
            treatment_fertilization.units,
            treatment_fertilization.notes
        FROM grp.treatment_fertilization
        GROUP BY
            treatment_fertilization.notes,
            treatment_fertilization.treatmentid,
            treatment_fertilization.type,
            treatment_fertilization.amount,
            treatment_fertilization.units
    ) f USING (treatmentid))

    LEFT JOIN (
        SELECT
            treatment_medium.treatmentid,
            treatment_medium.type,
            treatment_medium.top_soil_age,
            treatment_medium.growth_medium_depth,
            treatment_medium.growth_medium_depth_units,
            treatment_medium.notes
        FROM grp.treatment_medium
        GROUP BY
            treatment_medium.treatmentid,
            treatment_medium.notes,
            treatment_medium.type,
            treatment_medium.top_soil_age,
            treatment_medium.growth_medium_depth,
            treatment_medium.growth_medium_depth_units
    ) gm USING (treatmentid))

    LEFT JOIN (
        SELECT
            treatment_grazer.treatmentid,
            string_agg(treatment_grazer.type, ', '::text) AS grazer
        FROM grp.treatment_grazer
        GROUP BY treatment_grazer.treatmentid
    ) g USING (treatmentid))

    LEFT JOIN (
        SELECT
            treatment_herbicide.treatmentid,
            treatment_herbicide.type,
            treatment_herbicide.chemical,
            treatment_herbicide.amount,
            treatment_herbicide.units
        FROM grp.treatment_herbicide
        GROUP BY
            treatment_herbicide.treatmentid,
            treatment_herbicide.type,
            treatment_herbicide.chemical,
            treatment_herbicide.amount,
            treatment_herbicide.units
    ) h USING (treatmentid))

    LEFT JOIN (
        SELECT
            treatment_invasion.treatmentid,
            string_agg(treatment_invasion.type, ', '::text) AS invasion_control
        FROM grp.treatment_invasion
        GROUP BY treatment_invasion.treatmentid
    ) i USING (treatmentid))

    LEFT JOIN grp.treatment_irrigation ir USING (treatmentid))

GROUP BY
    treatment.treatmentid,
    treatment.notes,
    at.database,
    at.projectid,
    at.areaid,
    at.siteid,
    a.application_method,
    bm.bed_material,
    bp.bed_prep,
    e.erosion_control,
    g.grazer,
    i.invasion_control;

CREATE VIEW grp.treatments_by_area AS
SELECT
    area_treatment.areaid,
    area_treatment.treatmentid,
    full_treatment.year,
    full_treatment.month,
    full_treatment.day,
    full_treatment.weeks_since_restoration,
    full_treatment.other_treatment,
    full_treatment.application_method,
    full_treatment.bed_material,
    full_treatment.bed_prep,
    full_treatment.erosion_control,
    full_treatment.fertilization_type,
    full_treatment.fertilization_amount,
    full_treatment.fertilization_units,
    full_treatment.fertilization_info,
    full_treatment.grading,
    full_treatment.grazer,
    full_treatment.growth_medium,
    full_treatment.top_soil_age,
    full_treatment.growth_medium_depth,
    full_treatment.growth_medium_depth_units,
    full_treatment.growth_medium_info,
    full_treatment.herbicide_type,
    full_treatment.herbicide_chemical,
    full_treatment.herbicide_amount,
    full_treatment.herbicide_units,
    full_treatment.invasion_control,
    full_treatment.irrigation_type,
    full_treatment.irrigation_amount,
    full_treatment.irrigation_units,
    full_treatment.irrigation_info,
    full_treatment.shelter,
    full_treatment.maintenance_fire,
    full_treatment.maintenance_mowing,
    full_treatment.treatment_notes
FROM (
    grp.full_treatment
    RIGHT JOIN grp.area_treatment USING (treatmentid)
)
ORDER BY
    area_treatment.areaid,
    full_treatment.weeks_since_restoration;

-- =====================================================
-- View Update 003
-- Related Change ID: Change 002
-- Date: 2026-05-15
-- Description: Reflect seed mix normalization in full_seeding
-- =====================================================


DROP VIEW grp.full_seeding;

CREATE OR REPLACE VIEW grp.full_seeding AS
SELECT 
    s.treatmentid,
    s.seed_mixid,
    sm.mix_name,
    sm.mix_composition_status,
    sm.treated_richness,
    s.mix AS legacy_mix_name,
    sm.notes AS seed_mix_notes,
    spec.species_code AS species,
    s.cultivarid,
    s.type,
    s.rate,
    s.unit,
    s.viability,
    string_agg(p.type, ', '::text) AS pretreatment,
    s.origin,
    s.source,
    s.seed_distance,
    s.notes AS seeding_notes
FROM ((((grp.seeding s
    LEFT JOIN grp.seeding_pretreatment p USING (seedingid))
    LEFT JOIN grp.species spec USING (speciesid))
    LEFT JOIN grp.cultivar cultivar(cultivarid, speciesid_1, name, origin, latitude, longitude) USING (cultivarid))
    LEFT JOIN grp.seed_mix sm USING (seed_mixid))
GROUP BY 
    s.seedingid, 
    sm.mix_name,
    sm.mix_composition_status,
    sm.treated_richness,
    sm.notes,
    cultivar.name, 
    spec.species_code;

-- =====================================================
-- View Update 002
-- Related Change ID: Change 001
-- Date: 2026-05-14
-- Description: Add treatment_notes to grp.treatments_by_area
-- =====================================================

CREATE OR REPLACE VIEW grp.treatments_by_area AS
SELECT area_treatment.areaid,
    area_treatment.treatmentid,
    full_treatment.year,
    full_treatment.month,
    full_treatment.day,
    full_treatment.weeks_since_restoration,
    full_treatment.other_treatment,
    full_treatment.application_method,
    full_treatment.bed_material,
    full_treatment.bed_prep,
    full_treatment.erosion_control,
    full_treatment.fertilization_type,
    full_treatment.fertilization_amount,
    full_treatment.fertilization_units,
    full_treatment.fertilization_info,
    full_treatment.grading,
    full_treatment.grazer,
    full_treatment.growth_medium,
    full_treatment.top_soil_age,
    full_treatment.growth_medium_info,
    full_treatment.herbicide_type,
    full_treatment.herbicide_chemical,
    full_treatment.herbicide_amount,
    full_treatment.herbicide_units,
    full_treatment.invasion_control,
    full_treatment.irrigation_type,
    full_treatment.irrigation_amount,
    full_treatment.irrigation_units,
    full_treatment.irrigation_info,
    full_treatment.shelter,
    full_treatment.maintenance_fire,
    full_treatment.maintenance_mowing,
    full_treatment.treatment_notes
FROM (grp.full_treatment
     RIGHT JOIN grp.area_treatment USING (treatmentid))
ORDER BY area_treatment.areaid, full_treatment.weeks_since_restoration;

-- =====================================================
-- View Update 001
-- Related Change ID: Change 001
-- Date: 2026-05-14
-- Description: Add treatment_notes to grp.full_treatment
-- =====================================================

CREATE OR REPLACE VIEW grp.full_treatment AS
SELECT DISTINCT at.database,
    at.projectid,
    treatment.treatmentid,
    treatment.year,
    treatment.month,
    treatment.day,
    treatment.weeks_since_restoration,
    treatment.other_treatment,
    a.application_method,
    bm.bed_material,
    bp.bed_prep,
    e.erosion_control,
    string_agg(f.type, '; '::text) AS fertilization_type,
    string_agg(((f.amount)::character varying)::text, '; '::text) AS fertilization_amount,
    string_agg(f.units, '; '::text) AS fertilization_units,
    string_agg(f.notes, '; '::text) AS fertilization_info,
    treatment.grading,
    g.grazer,
    string_agg(gm.type, '; '::text) AS growth_medium,
    string_agg(((gm.top_soil_age)::character varying)::text, '; '::text) AS top_soil_age,
    string_agg(gm.notes, '; '::text) AS growth_medium_info,
    string_agg(h.type, '; '::text) AS herbicide_type,
    string_agg(h.chemical, '; '::text) AS herbicide_chemical,
    string_agg(((h.amount)::character varying)::text, '; '::text) AS herbicide_amount,
    string_agg(h.units, '; '::text) AS herbicide_units,
    i.invasion_control,
    string_agg(ir.type, '; '::text) AS irrigation_type,
    string_agg(((ir.amount)::character varying)::text, '; '::text) AS irrigation_amount,
    string_agg(ir.units, '; '::text) AS irrigation_units,
    string_agg(ir.notes, '; '::text) AS irrigation_info,
    treatment.shelter,
    treatment.maintenance_fire,
    treatment.maintenance_mowing,
    treatment.notes AS treatment_notes
FROM (((((((((((grp.treatment
     LEFT JOIN ( SELECT area_treatment.database,
            area_treatment.projectid,
            area_treatment.treatmentid,
            areaid,
            area.siteid
           FROM (grp.area_treatment
             LEFT JOIN grp.area USING (areaid))) at USING (treatmentid))
     LEFT JOIN ( SELECT treatment_application.treatmentid,
            string_agg(treatment_application.type, '; '::text) AS application_method
           FROM grp.treatment_application
          GROUP BY treatment_application.treatmentid) a USING (treatmentid))
     LEFT JOIN ( SELECT treatment_material.treatmentid,
            string_agg(treatment_material.type, ', '::text) AS bed_material
           FROM grp.treatment_material
          GROUP BY treatment_material.treatmentid) bm USING (treatmentid))
     LEFT JOIN ( SELECT treatment_prep.treatmentid,
            string_agg(treatment_prep.type, ', '::text) AS bed_prep
           FROM grp.treatment_prep
          GROUP BY treatment_prep.treatmentid) bp USING (treatmentid))
     LEFT JOIN ( SELECT treatment_erosion.treatmentid,
            string_agg(treatment_erosion.type, ', '::text) AS erosion_control
           FROM grp.treatment_erosion
          GROUP BY treatment_erosion.treatmentid) e USING (treatmentid))
     LEFT JOIN ( SELECT treatment_fertilization.treatmentid,
            treatment_fertilization.type,
            treatment_fertilization.amount,
            treatment_fertilization.units,
            treatment_fertilization.notes
           FROM grp.treatment_fertilization
          GROUP BY treatment_fertilization.notes, treatment_fertilization.treatmentid, treatment_fertilization.type, treatment_fertilization.amount, treatment_fertilization.units) f USING (treatmentid))
     LEFT JOIN ( SELECT treatment_medium.treatmentid,
            treatment_medium.type,
            treatment_medium.top_soil_age,
            treatment_medium.notes
           FROM grp.treatment_medium
          GROUP BY treatment_medium.treatmentid, treatment_medium.notes, treatment_medium.type, treatment_medium.top_soil_age) gm USING (treatmentid))
     LEFT JOIN ( SELECT treatment_grazer.treatmentid,
            string_agg(treatment_grazer.type, ', '::text) AS grazer
           FROM grp.treatment_grazer
          GROUP BY treatment_grazer.treatmentid) g USING (treatmentid))
     LEFT JOIN ( SELECT treatment_herbicide.treatmentid,
            treatment_herbicide.type,
            treatment_herbicide.chemical,
            treatment_herbicide.amount,
            treatment_herbicide.units
           FROM grp.treatment_herbicide
          GROUP BY treatment_herbicide.treatmentid, treatment_herbicide.type, treatment_herbicide.chemical, treatment_herbicide.amount, treatment_herbicide.units) h USING (treatmentid))
     LEFT JOIN ( SELECT treatment_invasion.treatmentid,
            string_agg(treatment_invasion.type, ', '::text) AS invasion_control
           FROM grp.treatment_invasion
          GROUP BY treatment_invasion.treatmentid) i USING (treatmentid))
     LEFT JOIN grp.treatment_irrigation ir USING (treatmentid))
GROUP BY treatment.treatmentid, treatment.notes, at.database, at.projectid, at.areaid, at.siteid, a.application_method, bm.bed_material, bp.bed_prep, e.erosion_control, g.grazer, i.invasion_control;
