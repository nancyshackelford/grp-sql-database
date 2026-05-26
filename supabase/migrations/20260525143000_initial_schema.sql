--
-- PostgreSQL database dump
--

-- Dumped from database version 14.17
-- Dumped by pg_dump version 17.6

-- Started on 2026-05-25 23:31:19

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
-- TOC entry 7 (class 2615 OID 16427)
-- Name: grp; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA grp;


ALTER SCHEMA grp OWNER TO postgres;

--
-- TOC entry 6 (class 2615 OID 2200)
-- Name: public; Type: SCHEMA; Schema: -; Owner: postgres
--

-- *not* creating schema, since initdb creates it


ALTER SCHEMA public OWNER TO postgres;

--
-- TOC entry 2 (class 3079 OID 25735)
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- TOC entry 5700 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 211 (class 1259 OID 24590)
-- Name: application_method; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.application_method (
    type text NOT NULL,
    definition text,
    notes text
);


ALTER TABLE grp.application_method OWNER TO postgres;

--
-- TOC entry 269 (class 1259 OID 26856)
-- Name: area; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.area (
    areaid bigint NOT NULL,
    siteid integer,
    type text,
    size numeric,
    units text,
    restoration_start_year numeric(4,0),
    restoration_type text,
    disturbance_end_year numeric(4,0),
    parentid integer,
    CONSTRAINT restoration_type_check CHECK ((restoration_type = ANY (ARRAY['degraded reference'::text, 'passive'::text, 'planting'::text, 'reference'::text, 'seeding'::text, 'seeding & planting'::text]))),
    CONSTRAINT type_check CHECK ((type = ANY (ARRAY['block'::text, 'individual'::text, 'plot'::text, 'transect'::text]))),
    CONSTRAINT units_check CHECK ((units = ANY (ARRAY['km2'::text, 'hm2'::text, 'dam2'::text, 'm2'::text, 'dm2'::text, 'cm2'::text, 'ha'::text, 'sqmi'::text, 'acre'::text, 'sqyd'::text, 'sqft'::text, 'sqin'::text, 'sqnmi'::text, 'm'::text, 'proportion'::text, 'cm'::text, 'minutes/hectare'::text])))
);


ALTER TABLE grp.area OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 25130)
-- Name: area_treatment; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.area_treatment (
    database text NOT NULL,
    projectid integer NOT NULL,
    areaid integer NOT NULL,
    treatmentid integer NOT NULL
);


ALTER TABLE grp.area_treatment OWNER TO postgres;

--
-- TOC entry 253 (class 1259 OID 25153)
-- Name: author_contributor; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.author_contributor (
    author_contributorid integer NOT NULL,
    given_name text,
    surname text,
    email text,
    CONSTRAINT email_check CHECK ((email ~~ '%_@_%'::text))
);


ALTER TABLE grp.author_contributor OWNER TO postgres;

--
-- TOC entry 212 (class 1259 OID 24597)
-- Name: bed_material; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.bed_material (
    type text NOT NULL,
    definition text,
    notes text
);


ALTER TABLE grp.bed_material OWNER TO postgres;

--
-- TOC entry 213 (class 1259 OID 24604)
-- Name: bed_prep; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.bed_prep (
    type text NOT NULL,
    definition text,
    notes text
);


ALTER TABLE grp.bed_prep OWNER TO postgres;

--
-- TOC entry 214 (class 1259 OID 24611)
-- Name: classification; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.classification (
    classificationid text NOT NULL,
    class text,
    subclass text,
    subsubclass text,
    CONSTRAINT class_check CHECK ((class = ANY (ARRAY['Forest & Woodland'::text, 'Shrub & Herb Vegetation'::text, 'Desert & Semi-Desert'::text, 'Polar & High Montane Scrub, Grassland & Barrens'::text, 'Aquatic Vegetation'::text, 'Open Rock Vegetation'::text, 'Agricultural & Developed Vegetation'::text]))),
    CONSTRAINT subclass_check CHECK ((subclass = ANY (ARRAY['Tropical Forest & Woodland'::text, 'Temperate & Boreal Forest & Woodland'::text, 'Tropical Grassland, Savanna & Shrubland'::text, 'Temperate & Boreal Grassland & Shrubland'::text, 'Shrub & Herb Wetland'::text, 'Warm Desert & Semi-Desert Woodland, Scrub & Grassland'::text, 'Cool Semi-Desert Scrub & Grassland'::text, 'Tropical High Montane Scrub & Grassland'::text, 'Temperate to Polar Alpine & Tundra Vegetation'::text, 'Saltwater Aquatic Vegetation'::text, 'Freshwater Aquatic Vegetation'::text, 'Tropical Open Rock Vegetation'::text, 'Temperate & Boreal Open Rock Vegetation'::text, 'Woody Agricultural Vegetation'::text, 'Herbaceous Agricultural Vegetation'::text, 'Herbaceous & Woody Developed Vegetation'::text, 'Agricultural & Developed Aquatic Vegetation'::text]))),
    CONSTRAINT subsubclass_check CHECK ((subsubclass = ANY (ARRAY['Tropical Dry Forest & Woodland'::text, 'Tropical Lowland Humid Forest'::text, 'Tropical Montane Humid Forest'::text, 'Tropical Flooded & Swamp Forest'::text, 'Mangrove'::text, 'Warm Temperate Forest & Woodland'::text, 'Cool Temperate Forest & Woodland'::text, 'Temperate Flooded & Swamp Forest'::text, 'Boreal Forest & Woodland'::text, 'Boreal Flooded & Swamp Forest'::text, 'Tropical Lowland Grassland, Savanna & Shrubland'::text, 'Tropical Montane Grassland & Shrubland'::text, 'Tropical Scrub & Herb Coastal Vegetation'::text, 'Mediterranean Scrub & Grassland'::text, 'Temperate Grassland & Shrubland'::text, 'Boreal Grassland & Shrubland'::text, 'Temperate to Polar Scrub & Herb Coastal Vegetation'::text, 'Tropical Bog & Fen'::text, 'Temperate to Polar Bog & Fen'::text, 'Tropical Freshwater Marsh, Wet Meadow & Shrubland'::text, 'Temperate to Polar Freshwater Marsh, Wet Meadow & Shrubland'::text, 'Salt Marsh'::text, 'Tropical Thorn Woodland'::text, 'Warm Desert & Semi-Desert Scrub & Grassland'::text, 'Cool Semi-Desert Scrub & Grassland'::text, 'Tropical High Montane Scrub & Grassland'::text, 'Temperate & Boreal Alpine Vegetation'::text, 'Polar Tundra & Barrens'::text, 'Floating & Suspended Macroalgae Saltwater Vegetation'::text, 'Benthic Macroalgae Saltwater Vegetation'::text, 'Benthic Vascular Saltwater Vegetation'::text, 'Benthic Lichen Saltwater Vegetation'::text, 'Tropical Freshwater Aquatic Vegetation'::text, 'Temperate to Polar Freshwater Aquatic Vegetation'::text, 'Tropical Cliff, Scree & Other Rock Vegetation'::text, 'Temperate & Boreal Cliff, Scree & Other Rock Vegetation'::text, 'Woody Horticultural Crop'::text, 'Forest Plantation & Agroforestry'::text, 'Woody Wetland Horticultural Crop'::text, 'Row & Close Grain Crop'::text, 'Pasture & Hay Field Crop'::text, 'Herbaceous Horticultural Crop'::text, 'Fallow Field & Weed Vegetation'::text, 'Herbaceous Wetland Crop'::text, 'Lawn, Garden & Recreational Vegetation'::text, 'Other Developed Vegetation'::text, 'Developed Wetland Vegetation'::text, 'Agricultural Aquatic Vegetation'::text, 'Developed Aquatic Vegetation'::text])))
);


ALTER TABLE grp.classification OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 25164)
-- Name: cultivar; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.cultivar (
    cultivarid integer NOT NULL,
    speciesid integer NOT NULL,
    name text,
    origin text,
    latitude numeric,
    longitude numeric,
    CONSTRAINT latitude_check CHECK (((('-90'::integer)::numeric <= latitude) AND (latitude <= (90)::numeric))),
    CONSTRAINT longitude_check CHECK (((('-180'::integer)::numeric <= longitude) AND (longitude <= (180)::numeric)))
);


ALTER TABLE grp.cultivar OWNER TO postgres;

--
-- TOC entry 278 (class 1259 OID 27245)
-- Name: data_dictionary; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.data_dictionary (
    dictionaryid integer NOT NULL,
    table_name text NOT NULL,
    column_name text NOT NULL,
    display_order integer,
    data_type text NOT NULL,
    is_nullable text NOT NULL,
    definition text NOT NULL,
    workflow_notes text,
    allowed_values text,
    example text,
    legacy_notes text,
    qa_qc_notes text,
    external_source_notes text,
    CONSTRAINT data_dictionary_is_nullable_check CHECK ((is_nullable = ANY (ARRAY['YES'::text, 'NO'::text])))
);


ALTER TABLE grp.data_dictionary OWNER TO postgres;

--
-- TOC entry 289 (class 1259 OID 27390)
-- Name: data_dictionary_dictionaryid_seq; Type: SEQUENCE; Schema: grp; Owner: postgres
--

ALTER TABLE grp.data_dictionary ALTER COLUMN dictionaryid ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME grp.data_dictionary_dictionaryid_seq
    START WITH 25
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 215 (class 1259 OID 24623)
-- Name: disturbance; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.disturbance (
    type text NOT NULL,
    definition text,
    notes text
);


ALTER TABLE grp.disturbance OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 24630)
-- Name: erosion_control; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.erosion_control (
    type text NOT NULL,
    definition text,
    notes text
);


ALTER TABLE grp.erosion_control OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 24637)
-- Name: fertilization; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.fertilization (
    type text NOT NULL,
    definition text,
    notes text
);


ALTER TABLE grp.fertilization OWNER TO postgres;

--
-- TOC entry 273 (class 1259 OID 26958)
-- Name: full_area; Type: VIEW; Schema: grp; Owner: postgres
--

CREATE VIEW grp.full_area AS
SELECT
    NULL::text AS database,
    NULL::integer AS projectid,
    NULL::integer AS siteid,
    NULL::bigint AS block,
    NULL::numeric AS block_area,
    NULL::text AS block_units,
    NULL::bigint AS subblock,
    NULL::numeric AS subblock_area,
    NULL::text AS subblock_units,
    NULL::bigint AS rep,
    NULL::text AS treatmentids,
    NULL::text AS type,
    NULL::numeric AS size,
    NULL::text AS units,
    NULL::numeric(4,0) AS restoration_start_year,
    NULL::text AS restoration_type,
    NULL::numeric(4,0) AS disturbance_end_year;


ALTER VIEW grp.full_area OWNER TO postgres;

--
-- TOC entry 234 (class 1259 OID 24858)
-- Name: species; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.species (
    speciesid integer NOT NULL,
    species_code text,
    "group" text,
    "order" text,
    family text,
    genus text,
    species text,
    subtype text,
    subtype_name text,
    lifeform text,
    CONSTRAINT lifeform_check CHECK ((lifeform = ANY (ARRAY['shrub'::text, 'tree'::text, 'forb'::text, 'moss'::text, 'grass'::text, 'fungus'::text, 'perennial forb'::text, 'annual forb'::text, 'perennial grass'::text, 'annual grass'::text, 'biennial forb'::text, 'biennial grass'::text, 'fern'::text, 'lichen'::text, 'liverwort'::text, 'palm'::text, 'vine'::text, 'succulent'::text]))),
    CONSTRAINT subtype_check CHECK ((subtype = ANY (ARRAY['subspecies'::text, 'variety'::text])))
);


ALTER TABLE grp.species OWNER TO postgres;

--
-- TOC entry 270 (class 1259 OID 26894)
-- Name: full_cultivar; Type: VIEW; Schema: grp; Owner: postgres
--

CREATE VIEW grp.full_cultivar AS
 SELECT s.species_code,
    cultivar.cultivarid,
    cultivar.name,
    cultivar.origin,
    cultivar.latitude,
    cultivar.longitude
   FROM (grp.cultivar
     LEFT JOIN grp.species s USING (speciesid));


ALTER VIEW grp.full_cultivar OWNER TO postgres;

--
-- TOC entry 255 (class 1259 OID 25190)
-- Name: individual; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.individual (
    individualid integer NOT NULL,
    areaid integer,
    speciesid integer,
    latitude numeric,
    longitude numeric,
    position_x numeric,
    position_y numeric,
    position_units text,
    initial_dbh numeric,
    dbh_units text,
    initial_height numeric,
    height_units text,
    initial_age numeric,
    age_units text,
    CONSTRAINT initial_age_check CHECK (((0)::numeric <= initial_age)),
    CONSTRAINT initial_dbh_check CHECK (((0)::numeric <= initial_dbh)),
    CONSTRAINT initial_height_check CHECK (((0)::numeric <= initial_height)),
    CONSTRAINT latitude_check CHECK (((('-90'::integer)::numeric <= latitude) AND (latitude <= (90)::numeric))),
    CONSTRAINT longitude_check CHECK (((('-180'::integer)::numeric <= longitude) AND (longitude <= (180)::numeric)))
);


ALTER TABLE grp.individual OWNER TO postgres;

--
-- TOC entry 272 (class 1259 OID 26934)
-- Name: full_individual; Type: VIEW; Schema: grp; Owner: postgres
--

CREATE VIEW grp.full_individual AS
 SELECT p.database,
    p.projectid,
    i.individualid,
    i.areaid AS rep,
    s.species_code,
    i.latitude,
    i.longitude,
    i.position_x,
    i.position_y,
    i.position_units,
    i.initial_dbh,
    i.dbh_units,
    i.initial_height,
    i.height_units,
    i.initial_age,
    i.age_units
   FROM ((grp.individual i
     LEFT JOIN grp.area_treatment p USING (areaid))
     LEFT JOIN grp.species s USING (speciesid));


ALTER VIEW grp.full_individual OWNER TO postgres;

--
-- TOC entry 280 (class 1259 OID 27267)
-- Name: paper; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.paper (
    paperid integer NOT NULL,
    publication_year integer,
    publication_title text,
    publication_journal text,
    publication_doi text,
    publication_url text
);


ALTER TABLE grp.paper OWNER TO postgres;

--
-- TOC entry 282 (class 1259 OID 27293)
-- Name: paper_author; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.paper_author (
    paperid integer NOT NULL,
    author_contributorid integer NOT NULL,
    is_corresponding_author boolean
);


ALTER TABLE grp.paper_author OWNER TO postgres;

--
-- TOC entry 281 (class 1259 OID 27276)
-- Name: project_paper; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.project_paper (
    database text NOT NULL,
    projectid integer NOT NULL,
    paperid integer NOT NULL,
    notes text
);


ALTER TABLE grp.project_paper OWNER TO postgres;

--
-- TOC entry 293 (class 1259 OID 27438)
-- Name: full_paper; Type: VIEW; Schema: grp; Owner: postgres
--

CREATE VIEW grp.full_paper AS
 SELECT pp.database,
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
   FROM (((grp.project_paper pp
     LEFT JOIN grp.paper p ON ((pp.paperid = p.paperid)))
     LEFT JOIN ( SELECT pa.paperid,
            string_agg(((ac.given_name || ' '::text) || ac.surname), '; '::text ORDER BY ac.surname, ac.given_name) AS authors
           FROM (grp.paper_author pa
             LEFT JOIN grp.author_contributor ac ON ((pa.author_contributorid = ac.author_contributorid)))
          GROUP BY pa.paperid) a ON ((p.paperid = a.paperid)))
     LEFT JOIN ( SELECT pa.paperid,
            string_agg(((ac.given_name || ' '::text) || ac.surname), '; '::text ORDER BY ac.surname, ac.given_name) AS corresponding_author,
            string_agg(ac.email, '; '::text ORDER BY ac.surname, ac.given_name) AS email
           FROM (grp.paper_author pa
             LEFT JOIN grp.author_contributor ac ON ((pa.author_contributorid = ac.author_contributorid)))
          WHERE (pa.is_corresponding_author = true)
          GROUP BY pa.paperid) ca ON ((p.paperid = ca.paperid)))
  ORDER BY pp.database DESC, pp.projectid, p.paperid;


ALTER VIEW grp.full_paper OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 24684)
-- Name: location; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.location (
    locationid integer NOT NULL,
    continent text,
    country text,
    state text,
    CONSTRAINT continent_check CHECK ((continent = ANY (ARRAY['Central America'::text, 'Africa'::text, 'Oceania'::text, 'Europe'::text, 'Middle East and Asia'::text, 'North America'::text, 'South America'::text]))),
    CONSTRAINT country_check CHECK ((country = ANY (ARRAY['Taiwan'::text, 'Afghanistan'::text, 'Albania'::text, 'Algeria'::text, 'Andorra'::text, 'Angola'::text, 'Antigua and Barbuda'::text, 'Argentina'::text, 'Armenia'::text, 'Australia'::text, 'Austria'::text, 'Azerbaijan'::text, 'Bahamas'::text, 'Bahrain'::text, 'Bangladesh'::text, 'Barbados'::text, 'Belarus'::text, 'Belgium'::text, 'Belize'::text, 'Benin'::text, 'Bhutan'::text, 'Bolivia'::text, 'Bosnia and Herzegovina'::text, 'Botswana'::text, 'Brazil'::text, 'Brunei'::text, 'Bulgaria'::text, 'Burkina Faso'::text, 'Burundi'::text, 'Cabo Verde'::text, 'Cambodia'::text, 'Cameroon'::text, 'Canada'::text, 'Central African Republic'::text, 'Chad'::text, 'Chile'::text, 'China'::text, 'Colombia'::text, 'Comoros'::text, 'Congo'::text, 'Democratic Republic of the Congo'::text, 'Costa Rica'::text, 'Côte d’Ivoire'::text, 'Croatia'::text, 'Cuba'::text, 'Cyprus'::text, 'Czech Republic'::text, 'Denmark'::text, 'Djibouti'::text, 'Dominica'::text, 'Dominican Republic'::text, 'Ecuador'::text, 'Egypt'::text, 'El Salvador'::text, 'Equatorial Guinea'::text, 'Eritrea'::text, 'Estonia'::text, 'Eswatini'::text, 'Ethiopia'::text, 'Fiji'::text, 'Finland'::text, 'France'::text, 'Gabon'::text, 'Gambia'::text, 'Georgia'::text, 'Germany'::text, 'Ghana'::text, 'Greece'::text, 'Grenada'::text, 'Guatemala'::text, 'Guinea'::text, 'Guinea-Bissau'::text, 'Guyana'::text, 'Haiti'::text, 'Honduras'::text, 'Holy See'::text, 'Hungary'::text, 'Iceland'::text, 'India'::text, 'Indonesia'::text, 'Iran'::text, 'Iraq'::text, 'Ireland'::text, 'Israel'::text, 'Italy'::text, 'Jamaica'::text, 'Japan'::text, 'Jordan'::text, 'Kazakhstan'::text, 'Kenya'::text, 'Kiribati'::text, 'North Korea'::text, 'South Korea'::text, 'Kuwait'::text, 'Kyrgyzstan'::text, 'Laos'::text, 'Latvia'::text, 'Lebanon'::text, 'Lesotho'::text, 'Liberia'::text, 'Libya'::text, 'Liechtenstein'::text, 'Lithuania'::text, 'Luxembourg'::text, 'Madagascar'::text, 'Malawi'::text, 'Malaysia'::text, 'Maldives'::text, 'Mali'::text, 'Malta'::text, 'Marshall Islands'::text, 'Mauritania'::text, 'Mauritius'::text, 'Mexico'::text, 'Micronesia'::text, 'Moldova'::text, 'Monaco'::text, 'Mongolia'::text, 'Montenegro'::text, 'Morocco'::text, 'Mozambique'::text, 'Myanmar'::text, 'Namibia'::text, 'Nauru'::text, 'Nepal'::text, 'Netherlands'::text, 'New Zealand'::text, 'Nicaragua'::text, 'Niger'::text, 'Nigeria'::text, 'North Macedonia'::text, 'Norway'::text, 'Oman'::text, 'Pakistan'::text, 'Palau'::text, 'Palestine'::text, 'Panama'::text, 'Papua New Guinea'::text, 'Paraguay'::text, 'Peru'::text, 'Philippines'::text, 'Poland'::text, 'Portugal'::text, 'Qatar'::text, 'Romania'::text, 'Russian Federation'::text, 'Rwanda'::text, 'Saint Kitts and Nevis'::text, 'Saint Lucia'::text, 'Saint Vincent and the Grenadines'::text, 'Samoa'::text, 'San Marino'::text, 'Sao Tome and Principe'::text, 'Saudi Arabia'::text, 'Senegal'::text, 'Serbia'::text, 'Seychelles'::text, 'Sierra Leone'::text, 'Singapore'::text, 'Slovakia'::text, 'Slovenia'::text, 'Solomon Islands'::text, 'Somalia'::text, 'South Africa'::text, 'South Sudan'::text, 'Spain'::text, 'Sri Lanka'::text, 'Sudan'::text, 'Suriname'::text, 'Sweden'::text, 'Switzerland'::text, 'Syria'::text, 'Tajikistan'::text, 'Tanzania'::text, 'Thailand'::text, 'Timor-Leste'::text, 'Togo'::text, 'Tonga'::text, 'Trinidad and Tobago'::text, 'Tunisia'::text, 'Turkey'::text, 'Turkmenistan'::text, 'Tuvalu'::text, 'Uganda'::text, 'Ukraine'::text, 'United Arab Emirates'::text, 'United Kingdom'::text, 'England'::text, 'Scotland'::text, 'Wales'::text, 'Northern Ireland'::text, 'United States of America'::text, 'Uruguay'::text, 'Uzbekistan'::text, 'Vanuatu'::text, 'Venezuela'::text, 'Vietnam'::text, 'Yemen'::text, 'Zambia'::text, 'Zimbabwe'::text])))
);


ALTER TABLE grp.location OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 24704)
-- Name: project; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.project (
    database text NOT NULL,
    projectid integer NOT NULL,
    type text,
    community text,
    reference text,
    notes text,
    CONSTRAINT community_check CHECK ((community = ANY (ARRAY['yes'::text, 'no'::text, 'full community'::text, 'functional group'::text, 'seeded community'::text, 'tree community'::text]))),
    CONSTRAINT database_check CHECK ((database = ANY (ARRAY['GAZP'::text, 'GRP'::text, 'OM'::text]))),
    CONSTRAINT reference_check CHECK ((reference = ANY (ARRAY['yes'::text, 'not provided'::text]))),
    CONSTRAINT type_check CHECK ((type = ANY (ARRAY['artificial plots'::text, 'experimental planting'::text, 'experimental restoration'::text, 'experimental seeding'::text, 'landscape restoration'::text, 'reference'::text])))
);


ALTER TABLE grp.project OWNER TO postgres;

--
-- TOC entry 256 (class 1259 OID 25258)
-- Name: project_contributor; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.project_contributor (
    database text NOT NULL,
    projectid integer NOT NULL,
    author_contributorid integer NOT NULL
);


ALTER TABLE grp.project_contributor OWNER TO postgres;

--
-- TOC entry 292 (class 1259 OID 27426)
-- Name: project_data_accessibility; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.project_data_accessibility (
    data_accessibilityid integer NOT NULL,
    database text NOT NULL,
    projectid integer NOT NULL,
    availability text,
    data_citation text,
    data_doi text,
    data_url text,
    creativecommons_license text,
    use_conditions text,
    date_received date,
    data_accessibility_notes text
);


ALTER TABLE grp.project_data_accessibility OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 24716)
-- Name: project_location; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.project_location (
    database text NOT NULL,
    projectid integer NOT NULL,
    locationid integer NOT NULL
);


ALTER TABLE grp.project_location OWNER TO postgres;

--
-- TOC entry 258 (class 1259 OID 25292)
-- Name: project_vegmetric; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.project_vegmetric (
    database text NOT NULL,
    projectid integer NOT NULL,
    type text NOT NULL
);


ALTER TABLE grp.project_vegmetric OWNER TO postgres;

--
-- TOC entry 294 (class 1259 OID 27443)
-- Name: full_project; Type: VIEW; Schema: grp; Owner: postgres
--

CREATE VIEW grp.full_project AS
 SELECT project.database,
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
   FROM ((((grp.project
     LEFT JOIN grp.project_vegmetric ON (((project.database = project_vegmetric.database) AND (project.projectid = project_vegmetric.projectid))))
     LEFT JOIN ( SELECT project_contributor.database,
            project_contributor.projectid,
            string_agg(((author_contributor.given_name || ' '::text) || author_contributor.surname), '; '::text) AS contributor,
            string_agg(author_contributor.email, '; '::text) AS contributor_email
           FROM (grp.project_contributor
             LEFT JOIN grp.author_contributor USING (author_contributorid))
          GROUP BY project_contributor.database, project_contributor.projectid) c ON (((project.database = c.database) AND (project.projectid = c.projectid))))
     LEFT JOIN ( SELECT project_location.database,
            project_location.projectid,
            string_agg(location.continent, '; '::text) AS continent,
            string_agg(location.country, '; '::text) AS country,
            string_agg(location.state, '; '::text) AS state
           FROM (grp.project_location
             LEFT JOIN grp.location USING (locationid))
          GROUP BY project_location.database, project_location.projectid) l ON (((project.database = l.database) AND (project.projectid = l.projectid))))
     LEFT JOIN ( SELECT project_data_accessibility.database,
            project_data_accessibility.projectid,
            string_agg(project_data_accessibility.availability, '; '::text ORDER BY project_data_accessibility.data_accessibilityid) AS availability,
            string_agg(project_data_accessibility.data_citation, '; '::text ORDER BY project_data_accessibility.data_accessibilityid) AS data_citation,
            string_agg(project_data_accessibility.data_doi, '; '::text ORDER BY project_data_accessibility.data_accessibilityid) AS data_doi,
            string_agg(project_data_accessibility.data_url, '; '::text ORDER BY project_data_accessibility.data_accessibilityid) AS data_url,
            string_agg(project_data_accessibility.creativecommons_license, '; '::text ORDER BY project_data_accessibility.data_accessibilityid) AS creativecommons_license,
            string_agg(project_data_accessibility.use_conditions, '; '::text ORDER BY project_data_accessibility.data_accessibilityid) AS use_conditions,
            min(project_data_accessibility.date_received) AS first_date_received,
            max(project_data_accessibility.date_received) AS latest_date_received,
            string_agg(project_data_accessibility.data_accessibility_notes, '; '::text ORDER BY project_data_accessibility.data_accessibilityid) AS data_accessibility_notes
           FROM grp.project_data_accessibility
          GROUP BY project_data_accessibility.database, project_data_accessibility.projectid) pda ON (((project.database = pda.database) AND (project.projectid = pda.projectid))))
  GROUP BY project.database, project.projectid, project.type, c.contributor, c.contributor_email, l.continent, l.country, l.state, project.community, project.reference, pda.availability, pda.data_citation, pda.data_doi, pda.data_url, pda.creativecommons_license, pda.use_conditions, pda.first_date_received, pda.latest_date_received, pda.data_accessibility_notes, project.notes
  ORDER BY project.database, project.projectid;


ALTER VIEW grp.full_project OWNER TO postgres;

--
-- TOC entry 275 (class 1259 OID 27214)
-- Name: full_seeding; Type: VIEW; Schema: grp; Owner: postgres
--

CREATE VIEW grp.full_seeding AS
SELECT
    NULL::integer AS treatmentid,
    NULL::integer AS seed_mixid,
    NULL::text AS mix_name,
    NULL::text AS mix_composition_status,
    NULL::text AS treated_richness,
    NULL::text AS legacy_mix_name,
    NULL::text AS seed_mix_notes,
    NULL::text AS species,
    NULL::integer AS cultivarid,
    NULL::text AS type,
    NULL::numeric AS rate,
    NULL::text AS unit,
    NULL::text AS viability,
    NULL::text AS pretreatment,
    NULL::text AS origin,
    NULL::text AS source,
    NULL::text AS seed_distance,
    NULL::text AS seeding_notes;


ALTER VIEW grp.full_seeding OWNER TO postgres;

--
-- TOC entry 257 (class 1259 OID 25275)
-- Name: project_site; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.project_site (
    database text NOT NULL,
    projectid integer NOT NULL,
    siteid integer NOT NULL
);


ALTER TABLE grp.project_site OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 24746)
-- Name: site; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.site (
    siteid integer NOT NULL,
    name text,
    latitude numeric,
    longitude numeric,
    aridity numeric,
    annual_temp numeric,
    annual_precip smallint,
    CONSTRAINT aridity_check CHECK (((0)::numeric <= aridity)),
    CONSTRAINT latitude_check CHECK (((('-90'::integer)::numeric <= latitude) AND (latitude <= (90)::numeric))),
    CONSTRAINT longitude_check CHECK (((('-180'::integer)::numeric <= longitude) AND (longitude <= (180)::numeric)))
);


ALTER TABLE grp.site OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 24761)
-- Name: site_classification; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.site_classification (
    siteid integer NOT NULL,
    classificationid text NOT NULL
);


ALTER TABLE grp.site_classification OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 24778)
-- Name: site_disturbance; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.site_disturbance (
    siteid integer NOT NULL,
    type text NOT NULL
);


ALTER TABLE grp.site_disturbance OWNER TO postgres;

--
-- TOC entry 259 (class 1259 OID 25334)
-- Name: site_invasive; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.site_invasive (
    siteid integer NOT NULL,
    speciesid integer NOT NULL
);


ALTER TABLE grp.site_invasive OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 24807)
-- Name: site_ref_ecosystem; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.site_ref_ecosystem (
    siteid integer NOT NULL,
    description text NOT NULL
);


ALTER TABLE grp.site_ref_ecosystem OWNER TO postgres;

--
-- TOC entry 232 (class 1259 OID 24822)
-- Name: site_soil_soilid_seq; Type: SEQUENCE; Schema: grp; Owner: postgres
--

CREATE SEQUENCE grp.site_soil_soilid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE grp.site_soil_soilid_seq OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 24823)
-- Name: site_soil; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.site_soil (
    soilid integer DEFAULT nextval('grp.site_soil_soilid_seq'::regclass) NOT NULL,
    siteid integer NOT NULL,
    sand numeric,
    silt numeric,
    clay numeric,
    description text,
    depth text,
    CONSTRAINT clay_check CHECK ((((0)::numeric <= clay) AND (clay <= (100)::numeric))),
    CONSTRAINT sand_check CHECK ((((0)::numeric <= sand) AND (sand <= (100)::numeric))),
    CONSTRAINT silt_check CHECK ((((0)::numeric <= silt) AND (silt <= (100)::numeric)))
);


ALTER TABLE grp.site_soil OWNER TO postgres;

--
-- TOC entry 287 (class 1259 OID 27379)
-- Name: full_site; Type: VIEW; Schema: grp; Owner: postgres
--

CREATE VIEW grp.full_site AS
 SELECT ps.database,
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
   FROM ((((((grp.site
     LEFT JOIN grp.project_site ps ON ((site.siteid = ps.siteid)))
     LEFT JOIN grp.site_ref_ecosystem rf ON ((site.siteid = rf.siteid)))
     LEFT JOIN ( SELECT site_classification.siteid,
            classification.class,
            classification.subclass,
            classification.subsubclass
           FROM (grp.site_classification
             LEFT JOIN grp.classification USING (classificationid))) c ON ((site.siteid = c.siteid)))
     LEFT JOIN grp.site_soil s ON ((site.siteid = s.siteid)))
     LEFT JOIN grp.site_disturbance d ON ((site.siteid = d.siteid)))
     LEFT JOIN ( SELECT site_invasive.siteid,
            species.species_code AS invasives,
            species.lifeform AS invasive_lifeform
           FROM (grp.site_invasive
             LEFT JOIN grp.species USING (speciesid))) spec ON ((site.siteid = spec.siteid)));


ALTER VIEW grp.full_site OWNER TO postgres;

--
-- TOC entry 288 (class 1259 OID 27384)
-- Name: full_species; Type: VIEW; Schema: grp; Owner: postgres
--

CREATE VIEW grp.full_species AS
SELECT
    NULL::integer AS speciesid,
    NULL::text AS species_code,
    NULL::text AS "group",
    NULL::text AS "order",
    NULL::text AS family,
    NULL::text AS genus,
    NULL::text AS species,
    NULL::text AS subtype,
    NULL::text AS subtype_name,
    NULL::text AS lifespan,
    NULL::text AS lifeform;


ALTER VIEW grp.full_species OWNER TO postgres;

--
-- TOC entry 296 (class 1259 OID 27456)
-- Name: full_treatment; Type: VIEW; Schema: grp; Owner: postgres
--

CREATE VIEW grp.full_treatment AS
SELECT
    NULL::text AS database,
    NULL::integer AS projectid,
    NULL::integer AS treatmentid,
    NULL::numeric(4,0) AS year,
    NULL::numeric(2,0) AS month,
    NULL::numeric(2,0) AS day,
    NULL::smallint AS weeks_since_restoration,
    NULL::text AS other_treatment,
    NULL::text AS application_method,
    NULL::text AS bed_material,
    NULL::text AS bed_prep,
    NULL::text AS erosion_control,
    NULL::text AS fertilization_type,
    NULL::text AS fertilization_amount,
    NULL::text AS fertilization_units,
    NULL::text AS fertilization_info,
    NULL::text AS grading,
    NULL::text AS grazer,
    NULL::text AS grazer_notes,
    NULL::text AS growth_medium,
    NULL::text AS top_soil_age,
    NULL::text AS growth_medium_depth,
    NULL::text AS growth_medium_depth_units,
    NULL::text AS growth_medium_info,
    NULL::text AS herbicide_type,
    NULL::text AS herbicide_chemical,
    NULL::text AS herbicide_amount,
    NULL::text AS herbicide_units,
    NULL::text AS invasion_control,
    NULL::text AS irrigation_type,
    NULL::text AS irrigation_amount,
    NULL::text AS irrigation_units,
    NULL::text AS irrigation_info,
    NULL::text AS mowing_type,
    NULL::text AS mowing_height_class,
    NULL::text AS mowing_amount,
    NULL::text AS mowing_units,
    NULL::text AS mowing_notes,
    NULL::text AS cover_crop_speciesid,
    NULL::text AS cover_crop_amount,
    NULL::text AS cover_crop_units,
    NULL::text AS cover_crop_notes,
    NULL::text AS shelter,
    NULL::boolean AS maintenance_fire,
    NULL::text AS treatment_notes;


ALTER VIEW grp.full_treatment OWNER TO postgres;

--
-- TOC entry 268 (class 1259 OID 26796)
-- Name: veg_result_vegresultid_seq; Type: SEQUENCE; Schema: grp; Owner: postgres
--

CREATE SEQUENCE grp.veg_result_vegresultid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE grp.veg_result_vegresultid_seq OWNER TO postgres;

--
-- TOC entry 260 (class 1259 OID 25391)
-- Name: veg_result; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.veg_result (
    veg_resultid integer DEFAULT nextval('grp.veg_result_vegresultid_seq'::regclass) NOT NULL,
    areaid integer NOT NULL,
    time_since_restoration smallint,
    year numeric(4,0),
    month numeric(2,0),
    day numeric(2,0),
    speciesid integer,
    cultivarid integer,
    individualid integer,
    origin text,
    level text,
    response numeric,
    metric text,
    notes text,
    CONSTRAINT day_check CHECK ((((1)::numeric <= day) AND (day <= (31)::numeric))),
    CONSTRAINT level_check CHECK ((level = ANY (ARRAY['species'::text, 'functional group'::text, 'plot'::text, 'individual'::text, 'non-species'::text, 'non-vascular species'::text]))),
    CONSTRAINT metric_check CHECK ((metric = ANY (ARRAY['basal area'::text, 'height'::text, 'basal diameter'::text, 'abundance'::text, 'area'::text, 'biomass'::text, 'cm'::text, 'cover'::text, 'DBH'::text, 'density'::text, 'emergence rate'::text, 'frequency'::text, 'survival rate'::text, 'presence'::text, 'cover class'::text]))),
    CONSTRAINT month_check CHECK ((((1)::numeric <= month) AND (month <= (12)::numeric))),
    CONSTRAINT origin_check CHECK ((origin = ANY (ARRAY['native'::text, 'exotic'::text, 'unknown'::text, 'mixed'::text])))
);


ALTER TABLE grp.veg_result OWNER TO postgres;

--
-- TOC entry 271 (class 1259 OID 26920)
-- Name: full_veg_results; Type: VIEW; Schema: grp; Owner: postgres
--

CREATE VIEW grp.full_veg_results AS
 SELECT ps.database,
    ps.projectid,
    veg_result.areaid AS rep,
    veg_result.year,
    veg_result.month,
    veg_result.day,
    veg_result.time_since_restoration,
    s.species_code,
    cultivar.cultivarid,
    veg_result.individualid,
    veg_result.origin,
    veg_result.level,
    veg_result.response,
    veg_result.metric,
    veg_result.notes
   FROM (((grp.veg_result
     LEFT JOIN grp.species s USING (speciesid))
     LEFT JOIN grp.cultivar cultivar(cultivarid, speciesid_1, name, origin, latitude, longitude) USING (cultivarid))
     LEFT JOIN ( SELECT project_site.database,
            project_site.projectid,
            area.areaid
           FROM (grp.area
             LEFT JOIN grp.project_site USING (siteid))) ps USING (areaid))
  ORDER BY ps.database, ps.projectid;


ALTER VIEW grp.full_veg_results OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 24644)
-- Name: grazer; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.grazer (
    type text NOT NULL,
    definition text,
    notes text
);


ALTER TABLE grp.grazer OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 24651)
-- Name: growth_medium; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.growth_medium (
    type text NOT NULL,
    definition text,
    notes text
);


ALTER TABLE grp.growth_medium OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 24658)
-- Name: herbicide; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.herbicide (
    type text NOT NULL,
    definition text,
    notes text
);


ALTER TABLE grp.herbicide OWNER TO postgres;

--
-- TOC entry 276 (class 1259 OID 27219)
-- Name: import_batch; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.import_batch (
    import_batchid integer NOT NULL,
    database text NOT NULL,
    projectid integer,
    source_folder text,
    source_file_list text,
    pipeline_stage_start text,
    pipeline_stage_end text,
    processed_by text,
    processed_date date,
    workflow_version text,
    notes text,
    CONSTRAINT import_batch_database_check CHECK ((database = ANY (ARRAY['GAZP'::text, 'GRP'::text, 'OM'::text])))
);


ALTER TABLE grp.import_batch OWNER TO postgres;

--
-- TOC entry 277 (class 1259 OID 27232)
-- Name: import_object_map; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.import_object_map (
    import_object_mapid integer NOT NULL,
    import_batchid integer NOT NULL,
    database text NOT NULL,
    projectid integer,
    source_layer text,
    source_object_type text,
    source_object_id text,
    source_object_label text,
    source_identifier_text text,
    grp_object_type text,
    grp_object_id integer,
    mapping_type text,
    mapping_notes text,
    CONSTRAINT import_object_map_database_check CHECK ((database = ANY (ARRAY['GAZP'::text, 'GRP'::text, 'OM'::text])))
);


ALTER TABLE grp.import_object_map OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 24666)
-- Name: invasion_control; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.invasion_control (
    type text NOT NULL,
    definition text,
    notes text
);


ALTER TABLE grp.invasion_control OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 24673)
-- Name: lifespan; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.lifespan (
    type text NOT NULL,
    definition text,
    notes text
);


ALTER TABLE grp.lifespan OWNER TO postgres;

--
-- TOC entry 295 (class 1259 OID 27449)
-- Name: mowing; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.mowing (
    type text NOT NULL,
    definition text,
    notes text
);


ALTER TABLE grp.mowing OWNER TO postgres;

--
-- TOC entry 279 (class 1259 OID 27266)
-- Name: paper_paperid_seq; Type: SEQUENCE; Schema: grp; Owner: postgres
--

ALTER TABLE grp.paper ALTER COLUMN paperid ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME grp.paper_paperid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 224 (class 1259 OID 24697)
-- Name: pretreatment; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.pretreatment (
    type text NOT NULL,
    definition text,
    notes text
);


ALTER TABLE grp.pretreatment OWNER TO postgres;

--
-- TOC entry 291 (class 1259 OID 27425)
-- Name: project_data_accessibility_data_accessibilityid_seq; Type: SEQUENCE; Schema: grp; Owner: postgres
--

ALTER TABLE grp.project_data_accessibility ALTER COLUMN data_accessibilityid ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME grp.project_data_accessibility_data_accessibilityid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 274 (class 1259 OID 27197)
-- Name: seed_mix; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.seed_mix (
    seed_mixid integer NOT NULL,
    treatmentid integer NOT NULL,
    mix_name text,
    mix_composition_status text,
    treated_richness text,
    notes text
);


ALTER TABLE grp.seed_mix OWNER TO postgres;

--
-- TOC entry 261 (class 1259 OID 25440)
-- Name: seeding; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.seeding (
    seedingid integer NOT NULL,
    treatmentid integer NOT NULL,
    mix text,
    speciesid integer,
    cultivarid integer,
    type text,
    rate numeric,
    unit text,
    viability text,
    origin text,
    source text,
    seed_distance text,
    seed_mixid integer NOT NULL,
    notes text,
    CONSTRAINT origin_check CHECK ((origin = ANY (ARRAY['mixed'::text, 'native'::text, 'exotic'::text, 'unknown'::text]))),
    CONSTRAINT source_check CHECK ((source = ANY (ARRAY['local'::text, 'commercial and wild'::text, 'farmed'::text, 'commercial'::text, 'wild'::text]))),
    CONSTRAINT type_check CHECK ((type = ANY (ARRAY['seeding'::text, 'planting'::text]))),
    CONSTRAINT unit_check CHECK ((unit = ANY (ARRAY['stems/ha'::text, 'g/ha'::text, 'g/km'::text, 'lbs/ac'::text, 'ounces/plot'::text, 'seeds/m2'::text, 'g/cell'::text, 'g/m2'::text, 'individuals/plot'::text, 'individuals/site'::text, 'seeds/plot'::text, 'seeds/pool'::text, 'unknown'::text]))),
    CONSTRAINT viability_check CHECK ((viability = ANY (ARRAY['PLS'::text, 'lab'::text, 'NA'::text])))
);


ALTER TABLE grp.seeding OWNER TO postgres;

--
-- TOC entry 262 (class 1259 OID 25469)
-- Name: seeding_pretreatment; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.seeding_pretreatment (
    seedingid integer NOT NULL,
    type text NOT NULL
);


ALTER TABLE grp.seeding_pretreatment OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 24876)
-- Name: species_lifespan; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.species_lifespan (
    speciesid integer NOT NULL,
    description text NOT NULL
);


ALTER TABLE grp.species_lifespan OWNER TO postgres;

--
-- TOC entry 236 (class 1259 OID 24893)
-- Name: species_names; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.species_names (
    speciesid integer NOT NULL,
    species_code text NOT NULL,
    name text NOT NULL
);


ALTER TABLE grp.species_names OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 24909)
-- Name: treatment; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.treatment (
    treatmentid integer NOT NULL,
    year numeric(4,0),
    month numeric(2,0),
    day numeric(2,0),
    weeks_since_restoration smallint,
    other_treatment text,
    shelter text,
    grading text,
    maintenance_fire boolean,
    notes text,
    CONSTRAINT day_check CHECK ((((1)::numeric <= day) AND (day <= (31)::numeric))),
    CONSTRAINT grading_check CHECK ((grading = ANY (ARRAY['yes'::text, 'no'::text]))),
    CONSTRAINT month_check CHECK ((((1)::numeric <= month) AND (month <= (12)::numeric))),
    CONSTRAINT shelter_check CHECK ((shelter = ANY (ARRAY['natural'::text, 'artificial'::text, 'living'::text, 'blanket'::text])))
);


ALTER TABLE grp.treatment OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 24921)
-- Name: treatment_application; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.treatment_application (
    treatmentid integer NOT NULL,
    type text NOT NULL
);


ALTER TABLE grp.treatment_application OWNER TO postgres;

--
-- TOC entry 284 (class 1259 OID 27314)
-- Name: treatment_cover_crop; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.treatment_cover_crop (
    covercropid integer NOT NULL,
    treatmentid integer NOT NULL,
    speciesid integer NOT NULL,
    amount numeric,
    units text,
    notes text
);


ALTER TABLE grp.treatment_cover_crop OWNER TO postgres;

--
-- TOC entry 283 (class 1259 OID 27313)
-- Name: treatment_cover_crop_covercropid_seq; Type: SEQUENCE; Schema: grp; Owner: postgres
--

ALTER TABLE grp.treatment_cover_crop ALTER COLUMN covercropid ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME grp.treatment_cover_crop_covercropid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 239 (class 1259 OID 24938)
-- Name: treatment_erosion; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.treatment_erosion (
    treatmentid integer NOT NULL,
    type text NOT NULL
);


ALTER TABLE grp.treatment_erosion OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 24958)
-- Name: treatment_fertilization_treatment_fertilizationid_seq; Type: SEQUENCE; Schema: grp; Owner: postgres
--

CREATE SEQUENCE grp.treatment_fertilization_treatment_fertilizationid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE grp.treatment_fertilization_treatment_fertilizationid_seq OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 24959)
-- Name: treatment_fertilization; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.treatment_fertilization (
    treatment_fertilizationid integer DEFAULT nextval('grp.treatment_fertilization_treatment_fertilizationid_seq'::regclass) NOT NULL,
    treatmentid integer NOT NULL,
    type text NOT NULL,
    amount numeric,
    units text,
    notes text
);


ALTER TABLE grp.treatment_fertilization OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 24977)
-- Name: treatment_grazer; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.treatment_grazer (
    treatmentid integer NOT NULL,
    type text NOT NULL,
    notes text
);


ALTER TABLE grp.treatment_grazer OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 24997)
-- Name: treatment_herbicide_treatment_herbicideid_seq; Type: SEQUENCE; Schema: grp; Owner: postgres
--

CREATE SEQUENCE grp.treatment_herbicide_treatment_herbicideid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE grp.treatment_herbicide_treatment_herbicideid_seq OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 24998)
-- Name: treatment_herbicide; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.treatment_herbicide (
    treatment_herbicideid integer DEFAULT nextval('grp.treatment_herbicide_treatment_herbicideid_seq'::regclass) NOT NULL,
    treatmentid integer NOT NULL,
    type text,
    chemical text,
    amount numeric,
    units text
);


ALTER TABLE grp.treatment_herbicide OWNER TO postgres;

--
-- TOC entry 245 (class 1259 OID 25016)
-- Name: treatment_invasion; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.treatment_invasion (
    treatmentid integer NOT NULL,
    type text NOT NULL
);


ALTER TABLE grp.treatment_invasion OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 25037)
-- Name: treatment_irrigation_treatment_irrigationid_seq; Type: SEQUENCE; Schema: grp; Owner: postgres
--

CREATE SEQUENCE grp.treatment_irrigation_treatment_irrigationid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE grp.treatment_irrigation_treatment_irrigationid_seq OWNER TO postgres;

--
-- TOC entry 247 (class 1259 OID 25038)
-- Name: treatment_irrigation; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.treatment_irrigation (
    treatment_irrigationid integer DEFAULT nextval('grp.treatment_irrigation_treatment_irrigationid_seq'::regclass) NOT NULL,
    treatmentid integer NOT NULL,
    type text NOT NULL,
    amount numeric,
    units text,
    notes text,
    CONSTRAINT type_check CHECK ((type = ANY (ARRAY['irrigation'::text, 'reduction'::text]))),
    CONSTRAINT units_check CHECK (((units = 'proportion'::text) OR (units ~~ 'mm/%'::text)))
);


ALTER TABLE grp.treatment_irrigation OWNER TO postgres;

--
-- TOC entry 248 (class 1259 OID 25053)
-- Name: treatment_material; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.treatment_material (
    treatmentid integer NOT NULL,
    type text NOT NULL
);


ALTER TABLE grp.treatment_material OWNER TO postgres;

--
-- TOC entry 249 (class 1259 OID 25073)
-- Name: treatment_medium_treatment_mediumid_seq; Type: SEQUENCE; Schema: grp; Owner: postgres
--

CREATE SEQUENCE grp.treatment_medium_treatment_mediumid_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE grp.treatment_medium_treatment_mediumid_seq OWNER TO postgres;

--
-- TOC entry 250 (class 1259 OID 25074)
-- Name: treatment_medium; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.treatment_medium (
    treatment_mediumid integer DEFAULT nextval('grp.treatment_medium_treatment_mediumid_seq'::regclass) NOT NULL,
    treatmentid integer NOT NULL,
    type text,
    top_soil_age numeric,
    notes text,
    growth_medium_depth numeric,
    growth_medium_depth_units text,
    CONSTRAINT topsoil_age_check CHECK ((top_soil_age >= (0)::numeric))
);


ALTER TABLE grp.treatment_medium OWNER TO postgres;

--
-- TOC entry 286 (class 1259 OID 27356)
-- Name: treatment_mowing; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.treatment_mowing (
    mowingid integer NOT NULL,
    treatmentid integer NOT NULL,
    type text NOT NULL,
    height_class text,
    amount numeric,
    units text,
    notes text
);


ALTER TABLE grp.treatment_mowing OWNER TO postgres;

--
-- TOC entry 285 (class 1259 OID 27355)
-- Name: treatment_mowing_mowingid_seq; Type: SEQUENCE; Schema: grp; Owner: postgres
--

ALTER TABLE grp.treatment_mowing ALTER COLUMN mowingid ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME grp.treatment_mowing_mowingid_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 251 (class 1259 OID 25093)
-- Name: treatment_prep; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.treatment_prep (
    treatmentid integer NOT NULL,
    type text NOT NULL
);


ALTER TABLE grp.treatment_prep OWNER TO postgres;

--
-- TOC entry 297 (class 1259 OID 27461)
-- Name: treatments_by_area; Type: VIEW; Schema: grp; Owner: postgres
--

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


ALTER VIEW grp.treatments_by_area OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 24733)
-- Name: vegmetric; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.vegmetric (
    type text NOT NULL,
    definition text,
    notes text
);


ALTER TABLE grp.vegmetric OWNER TO postgres;

--
-- TOC entry 290 (class 1259 OID 27404)
-- Name: view_dictionary; Type: TABLE; Schema: grp; Owner: postgres
--

CREATE TABLE grp.view_dictionary (
    view_name text NOT NULL,
    display_order integer,
    view_level text,
    primary_table text,
    is_denormalized boolean,
    purpose text,
    expected_row_grain text,
    key_assumptions text,
    known_limitations text,
    notes text,
    CONSTRAINT view_dictionary_view_level_check CHECK ((view_level = ANY (ARRAY['entity'::text, 'bridge'::text, 'reporting'::text, 'summary'::text])))
);


ALTER TABLE grp.view_dictionary OWNER TO postgres;

--
-- TOC entry 5338 (class 2606 OID 24596)
-- Name: application_method application_method_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.application_method
    ADD CONSTRAINT application_method_pkey PRIMARY KEY (type);


--
-- TOC entry 5444 (class 2606 OID 26865)
-- Name: area area_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.area
    ADD CONSTRAINT area_pkey PRIMARY KEY (areaid);


--
-- TOC entry 5416 (class 2606 OID 25136)
-- Name: area_treatment area_treatment_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.area_treatment
    ADD CONSTRAINT area_treatment_pkey PRIMARY KEY (database, projectid, areaid, treatmentid);


--
-- TOC entry 5418 (class 2606 OID 25161)
-- Name: author_contributor author_contributor_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.author_contributor
    ADD CONSTRAINT author_contributor_pkey PRIMARY KEY (author_contributorid);


--
-- TOC entry 5420 (class 2606 OID 25163)
-- Name: author_contributor author_email_unique; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.author_contributor
    ADD CONSTRAINT author_email_unique UNIQUE (email);


--
-- TOC entry 5340 (class 2606 OID 24603)
-- Name: bed_material bed_material_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.bed_material
    ADD CONSTRAINT bed_material_pkey PRIMARY KEY (type);


--
-- TOC entry 5342 (class 2606 OID 24610)
-- Name: bed_prep bed_prep_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.bed_prep
    ADD CONSTRAINT bed_prep_pkey PRIMARY KEY (type);


--
-- TOC entry 5344 (class 2606 OID 24620)
-- Name: classification classification_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.classification
    ADD CONSTRAINT classification_pkey PRIMARY KEY (classificationid);


--
-- TOC entry 5346 (class 2606 OID 24622)
-- Name: classification classification_unique; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.classification
    ADD CONSTRAINT classification_unique UNIQUE (class, subclass, subsubclass);


--
-- TOC entry 5464 (class 2606 OID 27320)
-- Name: treatment_cover_crop cover_crop_pk; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_cover_crop
    ADD CONSTRAINT cover_crop_pk PRIMARY KEY (covercropid);


--
-- TOC entry 5422 (class 2606 OID 25707)
-- Name: cultivar cultivar_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.cultivar
    ADD CONSTRAINT cultivar_pkey PRIMARY KEY (cultivarid, speciesid);


--
-- TOC entry 5452 (class 2606 OID 27252)
-- Name: data_dictionary data_dictionary_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.data_dictionary
    ADD CONSTRAINT data_dictionary_pkey PRIMARY KEY (dictionaryid);


--
-- TOC entry 5454 (class 2606 OID 27254)
-- Name: data_dictionary data_dictionary_unique; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.data_dictionary
    ADD CONSTRAINT data_dictionary_unique UNIQUE (table_name, column_name);


--
-- TOC entry 5348 (class 2606 OID 24629)
-- Name: disturbance disturbance_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.disturbance
    ADD CONSTRAINT disturbance_pkey PRIMARY KEY (type);


--
-- TOC entry 5350 (class 2606 OID 24636)
-- Name: erosion_control erosion_control_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.erosion_control
    ADD CONSTRAINT erosion_control_pkey PRIMARY KEY (type);


--
-- TOC entry 5352 (class 2606 OID 24643)
-- Name: fertilization fertilization_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.fertilization
    ADD CONSTRAINT fertilization_pkey PRIMARY KEY (type);


--
-- TOC entry 5354 (class 2606 OID 24650)
-- Name: grazer grazer_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.grazer
    ADD CONSTRAINT grazer_pkey PRIMARY KEY (type);


--
-- TOC entry 5356 (class 2606 OID 24657)
-- Name: growth_medium growth_medium_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.growth_medium
    ADD CONSTRAINT growth_medium_pkey PRIMARY KEY (type);


--
-- TOC entry 5358 (class 2606 OID 24664)
-- Name: herbicide herbicide_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.herbicide
    ADD CONSTRAINT herbicide_pkey PRIMARY KEY (type);


--
-- TOC entry 5448 (class 2606 OID 27226)
-- Name: import_batch import_batch_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.import_batch
    ADD CONSTRAINT import_batch_pkey PRIMARY KEY (import_batchid);


--
-- TOC entry 5450 (class 2606 OID 27239)
-- Name: import_object_map import_object_map_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.import_object_map
    ADD CONSTRAINT import_object_map_pkey PRIMARY KEY (import_object_mapid);


--
-- TOC entry 5424 (class 2606 OID 25201)
-- Name: individual individual_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.individual
    ADD CONSTRAINT individual_pkey PRIMARY KEY (individualid);


--
-- TOC entry 5360 (class 2606 OID 24672)
-- Name: invasion_control invasion_control_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.invasion_control
    ADD CONSTRAINT invasion_control_pkey PRIMARY KEY (type);


--
-- TOC entry 5362 (class 2606 OID 24679)
-- Name: lifespan lifespan_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.lifespan
    ADD CONSTRAINT lifespan_pkey PRIMARY KEY (type);


--
-- TOC entry 5364 (class 2606 OID 24694)
-- Name: location location_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.location
    ADD CONSTRAINT location_pkey PRIMARY KEY (locationid);


--
-- TOC entry 5366 (class 2606 OID 24696)
-- Name: location location_unique; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.location
    ADD CONSTRAINT location_unique UNIQUE (continent, country, state);


--
-- TOC entry 5466 (class 2606 OID 27362)
-- Name: treatment_mowing mowing_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_mowing
    ADD CONSTRAINT mowing_pkey PRIMARY KEY (mowingid);


--
-- TOC entry 5472 (class 2606 OID 27455)
-- Name: mowing mowing_pkey1; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.mowing
    ADD CONSTRAINT mowing_pkey1 PRIMARY KEY (type);


--
-- TOC entry 5456 (class 2606 OID 27273)
-- Name: paper paper_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.paper
    ADD CONSTRAINT paper_pkey PRIMARY KEY (paperid);


--
-- TOC entry 5462 (class 2606 OID 27297)
-- Name: paper_author pk_paper_author; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.paper_author
    ADD CONSTRAINT pk_paper_author PRIMARY KEY (paperid, author_contributorid);


--
-- TOC entry 5368 (class 2606 OID 24703)
-- Name: pretreatment pretreatment_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.pretreatment
    ADD CONSTRAINT pretreatment_pkey PRIMARY KEY (type);


--
-- TOC entry 5426 (class 2606 OID 25264)
-- Name: project_contributor project_contributor_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.project_contributor
    ADD CONSTRAINT project_contributor_pkey PRIMARY KEY (database, projectid, author_contributorid);


--
-- TOC entry 5470 (class 2606 OID 27432)
-- Name: project_data_accessibility project_data_accessibility_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.project_data_accessibility
    ADD CONSTRAINT project_data_accessibility_pkey PRIMARY KEY (data_accessibilityid);


--
-- TOC entry 5372 (class 2606 OID 24722)
-- Name: project_location project_location_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.project_location
    ADD CONSTRAINT project_location_pkey PRIMARY KEY (database, projectid, locationid);


--
-- TOC entry 5460 (class 2606 OID 27282)
-- Name: project_paper project_paper_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.project_paper
    ADD CONSTRAINT project_paper_pkey PRIMARY KEY (database, projectid, paperid);


--
-- TOC entry 5370 (class 2606 OID 24715)
-- Name: project project_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.project
    ADD CONSTRAINT project_pkey PRIMARY KEY (projectid, database);


--
-- TOC entry 5428 (class 2606 OID 26850)
-- Name: project_site project_site_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.project_site
    ADD CONSTRAINT project_site_pkey PRIMARY KEY (database, projectid, siteid);


--
-- TOC entry 5430 (class 2606 OID 25298)
-- Name: project_vegmetric project_vegmetric_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.project_vegmetric
    ADD CONSTRAINT project_vegmetric_pkey PRIMARY KEY (database, projectid, type);


--
-- TOC entry 5458 (class 2606 OID 27275)
-- Name: paper publication_doi_unique; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.paper
    ADD CONSTRAINT publication_doi_unique UNIQUE (publication_doi);


--
-- TOC entry 5446 (class 2606 OID 27203)
-- Name: seed_mix seed_mix_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.seed_mix
    ADD CONSTRAINT seed_mix_pkey PRIMARY KEY (seed_mixid);


--
-- TOC entry 5438 (class 2606 OID 25451)
-- Name: seeding seeding_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.seeding
    ADD CONSTRAINT seeding_pkey PRIMARY KEY (seedingid);


--
-- TOC entry 5440 (class 2606 OID 25475)
-- Name: seeding_pretreatment seeding_pretreatment_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.seeding_pretreatment
    ADD CONSTRAINT seeding_pretreatment_pkey PRIMARY KEY (seedingid, type);


--
-- TOC entry 5378 (class 2606 OID 26817)
-- Name: site_classification site_classification_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.site_classification
    ADD CONSTRAINT site_classification_pkey PRIMARY KEY (siteid, classificationid);


--
-- TOC entry 5380 (class 2606 OID 26848)
-- Name: site_disturbance site_disturbance_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.site_disturbance
    ADD CONSTRAINT site_disturbance_pkey PRIMARY KEY (siteid, type);


--
-- TOC entry 5432 (class 2606 OID 26846)
-- Name: site_invasive site_invasive_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.site_invasive
    ADD CONSTRAINT site_invasive_pkey PRIMARY KEY (siteid, speciesid);


--
-- TOC entry 5376 (class 2606 OID 26812)
-- Name: site site_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.site
    ADD CONSTRAINT site_pkey PRIMARY KEY (siteid);


--
-- TOC entry 5382 (class 2606 OID 26844)
-- Name: site_ref_ecosystem site_ref_ecosystem_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.site_ref_ecosystem
    ADD CONSTRAINT site_ref_ecosystem_pkey PRIMARY KEY (siteid, description);


--
-- TOC entry 5384 (class 2606 OID 24833)
-- Name: site_soil site_soil_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.site_soil
    ADD CONSTRAINT site_soil_pkey PRIMARY KEY (soilid);


--
-- TOC entry 5390 (class 2606 OID 24882)
-- Name: species_lifespan species_lifespan_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.species_lifespan
    ADD CONSTRAINT species_lifespan_pkey PRIMARY KEY (speciesid, description);


--
-- TOC entry 5392 (class 2606 OID 24899)
-- Name: species_names species_name_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.species_names
    ADD CONSTRAINT species_name_pkey PRIMARY KEY (speciesid, species_code);


--
-- TOC entry 5386 (class 2606 OID 24872)
-- Name: species species_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.species
    ADD CONSTRAINT species_pkey PRIMARY KEY (speciesid);


--
-- TOC entry 5388 (class 2606 OID 24874)
-- Name: species species_unique; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.species
    ADD CONSTRAINT species_unique UNIQUE ("group", "order", family, genus, species, subtype, subtype_name);


--
-- TOC entry 5396 (class 2606 OID 24927)
-- Name: treatment_application treatment_application_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_application
    ADD CONSTRAINT treatment_application_pkey PRIMARY KEY (treatmentid, type);


--
-- TOC entry 5398 (class 2606 OID 24944)
-- Name: treatment_erosion treatment_erosion_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_erosion
    ADD CONSTRAINT treatment_erosion_pkey PRIMARY KEY (treatmentid, type);


--
-- TOC entry 5400 (class 2606 OID 24966)
-- Name: treatment_fertilization treatment_fertilization_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_fertilization
    ADD CONSTRAINT treatment_fertilization_pkey PRIMARY KEY (treatment_fertilizationid);


--
-- TOC entry 5402 (class 2606 OID 24983)
-- Name: treatment_grazer treatment_grazer_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_grazer
    ADD CONSTRAINT treatment_grazer_pkey PRIMARY KEY (treatmentid, type);


--
-- TOC entry 5404 (class 2606 OID 25005)
-- Name: treatment_herbicide treatment_herbicide_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_herbicide
    ADD CONSTRAINT treatment_herbicide_pkey PRIMARY KEY (treatment_herbicideid);


--
-- TOC entry 5406 (class 2606 OID 25022)
-- Name: treatment_invasion treatment_invasion_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_invasion
    ADD CONSTRAINT treatment_invasion_pkey PRIMARY KEY (treatmentid, type);


--
-- TOC entry 5408 (class 2606 OID 25047)
-- Name: treatment_irrigation treatment_irrigation_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_irrigation
    ADD CONSTRAINT treatment_irrigation_pkey PRIMARY KEY (treatment_irrigationid);


--
-- TOC entry 5410 (class 2606 OID 25059)
-- Name: treatment_material treatment_material_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_material
    ADD CONSTRAINT treatment_material_pkey PRIMARY KEY (treatmentid, type);


--
-- TOC entry 5412 (class 2606 OID 25082)
-- Name: treatment_medium treatment_medium_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_medium
    ADD CONSTRAINT treatment_medium_pkey PRIMARY KEY (treatment_mediumid);


--
-- TOC entry 5394 (class 2606 OID 24920)
-- Name: treatment treatment_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment
    ADD CONSTRAINT treatment_pkey PRIMARY KEY (treatmentid);


--
-- TOC entry 5414 (class 2606 OID 25099)
-- Name: treatment_prep treatment_prep_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_prep
    ADD CONSTRAINT treatment_prep_pkey PRIMARY KEY (treatmentid, type);


--
-- TOC entry 5435 (class 2606 OID 25402)
-- Name: veg_result veg_result_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.veg_result
    ADD CONSTRAINT veg_result_pkey PRIMARY KEY (veg_resultid);


--
-- TOC entry 5374 (class 2606 OID 24739)
-- Name: vegmetric vegmetric_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.vegmetric
    ADD CONSTRAINT vegmetric_pkey PRIMARY KEY (type);


--
-- TOC entry 5468 (class 2606 OID 27410)
-- Name: view_dictionary view_dictionary_pkey; Type: CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.view_dictionary
    ADD CONSTRAINT view_dictionary_pkey PRIMARY KEY (view_name);


--
-- TOC entry 5436 (class 1259 OID 25713)
-- Name: fki_FK_Seeding.CultivarID; Type: INDEX; Schema: grp; Owner: postgres
--

CREATE INDEX "fki_FK_Seeding.CultivarID" ON grp.seeding USING btree (cultivarid, speciesid);


--
-- TOC entry 5433 (class 1259 OID 25719)
-- Name: fki_FK_Veg_Result.CultivarID; Type: INDEX; Schema: grp; Owner: postgres
--

CREATE INDEX "fki_FK_Veg_Result.CultivarID" ON grp.veg_result USING btree (cultivarid, speciesid);


--
-- TOC entry 5686 (class 2618 OID 26961)
-- Name: full_area _RETURN; Type: RULE; Schema: grp; Owner: postgres
--

CREATE OR REPLACE VIEW grp.full_area AS
 SELECT ps.database,
    ps.projectid,
    a1.siteid,
        CASE
            WHEN (a2.parentid IS NULL) THEN NULL::bigint
            ELSE a3.areaid
        END AS block,
        CASE
            WHEN (a2.parentid IS NULL) THEN (NULL::bigint)::numeric
            ELSE a3.size
        END AS block_area,
        CASE
            WHEN (a2.parentid IS NULL) THEN NULL::text
            ELSE a3.units
        END AS block_units,
        CASE
            WHEN (a1.parentid IS NULL) THEN NULL::bigint
            ELSE a2.areaid
        END AS subblock,
        CASE
            WHEN (a1.parentid IS NULL) THEN (NULL::bigint)::numeric
            ELSE a2.size
        END AS subblock_area,
        CASE
            WHEN (a1.parentid IS NULL) THEN NULL::text
            ELSE a2.units
        END AS subblock_units,
    a1.areaid AS rep,
    string_agg(((a_t.treatmentid)::character varying)::text, ', '::text ORDER BY a_t.treatmentid) AS treatmentids,
    a1.type,
    a1.size,
    a1.units,
    a1.restoration_start_year,
    a1.restoration_type,
    a1.disturbance_end_year
   FROM ((((grp.area a1
     LEFT JOIN grp.area a2 ON ((a1.parentid = a2.areaid)))
     LEFT JOIN grp.area a3 ON ((a2.parentid = a3.areaid)))
     LEFT JOIN grp.project_site ps ON ((a1.siteid = ps.siteid)))
     LEFT JOIN grp.area_treatment a_t ON ((a1.areaid = a_t.areaid)))
  WHERE ((a1.type <> 'block'::text) AND (a1.type <> 'subblock'::text))
  GROUP BY a1.areaid, ps.database, ps.projectid, a2.parentid, a3.areaid, a2.areaid;


--
-- TOC entry 5687 (class 2618 OID 27217)
-- Name: full_seeding _RETURN; Type: RULE; Schema: grp; Owner: postgres
--

CREATE OR REPLACE VIEW grp.full_seeding AS
 SELECT s.treatmentid,
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
  GROUP BY s.seedingid, sm.mix_name, sm.mix_composition_status, sm.treated_richness, sm.notes, cultivar.name, spec.species_code;


--
-- TOC entry 5689 (class 2618 OID 27387)
-- Name: full_species _RETURN; Type: RULE; Schema: grp; Owner: postgres
--

CREATE OR REPLACE VIEW grp.full_species AS
 SELECT species.speciesid,
    species.species_code,
    species."group",
    species."order",
    species.family,
    species.genus,
    species.species,
    species.subtype,
    species.subtype_name,
    string_agg(species_lifespan.description, '; '::text) AS lifespan,
    species.lifeform
   FROM (grp.species
     LEFT JOIN grp.species_lifespan USING (speciesid))
  GROUP BY species.speciesid
  ORDER BY species.speciesid;


--
-- TOC entry 5692 (class 2618 OID 27459)
-- Name: full_treatment _RETURN; Type: RULE; Schema: grp; Owner: postgres
--

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
    string_agg(m.type, '; '::text) AS mowing_type,
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


--
-- TOC entry 5480 (class 2606 OID 26838)
-- Name: site_soil FK.Site_Soil.SiteID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.site_soil
    ADD CONSTRAINT "FK.Site_Soil.SiteID" FOREIGN KEY (siteid) REFERENCES grp.site(siteid);


--
-- TOC entry 5496 (class 2606 OID 25048)
-- Name: treatment_irrigation FK.Treatment_Irrigation.TreatmentID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_irrigation
    ADD CONSTRAINT "FK.Treatment_Irrigation.TreatmentID" FOREIGN KEY (treatmentid) REFERENCES grp.treatment(treatmentid);


--
-- TOC entry 5526 (class 2606 OID 26866)
-- Name: area FK_Area.ParentID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.area
    ADD CONSTRAINT "FK_Area.ParentID" FOREIGN KEY (parentid) REFERENCES grp.area(areaid);


--
-- TOC entry 5527 (class 2606 OID 26872)
-- Name: area FK_Area.SiteID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.area
    ADD CONSTRAINT "FK_Area.SiteID" FOREIGN KEY (siteid) REFERENCES grp.site(siteid);


--
-- TOC entry 5503 (class 2606 OID 26877)
-- Name: area_treatment FK_Area_Treatment.AreaID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.area_treatment
    ADD CONSTRAINT "FK_Area_Treatment.AreaID" FOREIGN KEY (areaid) REFERENCES grp.area(areaid);


--
-- TOC entry 5504 (class 2606 OID 25142)
-- Name: area_treatment FK_Area_Treatment.TreatmentID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.area_treatment
    ADD CONSTRAINT "FK_Area_Treatment.TreatmentID" FOREIGN KEY (treatmentid) REFERENCES grp.treatment(treatmentid);


--
-- TOC entry 5506 (class 2606 OID 25173)
-- Name: cultivar FK_Cultivar.SpeciesID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.cultivar
    ADD CONSTRAINT "FK_Cultivar.SpeciesID" FOREIGN KEY (speciesid) REFERENCES grp.species(speciesid);


--
-- TOC entry 5507 (class 2606 OID 26882)
-- Name: individual FK_Individual.AreaID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.individual
    ADD CONSTRAINT "FK_Individual.AreaID" FOREIGN KEY (areaid) REFERENCES grp.area(areaid);


--
-- TOC entry 5508 (class 2606 OID 25207)
-- Name: individual FK_Individual.SpeciesID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.individual
    ADD CONSTRAINT "FK_Individual.SpeciesID" FOREIGN KEY (speciesid) REFERENCES grp.species(speciesid);


--
-- TOC entry 5509 (class 2606 OID 25265)
-- Name: project_contributor FK_Project_Contributor.Contributor_AuthorID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.project_contributor
    ADD CONSTRAINT "FK_Project_Contributor.Contributor_AuthorID" FOREIGN KEY (author_contributorid) REFERENCES grp.author_contributor(author_contributorid);


--
-- TOC entry 5510 (class 2606 OID 25270)
-- Name: project_contributor FK_Project_Contributor.ProjectID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.project_contributor
    ADD CONSTRAINT "FK_Project_Contributor.ProjectID" FOREIGN KEY (database, projectid) REFERENCES grp.project(database, projectid);


--
-- TOC entry 5473 (class 2606 OID 24723)
-- Name: project_location FK_Project_Location.LocationID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.project_location
    ADD CONSTRAINT "FK_Project_Location.LocationID" FOREIGN KEY (locationid) REFERENCES grp.location(locationid);


--
-- TOC entry 5474 (class 2606 OID 24728)
-- Name: project_location FK_Project_Location.ProjectID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.project_location
    ADD CONSTRAINT "FK_Project_Location.ProjectID" FOREIGN KEY (database, projectid) REFERENCES grp.project(database, projectid);


--
-- TOC entry 5511 (class 2606 OID 25282)
-- Name: project_site FK_Project_Site.ProjectID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.project_site
    ADD CONSTRAINT "FK_Project_Site.ProjectID" FOREIGN KEY (projectid, database) REFERENCES grp.project(projectid, database);


--
-- TOC entry 5512 (class 2606 OID 26851)
-- Name: project_site FK_Project_Site.SiteID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.project_site
    ADD CONSTRAINT "FK_Project_Site.SiteID" FOREIGN KEY (siteid) REFERENCES grp.site(siteid);


--
-- TOC entry 5513 (class 2606 OID 25299)
-- Name: project_vegmetric FK_Project_Vegmetric.ProjectID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.project_vegmetric
    ADD CONSTRAINT "FK_Project_Vegmetric.ProjectID" FOREIGN KEY (database, projectid) REFERENCES grp.project(database, projectid);


--
-- TOC entry 5514 (class 2606 OID 25304)
-- Name: project_vegmetric FK_Project_Vegmetric.Type; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.project_vegmetric
    ADD CONSTRAINT "FK_Project_Vegmetric.Type" FOREIGN KEY (type) REFERENCES grp.vegmetric(type);


--
-- TOC entry 5521 (class 2606 OID 25708)
-- Name: seeding FK_Seeding.CultivarID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.seeding
    ADD CONSTRAINT "FK_Seeding.CultivarID" FOREIGN KEY (cultivarid, speciesid) REFERENCES grp.cultivar(cultivarid, speciesid);


--
-- TOC entry 5522 (class 2606 OID 25457)
-- Name: seeding FK_Seeding.SpeciesID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.seeding
    ADD CONSTRAINT "FK_Seeding.SpeciesID" FOREIGN KEY (speciesid) REFERENCES grp.species(speciesid);


--
-- TOC entry 5524 (class 2606 OID 25476)
-- Name: seeding_pretreatment FK_Seeding_Pretreatment.SeedingID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.seeding_pretreatment
    ADD CONSTRAINT "FK_Seeding_Pretreatment.SeedingID" FOREIGN KEY (seedingid) REFERENCES grp.seeding(seedingid);


--
-- TOC entry 5525 (class 2606 OID 25481)
-- Name: seeding_pretreatment FK_Seeding_Pretreatment.Type; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.seeding_pretreatment
    ADD CONSTRAINT "FK_Seeding_Pretreatment.Type" FOREIGN KEY (type) REFERENCES grp.pretreatment(type);


--
-- TOC entry 5475 (class 2606 OID 24768)
-- Name: site_classification FK_Site_Classification.ClassificationID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.site_classification
    ADD CONSTRAINT "FK_Site_Classification.ClassificationID" FOREIGN KEY (classificationid) REFERENCES grp.classification(classificationid);


--
-- TOC entry 5476 (class 2606 OID 26818)
-- Name: site_classification FK_Site_Classification.SiteID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.site_classification
    ADD CONSTRAINT "FK_Site_Classification.SiteID" FOREIGN KEY (siteid) REFERENCES grp.site(siteid);


--
-- TOC entry 5477 (class 2606 OID 26823)
-- Name: site_disturbance FK_Site_Disturbance_Site.SiteID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.site_disturbance
    ADD CONSTRAINT "FK_Site_Disturbance_Site.SiteID" FOREIGN KEY (siteid) REFERENCES grp.site(siteid);


--
-- TOC entry 5478 (class 2606 OID 24790)
-- Name: site_disturbance FK_Site_Disturbance_Site.Type; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.site_disturbance
    ADD CONSTRAINT "FK_Site_Disturbance_Site.Type" FOREIGN KEY (type) REFERENCES grp.disturbance(type);


--
-- TOC entry 5515 (class 2606 OID 26828)
-- Name: site_invasive FK_Site_Invasive.SiteID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.site_invasive
    ADD CONSTRAINT "FK_Site_Invasive.SiteID" FOREIGN KEY (siteid) REFERENCES grp.site(siteid);


--
-- TOC entry 5516 (class 2606 OID 25346)
-- Name: site_invasive FK_Site_Invasive.SpeciesID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.site_invasive
    ADD CONSTRAINT "FK_Site_Invasive.SpeciesID" FOREIGN KEY (speciesid) REFERENCES grp.species(speciesid);


--
-- TOC entry 5479 (class 2606 OID 26833)
-- Name: site_ref_ecosystem FK_Site_Ref_Ecosystem.SiteID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.site_ref_ecosystem
    ADD CONSTRAINT "FK_Site_Ref_Ecosystem.SiteID" FOREIGN KEY (siteid) REFERENCES grp.site(siteid);


--
-- TOC entry 5481 (class 2606 OID 24883)
-- Name: species_lifespan FK_Species_Lifespan.Description; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.species_lifespan
    ADD CONSTRAINT "FK_Species_Lifespan.Description" FOREIGN KEY (description) REFERENCES grp.lifespan(type);


--
-- TOC entry 5482 (class 2606 OID 24888)
-- Name: species_lifespan FK_Species_Lifespan.SpeciesID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.species_lifespan
    ADD CONSTRAINT "FK_Species_Lifespan.SpeciesID" FOREIGN KEY (speciesid) REFERENCES grp.species(speciesid);


--
-- TOC entry 5483 (class 2606 OID 24900)
-- Name: species_names FK_Species_Names.SpeciesID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.species_names
    ADD CONSTRAINT "FK_Species_Names.SpeciesID" FOREIGN KEY (speciesid) REFERENCES grp.species(speciesid);


--
-- TOC entry 5490 (class 2606 OID 24984)
-- Name: treatment_grazer FK_Treatment_Grazer.TreatmentID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_grazer
    ADD CONSTRAINT "FK_Treatment_Grazer.TreatmentID" FOREIGN KEY (treatmentid) REFERENCES grp.treatment(treatmentid);


--
-- TOC entry 5492 (class 2606 OID 25006)
-- Name: treatment_herbicide FK_Treatment_Herbicide.TreatmentID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_herbicide
    ADD CONSTRAINT "FK_Treatment_Herbicide.TreatmentID" FOREIGN KEY (treatmentid) REFERENCES grp.treatment(treatmentid);


--
-- TOC entry 5493 (class 2606 OID 25011)
-- Name: treatment_herbicide FK_Treatment_Herbicide.Type; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_herbicide
    ADD CONSTRAINT "FK_Treatment_Herbicide.Type" FOREIGN KEY (type) REFERENCES grp.herbicide(type);


--
-- TOC entry 5499 (class 2606 OID 25083)
-- Name: treatment_medium FK_Treatment_Medium.TreatmentID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_medium
    ADD CONSTRAINT "FK_Treatment_Medium.TreatmentID" FOREIGN KEY (treatmentid) REFERENCES grp.treatment(treatmentid);


--
-- TOC entry 5500 (class 2606 OID 25088)
-- Name: treatment_medium FK_Treatment_Medium.Type; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_medium
    ADD CONSTRAINT "FK_Treatment_Medium.Type" FOREIGN KEY (type) REFERENCES grp.growth_medium(type);


--
-- TOC entry 5517 (class 2606 OID 26887)
-- Name: veg_result FK_Veg_Result.AreaID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.veg_result
    ADD CONSTRAINT "FK_Veg_Result.AreaID" FOREIGN KEY (areaid) REFERENCES grp.area(areaid);


--
-- TOC entry 5518 (class 2606 OID 25714)
-- Name: veg_result FK_Veg_Result.CultivarID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.veg_result
    ADD CONSTRAINT "FK_Veg_Result.CultivarID" FOREIGN KEY (cultivarid, speciesid) REFERENCES grp.cultivar(cultivarid, speciesid);


--
-- TOC entry 5519 (class 2606 OID 25413)
-- Name: veg_result FK_Veg_Result.IndividualID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.veg_result
    ADD CONSTRAINT "FK_Veg_Result.IndividualID" FOREIGN KEY (individualid) REFERENCES grp.individual(individualid);


--
-- TOC entry 5520 (class 2606 OID 25418)
-- Name: veg_result FK_Veg_Result.SpeciesID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.veg_result
    ADD CONSTRAINT "FK_Veg_Result.SpeciesID" FOREIGN KEY (speciesid) REFERENCES grp.species(speciesid);


--
-- TOC entry 5491 (class 2606 OID 24989)
-- Name: treatment_grazer Fk_Treatment_Grazer.Type; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_grazer
    ADD CONSTRAINT "Fk_Treatment_Grazer.Type" FOREIGN KEY (type) REFERENCES grp.grazer(type);


--
-- TOC entry 5484 (class 2606 OID 24928)
-- Name: treatment_application Treatment_Application.TreatmentID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_application
    ADD CONSTRAINT "Treatment_Application.TreatmentID" FOREIGN KEY (treatmentid) REFERENCES grp.treatment(treatmentid);


--
-- TOC entry 5485 (class 2606 OID 24933)
-- Name: treatment_application Treatment_Application.Type; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_application
    ADD CONSTRAINT "Treatment_Application.Type" FOREIGN KEY (type) REFERENCES grp.application_method(type);


--
-- TOC entry 5486 (class 2606 OID 24945)
-- Name: treatment_erosion Treatment_Erosion.TreatmentID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_erosion
    ADD CONSTRAINT "Treatment_Erosion.TreatmentID" FOREIGN KEY (treatmentid) REFERENCES grp.treatment(treatmentid);


--
-- TOC entry 5487 (class 2606 OID 24950)
-- Name: treatment_erosion Treatment_Erosion.Type; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_erosion
    ADD CONSTRAINT "Treatment_Erosion.Type" FOREIGN KEY (type) REFERENCES grp.erosion_control(type);


--
-- TOC entry 5488 (class 2606 OID 24967)
-- Name: treatment_fertilization Treatment_Fertilization.TreatmentID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_fertilization
    ADD CONSTRAINT "Treatment_Fertilization.TreatmentID" FOREIGN KEY (treatmentid) REFERENCES grp.treatment(treatmentid);


--
-- TOC entry 5489 (class 2606 OID 24972)
-- Name: treatment_fertilization Treatment_Fertilization.Type; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_fertilization
    ADD CONSTRAINT "Treatment_Fertilization.Type" FOREIGN KEY (type) REFERENCES grp.fertilization(type);


--
-- TOC entry 5494 (class 2606 OID 25023)
-- Name: treatment_invasion Treatment_Invasion.TreatmentID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_invasion
    ADD CONSTRAINT "Treatment_Invasion.TreatmentID" FOREIGN KEY (treatmentid) REFERENCES grp.treatment(treatmentid);


--
-- TOC entry 5495 (class 2606 OID 25028)
-- Name: treatment_invasion Treatment_Invasion.Type; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_invasion
    ADD CONSTRAINT "Treatment_Invasion.Type" FOREIGN KEY (type) REFERENCES grp.invasion_control(type);


--
-- TOC entry 5497 (class 2606 OID 25060)
-- Name: treatment_material Treatment_Material.TreatmentID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_material
    ADD CONSTRAINT "Treatment_Material.TreatmentID" FOREIGN KEY (treatmentid) REFERENCES grp.treatment(treatmentid);


--
-- TOC entry 5498 (class 2606 OID 25065)
-- Name: treatment_material Treatment_Material.Type; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_material
    ADD CONSTRAINT "Treatment_Material.Type" FOREIGN KEY (type) REFERENCES grp.bed_material(type);


--
-- TOC entry 5501 (class 2606 OID 25100)
-- Name: treatment_prep Treatment_Prep.TreatmentID; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_prep
    ADD CONSTRAINT "Treatment_Prep.TreatmentID" FOREIGN KEY (treatmentid) REFERENCES grp.treatment(treatmentid);


--
-- TOC entry 5502 (class 2606 OID 25105)
-- Name: treatment_prep Treatment_Prep.Type; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_prep
    ADD CONSTRAINT "Treatment_Prep.Type" FOREIGN KEY (type) REFERENCES grp.bed_prep(type);


--
-- TOC entry 5505 (class 2606 OID 27471)
-- Name: area_treatment fk_area_treatment_project; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.area_treatment
    ADD CONSTRAINT fk_area_treatment_project FOREIGN KEY (database, projectid) REFERENCES grp.project(database, projectid);


--
-- TOC entry 5534 (class 2606 OID 27326)
-- Name: treatment_cover_crop fk_cover_crop_species_speciesid; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_cover_crop
    ADD CONSTRAINT fk_cover_crop_species_speciesid FOREIGN KEY (speciesid) REFERENCES grp.species(speciesid);


--
-- TOC entry 5535 (class 2606 OID 27321)
-- Name: treatment_cover_crop fk_cover_crop_treatment_trtid; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_cover_crop
    ADD CONSTRAINT fk_cover_crop_treatment_trtid FOREIGN KEY (treatmentid) REFERENCES grp.treatment(treatmentid);


--
-- TOC entry 5536 (class 2606 OID 27363)
-- Name: treatment_mowing fk_mowing_treatment_trtid; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_mowing
    ADD CONSTRAINT fk_mowing_treatment_trtid FOREIGN KEY (treatmentid) REFERENCES grp.treatment(treatmentid);


--
-- TOC entry 5532 (class 2606 OID 27303)
-- Name: paper_author fk_paper_author_author; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.paper_author
    ADD CONSTRAINT fk_paper_author_author FOREIGN KEY (author_contributorid) REFERENCES grp.author_contributor(author_contributorid);


--
-- TOC entry 5533 (class 2606 OID 27298)
-- Name: paper_author fk_paper_author_paper; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.paper_author
    ADD CONSTRAINT fk_paper_author_paper FOREIGN KEY (paperid) REFERENCES grp.paper(paperid);


--
-- TOC entry 5530 (class 2606 OID 27288)
-- Name: project_paper fk_project_paper_paper; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.project_paper
    ADD CONSTRAINT fk_project_paper_paper FOREIGN KEY (paperid) REFERENCES grp.paper(paperid);


--
-- TOC entry 5531 (class 2606 OID 27283)
-- Name: project_paper fk_project_paper_project; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.project_paper
    ADD CONSTRAINT fk_project_paper_project FOREIGN KEY (database, projectid) REFERENCES grp.project(database, projectid);


--
-- TOC entry 5529 (class 2606 OID 27240)
-- Name: import_object_map import_object_map_import_batchid_fkey; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.import_object_map
    ADD CONSTRAINT import_object_map_import_batchid_fkey FOREIGN KEY (import_batchid) REFERENCES grp.import_batch(import_batchid);


--
-- TOC entry 5538 (class 2606 OID 27433)
-- Name: project_data_accessibility project_data_accessibility_project_fkey; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.project_data_accessibility
    ADD CONSTRAINT project_data_accessibility_project_fkey FOREIGN KEY (database, projectid) REFERENCES grp.project(database, projectid) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5528 (class 2606 OID 27204)
-- Name: seed_mix seed_mix_treatmentid_fkey; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.seed_mix
    ADD CONSTRAINT seed_mix_treatmentid_fkey FOREIGN KEY (treatmentid) REFERENCES grp.treatment(treatmentid);


--
-- TOC entry 5523 (class 2606 OID 27209)
-- Name: seeding seeding_seed_mixid_fkey; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.seeding
    ADD CONSTRAINT seeding_seed_mixid_fkey FOREIGN KEY (seed_mixid) REFERENCES grp.seed_mix(seed_mixid);


--
-- TOC entry 5537 (class 2606 OID 27466)
-- Name: treatment_mowing treatment_mowing_type_fkey; Type: FK CONSTRAINT; Schema: grp; Owner: postgres
--

ALTER TABLE ONLY grp.treatment_mowing
    ADD CONSTRAINT treatment_mowing_type_fkey FOREIGN KEY (type) REFERENCES grp.mowing(type);


--
-- TOC entry 5699 (class 0 OID 0)
-- Dependencies: 6
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE USAGE ON SCHEMA public FROM PUBLIC;
GRANT ALL ON SCHEMA public TO PUBLIC;


-- Completed on 2026-05-25 23:31:46

--
-- PostgreSQL database dump complete
--

