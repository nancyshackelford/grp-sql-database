--
-- PostgreSQL database dump

-- Dumped from database version 14.17
-- Dumped by pg_dump version 17.6

-- Started on 2026-05-25 23:40:21

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
-- TOC entry 5380 (class 0 OID 24590)
-- Dependencies: 211
-- Data for Name: application_method; Type: TABLE DATA; Schema: grp; Owner: postgres
--

INSERT INTO grp.application_method VALUES ('aerial', 'Aerial seeding.', NULL);
INSERT INTO grp.application_method VALUES ('broadcast', 'Mechanically spread onto soil surface.', NULL);
INSERT INTO grp.application_method VALUES ('drill', 'Drill-seeded below soil surface.', NULL);
INSERT INTO grp.application_method VALUES ('hand', 'Hand spread onto soil surface or hand planted.', 'Includes seed spreading and manual planting.');
INSERT INTO grp.application_method VALUES ('hay transfer', 'Hay collected from local site and spread.', NULL);
INSERT INTO grp.application_method VALUES ('hydro', 'Hydroseeded.', NULL);
INSERT INTO grp.application_method VALUES ('topsoil', 'Topsoil application designated by authors as a seeding treatment.', NULL);
INSERT INTO grp.application_method VALUES ('unknown', 'Application method unknown.', NULL);
INSERT INTO grp.application_method VALUES ('none', 'Unseeded treatment.', 'Used for passive and reference restoration types.');


--
-- TOC entry 5381 (class 0 OID 24597)
-- Dependencies: 212
-- Data for Name: bed_material; Type: TABLE DATA; Schema: grp; Owner: postgres
--

INSERT INTO grp.bed_material VALUES ('biochar', 'Biochar used as a bed material.', NULL);
INSERT INTO grp.bed_material VALUES ('brushpile', 'Brush piled material used as a bed material.', NULL);
INSERT INTO grp.bed_material VALUES ('gravel', 'Gravel used as a bed material.', NULL);
INSERT INTO grp.bed_material VALUES ('hay', 'Hay collected from natural systems.', 'Likely contains native seed sources.');
INSERT INTO grp.bed_material VALUES ('kelp', 'Dried seaweed used as a bed material.', NULL);
INSERT INTO grp.bed_material VALUES ('manure', 'Manure used as a bed material.', NULL);
INSERT INTO grp.bed_material VALUES ('mulch', 'Organic-based chipped medium excluding woodchips.', NULL);
INSERT INTO grp.bed_material VALUES ('organicmaterial', 'Organic material used as a bed material.', NULL);
INSERT INTO grp.bed_material VALUES ('sand', 'Sand used as a bed material.', NULL);
INSERT INTO grp.bed_material VALUES ('shells', 'Shell material used as a bed material.', NULL);
INSERT INTO grp.bed_material VALUES ('straw', 'Dried hay with no potential seed source.', NULL);
INSERT INTO grp.bed_material VALUES ('topsoilremoval', 'Topsoil removal treatment.', NULL);
INSERT INTO grp.bed_material VALUES ('woodchips', 'Chipped wood used as a bed material.', 'Often created from local shrub or tree removal.');


--
-- TOC entry 5382 (class 0 OID 24604)
-- Dependencies: 213
-- Data for Name: bed_prep; Type: TABLE DATA; Schema: grp; Owner: postgres
--

INSERT INTO grp.bed_prep VALUES ('clearing', 'Land cleared.', NULL);
INSERT INTO grp.bed_prep VALUES ('discing', 'Breaking soil surface with disc harrow.', 'Synonymous with harrowing.');
INSERT INTO grp.bed_prep VALUES ('harrowing', 'Breaking soil surface with disc harrow.', 'Synonymous with discing.');
INSERT INTO grp.bed_prep VALUES ('fire', 'Burning specifically to reform upper bed material.', NULL);
INSERT INTO grp.bed_prep VALUES ('packing', 'Pressing seed into surface.', 'Sometimes referred to as cultipacking if done mechanically.');
INSERT INTO grp.bed_prep VALUES ('pitting', 'Creation of microcatchments either mechanically or by hand.', NULL);
INSERT INTO grp.bed_prep VALUES ('raking', 'Hand raking.', NULL);
INSERT INTO grp.bed_prep VALUES ('tilling', 'Breaking up soil with mechanical tines to unknown depth.', 'Synonymous with ripping and scarification.');
INSERT INTO grp.bed_prep VALUES ('scarification', 'Breaking up soil with mechanical tines to unknown depth.', 'Synonymous with tilling and ripping.');
INSERT INTO grp.bed_prep VALUES ('ripping', 'Breaking up soil with mechanical tines to unknown depth.', 'Synonymous with tilling and scarification.');
INSERT INTO grp.bed_prep VALUES ('shallowripping', 'Breaking up soil with mechanical tines to shallow depth.', 'Synonymous with shallow tilling and shallow scarification.');
INSERT INTO grp.bed_prep VALUES ('deepripping', 'Breaking up soil with mechanical tines to deep depth.', 'Synonymous with deep tilling and deep scarification.');
INSERT INTO grp.bed_prep VALUES ('shallowtilling', 'Breaking up soil with mechanical tines to shallow depth.', 'Synonymous with shallow ripping.');
INSERT INTO grp.bed_prep VALUES ('deeptilling', 'Breaking up soil with mechanical tines to deep depth.', 'Synonymous with deep ripping.');
INSERT INTO grp.bed_prep VALUES ('ploughing', 'Turning soil over.', NULL);
INSERT INTO grp.bed_prep VALUES ('deepploughing', 'Turning soil over to deep depth.', NULL);
INSERT INTO grp.bed_prep VALUES ('furrowing', 'Creating long grooves, usually mechanically, to unknown depth.', NULL);
INSERT INTO grp.bed_prep VALUES ('shallowfurrowing', 'Creating long grooves, usually mechanically, to shallow depth.', NULL);
INSERT INTO grp.bed_prep VALUES ('deepfurrowing', 'Creating long grooves, usually mechanically, to deep depth.', NULL);
INSERT INTO grp.bed_prep VALUES ('vernalpool', 'Construction of a divot in the ground mimicking a vernal pool.', NULL);


--
-- TOC entry 5383 (class 0 OID 24623)
-- Dependencies: 215
-- Data for Name: disturbance; Type: TABLE DATA; Schema: grp; Owner: postgres
--

INSERT INTO grp.disturbance VALUES ('agriculture', 'Actively planted and harvested.', NULL);
INSERT INTO grp.disturbance VALUES ('clearing', 'Cleared with no subsequent longterm use.', NULL);
INSERT INTO grp.disturbance VALUES ('constructed habitat', 'Recreated conditions.', NULL);
INSERT INTO grp.disturbance VALUES ('drained', 'Drained wetland.', NULL);
INSERT INTO grp.disturbance VALUES ('erosion', 'Wind- or water-caused erosion.', NULL);
INSERT INTO grp.disturbance VALUES ('fire', 'Wild or prescribed fire.', NULL);
INSERT INTO grp.disturbance VALUES ('flooding', 'Floods.', NULL);
INSERT INTO grp.disturbance VALUES ('gas', 'Oil and gas development.', NULL);
INSERT INTO grp.disturbance VALUES ('grazing', 'Over-grazing.', NULL);
INSERT INTO grp.disturbance VALUES ('grub feeding', 'Larvae feeding on plant tissue.', NULL);
INSERT INTO grp.disturbance VALUES ('invasion', 'Invasive species dominance.', NULL);
INSERT INTO grp.disturbance VALUES ('logging', 'Logged area.', NULL);
INSERT INTO grp.disturbance VALUES ('mining', 'Mine site.', NULL);
INSERT INTO grp.disturbance VALUES ('roads', 'Clearing, paving, grading, or driving associated with road use.', NULL);
INSERT INTO grp.disturbance VALUES ('volcanic activity', 'Volcanic lava or ash.', NULL);
INSERT INTO grp.disturbance VALUES ('NA', 'No disturbance.', NULL);


--
-- TOC entry 5384 (class 0 OID 24630)
-- Dependencies: 216
-- Data for Name: erosion_control; Type: TABLE DATA; Schema: grp; Owner: postgres
--

INSERT INTO grp.erosion_control VALUES ('rolling', 'Compaction.', NULL);
INSERT INTO grp.erosion_control VALUES ('blanket', 'Surface cover of straw or other material.', NULL);


--
-- TOC entry 5385 (class 0 OID 24637)
-- Dependencies: 217
-- Data for Name: fertilization; Type: TABLE DATA; Schema: grp; Owner: postgres
--

INSERT INTO grp.fertilization VALUES ('compound', 'Known to include multiple nutrients.', 'Specific nutrients unknown.');
INSERT INTO grp.fertilization VALUES ('fertilization', 'Fertilization mentioned.', 'Details of fertilizer used unknown.');
INSERT INTO grp.fertilization VALUES ('C', 'Carbon fertilization.', NULL);
INSERT INTO grp.fertilization VALUES ('N', 'Nitrogen fertilization.', NULL);
INSERT INTO grp.fertilization VALUES ('NP', 'Nitrogen and phosphorus combination fertilization.', NULL);
INSERT INTO grp.fertilization VALUES ('NPK', 'Nitrogen, phosphorus, and potassium combination fertilization.', NULL);
INSERT INTO grp.fertilization VALUES ('P', 'Phosphorus fertilization.', NULL);
INSERT INTO grp.fertilization VALUES ('sawdust', 'Sawdust added to reduce nutrient availability.', 'Represents fertilization reduction treatment.');


--
-- TOC entry 5386 (class 0 OID 24644)
-- Dependencies: 218
-- Data for Name: grazer; Type: TABLE DATA; Schema: grp; Owner: postgres
--

INSERT INTO grp.grazer VALUES ('added', 'Grazers added to site.', 'Not previously present.');
INSERT INTO grp.grazer VALUES ('allowed', 'Grazing allowed to continue.', NULL);
INSERT INTO grp.grazer VALUES ('removed', 'Grazers removed.', NULL);


--
-- TOC entry 5387 (class 0 OID 24651)
-- Dependencies: 219
-- Data for Name: growth_medium; Type: TABLE DATA; Schema: grp; Owner: postgres
--

INSERT INTO grp.growth_medium VALUES ('byproduct', 'Biotic or abiotic byproducts from another process.', 'Includes coarse rejects from ore cleaning or organics from recycling/compost processes.');
INSERT INTO grp.growth_medium VALUES ('fines', 'Overburden waste types with a high proportion of silts or clays.', 'Normally a highly dispersive or erodible growing medium.');
INSERT INTO grp.growth_medium VALUES ('gypsum spoil', 'Byproduct of gypsum mining.', NULL);
INSERT INTO grp.growth_medium VALUES ('mixed', 'Multiple growth medium types.', NULL);
INSERT INTO grp.growth_medium VALUES ('sand', 'Seeds mixed with sand before seeding.', NULL);
INSERT INTO grp.growth_medium VALUES ('topsoil', 'Native soil taken from previously intact ecosystems and applied prior to restoration.', 'May be directly returned or applied from stockpiles.');
INSERT INTO grp.growth_medium VALUES ('waste', 'Uneconomical material produced during the mining process.', NULL);
INSERT INTO grp.growth_medium VALUES ('haul', 'Specialized growth media from a stockpile or borrow pit.', NULL);
INSERT INTO grp.growth_medium VALUES ('scoria', 'Highly porous lightweight volcanic rock used as a structural growth medium or soil amendment.', NULL);
INSERT INTO grp.growth_medium VALUES ('spoil', 'Waste rock and earth excavated to reach a target resource.', NULL);


--
-- TOC entry 5388 (class 0 OID 24658)
-- Dependencies: 220
-- Data for Name: herbicide; Type: TABLE DATA; Schema: grp; Owner: postgres
--

INSERT INTO grp.herbicide VALUES ('herbicide', 'Herbicide applied.', 'Specific herbicide details unknown.');
INSERT INTO grp.herbicide VALUES ('glyphosate', 'Glyphosate herbicide.', NULL);
INSERT INTO grp.herbicide VALUES ('leafapplied', 'Surface spray applied across area.', NULL);
INSERT INTO grp.herbicide VALUES ('picloram', 'Picloram herbicide.', NULL);
INSERT INTO grp.herbicide VALUES ('spot sprayed', 'Spot sprayed as needed.', NULL);


--
-- TOC entry 5389 (class 0 OID 24666)
-- Dependencies: 221
-- Data for Name: invasion_control; Type: TABLE DATA; Schema: grp; Owner: postgres
--

INSERT INTO grp.invasion_control VALUES ('biomassremoval', 'Removal of biomass or litter after mowing.', NULL);
INSERT INTO grp.invasion_control VALUES ('fire', 'Prescribed burn.', NULL);
INSERT INTO grp.invasion_control VALUES ('haying', 'Cutting surface vegetation referred to as haying.', NULL);
INSERT INTO grp.invasion_control VALUES ('lopping', 'Cutting individuals at base with machete or other tool.', NULL);
INSERT INTO grp.invasion_control VALUES ('late mowing', 'Late season mowing.', NULL);
INSERT INTO grp.invasion_control VALUES ('mowing', 'Cutting or mowing surface vegetation specifically for invasion removal.', 'Includes mechanical lopping.');
INSERT INTO grp.invasion_control VALUES ('natural', 'Natural mortality event.', NULL);
INSERT INTO grp.invasion_control VALUES ('pulling', 'Hand or hoe pulling of herbaceous species.', NULL);
INSERT INTO grp.invasion_control VALUES ('rhizomeremoval', 'Hand removal of roots and rhizomes.', 'Usually after mowing or tilling.');
INSERT INTO grp.invasion_control VALUES ('removal', 'Targeted removal of species.', 'No additional detail provided.');
INSERT INTO grp.invasion_control VALUES ('scalping', 'Removing topsoil layer.', NULL);
INSERT INTO grp.invasion_control VALUES ('thinning', 'Mechanical or hand pulling specifically for woody species.', 'May involve tractor-assisted removal.');


--
-- TOC entry 5390 (class 0 OID 24673)
-- Dependencies: 222
-- Data for Name: lifespan; Type: TABLE DATA; Schema: grp; Owner: postgres
--

INSERT INTO grp.lifespan VALUES ('annual', 'Completes life cycle within one growing season.', NULL);
INSERT INTO grp.lifespan VALUES ('biennial', 'Completes life cycle across two growing seasons.', NULL);
INSERT INTO grp.lifespan VALUES ('perennial', 'Lives for more than two growing seasons.', NULL);


--
-- TOC entry 5393 (class 0 OID 27449)
-- Dependencies: 295
-- Data for Name: mowing; Type: TABLE DATA; Schema: grp; Owner: postgres
--

INSERT INTO grp.mowing VALUES ('present', 'Vegetation was mowed.', NULL);
INSERT INTO grp.mowing VALUES ('mulch', 'Vegetation was mowed and biomass left on site.', NULL);
INSERT INTO grp.mowing VALUES ('removal', 'Vegetation was cut and removed as hay or biomass.', NULL);
INSERT INTO grp.mowing VALUES ('flail', 'Vegetation was mowed using a flail mower.', NULL);


--
-- TOC entry 5391 (class 0 OID 24697)
-- Dependencies: 224
-- Data for Name: pretreatment; Type: TABLE DATA; Schema: grp; Owner: postgres
--

INSERT INTO grp.pretreatment VALUES ('acid', 'Acid bath pretreatment.', NULL);
INSERT INTO grp.pretreatment VALUES ('boiled', 'Boiling or soaking in hot water.', NULL);
INSERT INTO grp.pretreatment VALUES ('coated', 'Seed coating without hormonal or fungicide treatment.', NULL);
INSERT INTO grp.pretreatment VALUES ('moddus', 'Seed treated with plant growth regulator MODDUS.', NULL);
INSERT INTO grp.pretreatment VALUES ('scarification', 'Mechanically rupturing or fracturing fruit or seed coats.', NULL);
INSERT INTO grp.pretreatment VALUES ('cleaned', 'Outer fruit or floral layers removed to obtain pure seed.', NULL);
INSERT INTO grp.pretreatment VALUES ('soaked', 'Immersed in water below boiling temperature.', NULL);
INSERT INTO grp.pretreatment VALUES ('smoke', 'Smoke treatment or use of karrikinolide.', NULL);
INSERT INTO grp.pretreatment VALUES ('GA', 'Gibberellic acid treatment.', NULL);
INSERT INTO grp.pretreatment VALUES ('pellet', 'Cylindrical pretreatments in which seeds are mixed and extruded with beneficial ingredients.', NULL);
INSERT INTO grp.pretreatment VALUES ('hydrophobic', 'Hydrophobic polymer seed coating that delays germination.', NULL);
INSERT INTO grp.pretreatment VALUES ('agglomerate', 'Seed coating process in which multiple seeds are contained within coated units.', NULL);
INSERT INTO grp.pretreatment VALUES ('surfactant', 'Seed coating containing surfactants to improve water infiltration beneath seed.', 'Used when hydrophobic or crusted soils are present.');


--
-- TOC entry 5392 (class 0 OID 24733)
-- Dependencies: 227
-- Data for Name: vegmetric; Type: TABLE DATA; Schema: grp; Owner: postgres
--

INSERT INTO grp.vegmetric VALUES ('abundance', 'Number of individuals of a species.', NULL);
INSERT INTO grp.vegmetric VALUES ('biomass', 'Weighed dry mass in g/m² at species or unit level.', NULL);
INSERT INTO grp.vegmetric VALUES ('cover', 'Estimated by contributor without restriction on survey or estimation methodology.', NULL);
INSERT INTO grp.vegmetric VALUES ('DBH', 'Diameter at breast height for trees.', NULL);
INSERT INTO grp.vegmetric VALUES ('density', 'Estimated by contributor and generally converted to plants/m².', 'Exceptions include linear densities, conversions affecting data quality, or unclear original units.');
INSERT INTO grp.vegmetric VALUES ('presence', 'Presence of a species within a unit.', NULL);


-- Completed on 2026-05-25 23:41:07

--
-- PostgreSQL database dump complete
--

