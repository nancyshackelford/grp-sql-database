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
