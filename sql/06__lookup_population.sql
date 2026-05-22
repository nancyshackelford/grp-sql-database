-- =====================================================
-- Lookup Table Population
-- Phase 13: Lookup table refinement
-- Date: 2026-05-22
-- Purpose: Initial population of lookup tables
-- =====================================================

-- application_method
INSERT INTO grp.application_method (
  "type",
  definition,
  notes
)
VALUES
(
    'aerial',
    'Aerial seeding.',
    NULL
),
(
    'broadcast',
    'Mechanically spread onto soil surface.',
    NULL
),
(
    'drill',
    'Drill-seeded below soil surface.',
    NULL
),
(
    'hand',
    'Hand spread onto soil surface or hand planted.',
    'Includes seed spreading and manual planting.'
),
(
    'hay transfer',
    'Hay collected from local site and spread.',
    NULL
),
(
    'hydro',
    'Hydroseeded.',
    NULL
),
(
    'topsoil',
    'Topsoil application designated by authors as a seeding treatment.',
    NULL
),
(
    'unknown',
    'Application method unknown.',
    NULL
),
(
    'none',
    'Unseeded treatment.',
    'Used for passive and reference restoration types.'
);

-- bed_material
INSERT INTO grp.bed_material (
  "type",
  definition,
  notes
)
VALUES 
  (
    'biochar',
    'Biochar used as a bed material.',
    NULL
),
(
    'brushpile',
    'Brush piled material used as a bed material.',
    NULL
),
(
    'gravel',
    'Gravel used as a bed material.',
    NULL
),
(
    'hay',
    'Hay collected from natural systems.',
    'Likely contains native seed sources.'
),
(
    'kelp',
    'Dried seaweed used as a bed material.',
    NULL
),
(
    'manure',
    'Manure used as a bed material.',
    NULL
),
(
    'mulch',
    'Organic-based chipped medium excluding woodchips.',
    NULL
),
(
    'organicmaterial',
    'Organic material used as a bed material.',
    NULL
),
(
    'sand',
    'Sand used as a bed material.',
    NULL
),
(
    'shells',
    'Shell material used as a bed material.',
    NULL
),
(
    'straw',
    'Dried hay with no potential seed source.',
    NULL
),
(
    'topsoilremoval',
    'Topsoil removal treatment.',
    NULL
),
(
    'woodchips',
    'Chipped wood used as a bed material.',
    'Often created from local shrub or tree removal.'
);

-- bed_prep
INSERT INTO grp.bed_prep (
  "type",
  definition,
  notes
)
VALUES 
(
    'clearing',
    'Land cleared.',
    NULL
),
(
    'discing',
    'Breaking soil surface with disc harrow.',
    'Synonymous with harrowing.'
),
(
    'harrowing',
    'Breaking soil surface with disc harrow.',
    'Synonymous with discing.'
),
(
    'fire',
    'Burning specifically to reform upper bed material.',
    NULL
),
(
    'packing',
    'Pressing seed into surface.',
    'Sometimes referred to as cultipacking if done mechanically.'
),
(
    'pitting',
    'Creation of microcatchments either mechanically or by hand.',
    NULL
),
(
    'raking',
    'Hand raking.',
    NULL
),
(
    'tilling',
    'Breaking up soil with mechanical tines to unknown depth.',
    'Synonymous with ripping and scarification.'
),
(
    'scarification',
    'Breaking up soil with mechanical tines to unknown depth.',
    'Synonymous with tilling and ripping.'
),
(
    'ripping',
    'Breaking up soil with mechanical tines to unknown depth.',
    'Synonymous with tilling and scarification.'
),
(
    'shallowripping',
    'Breaking up soil with mechanical tines to shallow depth.',
    'Synonymous with shallow tilling and shallow scarification.'
),
(
    'deepripping',
    'Breaking up soil with mechanical tines to deep depth.',
    'Synonymous with deep tilling and deep scarification.'
),
(
    'shallowtilling',
    'Breaking up soil with mechanical tines to shallow depth.',
    'Synonymous with shallow ripping.'
),
(
    'deeptilling',
    'Breaking up soil with mechanical tines to deep depth.',
    'Synonymous with deep ripping.'
),
(
    'ploughing',
    'Turning soil over.',
    NULL
),
(
    'deepploughing',
    'Turning soil over to deep depth.',
    NULL
),
(
    'furrowing',
    'Creating long grooves, usually mechanically, to unknown depth.',
    NULL
),
(
    'shallowfurrowing',
    'Creating long grooves, usually mechanically, to shallow depth.',
    NULL
),
(
    'deepfurrowing',
    'Creating long grooves, usually mechanically, to deep depth.',
    NULL
),
(
    'vernalpool',
    'Construction of a divot in the ground mimicking a vernal pool.',
    NULL
);

-- disturbance
INSERT INTO grp.disturbance (
  "type",
  definition,
  notes
)
VALUES 
(
    'agriculture',
    'Actively planted and harvested.',
    NULL
),
(
    'clearing',
    'Cleared with no subsequent longterm use.',
    NULL
),
(
    'constructed habitat',
    'Recreated conditions.',
    NULL
),
(
    'drained',
    'Drained wetland.',
    NULL
),
(
    'erosion',
    'Wind- or water-caused erosion.',
    NULL
),
(
    'fire',
    'Wild or prescribed fire.',
    NULL
),
(
    'flooding',
    'Floods.',
    NULL
),
(
    'gas',
    'Oil and gas development.',
    NULL
),
(
    'grazing',
    'Over-grazing.',
    NULL
),
(
    'grub feeding',
    'Larvae feeding on plant tissue.',
    NULL
),
(
    'invasion',
    'Invasive species dominance.',
    NULL
),
(
    'logging',
    'Logged area.',
    NULL
),
(
    'mining',
    'Mine site.',
    NULL
),
(
    'roads',
    'Clearing, paving, grading, or driving associated with road use.',
    NULL
),
(
    'volcanic activity',
    'Volcanic lava or ash.',
    NULL
),
(
    'NA',
    'No disturbance.',
    NULL
); 

-- erosion_control
INSERT INTO grp.erosion_control (
  "type",
  definition,
  notes
)
VALUES 
(
    'rolling',
    'Compaction.',
    NULL
),
(
    'blanket',
    'Surface cover of straw or other material.',
    NULL
);
  
-- fertilization
INSERT INTO grp.fertilization (
  "type",
  definition,
  notes
)
VALUES 
(
    'compound',
    'Known to include multiple nutrients.',
    'Specific nutrients unknown.'
),
(
    'fertilization',
    'Fertilization mentioned.',
    'Details of fertilizer used unknown.'
),
(
    'C',
    'Carbon fertilization.',
    NULL
),
(
    'N',
    'Nitrogen fertilization.',
    NULL
),
(
    'NP',
    'Nitrogen and phosphorus combination fertilization.',
    NULL
),
(
    'NPK',
    'Nitrogen, phosphorus, and potassium combination fertilization.',
    NULL
),
(
    'P',
    'Phosphorus fertilization.',
    NULL
),
(
    'sawdust',
    'Sawdust added to reduce nutrient availability.',
    'Represents fertilization reduction treatment.'
);

-- grazer
INSERT INTO grp.grazer (
  "type",
  definition,
  notes
)
VALUES 
(
    'added',
    'Grazers added to site.',
    'Not previously present.'
),
(
    'allowed',
    'Grazing allowed to continue.',
    NULL
),
(
    'removed',
    'Grazers removed.',
    NULL
);

-- growth_medium
INSERT INTO grp.growth_medium (
  "type",
  definition,
  notes
)
VALUES 
(
    'byproduct',
    'Biotic or abiotic byproducts from another process.',
    'Includes coarse rejects from ore cleaning or organics from recycling/compost processes.'
),
(
    'fines',
    'Overburden waste types with a high proportion of silts or clays.',
    'Normally a highly dispersive or erodible growing medium.'
),
(
    'gypsum spoil',
    'Byproduct of gypsum mining.',
    NULL
),
(
    'mixed',
    'Multiple growth medium types.',
    NULL
),
(
    'sand',
    'Seeds mixed with sand before seeding.',
    NULL
),
(
    'topsoil',
    'Native soil taken from previously intact ecosystems and applied prior to restoration.',
    'May be directly returned or applied from stockpiles.'
),
(
    'waste',
    'Uneconomical material produced during the mining process.',
    NULL
),
(
    'haul',
    'Specialized growth media from a stockpile or borrow pit.',
    NULL
),
(
    'scoria',
    'Highly porous lightweight volcanic rock used as a structural growth medium or soil amendment.',
    NULL
),
(
    'spoil',
    'Waste rock and earth excavated to reach a target resource.',
    NULL
);
  
-- herbicide
INSERT INTO grp.herbicide (
  "type",
  definition,
  notes
)
VALUES 
(
    'herbicide',
    'Herbicide applied.',
    'Specific herbicide details unknown.'
),
(
    'glyphosate',
    'Glyphosate herbicide.',
    NULL
),
(
    'leafapplied',
    'Surface spray applied across area.',
    NULL
),
(
    'picloram',
    'Picloram herbicide.',
    NULL
),
(
    'spot sprayed',
    'Spot sprayed as needed.',
    NULL
);

-- invasion_control
INSERT INTO grp.invasion_control (
  "type",
  definition,
  notes
)
VALUES 
(
    'biomassremoval',
    'Removal of biomass or litter after mowing.',
    NULL
),
(
    'fire',
    'Prescribed burn.',
    NULL
),
(
    'haying',
    'Cutting surface vegetation referred to as haying.',
    NULL
),
(
    'lopping',
    'Cutting individuals at base with machete or other tool.',
    NULL
),
(
    'late mowing',
    'Late season mowing.',
    NULL
),
(
    'mowing',
    'Cutting or mowing surface vegetation specifically for invasion removal.',
    'Includes mechanical lopping.'
),
(
    'natural',
    'Natural mortality event.',
    NULL
),
(
    'pulling',
    'Hand or hoe pulling of herbaceous species.',
    NULL
),
(
    'rhizomeremoval',
    'Hand removal of roots and rhizomes.',
    'Usually after mowing or tilling.'
),
(
    'removal',
    'Targeted removal of species.',
    'No additional detail provided.'
),
(
    'scalping',
    'Removing topsoil layer.',
    NULL
),
(
    'thinning',
    'Mechanical or hand pulling specifically for woody species.',
    'May involve tractor-assisted removal.'
);

-- lifespan
INSERT INTO grp.lifespan (
  "type",
  definition,
  notes
)
VALUES 
(
    'annual',
    'Completes life cycle within one growing season.',
    NULL
),
(
    'biennial',
    'Completes life cycle across two growing seasons.',
    NULL
),
(
    'perennial',
    'Lives for more than two growing seasons.',
    NULL
);

-- pretreatment
INSERT INTO grp.pretreatment (
  "type",
  definition,
  notes
)
VALUES 
(
    'acid',
    'Acid bath pretreatment.',
    NULL
),
(
    'boiled',
    'Boiling or soaking in hot water.',
    NULL
),
(
    'coated',
    'Seed coating without hormonal or fungicide treatment.',
    NULL
),
(
    'moddus',
    'Seed treated with plant growth regulator MODDUS.',
    NULL
),
(
    'scarification',
    'Mechanically rupturing or fracturing fruit or seed coats.',
    NULL
),
(
    'cleaned',
    'Outer fruit or floral layers removed to obtain pure seed.',
    NULL
),
(
    'soaked',
    'Immersed in water below boiling temperature.',
    NULL
),
(
    'smoke',
    'Smoke treatment or use of karrikinolide.',
    NULL
),
(
    'GA',
    'Gibberellic acid treatment.',
    NULL
),
(
    'pellet',
    'Cylindrical pretreatments in which seeds are mixed and extruded with beneficial ingredients.',
    NULL
),
(
    'hydrophobic',
    'Hydrophobic polymer seed coating that delays germination.',
    NULL
),
(
    'agglomerate',
    'Seed coating process in which multiple seeds are contained within coated units.',
    NULL
),
(
    'surfactant',
    'Seed coating containing surfactants to improve water infiltration beneath seed.',
    'Used when hydrophobic or crusted soils are present.'
);

-- vegmetric
INSERT INTO grp.vegmetric (
  "type",
  definition,
  notes
)
VALUES 
(
    'abundance',
    'Number of individuals of a species.',
    NULL
),
(
    'biomass',
    'Weighed dry mass in g/m² at species or unit level.',
    NULL
),
(
    'cover',
    'Estimated by contributor without restriction on survey or estimation methodology.',
    NULL
),
(
    'DBH',
    'Diameter at breast height for trees.',
    NULL
),
(
    'density',
    'Estimated by contributor and generally converted to plants/m².',
    'Exceptions include linear densities, conversions affecting data quality, or unclear original units.'
),
(
    'presence',
    'Presence of a species within a unit.',
    NULL
);
