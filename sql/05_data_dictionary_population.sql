-- =====================================================
-- Data Dictionary Population
-- Phase 13: Lookup table refinement
-- Date: 2026-05-22
-- Purpose: Add definition and notes to lookup tables
-- =====================================================

-- Add data_dictionary rows
-- Note in rows that all was populated today
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
-- application_method
(
    'application_method',
    'definition',
    2,
    'text',
    'YES',
    'Definition of the application method lookup value.',
    'Populate with concise controlled vocabulary definitions.',
    NULL,
    'Aerial seeding.',
    NULL,
    'Definitions should remain consistent across related lookup tables.',
    NULL
),
(
    'application_method',
    'notes',
    3,
    'text',
    'YES',
    'Additional notes or clarification for the application method lookup value.',
    'Use for edge cases, synonyms, or contributor interpretation guidance.',
    NULL,
    'Includes seed spreading and manual planting.',
    NULL,
    'Avoid duplicating information already present in definition.',
    NULL
),

-- bed_material
(
    'bed_material',
    'definition',
    2,
    'text',
    'YES',
    'Definition of the bed material lookup value.',
    'Populate with concise controlled vocabulary definitions.',
    NULL,
    'Gravel used as a bed material.',
    NULL,
    'Definitions should remain consistent across related lookup tables.',
    NULL
),
(
    'bed_material',
    'notes',
    3,
    'text',
    'YES',
    'Additional notes or clarification for the bed material lookup value.',
    'Use for edge cases, synonyms, or contributor interpretation guidance.',
    NULL,
    'Likely contains native seed sources.',
    NULL,
    'Avoid duplicating information already present in definition.',
    NULL
),

-- bed_prep
(
    'bed_prep',
    'definition',
    2,
    'text',
    'YES',
    'Definition of the bed preparation lookup value.',
    'Populate with concise controlled vocabulary definitions.',
    NULL,
    'Land cleared.',
    NULL,
    'Definitions should remain consistent across related lookup tables.',
    NULL
),
(
    'bed_prep',
    'notes',
    3,
    'text',
    'YES',
    'Additional notes or clarification for the bed preparation lookup value.',
    'Use for edge cases, synonyms, or contributor interpretation guidance.',
    NULL,
    'Synonymous with harrowing.',
    NULL,
    'Avoid duplicating information already present in definition.',
    NULL
),

-- disturbance
(
    'disturbance',
    'definition',
    2,
    'text',
    'YES',
    'Definition of the disturbance lookup value.',
    'Populate with concise controlled vocabulary definitions.',
    NULL,
    'Wild or prescribed fire.',
    NULL,
    'Definitions should remain consistent across related lookup tables.',
    NULL
),
(
    'disturbance',
    'notes',
    3,
    'text',
    'YES',
    'Additional notes or clarification for the disturbance lookup value.',
    'Use for edge cases, synonyms, or contributor interpretation guidance.',
    NULL,
    'Multiple disturbances listed in alphabetical order using "|" separator.',
    NULL,
    'Avoid duplicating information already present in definition.',
    NULL
),

-- erosion_control
(
    'erosion_control',
    'definition',
    2,
    'text',
    'YES',
    'Definition of the erosion control lookup value.',
    'Populate with concise controlled vocabulary definitions.',
    NULL,
    'Compaction.',
    NULL,
    'Definitions should remain consistent across related lookup tables.',
    NULL
),
(
    'erosion_control',
    'notes',
    3,
    'text',
    'YES',
    'Additional notes or clarification for the erosion control lookup value.',
    'Use for edge cases, synonyms, or contributor interpretation guidance.',
    NULL,
    'Surface cover of straw or other material.',
    NULL,
    'Avoid duplicating information already present in definition.',
    NULL
),

-- fertilization
(
    'fertilization',
    'definition',
    2,
    'text',
    'YES',
    'Definition of the fertilization lookup value.',
    'Populate with concise controlled vocabulary definitions.',
    NULL,
    'Nitrogen fertilization.',
    NULL,
    'Definitions should remain consistent across related lookup tables.',
    NULL
),
(
    'fertilization',
    'notes',
    3,
    'text',
    'YES',
    'Additional notes or clarification for the fertilization lookup value.',
    'Use for edge cases, synonyms, or contributor interpretation guidance.',
    NULL,
    'Specific nutrients unknown.',
    NULL,
    'Avoid duplicating information already present in definition.',
    NULL
),

-- grazer
(
    'grazer',
    'definition',
    2,
    'text',
    'YES',
    'Definition of the grazer lookup value.',
    'Populate with concise controlled vocabulary definitions.',
    NULL,
    'Grazers removed.',
    NULL,
    'Definitions should remain consistent across related lookup tables.',
    NULL
),
(
    'grazer',
    'notes',
    3,
    'text',
    'YES',
    'Additional notes or clarification for the grazer lookup value.',
    'Use for edge cases, synonyms, or contributor interpretation guidance.',
    NULL,
    'Not previously present.',
    NULL,
    'Avoid duplicating information already present in definition.',
    NULL
),

-- growth_medium
(
    'growth_medium',
    'definition',
    2,
    'text',
    'YES',
    'Definition of the growth medium lookup value.',
    'Populate with concise controlled vocabulary definitions.',
    NULL,
    'Waste rock and earth excavated to reach a target resource.',
    NULL,
    'Definitions should remain consistent across related lookup tables.',
    NULL
),
(
    'growth_medium',
    'notes',
    3,
    'text',
    'YES',
    'Additional notes or clarification for the growth medium lookup value.',
    'Use for edge cases, synonyms, or contributor interpretation guidance.',
    NULL,
    'May be directly returned or applied from stockpiles.',
    NULL,
    'Avoid duplicating information already present in definition.',
    NULL
),

-- herbicide
(
    'herbicide',
    'definition',
    2,
    'text',
    'YES',
    'Definition of the herbicide lookup value.',
    'Populate with concise controlled vocabulary definitions.',
    NULL,
    'Glyphosate herbicide.',
    NULL,
    'Definitions should remain consistent across related lookup tables.',
    NULL
),
(
    'herbicide',
    'notes',
    3,
    'text',
    'YES',
    'Additional notes or clarification for the herbicide lookup value.',
    'Use for edge cases, synonyms, or contributor interpretation guidance.',
    NULL,
    'Specific herbicide details unknown.',
    NULL,
    'Avoid duplicating information already present in definition.',
    NULL
),

-- invasion_control
(
    'invasion_control',
    'definition',
    2,
    'text',
    'YES',
    'Definition of the invasion control lookup value.',
    'Populate with concise controlled vocabulary definitions.',
    NULL,
    'Prescribed burn.',
    NULL,
    'Definitions should remain consistent across related lookup tables.',
    NULL
),
(
    'invasion_control',
    'notes',
    3,
    'text',
    'YES',
    'Additional notes or clarification for the invasion control lookup value.',
    'Use for edge cases, synonyms, or contributor interpretation guidance.',
    NULL,
    'Usually after mowing or tilling.',
    NULL,
    'Avoid duplicating information already present in definition.',
    NULL
),

-- lifespan
(
    'lifespan',
    'definition',
    2,
    'text',
    'YES',
    'Definition of the lifespan lookup value.',
    'Populate with concise controlled vocabulary definitions.',
    NULL,
    'Lives for more than two growing seasons.',
    NULL,
    'Definitions should remain consistent across related lookup tables.',
    NULL
),
(
    'lifespan',
    'notes',
    3,
    'text',
    'YES',
    'Additional notes or clarification for the lifespan lookup value.',
    'Use for edge cases, synonyms, or contributor interpretation guidance.',
    NULL,
    NULL,
    NULL,
    'Avoid duplicating information already present in definition.',
    NULL
),

-- pretreatment
(
    'pretreatment',
    'definition',
    2,
    'text',
    'YES',
    'Definition of the pretreatment lookup value.',
    'Populate with concise controlled vocabulary definitions.',
    NULL,
    'Smoke treatment or use of karrikinolide.',
    NULL,
    'Definitions should remain consistent across related lookup tables.',
    NULL
),
(
    'pretreatment',
    'notes',
    3,
    'text',
    'YES',
    'Additional notes or clarification for the pretreatment lookup value.',
    'Use for edge cases, synonyms, or contributor interpretation guidance.',
    NULL,
    'Used when hydrophobic or crusted soils are present.',
    NULL,
    'Avoid duplicating information already present in definition.',
    NULL
),

-- vegmetric
(
    'vegmetric',
    'definition',
    2,
    'text',
    'YES',
    'Definition of the vegetation metric lookup value.',
    'Populate with concise controlled vocabulary definitions.',
    NULL,
    'Presence of a species within a unit.',
    NULL,
    'Definitions should remain consistent across related lookup tables.',
    NULL
),
(
    'vegmetric',
    'notes',
    3,
    'text',
    'YES',
    'Additional notes or clarification for the vegetation metric lookup value.',
    'Use for edge cases, synonyms, or contributor interpretation guidance.',
    NULL,
    'Exceptions include linear densities or unclear original units.',
    NULL,
    'Avoid duplicating information already present in definition.',
    NULL
);

-- Update existing data_dictionary entry for grp.lifespan.description
UPDATE grp.data_dictionary
SET field_name = 'type'
WHERE table_name = 'lifespan'
AND field_name = 'description';

-- =====================================================
-- Data Dictionary Population
-- Phase 12: Metadata and workflow documentation
-- Date: 2026-05-21
-- Purpose: Populate grp.data_dictionary with table and column metadata
-- =====================================================

-- =====================================================
-- Table: grp.data_dictionary
-- Self-documentation entries
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

(
    'data_dictionary',
    'dictionaryid',
    1,
    'integer',
    'NO',
    'Unique identifier for each data dictionary entry.',
    'Automatically generated for internal tracking of metadata records.',
    NULL,
    '1',
    NULL,
    'Must be unique and non-null.',
    NULL
),
(
    'data_dictionary',
    'table_name',
    2,
    'text',
    'NO',
    'Name of the table being documented.',
    'Used together with column_name to uniquely identify a metadata entry.',
    NULL,
    'veg_result',
    NULL,
    'Should exactly match an existing table name in the grp schema.',
    NULL
),
(
    'data_dictionary',
    'column_name',
    3,
    'text',
    'NO',
    'Name of the column being documented.',
    'Used together with table_name to uniquely identify a metadata entry.',
    NULL,
    'response',
    NULL,
    'Should exactly match an existing column name in the documented table.',
    NULL
),
(
    'data_dictionary',
    'display_order',
    4,
    'integer',
    'YES',
    'Optional ordering field controlling the display sequence of documented columns.',
    'Typically follows the ordinal position of the column in the source table.',
    NULL,
    '4',
    NULL,
    'Should generally align with source table structure for readability.',
    NULL
),
(
    'data_dictionary',
    'data_type',
    5,
    'text',
    'NO',
    'SQL data type associated with the documented column.',
    'Used to communicate expected storage and formatting behavior.',
    NULL,
    'numeric',
    NULL,
    'Should match the current SQL schema definition.',
    NULL
),
(
    'data_dictionary',
    'is_nullable',
    6,
    'text',
    'NO',
    'Indicates whether the documented column allows NULL values.',
    'Stored as YES or NO to align with PostgreSQL information_schema conventions.',
    'YES, NO',
    'YES',
    NULL,
    'Validated using is_nullable_check constraint.',
    NULL
),
(
    'data_dictionary',
    'definition',
    7,
    'text',
    'NO',
    'Primary human-readable definition of the documented column.',
    'Should provide concise conceptual meaning of the field.',
    NULL,
    'Numerical vegetation response value associated with the observation.',
    NULL,
    'Required for all documented columns.',
    NULL
),
(
    'data_dictionary',
    'workflow_notes',
    8,
    'text',
    'YES',
    'Operational or workflow-related notes associated with the documented field.',
    'Used to describe upload logic, processing assumptions, or interpretation guidance.',
    NULL,
    'Calculated relative to the first restoration event.',
    NULL,
    'Avoid duplicating information already captured in definition.',
    NULL
),
(
    'data_dictionary',
    'allowed_values',
    9,
    'text',
    'YES',
    'Controlled vocabulary or expected values associated with the documented field.',
    'Used for categorical fields or constrained value lists.',
    NULL,
    'native, exotic, mixed, unknown',
    NULL,
    'Should align with SQL CHECK constraints where applicable.',
    NULL
),
(
    'data_dictionary',
    'example',
    10,
    'text',
    'YES',
    'Example value illustrating expected field content.',
    'Examples should reflect realistic database entries.',
    NULL,
    'cover',
    NULL,
    'Examples should not contradict allowed values or field definitions.',
    NULL
),
(
    'data_dictionary',
    'legacy_notes',
    11,
    'text',
    'YES',
    'Notes describing legacy spreadsheet structures, terminology, or historical workflow context.',
    'Used to document deviations from earlier Excel-based database systems.',
    NULL,
    'Legacy variable name: tsr.',
    NULL,
    'Useful for migration tracking and historical interpretation.',
    NULL
),
(
    'data_dictionary',
    'qa_qc_notes',
    12,
    'text',
    'YES',
    'Quality assurance and quality control guidance associated with the documented field.',
    'Used to describe validation expectations, formatting checks, or known issues.',
    NULL,
    'Must correspond to an existing species record.',
    NULL,
    'Should reflect implemented SQL constraints where possible.',
    NULL
),
(
    'data_dictionary',
    'external_source_notes',
    13,
    'text',
    'YES',
    'Notes describing relationships to external datasets, APIs, derived products, or reference systems.',
    'Used when values originate from or align with external sources.',
    NULL,
    'Derived from CHELSA climate layers.',
    NULL,
    'Document versioning or source assumptions where relevant.',
    NULL
);

-- =====================================================
-- Table: grp.veg_result
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

(
    'veg_result',
    'veg_resultid',
    1,
    'integer',
    'NO',
    'Unique identifier for a vegetation monitoring observation record.',
    'Each row represents a single vegetation response observation associated with a monitoring area and timepoint.',
    NULL,
    '1',
    NULL,
    'Must be unique and non-null.',
    NULL
),
(
    'veg_result',
    'areaid',
    2,
    'integer',
    'NO',
    'Identifier for the monitored area associated with the vegetation observation.',
    'Foreign key to grp.area.areaid.',
    NULL,
    '501',
    NULL,
    'Must correspond to an existing monitoring area.',
    NULL
),
(
    'veg_result',
    'time_since_restoration',
    3,
    'smallint',
    'YES',
    'Time in weeks between restoration initiation and the vegetation monitoring observation.',
    'Typically calculated relative to the first restoration or seeding event associated with the treatment.',
    NULL,
    '52',
    'Legacy variable name: tsr.',
    'Should be non-negative where populated.',
    NULL
),
(
    'veg_result',
    'year',
    4,
    'numeric',
    'YES',
    'Calendar year of the vegetation monitoring observation.',
    'Used for monitoring chronology and temporal alignment.',
    NULL,
    '2022',
    NULL,
    'Should represent a valid calendar year.',
    NULL
),
(
    'veg_result',
    'month',
    5,
    'numeric',
    'YES',
    'Calendar month of the vegetation monitoring observation.',
    'Used when monitoring date precision is available.',
    '1–12',
    '6',
    NULL,
    'Validated using month_check constraint.',
    NULL
),
(
    'veg_result',
    'day',
    6,
    'numeric',
    'YES',
    'Calendar day of the vegetation monitoring observation.',
    'Used when monitoring date precision is available.',
    '1–31',
    '15',
    NULL,
    'Validated using day_check constraint.',
    NULL
),
(
    'veg_result',
    'speciesid',
    7,
    'integer',
    'YES',
    'Identifier for the species associated with the vegetation response observation.',
    'Foreign key to grp.species.speciesid. Used when the response level is species or species-associated.',
    NULL,
    '2045',
    'Unknown or unresolved species codes may map to designated unknown species entries.',
    'Must correspond to an existing species record where populated.',
    NULL
),
(
    'veg_result',
    'cultivarid',
    8,
    'integer',
    'YES',
    'Identifier for the cultivar associated with the vegetation response observation.',
    'Foreign key to grp.cultivar. Used only when cultivar-level information is available.',
    NULL,
    '15',
    NULL,
    'Must correspond to a valid cultivar-species combination where populated.',
    NULL
),
(
    'veg_result',
    'individualid',
    9,
    'integer',
    'YES',
    'Identifier for an individual organism associated with the vegetation response observation.',
    'Foreign key to grp.individual.individualid. Used for repeated measures or individual-level tracking.',
    NULL,
    '1201',
    NULL,
    'Must correspond to an existing individual record where populated.',
    NULL
),
(
    'veg_result',
    'origin',
    10,
    'text',
    'YES',
    'Origin classification associated with the observed vegetation entity.',
    'Used to distinguish native, exotic, mixed, or unknown origin categories.',
    'native, exotic, unknown, mixed',
    'native',
    'Legacy metadata also referenced unresolved and NA values, but current SQL schema standardizes to four controlled categories.',
    'Validated using origin_check constraint.',
    NULL
),
(
    'veg_result',
    'level',
    11,
    'text',
    'YES',
    'Ecological or observational level at which the vegetation response was measured.',
    'Defines the interpretation context for the response variable.',
    'species, functional group, plot, individual, non-species, non-vascular species',
    'species',
    'Legacy metadata referred to this concept as responselevel.',
    'Validated using level_check constraint.',
    NULL
),
(
    'veg_result',
    'response',
    12,
    'numeric',
    'YES',
    'Numerical vegetation response value associated with the observation.',
    'Interpretation depends on the associated metric field.',
    NULL,
    '45.7',
    'Legacy metadata included converted and standardized values for some studies.',
    'Should contain only numeric values. Units and meaning depend on metric.',
    NULL
),
(
    'veg_result',
    'metric',
    13,
    'text',
    'YES',
    'Vegetation response metric represented by the response value.',
    'Defines the ecological meaning and interpretation of the response measurement.',
    'basal area, height, basal diameter, abundance, area, biomass, cm, cover, DBH, density, emergence rate, frequency, survival rate, presence, cover class',
    'cover',
    'Legacy metadata referred to this concept as responsemetric.',
    'Validated using metric_check constraint.',
    NULL
),
(
    'veg_result',
    'notes',
    14,
    'text',
    'YES',
    'Additional notes associated with the vegetation observation.',
    'Use for methodological notes, conversion concerns, uncertainty, or contextual interpretation details.',
    NULL,
    'Cover estimated using Braun-Blanquet classes and converted to midpoint values.',
    NULL,
    'Avoid storing structured measurement values or taxonomy details here when dedicated fields exist.',
    NULL
);

-- =====================================================
-- Tables:
-- grp.treatment_material
-- grp.treatment_grazer
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

-- =====================================================
-- grp.treatment_material
-- =====================================================

(
    'treatment_material',
    'treatmentid',
    1,
    'integer',
    'NO',
    'Identifier for the treatment associated with the bed material record.',
    'Foreign key to grp.treatment.treatmentid. Used with type as the composite primary key for treatment-material relationships.',
    NULL,
    '205',
    NULL,
    'Must correspond to an existing treatment record.',
    NULL
),
(
    'treatment_material',
    'type',
    2,
    'text',
    'NO',
    'Bed material type associated with the treatment.',
    'Foreign key to grp.bed_material.type. Values must exist in grp.bed_material before they can be referenced in treatment material records.',
    NULL,
    'mulch',
    'Legacy Excel treatment category: bed material.',
    'Must correspond to an existing bed_material lookup value.',
    NULL
),

-- =====================================================
-- grp.treatment_grazer
-- =====================================================

(
    'treatment_grazer',
    'treatmentid',
    1,
    'integer',
    'NO',
    'Identifier for the treatment associated with the grazer manipulation record.',
    'Foreign key to grp.treatment.treatmentid. Used with type as the composite primary key for treatment-grazer relationships.',
    NULL,
    '205',
    NULL,
    'Must correspond to an existing treatment record.',
    NULL
),
(
    'treatment_grazer',
    'type',
    2,
    'text',
    'NO',
    'Grazer manipulation status associated with the treatment.',
    'Foreign key to grp.grazer.type. Values must exist in grp.grazer before they can be referenced in treatment grazer records.',
    NULL,
    'removed',
    'Legacy Excel treatment category: grazer manipulation.',
    'Must correspond to an existing grazer lookup value. Values should describe grazer manipulation status, not grazer identity.',
    NULL
),
(
    'treatment_grazer',
    'notes',
    3,
    'text',
    'YES',
    'Additional notes about grazer identity or grazer treatment context.',
    'Use for details such as domestic grazers, wildlife grazers, species identity, grazing intensity, or other context not captured by the grazer manipulation status.',
    NULL,
    'Domestic sheep removed from site.',
    NULL,
    'Avoid storing the manipulation status here when it belongs in type.',
    NULL
);

-- =====================================================
-- Tables:
-- grp.treatment_fertilization
-- grp.treatment_herbicide
-- grp.treatment_irrigation
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

-- =====================================================
-- grp.treatment_fertilization
-- =====================================================

(
    'treatment_fertilization',
    'treatment_fertilizationid',
    1,
    'integer',
    'NO',
    'Unique identifier for a treatment fertilization record.',
    'Auto-generated identifier for fertilization details associated with a treatment.',
    NULL,
    '1',
    NULL,
    'Must be unique and non-null.',
    NULL
),
(
    'treatment_fertilization',
    'treatmentid',
    2,
    'integer',
    'NO',
    'Identifier for the treatment associated with the fertilization record.',
    'Foreign key to grp.treatment.treatmentid.',
    NULL,
    '205',
    NULL,
    'Must correspond to an existing treatment record.',
    NULL
),
(
    'treatment_fertilization',
    'type',
    3,
    'text',
    'NO',
    'Fertilization type or fertilization treatment associated with the treatment.',
    'Foreign key to grp.fertilization.type. Values must exist in grp.fertilization before they can be referenced in fertilization treatment records.',
    NULL,
    'NPK',
    'Legacy Excel treatment category: fertilization treatment.',
    'Must correspond to an existing fertilization lookup value.',
    NULL
),
(
    'treatment_fertilization',
    'amount',
    4,
    'numeric',
    'YES',
    'Numerical amount of fertilizer applied.',
    'Use when fertilization amount is quantified. Interpret with units.',
    NULL,
    '25',
    NULL,
    'Should be populated only when a numeric amount is known. Use notes for unclear, unquantifiable, or unknown amounts.',
    NULL
),
(
    'treatment_fertilization',
    'units',
    5,
    'text',
    'YES',
    'Units associated with the fertilization amount.',
    'Use with amount to interpret fertilizer quantity.',
    NULL,
    'g/m2',
    'Legacy Excel treatment unit examples included g and kg per area.',
    'Should be populated when amount is populated, where possible.',
    NULL
),
(
    'treatment_fertilization',
    'notes',
    6,
    'text',
    'YES',
    'Additional notes about fertilization treatment details.',
    'Use for unclear amounts, fertilizer formulation details, timing, or interpretation decisions not captured in structured fields.',
    NULL,
    'Fertilizer applied, but amount not reported.',
    NULL,
    'Avoid storing structured amount or unit data here when amount and units fields can be used.',
    NULL
),

-- =====================================================
-- grp.treatment_herbicide
-- =====================================================

(
    'treatment_herbicide',
    'treatment_herbicideid',
    1,
    'integer',
    'NO',
    'Unique identifier for a treatment herbicide record.',
    'Auto-generated identifier for herbicide details associated with a treatment.',
    NULL,
    '1',
    NULL,
    'Must be unique and non-null.',
    NULL
),
(
    'treatment_herbicide',
    'treatmentid',
    2,
    'integer',
    'NO',
    'Identifier for the treatment associated with the herbicide record.',
    'Foreign key to grp.treatment.treatmentid.',
    NULL,
    '205',
    NULL,
    'Must correspond to an existing treatment record.',
    NULL
),
(
    'treatment_herbicide',
    'type',
    3,
    'text',
    'YES',
    'Controlled herbicide treatment type or application approach associated with the treatment.',
    'Foreign key to grp.herbicide.type when populated. Use for standardized herbicide treatment categories or application approaches.',
    NULL,
    'spot sprayed',
    'Legacy Excel treatment category: herbicide.',
    'If populated, must correspond to an existing herbicide lookup value.',
    NULL
),
(
    'treatment_herbicide',
    'chemical',
    4,
    'text',
    'YES',
    'Specific herbicide product, chemical name, or active ingredient used in the treatment.',
    'Use for product or chemical details beyond the controlled herbicide type.',
    NULL,
    'glyphosate',
    NULL,
    'Check spelling consistency for repeated products or chemicals.',
    NULL
),
(
    'treatment_herbicide',
    'amount',
    5,
    'numeric',
    'YES',
    'Numerical amount of herbicide applied.',
    'Use when herbicide amount is quantified. Interpret with units.',
    NULL,
    '2.5',
    NULL,
    'Should be populated only when a numeric amount is known. Use notes or source documentation for unclear, unquantifiable, or unknown amounts.',
    NULL
),
(
    'treatment_herbicide',
    'units',
    6,
    'text',
    'YES',
    'Units associated with the herbicide amount.',
    'Use with amount to interpret herbicide quantity or concentration.',
    NULL,
    'L/ha',
    'Legacy Excel treatment unit notes indicated amount per hectare or otherwise source-indicated units.',
    'Should be populated when amount is populated, where possible.',
    NULL
),

-- =====================================================
-- grp.treatment_irrigation
-- =====================================================

(
    'treatment_irrigation',
    'treatment_irrigationid',
    1,
    'integer',
    'NO',
    'Unique identifier for a treatment irrigation record.',
    'Auto-generated identifier for irrigation or water manipulation details associated with a treatment.',
    NULL,
    '1',
    NULL,
    'Must be unique and non-null.',
    NULL
),
(
    'treatment_irrigation',
    'treatmentid',
    2,
    'integer',
    'NO',
    'Identifier for the treatment associated with the irrigation record.',
    'Foreign key to grp.treatment.treatmentid.',
    NULL,
    '205',
    NULL,
    'Must correspond to an existing treatment record.',
    NULL
),
(
    'treatment_irrigation',
    'type',
    3,
    'text',
    'NO',
    'Type of irrigation or water manipulation treatment.',
    'Use to distinguish water addition from reduced-water or drought treatments.',
    'irrigation; reduction',
    'irrigation',
    'Legacy Excel treatment category: irrigation.',
    'Must match the type_check SQL CHECK constraint.',
    NULL
),
(
    'treatment_irrigation',
    'amount',
    4,
    'numeric',
    'YES',
    'Numerical amount of irrigation or water manipulation applied.',
    'Use with units. May represent water added, water reduced, or a proportional water manipulation depending on type and units.',
    NULL,
    '25',
    NULL,
    'Should be populated only when a numeric amount is known. Interpret carefully with type and units.',
    NULL
),
(
    'treatment_irrigation',
    'units',
    5,
    'text',
    'YES',
    'Units associated with the irrigation or water manipulation amount.',
    'Use with amount to interpret irrigation quantity or proportional reduction.',
    'proportion; mm/%',
    'mm/%',
    'Legacy Excel treatment unit notes included mm of water per area and decimal proportion of ambient conditions.',
    'Must match the units_check SQL CHECK constraint when populated.',
    NULL
),
(
    'treatment_irrigation',
    'notes',
    6,
    'text',
    'YES',
    'Additional notes about irrigation or water manipulation treatment details.',
    'Use for unclear amounts, drought manipulation context, hydrological restoration context, or interpretation decisions not captured in structured fields.',
    NULL,
    'Water reduced to 50% of ambient precipitation.',
    NULL,
    'Avoid storing structured amount or unit data here when amount and units fields can be used.',
    NULL
);

-- =====================================================
-- Table: grp.treatment_medium
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

(
    'treatment_medium',
    'treatment_mediumid',
    1,
    'integer',
    'NO',
    'Unique identifier for a treatment growth medium record.',
    'Auto-generated identifier for growth medium details associated with a treatment.',
    NULL,
    '1',
    NULL,
    'Must be unique and non-null.',
    NULL
),
(
    'treatment_medium',
    'treatmentid',
    2,
    'integer',
    'NO',
    'Identifier for the treatment associated with the growth medium record.',
    'Foreign key to grp.treatment.treatmentid.',
    NULL,
    '205',
    NULL,
    'Must correspond to an existing treatment record.',
    NULL
),
(
    'treatment_medium',
    'type',
    3,
    'text',
    'YES',
    'Growth medium or substrate type applied as part of the treatment.',
    'Foreign key to grp.growth_medium.type when populated. Used to describe the substrate or seedbed material associated with restoration.',
    NULL,
    'topsoil',
    'Legacy Excel treatment category: growth medium.',
    'If populated, must correspond to an existing growth_medium lookup value.',
    NULL
),
(
    'treatment_medium',
    'top_soil_age',
    4,
    'numeric',
    'YES',
    'Age of applied topsoil material, when known.',
    'Typically used when topsoil was salvaged, stockpiled, or otherwise aged prior to application.',
    NULL,
    '5',
    'Legacy Excel notes included years or estimated topsoil age categories.',
    'Must be greater than or equal to zero based on SQL CHECK constraint.',
    NULL
),
(
    'treatment_medium',
    'notes',
    5,
    'text',
    'YES',
    'Additional notes about the growth medium treatment.',
    'Use for interpretation details, uncertainty, stockpile history, mixed substrates, or context not captured in structured fields.',
    NULL,
    'Mixed topsoil and sand substrate from local salvage pile.',
    NULL,
    'Avoid storing structured depth or age information here when dedicated fields can be used.',
    NULL
),
(
    'treatment_medium',
    'growth_medium_depth',
    6,
    'numeric',
    'YES',
    'Depth of applied growth medium or substrate.',
    'Use with growth_medium_depth_units to describe the depth of material applied to the treatment area.',
    NULL,
    '15',
    NULL,
    'Should be populated only when a numeric depth is known.',
    NULL
),
(
    'treatment_medium',
    'growth_medium_depth_units',
    7,
    'text',
    'YES',
    'Units associated with growth medium depth.',
    'Use with growth_medium_depth to interpret substrate depth measurements.',
    NULL,
    'cm',
    NULL,
    'Should be populated when growth_medium_depth is populated, where possible.',
    NULL
);

-- =====================================================
-- Tables:
-- grp.treatment_cover_crop
-- grp.treatment_mowing
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

-- =====================================================
-- grp.treatment_cover_crop
-- =====================================================

(
    'treatment_cover_crop',
    'covercropid',
    1,
    'integer',
    'NO',
    'Unique identifier for a treatment cover crop record.',
    'Used to identify cover crop details associated with a treatment.',
    NULL,
    '1',
    NULL,
    'Must be unique and non-null.',
    NULL
),
(
    'treatment_cover_crop',
    'treatmentid',
    2,
    'integer',
    'NO',
    'Identifier for the treatment associated with the cover crop record.',
    'Foreign key to grp.treatment.treatmentid.',
    NULL,
    '205',
    NULL,
    'Must correspond to an existing treatment record.',
    NULL
),
(
    'treatment_cover_crop',
    'speciesid',
    3,
    'integer',
    'NO',
    'Identifier for the cover crop species associated with the treatment.',
    'Foreign key to grp.species.speciesid. Use speciesid = 1 for unknown species when cover crop was present but species identity was not reported.',
    NULL,
    '1',
    NULL,
    'Must correspond to an existing species record. Unknown cover crop species should use the designated unknown species record.',
    NULL
),
(
    'treatment_cover_crop',
    'amount',
    4,
    'numeric',
    'YES',
    'Numerical amount of cover crop applied or planted.',
    'Use when cover crop amount is quantified. Interpret with units.',
    NULL,
    '10',
    NULL,
    'Should be populated only when a numeric amount is known.',
    NULL
),
(
    'treatment_cover_crop',
    'units',
    5,
    'text',
    'YES',
    'Units associated with the cover crop amount.',
    'Use with amount to interpret cover crop quantity or rate.',
    NULL,
    'kg/ha',
    NULL,
    'Should be populated when amount is populated, where possible.',
    NULL
),
(
    'treatment_cover_crop',
    'notes',
    6,
    'text',
    'YES',
    'Additional notes about the cover crop treatment.',
    'Use for species uncertainty, mixture details, cover crop timing, or other context not captured in structured fields.',
    NULL,
    'Cover crop present but species not reported.',
    NULL,
    'Avoid storing structured amount, units, or species information here when dedicated fields can be used.',
    NULL
),

-- =====================================================
-- grp.treatment_mowing
-- =====================================================

(
    'treatment_mowing',
    'mowingid',
    1,
    'integer',
    'NO',
    'Unique identifier for a treatment mowing record.',
    'Used to identify mowing details associated with a treatment.',
    NULL,
    '1',
    NULL,
    'Must be unique and non-null.',
    NULL
),
(
    'treatment_mowing',
    'treatmentid',
    2,
    'integer',
    'NO',
    'Identifier for the treatment associated with the mowing record.',
    'Foreign key to grp.treatment.treatmentid.',
    NULL,
    '205',
    NULL,
    'Must correspond to an existing treatment record.',
    NULL
),
(
    'treatment_mowing',
    'mowing_type',
    3,
    'text',
    'NO',
    'Type or frequency category of mowing treatment.',
    'Use to distinguish general mowing from annual mowing or other source-described mowing categories.',
    NULL,
    'annual mowing',
    'Legacy Excel treatment category: mowing.',
    'Review values for spelling consistency and unintended variants.',
    NULL
),
(
    'treatment_mowing',
    'height_class',
    4,
    'text',
    'YES',
    'Categorical mowing height class.',
    'Use when mowing height is described categorically rather than numerically.',
    NULL,
    'low',
    NULL,
    'Should be consistent with source-described categories such as low, medium, and high where used.',
    NULL
),
(
    'treatment_mowing',
    'amount',
    5,
    'numeric',
    'YES',
    'Numerical mowing height or mowing frequency amount.',
    'Use when mowing height or frequency is quantified. Interpret with units.',
    NULL,
    '0.15',
    NULL,
    'Should be populated only when a numeric amount is known.',
    NULL
),
(
    'treatment_mowing',
    'units',
    6,
    'text',
    'YES',
    'Units associated with the mowing amount.',
    'Use with amount to interpret mowing height or frequency.',
    NULL,
    'm',
    'Legacy Excel treatment unit notes included m for height and annual for frequency.',
    'Should be populated when amount is populated, where possible.',
    NULL
),
(
    'treatment_mowing',
    'notes',
    7,
    'text',
    'YES',
    'Additional notes about the mowing treatment.',
    'Use for mowing timing, frequency, height uncertainty, haying context, or other mowing treatment interpretation details.',
    NULL,
    'Mowed annually in late summer; height not reported.',
    NULL,
    'Avoid storing structured height, frequency, or unit information here when dedicated fields can be used.',
    NULL
);

-- =====================================================
-- Tables:
-- grp.treatment_application
-- grp.treatment_erosion
-- grp.treatment_invasion
-- grp.treatment_prep
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

-- grp.treatment_application
(
    'treatment_application',
    'treatmentid',
    1,
    'integer',
    'NO',
    'Identifier for the treatment associated with the application method record.',
    'Foreign key to grp.treatment.treatmentid. Used with type as the composite primary key.',
    NULL,
    '205',
    NULL,
    'Must correspond to an existing treatment record.',
    NULL
),
(
    'treatment_application',
    'type',
    2,
    'text',
    'NO',
    'Application method associated with the treatment.',
    'Foreign key to grp.application_method.type.',
    NULL,
    'broadcast',
    NULL,
    'Must correspond to an existing application_method lookup value.',
    NULL
),

-- grp.treatment_erosion
(
    'treatment_erosion',
    'treatmentid',
    1,
    'integer',
    'NO',
    'Identifier for the treatment associated with the erosion control record.',
    'Foreign key to grp.treatment.treatmentid. Used with type as the composite primary key.',
    NULL,
    '205',
    NULL,
    'Must correspond to an existing treatment record.',
    NULL
),
(
    'treatment_erosion',
    'type',
    2,
    'text',
    'NO',
    'Erosion control treatment associated with the treatment.',
    'Foreign key to grp.erosion_control.type.',
    NULL,
    'blanket',
    NULL,
    'Must correspond to an existing erosion_control lookup value.',
    NULL
),

-- grp.treatment_invasion
(
    'treatment_invasion',
    'treatmentid',
    1,
    'integer',
    'NO',
    'Identifier for the treatment associated with the invasive species control record.',
    'Foreign key to grp.treatment.treatmentid. Used with type as the composite primary key.',
    NULL,
    '205',
    NULL,
    'Must correspond to an existing treatment record.',
    NULL
),
(
    'treatment_invasion',
    'type',
    2,
    'text',
    'NO',
    'Invasive species control method associated with the treatment.',
    'Foreign key to grp.invasion_control.type.',
    NULL,
    'pulling',
    NULL,
    'Must correspond to an existing invasion_control lookup value.',
    NULL
),

-- grp.treatment_prep
(
    'treatment_prep',
    'treatmentid',
    1,
    'integer',
    'NO',
    'Identifier for the treatment associated with the bed preparation record.',
    'Foreign key to grp.treatment.treatmentid. Used with type as the composite primary key.',
    NULL,
    '205',
    NULL,
    'Must correspond to an existing treatment record.',
    NULL
),
(
    'treatment_prep',
    'type',
    2,
    'text',
    'NO',
    'Bed preparation method associated with the treatment.',
    'Foreign key to grp.bed_prep.type.',
    NULL,
    'ripping',
    NULL,
    'Must correspond to an existing bed_prep lookup value.',
    NULL
);

-- =====================================================
-- Table: grp.treatment
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
(
    'treatment',
    'treatmentid',
    1,
    'integer',
    'NO',
    'Unique identifier for a treatment record.',
    'Represents a treatment event or treatment package that may be linked to one or more treatment detail tables. Referenced by area_treatment, seed_mix, and treatment-specific tables.',
    NULL,
    '205',
    'Legacy Excel metadata treated treatmentid as a GRP/GAZP treatment identifier. A single treatmentid could represent a collection of subtreatments.',
    'Must be unique and non-null. If the same treatment is applied in more than one site or area, confirm whether separate treatmentid values are needed.',
    NULL
),
(
    'treatment',
    'year',
    2,
    'numeric',
    'YES',
    'Calendar year when the treatment occurred.',
    'Use for treatment timing when year is known. For multi-action treatment packages, use treatment-specific records and notes where timing differs among subtreatments.',
    NULL,
    '2018',
    'Legacy Excel fields included trt_year and tsr_start_year.',
    'Should be a plausible four-digit year when populated.',
    NULL
),
(
    'treatment',
    'month',
    3,
    'numeric',
    'YES',
    'Calendar month when the treatment occurred.',
    'Use when treatment month is known.',
    NULL,
    '6',
    'Legacy Excel field: treatmentmonth.',
    'Must be between 1 and 12 when populated.',
    NULL
),
(
    'treatment',
    'day',
    4,
    'numeric',
    'YES',
    'Calendar day when the treatment occurred.',
    'Use when treatment day is known.',
    NULL,
    '15',
    'Legacy Excel field: treatmentday.',
    'Must be between 1 and 31 when populated.',
    NULL
),
(
    'treatment',
    'weeks_since_restoration',
    5,
    'smallint',
    'YES',
    'Time since restoration treatment, in weeks.',
    'Use when treatment timing is expressed relative to restoration rather than as an exact date.',
    NULL,
    '12',
    'Legacy Excel field: trt_tsr.',
    'Check consistency with treatment date fields and monitoring timing where both are available.',
    NULL
),
(
    'treatment',
    'other_treatment',
    6,
    'text',
    'YES',
    'Additional treatment information not captured in structured treatment-specific tables.',
    'Use sparingly for treatment details that do not fit existing treatment categories.',
    NULL,
    'manual removal followed by site-specific erosion control',
    'Legacy Excel field: othertreatments.',
    'Avoid using this field for information that belongs in a treatment-specific table.',
    NULL
),
(
    'treatment',
    'shelter',
    7,
    'text',
    'YES',
    'Shelter or protective structure associated with the treatment.',
    'Use for shelter created or applied for protection during restoration.',
    'natural; artificial; living; blanket',
    'artificial',
    'Legacy Excel treatment_category included shelter as a treatment category.',
    'Must match the shelter_check SQL CHECK constraint when populated.',
    NULL
),
(
    'treatment',
    'grading',
    8,
    'text',
    'YES',
    'Indicates whether grading was applied as part of restoration treatment.',
    'Use when site grading or surface recontouring was part of the treatment.',
    'yes; no',
    'yes',
    'Legacy Excel treatment_category included grading as a treatment category.',
    'Must match the grading_check SQL CHECK constraint when populated.',
    NULL
),
(
    'treatment',
    'maintenance_fire',
    9,
    'boolean',
    'YES',
    'Indicates whether maintenance fire was applied as part of restoration treatment or management.',
    'Use for fire applied after or as part of ongoing treatment maintenance, distinct from fire as a disturbance type.',
    'TRUE; FALSE',
    'FALSE',
    NULL,
    'Should be TRUE only when maintenance fire is explicitly documented.',
    NULL
),
(
    'treatment',
    'notes',
    10,
    'text',
    'YES',
    'Additional notes about the treatment record.',
    'Use for treatment-level caveats, unusual timing, multi-action treatment packages, or interpretation decisions not captured in structured fields.',
    NULL,
    'Treatment timing varied across subtreatments; see treatment detail records.',
    NULL,
    'Avoid duplicating information already captured in treatment-specific tables unless context is needed.',
    NULL
);

-- =====================================================
-- Tables:
-- grp.species
-- grp.species_lifespan
-- grp.species_names
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

-- =====================================================
-- grp.species
-- =====================================================

(
    'species',
    'speciesid',
    1,
    'integer',
    'NO',
    'Unique internal identifier for a species-level taxonomic record.',
    'Primary key for grp.species. Referenced throughout the database for vegetation, treatment, cultivar, and invasive species records.',
    NULL,
    '455',
    'Legacy Excel identifier concept stored primarily as species_code.',
    'Each speciesid must be unique.',
    NULL
),
(
    'species',
    'species_code',
    2,
    'text',
    'YES',
    'Short standardized GRP/GAZP species code derived from genus and species names.',
    'Typically formatted as Gen_spe. Codes may deviate from strict three-letter conventions to maintain uniqueness. Genus-level records may use formats such as G_Euc_spp. Lifeform-only records may use formats such as L_Pgrass.',
    NULL,
    'Rum_acetosa',
    'Legacy Excel field: speciesid.',
    'Species codes should remain stable once assigned.',
    'Taxonomy updated using World Flora Online / World Plant List workflows.'
),
(
    'species',
    'group',
    3,
    'text',
    'YES',
    'Higher-level taxonomic grouping associated with the species.',
    'Used for broad taxonomic organization where available.',
    NULL,
    'Angiosperm',
    'Legacy Excel field: group.',
    NULL,
    NULL
),
(
    'species',
    'order',
    4,
    'text',
    'YES',
    'Taxonomic order associated with the species.',
    'Stored using accepted taxonomic nomenclature where available.',
    NULL,
    'Poales',
    'Legacy Excel field: order.',
    NULL,
    'Taxonomy updated using World Flora Online / World Plant List workflows.'
),
(
    'species',
    'family',
    5,
    'text',
    'YES',
    'Taxonomic family associated with the species.',
    'Stored using accepted taxonomic nomenclature where available.',
    NULL,
    'Poaceae',
    'Legacy Excel field: family.',
    NULL,
    'Taxonomy updated using World Flora Online / World Plant List workflows.'
),
(
    'species',
    'genus',
    6,
    'text',
    'YES',
    'Taxonomic genus associated with the species.',
    'Stored using accepted taxonomic nomenclature where available.',
    NULL,
    'Festuca',
    'Legacy Excel field: genus.',
    NULL,
    'Taxonomy updated using World Flora Online / World Plant List workflows.'
),
(
    'species',
    'species',
    7,
    'text',
    'YES',
    'Specific epithet associated with the species.',
    'Together with genus, represents the accepted scientific name.',
    NULL,
    'rubra',
    'Legacy Excel field: species.',
    NULL,
    'Taxonomy updated using World Flora Online / World Plant List workflows.'
),
(
    'species',
    'subtype',
    8,
    'text',
    'YES',
    'Subtype designation associated with the taxon.',
    'Used when the taxon is identified below species level.',
    'subspecies; variety',
    'variety',
    'Legacy Excel field: sub_type.',
    'Must match allowed CHECK constraint values.',
    NULL
),
(
    'species',
    'subtype_name',
    9,
    'text',
    'YES',
    'Name associated with the subtype designation.',
    'Stores the varietal or subspecies name when subtype is present.',
    NULL,
    'commutata',
    NULL,
    NULL,
    NULL
),
(
    'species',
    'lifeform',
    10,
    'text',
    'YES',
    'Broad manually assigned lifeform category associated with the species.',
    'Used for ecological grouping and trait interpretation.',
    'shrub; tree; forb; moss; grass; fungus; perennial forb; annual forb; perennial grass; annual grass; biennial forb; biennial grass; fern; lichen; liverwort; palm; vine; succulent',
    'perennial grass',
    'Legacy Excel field: lifeform.',
    'Must match allowed CHECK constraint values.',
    'Originally informed by TRY and related trait harmonization workflows.'
),

-- =====================================================
-- grp.species_lifespan
-- =====================================================

(
    'species_lifespan',
    'speciesid',
    1,
    'integer',
    'NO',
    'Identifier for the species associated with the lifespan classification.',
    'Foreign key to grp.species.speciesid. Used with description as the composite primary key.',
    NULL,
    '455',
    NULL,
    'Must correspond to an existing species record.',
    NULL
),
(
    'species_lifespan',
    'description',
    2,
    'text',
    'NO',
    'Lifespan classification associated with the species.',
    'Foreign key to grp.lifespan.description. Multiple lifespan classifications for a single species are represented as separate rows.',
    NULL,
    'perennial',
    'Legacy Excel field: lifespan.',
    'Must correspond to an existing lifespan lookup value.',
    'Derived primarily from TRY and USDA trait datasets.'
),

-- =====================================================
-- grp.species_names
-- =====================================================

(
    'species_names',
    'speciesid',
    1,
    'integer',
    'NO',
    'Identifier for the species associated with the stored name record.',
    'Foreign key to grp.species.speciesid.',
    NULL,
    '455',
    NULL,
    'Must correspond to an existing species record.',
    NULL
),
(
    'species_names',
    'species_code',
    2,
    'text',
    'NO',
    'Species code associated with the stored name record.',
    'Used to associate alternate or historical naming records with a standardized GRP/GAZP species code.',
    NULL,
    'Fest_rubra',
    NULL,
    'Should correspond to the accepted species code used in grp.species.',
    NULL
),
(
    'species_names',
    'name',
    3,
    'text',
    'NO',
    'Scientific name associated with the species record.',
    'Typically stores the combined genus and species name as a single text string.',
    NULL,
    'Festuca rubra',
    'Legacy Excel field: name.',
    'Maintain consistency with accepted taxonomic nomenclature where possible.',
    'Taxonomy updated using World Flora Online / World Plant List workflows.'
);

-- =====================================================
-- Table: grp.site
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

(
    'site',
    'siteid',
    1,
    'integer',
    'NO',
    'Unique identifier for a restoration or monitoring site.',
    'If multiple projects share the same site, they should reference the same siteid through project_site. Site records should be stabilized before importing dependent tables such as area or veg_result.',
    NULL,
    '101',
    'Legacy Excel site sheet duplicated shared sites across project rows before normalization.',
    'Must be unique and non-null.',
    NULL
),
(
    'site',
    'name',
    2,
    'text',
    'YES',
    'Contributor-provided site name or identifier.',
    'Use contributor terminology where possible. May represent a formal site name, plot complex, restoration unit, or local identifier.',
    NULL,
    'Willow Creek Restoration Area',
    'Legacy Excel field: sitename.',
    'Check for duplicate site names that may refer to distinct sites.',
    NULL
),
(
    'site',
    'latitude',
    3,
    'numeric',
    'YES',
    'Latitude of the site in decimal degrees.',
    'Coordinates should be converted to decimal degrees if necessary. If site coordinates are private or publication-restricted, round to the nearest tenth of a decimal degree.',
    NULL,
    '49.2827',
    NULL,
    'Must fall between -90 and 90. Verify coordinate order and sign conventions.',
    NULL
),
(
    'site',
    'longitude',
    4,
    'numeric',
    'YES',
    'Longitude of the site in decimal degrees.',
    'Coordinates should be converted to decimal degrees if necessary. If site coordinates are private or publication-restricted, round to the nearest tenth of a decimal degree.',
    NULL,
    '-123.1207',
    NULL,
    'Must fall between -180 and 180. Verify coordinate order and sign conventions.',
    NULL
),
(
    'site',
    'aridity',
    5,
    'numeric',
    'YES',
    'Aridity index calculated as average annual precipitation divided by potential evapotranspiration.',
    'Lower values indicate more arid conditions.',
    NULL,
    '0.42',
    'Legacy metadata referenced CGIAR-CSI aridity layers.',
    'Must be greater than or equal to 0.',
    'Current workflow sources aridity metrics externally; historical metadata referenced CGIAR-CSI.'
),
(
    'site',
    'annual_temp',
    6,
    'numeric',
    'YES',
    'Annual mean temperature for the site.',
    'Represents externally sourced climate data associated with the site location.',
    NULL,
    '12.4',
    'Legacy Excel field: temp.',
    'Check units and climate raster version consistency across imports.',
    'Current workflow sources climate data from CHELSA; older metadata referenced WorldClim.'
),
(
    'site',
    'annual_precip',
    7,
    'smallint',
    'YES',
    'Annual precipitation associated with the site location.',
    'Represents externally sourced climate data associated with the site location.',
    NULL,
    '842',
    'Legacy Excel field: precip.',
    'Check units and climate raster version consistency across imports.',
    'Current workflow sources climate data from CHELSA; older metadata referenced WorldClim.'
);

-- =====================================================
-- Table: grp.site_soil
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

(
    'site_soil',
    'soilid',
    1,
    'integer',
    'NO',
    'Unique identifier for a site soil record.',
    'Auto-generated identifier for soil records associated with a site.',
    NULL,
    '1',
    NULL,
    'Must be unique and non-null.',
    NULL
),
(
    'site_soil',
    'siteid',
    2,
    'integer',
    'NO',
    'Identifier for the site associated with the soil record.',
    'Foreign key to grp.site.siteid. Multiple soil records may exist for a single site if multiple soil horizons, sampling depths, or descriptions are reported.',
    NULL,
    '101',
    NULL,
    'Must correspond to an existing site record.',
    NULL
),
(
    'site_soil',
    'sand',
    3,
    'numeric',
    'YES',
    'Percent sand content of the soil as reported by the contributor.',
    'If a range was reported in the source material, the center value was historically used.',
    NULL,
    '42.5',
    'Legacy Excel field: sand.',
    'Must fall between 0 and 100.',
    NULL
),
(
    'site_soil',
    'silt',
    4,
    'numeric',
    'YES',
    'Percent silt content of the soil as reported by the contributor.',
    'If a range was reported in the source material, the center value was historically used.',
    NULL,
    '35',
    'Legacy Excel field: silt.',
    'Must fall between 0 and 100.',
    NULL
),
(
    'site_soil',
    'clay',
    5,
    'numeric',
    'YES',
    'Percent clay content of the soil as reported by the contributor.',
    'If a range was reported in the source material, the center value was historically used.',
    NULL,
    '22.5',
    'Legacy Excel field: clay.',
    'Must fall between 0 and 100.',
    NULL
),
(
    'site_soil',
    'description',
    6,
    'text',
    'YES',
    'Categorical or descriptive soil texture or soil type information.',
    'Use contributor-provided terminology where available. May approximate traditional soil texture classes or preserve verbatim contributor descriptions.',
    NULL,
    'sandy loam',
    'Legacy Excel field: soildescription.',
    'Check consistency between texture description and particle-size percentages where both are available.',
    NULL
),
(
    'site_soil',
    'depth',
    7,
    'text',
    'YES',
    'Description of soil depth or sampled soil interval.',
    'Stored as text because source materials may report ranges, categories, qualitative descriptions, or inconsistent units.',
    NULL,
    '0-10 cm',
    'Legacy Excel field: soildepth.',
    'Preserve source wording where interpretation is uncertain.',
    NULL
);

-- =====================================================
-- Tables:
-- grp.site_classification
-- grp.site_disturbance
-- grp.site_invasive
-- grp.site_ref_ecosystem
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

-- =====================================================
-- grp.site_classification
-- =====================================================

(
    'site_classification',
    'siteid',
    1,
    'integer',
    'NO',
    'Identifier for the site associated with the classification record.',
    'Foreign key to grp.site.siteid. Used with classificationid as the composite primary key for site-classification relationships.',
    NULL,
    '101',
    NULL,
    'Must correspond to an existing site record.',
    NULL
),
(
    'site_classification',
    'classificationid',
    2,
    'integer',
    'NO',
    'Identifier for the standardized ecological classification associated with the site.',
    'Foreign key to grp.classification.classificationid.',
    NULL,
    '12',
    NULL,
    'Must correspond to an existing classification record.',
    NULL
),

-- =====================================================
-- grp.site_disturbance
-- =====================================================

(
    'site_disturbance',
    'siteid',
    1,
    'integer',
    'NO',
    'Identifier for the site associated with the disturbance record.',
    'Foreign key to grp.site.siteid. Used with type as the composite primary key for site-disturbance relationships.',
    NULL,
    '101',
    NULL,
    'Must correspond to an existing site record.',
    NULL
),
(
    'site_disturbance',
    'type',
    2,
    'text',
    'NO',
    'Major disturbance type associated with the site that led to restoration treatment.',
    'Foreign key to grp.disturbance.type. Multiple disturbance types should be represented as separate rows rather than combined strings.',
    NULL,
    'grazing',
    'Legacy Excel field: disturbance.',
    'Must correspond to an existing disturbance lookup value.',
    NULL
),

-- =====================================================
-- grp.site_invasive
-- =====================================================

(
    'site_invasive',
    'siteid',
    1,
    'integer',
    'NO',
    'Identifier for the site associated with the invasive species record.',
    'Foreign key to grp.site.siteid. Used with speciesid as the composite primary key for site-invasive relationships.',
    NULL,
    '101',
    NULL,
    'Must correspond to an existing site record.',
    NULL
),
(
    'site_invasive',
    'speciesid',
    2,
    'integer',
    'NO',
    'Identifier for an invasive species of primary concern at the site.',
    'Foreign key to grp.species.speciesid.',
    NULL,
    '455',
    'Legacy Excel field: invasivespe.',
    'Must correspond to an existing species record.',
    NULL
),

-- =====================================================
-- grp.site_ref_ecosystem
-- =====================================================

(
    'site_ref_ecosystem',
    'siteid',
    1,
    'integer',
    'NO',
    'Identifier for the site associated with the reference ecosystem description.',
    'Foreign key to grp.site.siteid. Used with description as the composite primary key for site-reference ecosystem relationships.',
    NULL,
    '101',
    NULL,
    'Must correspond to an existing site record.',
    NULL
),
(
    'site_ref_ecosystem',
    'description',
    2,
    'text',
    'NO',
    'Contributor-provided description of the target or historical reference ecosystem associated with the site.',
    'Preserve contributor terminology where possible. This field stores source descriptions separately from standardized ecological classifications in grp.classification.',
    NULL,
    'tallgrass prairie',
    'Legacy Excel field: refecosystem.',
    'Reference existing descriptions when possible to improve consistency across projects while preserving contributor meaning.',
    NULL
);

-- =====================================================
-- Tables: grp.seed_mix, grp.seeding, grp.seeding_pretreatment
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

-- =====================================================
-- grp.seed_mix
-- =====================================================

(
    'seed_mix',
    'seed_mixid',
    1,
    'integer',
    'NO',
    'Unique identifier for a seed mix record.',
    'Used to group seeding records that belong to the same treatment-level seed or planting mix.',
    NULL,
    '1',
    NULL,
    'Must be unique and non-null.',
    NULL
),
(
    'seed_mix',
    'treatmentid',
    2,
    'integer',
    'NO',
    'Identifier for the treatment associated with the seed mix.',
    'Foreign key to grp.treatment.treatmentid. Each seed mix belongs to a treatment.',
    NULL,
    '205',
    NULL,
    'Must correspond to an existing treatment record.',
    NULL
),
(
    'seed_mix',
    'mix_name',
    3,
    'text',
    'YES',
    'Name or label for the seed mix, when available.',
    'May store source mix labels such as mix_5, mix_unknown, mix_hay, mix_topsoil, or a named mix from source materials.',
    NULL,
    'mix_5',
    NULL,
    'Check for consistency with mix_composition_status and treated_richness.',
    NULL
),
(
    'seed_mix',
    'mix_composition_status',
    4,
    'text',
    'YES',
    'Indicates whether the seed or planting mix composition is known, unknown, or includes both known and unknown components.',
    'SQL replacement for legacy Excel mix_trt. Used to distinguish known-composition mixes from unknown-composition mixes and hybrid known/unknown cases.',
    NULL,
    'known & unknown',
    'Legacy Excel field: mix_trt.',
    'Expected values include known, unknown, and known & unknown. Check consistency with mix_name, treated_richness, and associated seeding species records.',
    NULL
),
(
    'seed_mix',
    'treated_richness',
    5,
    'text',
    'YES',
    'Number of species in a seed or planting mix associated with a single treatment, or a categorical richness descriptor when numeric richness is unavailable.',
    'Stored as text because source values may include numeric richness, unknown richness, hay/topsoil categories, or mixed known/unknown descriptors.',
    NULL,
    '5_mix',
    NULL,
    'Check that values are interpretable in relation to mix_composition_status. Numeric values generally represent the number of species used in the mix; categorical values such as unknown, hay, or topsoil should be used only when source composition is not fully known.',
    NULL
),
(
    'seed_mix',
    'notes',
    6,
    'text',
    'YES',
    'Additional notes about the seed or planting mix.',
    'Use for mix-level comments such as estimated richness, hay transfer, topsoil seed bank use, unclear mix identity, or other interpretation decisions.',
    NULL,
    'Richness estimated from germination trial.',
    NULL,
    'Avoid storing structured mix attributes here when a dedicated field exists.',
    NULL
),

-- =====================================================
-- grp.seeding
-- =====================================================

(
    'seeding',
    'seedingid',
    1,
    'integer',
    'NO',
    'Unique identifier for a seeding or planting record.',
    'Used to represent a specific seeded or planted species, cultivar, unknown mix component, or related entry within a seed mix.',
    NULL,
    '1',
    NULL,
    'Must be unique and non-null.',
    NULL
),
(
    'seeding',
    'treatmentid',
    2,
    'integer',
    'NO',
    'Identifier for the treatment associated with the seeding or planting record.',
    'Links the seeding record to the broader restoration treatment.',
    NULL,
    '205',
    NULL,
    'Must correspond to the treatment associated with the linked seed_mix record.',
    NULL
),
(
    'seeding',
    'mix',
    3,
    'text',
    'YES',
    'Legacy or source mix label associated with the seeding or planting record.',
    'Retained to preserve source mix information after normalization into grp.seed_mix. Interpret with seed_mixid and mix_name.',
    NULL,
    'mix_5',
    'Legacy Excel mix identifiers used values such as mix_#, mix_unknown, mix_hay, mix_topsoil, mix_topsoilhay, and mix_bird_perch.',
    'Check whether this value duplicates seed_mix.mix_name. Prefer seed_mixid for relational linking.',
    NULL
),
(
    'seeding',
    'speciesid',
    4,
    'integer',
    'YES',
    'Identifier for the species associated with the seeding or planting record, when known.',
    'Foreign key to grp.species.speciesid. May be used with cultivarid when cultivar-level information is available.',
    NULL,
    '45',
    'Legacy Excel speciesid included identified species, unidentified species codes, cultivar-linked species, and mix-style identifiers before normalization.',
    'If populated, must correspond to an existing species record. Unknown mix composition should be represented through seed mix metadata rather than invented species identities where possible.',
    NULL
),
(
    'seeding',
    'cultivarid',
    5,
    'integer',
    'YES',
    'Identifier for the cultivar associated with the seeding or planting record, when known.',
    'Used with speciesid as a composite foreign key to grp.cultivar(cultivarid, speciesid).',
    NULL,
    '3',
    NULL,
    'If populated, the cultivarid and speciesid combination must correspond to an existing cultivar record.',
    NULL
),
(
    'seeding',
    'type',
    6,
    'text',
    'YES',
    'Type of propagule addition represented by the record.',
    'Distinguishes seeding from planting records.',
    'seeding; planting',
    'seeding',
    'Legacy Excel field: trt.',
    'Must match the type_check SQL CHECK constraint when populated.',
    NULL
),
(
    'seeding',
    'rate',
    7,
    'numeric',
    'YES',
    'Numerical seeding or planting rate.',
    'Interpret with unit. Use only for numeric rates; unknown rates should be represented through notes or allowed categorical handling elsewhere rather than forced into this numeric field.',
    NULL,
    '12.5',
    'Legacy Excel rate field allowed unknown as a source value, but SQL rate is numeric.',
    'Check that rate is paired with an appropriate unit when populated.',
    NULL
),
(
    'seeding',
    'unit',
    8,
    'text',
    'YES',
    'Unit associated with the seeding or planting rate.',
    'Use with rate to interpret seeding or planting quantity.',
    'stems/ha; g/ha; g/km; lbs/ac; ounces/plot; seeds/m2; g/cell; g/m2; individuals/plot; individuals/site; seeds/plot; seeds/pool; unknown',
    'g/m2',
    'Legacy Excel field: unit.',
    'Must match the unit_check SQL CHECK constraint when populated.',
    NULL
),
(
    'seeding',
    'viability',
    9,
    'text',
    'YES',
    'Indicates whether seed viability was considered in estimated seed rates.',
    'Use to distinguish pure live seed rates, lab-tested viability adjustments, and total seed weight or not-applicable cases.',
    'PLS; lab; NA',
    'PLS',
    'Legacy Excel field: viability.',
    'Must match the viability_check SQL CHECK constraint when populated.',
    NULL
),
(
    'seeding',
    'origin',
    10,
    'text',
    'YES',
    'Origin category for the seeded or planted species relative to the project location.',
    'Use to classify species origin for the seeding or planting record.',
    'mixed; native; exotic; unknown',
    'native',
    'Legacy Excel field: seed_origin.',
    'Must match the origin_check SQL CHECK constraint when populated.',
    NULL
),
(
    'seeding',
    'source',
    11,
    'text',
    'YES',
    'Source category for seeds, plugs, seedlings, or other planted material.',
    'Use to distinguish local, commercial, farmed, wild, or mixed commercial/wild sources.',
    'local; commercial and wild; farmed; commercial; wild',
    'commercial',
    'Legacy Excel field: source.',
    'Must match the source_check SQL CHECK constraint when populated.',
    NULL
),
(
    'seeding',
    'seed_distance',
    12,
    'text',
    'YES',
    'Distance between the seed or propagule source and the restoration site, when reported.',
    'May be recorded in kilometres or as described in the source paper.',
    NULL,
    '15 km',
    'Legacy Excel field: seeddist.',
    'Check for units and interpretation. Values may be descriptive rather than strictly numeric.',
    NULL
),
(
    'seeding',
    'seed_mixid',
    13,
    'integer',
    'NO',
    'Identifier for the seed mix associated with the seeding or planting record.',
    'Foreign key to grp.seed_mix.seed_mixid. Used to group seeding records within treatment-level seed or planting mixes.',
    NULL,
    '1',
    NULL,
    'Must correspond to an existing seed_mix record.',
    NULL
),
(
    'seeding',
    'notes',
    14,
    'text',
    'YES',
    'Additional notes about the seeding or planting record.',
    'Use for source-specific interpretation decisions, uncertain rates, species identity caveats, or other seeding-level context not captured in structured fields.',
    NULL,
    'Rate reported as unknown in source paper.',
    NULL,
    'Avoid storing structured values here when a dedicated field exists.',
    NULL
),

-- =====================================================
-- grp.seeding_pretreatment
-- =====================================================

(
    'seeding_pretreatment',
    'seedingid',
    1,
    'integer',
    'NO',
    'Identifier for the seeding record associated with the pretreatment.',
    'Foreign key to grp.seeding.seedingid. Used with type as the composite primary key for seeding pretreatment records.',
    NULL,
    '1',
    NULL,
    'Must correspond to an existing seeding record.',
    NULL
),
(
    'seeding_pretreatment',
    'type',
    2,
    'text',
    'NO',
    'Seed pretreatment type associated with the seeding record.',
    'Foreign key to grp.pretreatment.type. Values must exist in grp.pretreatment before they can be referenced in seeding pretreatment records.',
    NULL,
    'scarification',
    'Legacy Excel field: seedpretreatment.',
    'Must correspond to an existing pretreatment lookup value.',
    NULL
);

-- =====================================================
-- Table: grp.vegmetric
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
(
    'vegmetric',
    'type',
    1,
    'text',
    'NO',
    'Controlled vocabulary value describing a vegetation monitoring metric collected within a project.',
    'Used as a lookup table for grp.project_vegmetric.type. Values must exist here before they can be linked to projects.',
    NULL,
    'cover',
    'Legacy Excel field: vegmetric.',
    'Must be unique, non-null, and reflect the intended controlled vocabulary for vegetation monitoring metrics.',
    NULL
);

-- =====================================================
-- Table: grp.project_vegmetric
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
(
    'project_vegmetric',
    'database',
    1,
    'text',
    'NO',
    'Database/workflow family associated with the project-vegetation metric relationship.',
    'Used with projectid as a composite foreign key to grp.project(database, projectid).',
    'GAZP; GRP; OM',
    'GRP',
    NULL,
    'Must correspond to an existing project record when combined with projectid.',
    NULL
),
(
    'project_vegmetric',
    'projectid',
    2,
    'integer',
    'NO',
    'Identifier for the project associated with the vegetation metric relationship.',
    'Used with database as a composite foreign key to grp.project(database, projectid).',
    NULL,
    '14',
    NULL,
    'Must correspond to an existing project record when combined with database.',
    NULL
),
(
    'project_vegmetric',
    'type',
    3,
    'text',
    'NO',
    'Vegetation monitoring metric associated with the project.',
    'Foreign key to grp.vegmetric.type. Used with database and projectid as the composite primary key for project-vegetation metric relationships.',
    NULL,
    'cover',
    NULL,
    'Must correspond to an existing vegmetric record.',
    NULL
);

-- =====================================================
-- Table: grp.project_site
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
(
    'project_site',
    'database',
    1,
    'text',
    'NO',
    'Database/workflow family associated with the project-site relationship.',
    'Used with projectid as a composite foreign key to grp.project(database, projectid).',
    'GAZP; GRP; OM',
    'GRP',
    NULL,
    'Must correspond to an existing project record when combined with projectid.',
    NULL
),
(
    'project_site',
    'projectid',
    2,
    'integer',
    'NO',
    'Identifier for the project associated with the site relationship.',
    'Used with database as a composite foreign key to grp.project(database, projectid).',
    NULL,
    '14',
    NULL,
    'Must correspond to an existing project record when combined with database.',
    NULL
),
(
    'project_site',
    'siteid',
    3,
    'integer',
    'NO',
    'Identifier for the site associated with the project.',
    'Foreign key to grp.site.siteid. Used with database and projectid as the composite primary key for project-site relationships.',
    NULL,
    '27',
    NULL,
    'Must correspond to an existing site record.',
    NULL
);

-- =====================================================
-- Table: grp.project_paper
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
(
    'project_paper',
    'database',
    1,
    'text',
    'NO',
    'Database/workflow family associated with the project-paper relationship.',
    'Used with projectid as a composite foreign key to grp.project(database, projectid).',
    'GAZP; GRP; OM',
    'GRP',
    NULL,
    'Must correspond to an existing project record when combined with projectid.',
    NULL
),
(
    'project_paper',
    'projectid',
    2,
    'integer',
    'NO',
    'Identifier for the project associated with the paper relationship.',
    'Used with database as a composite foreign key to grp.project(database, projectid).',
    NULL,
    '14',
    NULL,
    'Must correspond to an existing project record when combined with database.',
    NULL
),
(
    'project_paper',
    'paperid',
    3,
    'integer',
    'NO',
    'Identifier for the paper or source associated with the project.',
    'Foreign key to grp.paper.paperid. Used with database and projectid as the composite primary key for project-paper relationships.',
    NULL,
    '8',
    NULL,
    'Must correspond to an existing paper record.',
    NULL
),
(
    'project_paper',
    'notes',
    4,
    'text',
    'YES',
    'Additional notes describing the relationship between the project and the associated paper or source.',
    'Use for contextual information such as partial data extraction, supplemental appendices, unusual linkage decisions, or project-specific caveats related to the source.',
    NULL,
    'Only pre-treatment monitoring data were extracted from this paper.',
    NULL,
    'Avoid duplicating information already stored in grp.project.notes or grp.paper fields unless relationship-specific context is required.',
    NULL
);

-- =====================================================
-- Table: grp.project_location
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
(
    'project_location',
    'database',
    1,
    'text',
    'NO',
    'Database/workflow family associated with the project-location relationship.',
    'Used with projectid as a composite foreign key to grp.project(database, projectid).',
    'GAZP; GRP; OM',
    'GRP',
    NULL,
    'Must correspond to an existing project record when combined with projectid.',
    NULL
),
(
    'project_location',
    'projectid',
    2,
    'integer',
    'NO',
    'Identifier for the project associated with the location relationship.',
    'Used with database as a composite foreign key to grp.project(database, projectid).',
    NULL,
    '14',
    NULL,
    'Must correspond to an existing project record when combined with database.',
    NULL
),
(
    'project_location',
    'locationid',
    3,
    'integer',
    'NO',
    'Identifier for the geographic location associated with the project.',
    'Foreign key to grp.location.locationid. Used with database and projectid as the composite primary key for project-location relationships.',
    NULL,
    '3',
    NULL,
    'Must correspond to an existing location record.',
    NULL
);

-- =====================================================
-- Table: grp.project_contributor
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
(
    'project_contributor',
    'database',
    1,
    'text',
    'NO',
    'Database/workflow family associated with the project-contributor relationship.',
    'Used with projectid as a composite foreign key to grp.project(database, projectid).',
    'GAZP; GRP; OM',
    'GRP',
    NULL,
    'Must correspond to an existing project record when combined with projectid.',
    NULL
),
(
    'project_contributor',
    'projectid',
    2,
    'integer',
    'NO',
    'Identifier for the project associated with the contributor relationship.',
    'Used with database as a composite foreign key to grp.project(database, projectid).',
    NULL,
    '14',
    NULL,
    'Must correspond to an existing project record when combined with database.',
    NULL
),
(
    'project_contributor',
    'author_contributorid',
    3,
    'integer',
    'NO',
    'Identifier for the author or contributor associated with the project.',
    'Foreign key to grp.author_contributor.author_contributorid. Used with database and projectid as the composite primary key for project-contributor relationships.',
    NULL,
    '12',
    NULL,
    'Must correspond to an existing author_contributor record.',
    NULL
);

-- =====================================================
-- Table: grp.project
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
(
    'project',
    'database',
    1,
    'text',
    'NO',
    'Database/workflow family associated with the project record.',
    'Used with projectid as the composite primary key for projects and linked project tables.',
    'GAZP; GRP; OM',
    'GRP',
    'GAZP = Global Arid Zone Project; GRP = Global Restore Project; OM = Oak Meadow workflow.',
    'Must match the database_check SQL CHECK constraint.',
    NULL
),
(
    'project',
    'projectid',
    2,
    'integer',
    'NO',
    'Unique project identifier within a database/workflow family.',
    'Used with database as the composite primary key for projects.',
    NULL,
    '14',
    'Legacy Excel field: projectid.',
    'Must be unique within each database value.',
    NULL
),
(
    'project',
    'type',
    3,
    'text',
    'YES',
    'Study or restoration project design type.',
    'Describes the overall restoration or monitoring design represented by the project.',
    'artificial plots; experimental planting; experimental restoration; experimental seeding; landscape restoration; reference',
    'experimental seeding',
    'Legacy Excel field: studytype.',
    'Must match the type_check SQL CHECK constraint. Multiple values should not be combined within a single record.',
    NULL
),
(
    'project',
    'community',
    4,
    'text',
    'YES',
    'Indicates whether vegetation monitoring data were collected at the community level rather than only for focal species.',
    'Used to distinguish species/community-level monitoring from more limited vegetation observations.',
    'yes; no; full community; functional group; seeded community; tree community',
    'full community',
    'Legacy Excel field: community.',
    'Must match the community_check SQL CHECK constraint.',
    NULL
),
(
    'project',
    'reference',
    5,
    'text',
    'YES',
    'Indicates whether reference ecosystem or reference-site data were available for the project.',
    'Used to identify projects that include reference-condition comparisons.',
    'yes; not provided',
    'yes',
    'Legacy Excel field: refdata.',
    'Must match the reference_check SQL CHECK constraint.',
    NULL
),
(
    'project',
    'availability',
    6,
    'text',
    'YES',
    'Level of public availability or access restriction associated with the project data.',
    'Used to document sharing permissions, restrictions, or release timing for project data.',
    'public; no spatial information; delayed public; by request; private',
    'by request',
    'Legacy Excel field: availability.',
    'Must match the availability_check SQL CHECK constraint.',
    NULL
),
(
    'project',
    'notes',
    7,
    'text',
    'YES',
    'Additional project details, caveats, or workflow notes important for interpretation or reuse.',
    'Use for methodological notes, unusual project structure, known limitations, or other contextual information not captured elsewhere.',
    NULL,
    'Pin-drop coordinates were used instead of site polygons.',
    'Legacy Excel field: notes.',
    'Avoid storing structured variables here when a dedicated field exists elsewhere in the schema.',
    NULL
);

-- =====================================================
-- Table: grp.paper_author
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
(
    'paper_author',
    'paperid',
    1,
    'integer',
    'NO',
    'Identifier for the paper associated with the author relationship.',
    'Foreign key to grp.paper.paperid. Used with author_contributorid as the composite primary key for paper-author relationships.',
    NULL,
    '1',
    NULL,
    'Must correspond to an existing paper record.',
    NULL
),
(
    'paper_author',
    'author_contributorid',
    2,
    'integer',
    'NO',
    'Identifier for the author or contributor associated with the paper.',
    'Foreign key to grp.author_contributor.author_contributorid. Used with paperid as the composite primary key for paper-author relationships.',
    NULL,
    '12',
    NULL,
    'Must correspond to an existing author_contributor record.',
    NULL
),
(
    'paper_author',
    'is_corresponding_author',
    3,
    'boolean',
    'YES',
    'Indicates whether the author/contributor is the corresponding author for the paper.',
    'Use when corresponding author information is known.',
    'TRUE; FALSE',
    'TRUE',
    NULL,
    'Should be TRUE only for confirmed corresponding authors. May be NULL when corresponding author status is unknown or not recorded.',
    NULL
);

-- =====================================================
-- Table: grp.paper
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
(
    'paper',
    'paperid',
    1,
    'integer',
    'NO',
    'Unique identifier for a paper, report, or source record.',
    'Used to link source records to authors through grp.paper_author and to projects through grp.project_paper.',
    NULL,
    '1',
    NULL,
    'Must be unique and non-null.',
    NULL
),
(
    'paper',
    'publication_year',
    2,
    'integer',
    'YES',
    'Year the paper, report, or source was published.',
    'Publication/source metadata.',
    NULL,
    '2018',
    'Legacy Excel field: pubyear.',
    'Should be a plausible four-digit year when populated.',
    NULL
),
(
    'paper',
    'publication_title',
    3,
    'text',
    'YES',
    'Title of the paper, report, or associated source.',
    'Publication/source metadata.',
    NULL,
    'Restoration outcomes in dryland ecosystems',
    'Legacy Excel field: pubtitle.',
    'Check for duplicate or near-duplicate source records.',
    NULL
),
(
    'paper',
    'publication_journal',
    4,
    'text',
    'YES',
    'Journal name, report publisher, or source outlet.',
    'Publication/source metadata.',
    NULL,
    'Restoration Ecology',
    'Legacy Excel field: pubjournal.',
    'Check for spelling consistency in repeated journal or publisher names.',
    NULL
),
(
    'paper',
    'publication_doi',
    5,
    'text',
    'YES',
    'Digital Object Identifier for the paper or source, if available.',
    'Publication/source metadata.',
    NULL,
    '10.1111/rec.12345',
    'Legacy Excel field: pubDOI.',
    'Must be unique when populated. Check DOI formatting and avoid entering URL prefixes unless intentionally standardized.',
    NULL
),
(
    'paper',
    'publication_url',
    6,
    'text',
    'YES',
    'URL for the paper, report, or source, if available.',
    'Publication/source metadata.',
    NULL,
    'https://example.org/report.pdf',
    'Legacy Excel field: pubURL.',
    'Check that URLs are complete and stable where possible.',
    NULL
),
(
    'paper',
    'data_citation',
    7,
    'text',
    'YES',
    'Citation for the dataset or data source associated with the paper or project, when distinct from the publication citation.',
    'Data access/provenance metadata currently stored in the paper table. Future restructuring may separate dataset/source-access records from publication records.',
    NULL,
    'Smith et al. 2018. Dryland restoration dataset. Dryad.',
    'Legacy Excel field: citationofdatasource.',
    'Use when data were open-source, downloaded, or otherwise have a distinct data citation. Avoid duplicating publication citation unless it is also the data citation.',
    NULL
),
(
    'paper',
    'creativecommons_license',
    8,
    'text',
    'YES',
    'Creative Commons or similar reuse license associated with the dataset or source material, if applicable.',
    'Data access/reuse metadata currently stored in the paper table. Future restructuring may separate dataset/source-access records from publication records.',
    NULL,
    'CC-BY',
    'Legacy Excel field: creativecommonslicence.',
    'Only populate when license information is known. Check for consistent license naming.',
    'Creative Commons license information may be derived from publication, repository, or source data access pages.'
),
(
    'paper',
    'use_conditions',
    9,
    'text',
    'YES',
    'Conditions for use or republishing of the associated data or source material.',
    'Data access/reuse metadata currently stored in the paper table. Future restructuring may separate dataset/source-access records from publication records.',
    NULL,
    'Use permitted with attribution; embargo until 2027-01-01.',
    'Legacy Excel field: conditionsforuseandrepublishing.',
    'Use for embargoes, attribution requirements, restrictions, or other data-use conditions. Do not leave ambiguous restrictions undocumented when known.',
    NULL
),
(
    'paper',
    'date_received',
    10,
    'date',
    'YES',
    'Date the associated data or source material was received by the GRP workflow.',
    'Data access/provenance metadata currently stored in the paper table. Future restructuring may separate dataset/source-access records from publication records.',
    NULL,
    '2026-05-20',
    NULL,
    'Use ISO date format. Should reflect receipt of data/source material, not publication date.',
    NULL
);

-- =====================================================
-- Table: grp.location
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
(
    'location',
    'locationid',
    1,
    'integer',
    'NO',
    'Unique identifier for a geographic location record.',
    'Used to normalize and reuse geographic location information across projects through grp.project_location.',
    NULL,
    '1',
    NULL,
    'Must be unique and non-null.',
    NULL
),
(
    'location',
    'continent',
    2,
    'text',
    'YES',
    'Continent or major geographic region associated with the location.',
    'Used with country and state to define standardized project locations.',
    NULL,
    'North America',
    NULL,
    'Values are constrained by the continent_check SQL CHECK constraint. Used together with country and state to define a unique location combination.',
    NULL
),
(
    'location',
    'country',
    3,
    'text',
    'YES',
    'Country associated with the location.',
    'Used with continent and state to define standardized project locations.',
    NULL,
    'Canada',
    NULL,
    'Values are constrained by the country_check SQL CHECK constraint. Used together with continent and state to define a unique location combination.',
    NULL
),
(
    'location',
    'state',
    4,
    'text',
    'YES',
    'State, province, territory, or other subnational administrative region associated with the location.',
    'Used with continent and country to provide finer-scale geographic information where relevant.',
    NULL,
    'British Columbia',
    NULL,
    'No SQL CHECK constraint currently standardizes subnational administrative names. Values should be reviewed for spelling consistency and naming conventions during import.',
    NULL
);

-- =====================================================
-- Table: grp.lifespan
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
(
    'lifespan',
    'description',
    1,
    'text',
    'NO',
    'Controlled vocabulary value describing plant lifespan category.',
    'Used as a lookup table for grp.species_lifespan.description. Lifespan classifications are derived primarily from TRY and USDA trait sources.',
    NULL,
    'perennial',
    'Multiple lifespan values may be stored using "/" separators when source trait databases reported multiple lifespan categories for a species.',
    'Controlled vocabulary is maintained through this lookup table rather than a CHECK constraint. Values should be reviewed for separator consistency and unintended spelling variants.',
    'Derived primarily from TRY and USDA trait databases.'
);

-- =====================================================
-- Table: grp.individual
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
(
    'individual',
    'individualid',
    1,
    'integer',
    'NO',
    'Unique identifier for an individual plant or organism record.',
    'Used to track individual-level planting, monitoring, survival, growth, or vegetation result data.',
    NULL,
    '1',
    NULL,
    'Must be unique and non-null.',
    NULL
),
(
    'individual',
    'areaid',
    2,
    'integer',
    'YES',
    'Identifier for the area where the individual is located.',
    'Foreign key to grp.area.areaid.',
    NULL,
    '101',
    NULL,
    'If populated, must correspond to an existing area record.',
    NULL
),
(
    'individual',
    'speciesid',
    3,
    'integer',
    'YES',
    'Identifier for the species associated with the individual.',
    'Foreign key to grp.species.speciesid.',
    NULL,
    '45',
    NULL,
    'If populated, must correspond to an existing species record.',
    NULL
),
(
    'individual',
    'latitude',
    4,
    'numeric',
    'YES',
    'Latitude coordinate for the individual location, when available.',
    'Use with longitude for geographic coordinates.',
    NULL,
    '48.4634',
    NULL,
    'Must be between -90 and 90 when populated.',
    NULL
),
(
    'individual',
    'longitude',
    5,
    'numeric',
    'YES',
    'Longitude coordinate for the individual location, when available.',
    'Use with latitude for geographic coordinates.',
    NULL,
    '-123.3117',
    NULL,
    'Must be between -180 and 180 when populated.',
    NULL
),
(
    'individual',
    'position_x',
    6,
    'numeric',
    'YES',
    'Local x-coordinate or column position for the individual within an area or planting grid.',
    'Use with position_y and position_units when individuals are mapped using local grid, row-column, or Cartesian-style coordinates rather than latitude/longitude.',
    NULL,
    '3',
    NULL,
    'Should be interpreted as a local within-area position, not a geographic coordinate.',
    NULL
),
(
    'individual',
    'position_y',
    7,
    'numeric',
    'YES',
    'Local y-coordinate or row position for the individual within an area or planting grid.',
    'Use with position_x and position_units when individuals are mapped using local grid, row-column, or Cartesian-style coordinates rather than latitude/longitude.',
    NULL,
    '7',
    NULL,
    'Should be interpreted as a local within-area position, not a geographic coordinate.',
    NULL
),
(
    'individual',
    'position_units',
    8,
    'text',
    'YES',
    'Units or coordinate system used for position_x and position_y.',
    'Use to clarify whether local positions are recorded as metres, grid cells, rows/columns, or another within-area positioning system.',
    NULL,
    'grid cells',
    NULL,
    'Should be populated when position_x or position_y is populated, where possible.',
    NULL
),
(
    'individual',
    'initial_dbh',
    9,
    'numeric',
    'YES',
    'Initial diameter at breast height recorded for the individual.',
    'Use for individual-level baseline size measurements, especially woody plants.',
    NULL,
    '12.5',
    NULL,
    'Must be zero or greater when populated. Interpret with dbh_units.',
    NULL
),
(
    'individual',
    'dbh_units',
    10,
    'text',
    'YES',
    'Units for initial_dbh.',
    'Use to interpret the initial diameter at breast height value.',
    NULL,
    'cm',
    NULL,
    'Should be populated when initial_dbh is populated, where possible.',
    NULL
),
(
    'individual',
    'initial_height',
    11,
    'numeric',
    'YES',
    'Initial height recorded for the individual.',
    'Use for individual-level baseline size measurements.',
    NULL,
    '45',
    NULL,
    'Must be zero or greater when populated. Interpret with height_units.',
    NULL
),
(
    'individual',
    'height_units',
    12,
    'text',
    'YES',
    'Units for initial_height.',
    'Use to interpret the initial height value.',
    NULL,
    'cm',
    NULL,
    'Should be populated when initial_height is populated, where possible.',
    NULL
),
(
    'individual',
    'initial_age',
    13,
    'numeric',
    'YES',
    'Initial age recorded for the individual.',
    'Use when age at planting, observation, or initial monitoring is known.',
    NULL,
    '2',
    NULL,
    'Must be zero or greater when populated. Interpret with age_units.',
    NULL
),
(
    'individual',
    'age_units',
    14,
    'text',
    'YES',
    'Units for initial_age.',
    'Use to interpret the initial age value.',
    NULL,
    'years',
    NULL,
    'Should be populated when initial_age is populated, where possible.',
    NULL
);

-- =====================================================
-- Tables: grp.grazer, grp.growth_medium, grp.herbicide,
--         grp.invasion_control, grp.pretreatment
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

-- =====================================================
-- grp.grazer
-- =====================================================

(
    'grazer',
    'type',
    1,
    'text',
    'NO',
    'Controlled vocabulary value describing the grazer manipulation status associated with a restoration treatment.',
    'Used as a lookup table for grp.treatment_grazer.type. Values must exist here before they can be referenced in treatment records.',
    NULL,
    'removed',
    NULL,
    'Controlled vocabulary is maintained through this lookup table rather than a CHECK constraint. Values should describe grazer manipulation status, not grazer identity; grazer identity details such as domestic, wildlife, or species should be recorded in treatment notes where available.',
    NULL
),

-- =====================================================
-- grp.growth_medium
-- =====================================================

(
    'growth_medium',
    'type',
    1,
    'text',
    'NO',
    'Controlled vocabulary value describing substrate or growth medium applied as part of restoration treatment.',
    'Used as a lookup table for grp.treatment_medium.type. Values must exist here before they can be referenced in treatment records.',
    NULL,
    'topsoil',
    NULL,
    'Controlled vocabulary is maintained through this lookup table rather than a CHECK constraint. Values may describe substrate source material, texture, processing byproducts, or mixtures.',
    NULL
),

-- =====================================================
-- grp.herbicide
-- =====================================================

(
    'herbicide',
    'type',
    1,
    'text',
    'NO',
    'Controlled vocabulary value describing herbicide treatment type or herbicide application approach.',
    'Used as a lookup table for grp.treatment_herbicide.type. Values must exist here before they can be referenced in treatment records.',
    NULL,
    'glyphosate',
    NULL,
    'Controlled vocabulary is maintained through this lookup table rather than a CHECK constraint. Values may represent herbicide compounds, application strategies, or qualitative herbicide treatment descriptions.',
    NULL
),

-- =====================================================
-- grp.invasion_control
-- =====================================================

(
    'invasion_control',
    'type',
    1,
    'text',
    'NO',
    'Controlled vocabulary value describing invasive species control methods used during restoration treatment.',
    'Used as a lookup table for grp.treatment_invasion.type. Values must exist here before they can be referenced in treatment records.',
    NULL,
    'pulling',
    NULL,
    'Controlled vocabulary is maintained through this lookup table rather than a CHECK constraint. Values may describe manual, mechanical, fire-based, or other invasive species control approaches.',
    NULL
),

-- =====================================================
-- grp.pretreatment
-- =====================================================

(
    'pretreatment',
    'type',
    1,
    'text',
    'NO',
    'Controlled vocabulary value describing seed pretreatment methods applied prior to seeding.',
    'Used as a lookup table for grp.seeding_pretreatment.type. Values must exist here before they can be referenced in seeding pretreatment records.',
    NULL,
    'scarification',
    NULL,
    'Controlled vocabulary is maintained through this lookup table rather than a CHECK constraint. Values may describe physical, chemical, thermal, hormonal, or coating-based seed pretreatments.',
    NULL
);

-- =====================================================
-- Tables: grp.disturbance, grp.erosion_control, grp.fertilization
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

-- =====================================================
-- grp.disturbance
-- =====================================================

(
    'disturbance',
    'type',
    1,
    'text',
    'NO',
    'Controlled vocabulary value describing the major disturbance type associated with the site that led to restoration treatment.',
    'Used as a lookup table for grp.site_disturbance.type. Values must exist here before they can be referenced in site disturbance records.',
    NULL,
    'invasion',
    NULL,
    'Controlled vocabulary is maintained through this lookup table rather than a CHECK constraint. Multiple disturbances should be listed in alphabetical order using a consistent separator.',
    NULL
),

-- =====================================================
-- grp.erosion_control
-- =====================================================

(
    'erosion_control',
    'type',
    1,
    'text',
    'NO',
    'Controlled vocabulary value describing erosion control treatments applied during restoration.',
    'Used as a lookup table for grp.treatment_erosion.type. Values must exist here before they can be referenced in treatment records.',
    NULL,
    'blanket',
    NULL,
    'Controlled vocabulary is maintained through this lookup table rather than a CHECK constraint. Values should be reviewed for spelling consistency and unintended variants.',
    NULL
),

-- =====================================================
-- grp.fertilization
-- =====================================================

(
    'fertilization',
    'type',
    1,
    'text',
    'NO',
    'Controlled vocabulary value describing fertilizer type or fertilization treatment applied during restoration.',
    'Used as a lookup table for grp.treatment_fertilization.type. Values must exist here before they can be referenced in treatment records.',
    NULL,
    'NPK',
    NULL,
    'Controlled vocabulary is maintained through this lookup table rather than a CHECK constraint. Values may describe compounds, nutrient types, or qualitative fertilization treatments.',
    NULL
);

-- =====================================================
-- Table: grp.cultivar
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
(
    'cultivar',
    'cultivarid',
    1,
    'integer',
    'NO',
    'Identifier for a cultivar record within a species.',
    'Used with speciesid as the composite primary key for cultivar records. Cultivars may share a name or origin but still be treated as separate cultivar records depending on context.',
    NULL,
    '1',
    NULL,
    'Must be non-null. The cultivarid and speciesid combination must be unique.',
    NULL
),
(
    'cultivar',
    'speciesid',
    2,
    'integer',
    'NO',
    'Identifier for the species associated with the cultivar.',
    'Foreign key to grp.species.speciesid. Used with cultivarid to identify cultivar records and to link cultivar information to seeding and vegetation result records.',
    NULL,
    '45',
    'Legacy Excel metadata described this as the GAZP unique species code.',
    'Must correspond to an existing species record. The cultivarid and speciesid combination must be unique.',
    NULL
),
(
    'cultivar',
    'name',
    3,
    'text',
    'YES',
    'Cultivar name or cultivar name identifier.',
    'Use when a seeded or observed plant was identified to a cultivar, variety, or named seed source level below species.',
    NULL,
    'Dacotah',
    NULL,
    'Check for spelling consistency and unintended duplicate cultivar records.',
    NULL
),
(
    'cultivar',
    'origin',
    4,
    'text',
    'YES',
    'Place name or source location associated with the cultivar origin.',
    'May be a broad place name rather than a precise coordinate location.',
    NULL,
    'Wyoming',
    NULL,
    'Check that origin is interpreted as a descriptive place/source field, not necessarily as a geocoded location.',
    NULL
),
(
    'cultivar',
    'latitude',
    5,
    'numeric',
    'YES',
    'Latitude coordinate for the cultivar origin, when available.',
    'Use with longitude when the cultivar origin is available as coordinates.',
    NULL,
    '43.0759',
    'Legacy Excel field: seedlat.',
    'Must be between -90 and 90 when populated. Coordinates should describe the cultivar origin, not the restoration site unless those are intentionally the same.',
    NULL
),
(
    'cultivar',
    'longitude',
    6,
    'numeric',
    'YES',
    'Longitude coordinate for the cultivar origin, when available.',
    'Use with latitude when the cultivar origin is available as coordinates.',
    NULL,
    '-107.2903',
    'Legacy Excel field: seedlong.',
    'Must be between -180 and 180 when populated. Coordinates should describe the cultivar origin, not the restoration site unless those are intentionally the same.',
    NULL
);

-- =====================================================
-- Table: grp.classification
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
(
    'classification',
    'classificationid',
    1,
    'text',
    'NO',
    'Unique identifier for a habitat classification record.',
    'Used to link habitat classifications to sites through grp.site_classification.',
    NULL,
    '2.1.3',
    NULL,
    'Must be unique and non-null.',
    NULL
),
(
    'classification',
    'class',
    2,
    'text',
    'YES',
    'Top-level USDA/NatureServe world formation habitat classification category.',
    'Part of the hierarchical habitat classification system used for site classification.',
    NULL,
    'Forest & Woodland',
    NULL,
    'Values are constrained by the class_check SQL CHECK constraint. Used together with subclass and subsubclass to define a unique classification combination.',
    'Based on Faber-Langendoen et al. (2016) world formation classification framework.'
),
(
    'classification',
    'subclass',
    3,
    'text',
    'YES',
    'Intermediate USDA/NatureServe world formation habitat classification category.',
    'Part of the hierarchical habitat classification system used for site classification.',
    NULL,
    'Temperate & Boreal Forest & Woodland',
    NULL,
    'Values are constrained by the subclass_check SQL CHECK constraint. Used together with class and subsubclass to define a unique classification combination.',
    'Based on Faber-Langendoen et al. (2016) world formation classification framework.'
),
(
    'classification',
    'subsubclass',
    4,
    'text',
    'YES',
    'Detailed USDA/NatureServe world formation habitat classification category.',
    'Part of the hierarchical habitat classification system used for site classification.',
    NULL,
    'Cool Temperate Forest & Woodland',
    NULL,
    'Values are constrained by the subsubclass_check SQL CHECK constraint. Used together with class and subclass to define a unique classification combination.',
    'Based on Faber-Langendoen et al. (2016) world formation classification framework.'
);

-- =====================================================
-- Table: grp.bed_prep
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
(
    'bed_prep',
    'type',
    1,
    'text',
    'NO',
    'Controlled vocabulary value describing reformation or preparation of the upper bed material as part of a restoration treatment.',
    'Used as a lookup table for grp.treatment_prep.type. Values must exist here before they can be referenced in treatment records.',
    NULL,
    'ripping',
    NULL,
    'Controlled vocabulary is maintained through this lookup table rather than a CHECK constraint. Values should be reviewed for spelling consistency and unintended variants.',
    NULL
);

-- =====================================================
-- Table: grp.bed_material
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
(
    'bed_material',
    'type',
    1,
    'text',
    'NO',
    'Controlled vocabulary value describing material added to the substrate surface as part of a restoration treatment.',
    'Used as a lookup table for grp.treatment_material.type. Values must exist here before they can be referenced in treatment records.',
    NULL,
    'mulch',
    NULL,
    'Controlled vocabulary is maintained through this lookup table rather than a CHECK constraint. Values should be reviewed for spelling consistency and unintended variants.',
    NULL
);

-- =====================================================
-- Table: grp.author_contributor
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
(
    'author_contributor',
    'author_contributorid',
    1,
    'integer',
    'NO',
    'Unique identifier for an author or contributor person record.',
    'Used to identify people who are linked to papers, projects, or both.',
    NULL,
    '1',
    NULL,
    'Must be unique and non-null.',
    NULL
),
(
    'author_contributor',
    'given_name',
    2,
    'text',
    'YES',
    'Given name or first name of the author or contributor.',
    'Use with surname to identify the person.',
    NULL,
    'Jane',
    NULL,
    'Check for inconsistent spelling or duplicate people entered with slight name variations.',
    NULL
),
(
    'author_contributor',
    'surname',
    3,
    'text',
    'YES',
    'Surname or family name of the author or contributor.',
    'Use with given_name to identify the person.',
    NULL,
    'Smith',
    NULL,
    'Check for inconsistent spelling or duplicate people entered with slight name variations.',
    NULL
),
(
    'author_contributor',
    'email',
    4,
    'text',
    'YES',
    'Email address for the author or contributor, if available.',
    'Used as an optional contact or disambiguation field.',
    NULL,
    'jane.smith@example.org',
    NULL,
    'When populated, must satisfy the email format CHECK constraint and must be unique across author_contributor records.',
    NULL
);

-- =====================================================
-- Table: grp.area_treatment
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
(
    'area_treatment',
    'database',
    1,
    'text',
    'NO',
    'Workflow/database namespace associated with the area-treatment relationship record.',
    'Used to distinguish historical and current workflow streams and participates in the composite primary key for this relationship table.',
    'GAZP; GRP; OM',
    'OM',
    'GAZP = first-generation data; GRP = Emma-era workflow; OM = Oak Meadow redevelopment workflow.',
    'Should match the intended workflow namespace used by the linked project and treatment records.',
    NULL
),
(
    'area_treatment',
    'projectid',
    2,
    'integer',
    'NO',
    'Identifier for the project associated with the area-treatment relationship.',
    'Used with database to anchor the relationship within a project namespace.',
    NULL,
    '14',
    NULL,
    'Should correspond to a valid project associated with both the area and treatment records.',
    NULL
),
(
    'area_treatment',
    'areaid',
    3,
    'integer',
    'NO',
    'Identifier for the area receiving or associated with the treatment.',
    'Foreign key to grp.area.areaid.',
    NULL,
    '101',
    NULL,
    'Must correspond to an existing area record.',
    NULL
),
(
    'area_treatment',
    'treatmentid',
    4,
    'integer',
    'NO',
    'Identifier for the treatment associated with the area.',
    'Foreign key to grp.treatment.treatmentid. Used to link treatments to specific spatial units within a project.',
    NULL,
    '205',
    NULL,
    'Must correspond to an existing treatment record.',
    NULL
);

-- =====================================================
-- Table: grp.area
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
(
    'area',
    'areaid',
    1,
    'bigint',
    'NO',
    'Unique identifier for an area record. An area is a project spatial unit below the site level, usually the smallest spatial unit used for treatment or monitoring within a project.',
    'Use for plots, subplots, transects, blocks, individuals, or other within-site spatial units that need to be linked to treatments or monitoring results. Sites are stored separately in grp.site and do not receive areaid values.',
    NULL,
    '101',
    NULL,
    'Must be unique and non-null. Should represent a real within-site spatial unit rather than the site itself.',
    NULL
),
(
    'area',
    'siteid',
    4,
    'integer',
    'YES',
    'Identifier for the site that the area belongs to.',
    'Links the area to grp.site.siteid. For nested area structures, siteid may identify the overall site even when parentid identifies a larger within-site area.',
    NULL,
    '14',
    NULL,
    'If populated, must correspond to a valid site. Confirm during import whether siteid should be populated for all nested area levels or only for top-level areas within a site.',
    NULL
),
(
    'area',
    'type',
    5,
    'text',
    'YES',
    'Type of spatial unit represented by the area record.',
    'Use to distinguish the kind of within-site spatial unit being represented.',
    'block; individual; plot; transect',
    'plot',
    NULL,
    'Must match the allowed values enforced by the type_check constraint when populated.',
    NULL
),
(
    'area',
    'size',
    6,
    'numeric',
    'YES',
    'Spatial size or extent of the area.',
    'May represent area for plots, blocks, or other spatial units, or length for transects. Interpret together with units and type.',
    NULL,
    '25',
    NULL,
    'Must be interpreted with units. Check for impossible or inconsistent values, such as area units used for transect length unless intentionally documented.',
    NULL
),
(
    'area',
    'units',
    7,
    'text',
    'YES',
    'Units associated with the size value.',
    'Use with size to interpret the spatial extent of the area.',
    'km2; hm2; dam2; m2; dm2; cm2; ha; sqmi; acre; sqyd; sqft; sqin; sqnmi; m; proportion; cm; minutes/hectare',
    'm2',
    NULL,
    'Must match the allowed values enforced by the units_check constraint when populated. Confirm that the unit is appropriate for the area type and size value.',
    NULL
),
(
    'area',
    'restoration_start_year',
    8,
    'numeric',
    'YES',
    'Year restoration began in the area.',
    'Use when restoration timing differs among areas within a site or project.',
    NULL,
    '2018',
    NULL,
    'Should be a plausible four-digit year when populated. Check consistency with project, treatment, and monitoring dates.',
    NULL
),
(
    'area',
    'restoration_type',
    9,
    'text',
    'YES',
    'Broad restoration or reference condition category assigned to the area.',
    'Use to distinguish passive restoration, active planting or seeding, reference areas, degraded reference areas, and related restoration categories.',
    'degraded reference; passive; planting; reference; seeding; seeding & planting',
    'seeding & planting',
    NULL,
    'Must match the allowed values enforced by the restoration_type_check constraint when populated. Confirm that reference and degraded reference areas are coded intentionally.',
    NULL
),
(
    'area',
    'disturbance_end_year',
    10,
    'numeric',
    'YES',
    'Year the main pre-restoration disturbance ended in the area, if known.',
    'May be unknown, approximate, or not applicable when the disturbance is ongoing, diffuse, or does not have a clear end date.',
    NULL,
    '2015',
    NULL,
    'Should be a plausible four-digit year when populated. Do not force a value for ongoing disturbances such as invasion where the disturbance does not clearly end with restoration.',
    NULL
),
(
    'area',
    'parentid',
    11,
    'integer',
    'YES',
    'Area identifier for the larger spatial unit that contains this area, when areas are nested.',
    'Self-referencing link to grp.area.areaid. Use to represent nested spatial structures such as plots within blocks within sites.',
    NULL,
    '100',
    NULL,
    'If populated, must correspond to an existing areaid. Check that parent-child relationships are logically nested and do not create circular references.',
    NULL
);

-- =====================================================
-- Table: grp.application_method
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
VALUES (
    'application_method',
    'type',
    1,
    'text',
    'NO',
    'Controlled vocabulary value describing the method by which a treatment application was carried out.',
    'Used as a lookup table for grp.treatment_application.type. Values must exist here before they can be referenced in treatment records.',
    NULL,
    NULL,
    NULL,
    'Must be unique, non-null, and reflect the intended controlled vocabulary for treatment application methods.',
    NULL
);

