-- ============================================================
-- Rebuild full_species view
-- ============================================================

DROP VIEW IF EXISTS grp.full_species;

CREATE VIEW grp.full_species AS
SELECT
    s.speciesid,
    s.species_code,
    s."group",
    s."order",
    s.family,
    s.genus,
    s.species,
    s.subtype,
    s.subtype_name,
STRING_AGG(sl.type, '; ' ORDER BY sl.type) AS lifespan,
    s.lifeform
FROM grp.species s
LEFT JOIN grp.species_lifespan sl
    ON s.speciesid = sl.speciesid
GROUP BY
    s.speciesid,
    s.species_code,
    s."group",
    s."order",
    s.family,
    s.genus,
    s.species,
    s.subtype,
    s.subtype_name,
    s.lifeform
ORDER BY s.speciesid;