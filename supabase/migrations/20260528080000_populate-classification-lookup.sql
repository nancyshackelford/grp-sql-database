-- Remove existing constraints
ALTER TABLE grp.classification
DROP CONSTRAINT IF EXISTS class_check;

ALTER TABLE grp.classification
DROP CONSTRAINT IF EXISTS subclass_check;

ALTER TABLE grp.classification
DROP CONSTRAINT IF EXISTS subsubclass_check;

-- Insert USDA classification system from reference source: Faber-Langendoen, D.; Keeler, T.; Meidinger, D.; Josse, C.; Weakley, A.; Tart, D.; Navarro, G.; Hoagland, B.; Ponomarenko, S.; Fults, G.; Helmer, E. 2016. Classification and description of world formation types. Gen. Tech. Rep. RMRS-GTR-346. Fort Collins, CO: U.S. Department of Agriculture, Forest Service, Rocky Mountain Research Station. 222 p.
INSERT INTO grp.classification (
  classificationid,
  class,
  subclass,
  subsubclass
)
VALUES
('1.A.1', 'Forest & Woodland', 'Tropical Forest & Woodland', 'Tropical Dry Forest & Woodland'),
('1.A.2', 'Forest & Woodland', 'Tropical Forest & Woodland', 'Tropical Lowland Humid Forest'),
('1.A.3', 'Forest & Woodland', 'Tropical Forest & Woodland', 'Tropical Montane Humid Forest'),
('1.A.4', 'Forest & Woodland', 'Tropical Forest & Woodland', 'Tropical Flooded & Swamp Forest'),
('1.A.5', 'Forest & Woodland', 'Tropical Forest & Woodland', 'Mangrove'),

('1.B.1', 'Forest & Woodland', 'Temperate & Boreal Forest & Woodland', 'Warm Temperate Forest & Woodland'),
('1.B.2', 'Forest & Woodland', 'Temperate & Boreal Forest & Woodland', 'Cool Temperate Forest & Woodland'),
('1.B.3', 'Forest & Woodland', 'Temperate & Boreal Forest & Woodland', 'Temperate Flooded & Swamp Forest'),
('1.B.4', 'Forest & Woodland', 'Temperate & Boreal Forest & Woodland', 'Boreal Forest & Woodland'),
('1.B.5', 'Forest & Woodland', 'Temperate & Boreal Forest & Woodland', 'Boreal Flooded & Swamp Forest'),

('2.A.1', 'Shrub & Herb Vegetation', 'Tropical Grassland, Savanna & Shrubland', 'Tropical Lowland Grassland, Savanna & Shrubland'),
('2.A.2', 'Shrub & Herb Vegetation', 'Tropical Grassland, Savanna & Shrubland', 'Tropical Montane Grassland & Shrubland'),
('2.A.3', 'Shrub & Herb Vegetation', 'Tropical Grassland, Savanna & Shrubland', 'Tropical Scrub & Herb Coastal Vegetation'),

('2.B.1', 'Shrub & Herb Vegetation', 'Temperate & Boreal Grassland & Shrubland', 'Mediterranean Scrub & Grassland'),
('2.B.2', 'Shrub & Herb Vegetation', 'Temperate & Boreal Grassland & Shrubland', 'Temperate Grassland & Shrubland'),
('2.B.3', 'Shrub & Herb Vegetation', 'Temperate & Boreal Grassland & Shrubland', 'Boreal Grassland & Shrubland'),
('2.B.4', 'Shrub & Herb Vegetation', 'Temperate & Boreal Grassland & Shrubland', 'Temperate to Polar Scrub & Herb Coastal Vegetation'),

('2.C.1', 'Shrub & Herb Vegetation', 'Shrub & Herb Wetland', 'Tropical Bog & Fen'),
('2.C.2', 'Shrub & Herb Vegetation', 'Shrub & Herb Wetland', 'Temperate to Polar Bog & Fen'),
('2.C.3', 'Shrub & Herb Vegetation', 'Shrub & Herb Wetland', 'Tropical Freshwater Marsh, Wet Meadow & Shrubland'),
('2.C.4', 'Shrub & Herb Vegetation', 'Shrub & Herb Wetland', 'Temperate to Polar Freshwater Marsh, Wet Meadow & Shrubland'),
('2.C.5', 'Shrub & Herb Vegetation', 'Shrub & Herb Wetland', 'Salt Marsh'),

('3.A.1', 'Desert & Semi-Desert', 'Warm Desert & Semi-Desert Woodland, Scrub & Grassland', 'Tropical Thorn Woodland'),
('3.A.2', 'Desert & Semi-Desert', 'Warm Desert & Semi-Desert Woodland, Scrub & Grassland', 'Warm Desert & Semi-Desert Scrub & Grassland'),
('3.B.1', 'Desert & Semi-Desert', 'Cool Semi-Desert Scrub & Grassland', 'Cool Semi-Desert Scrub & Grassland'),

('4.A.1', 'Polar & High Montane Scrub, Grassland & Barrens', 'Tropical High Montane Scrub & Grassland', 'Tropical High Montane Scrub & Grassland'),
('4.B.1', 'Polar & High Montane Scrub, Grassland & Barrens', 'Temperate to Polar Alpine & Tundra Vegetation', 'Temperate & Boreal Alpine Dwarf-shrub & Grassland'),
('4.B.2', 'Polar & High Montane Scrub, Grassland & Barrens', 'Temperate to Polar Alpine & Tundra Vegetation', 'Polar Tundra & Barrens'),

('5.A.1', 'Aquatic Vegetation', 'Saltwater Aquatic Vegetation', 'Floating & Suspended Macroalgae Saltwater Vegetation'),
('5.A.2', 'Aquatic Vegetation', 'Saltwater Aquatic Vegetation', 'Benthic Macroalgae Saltwater Vegetation'),
('5.A.3', 'Aquatic Vegetation', 'Saltwater Aquatic Vegetation', 'Benthic Vascular Saltwater Vegetation'),
('5.A.4', 'Aquatic Vegetation', 'Saltwater Aquatic Vegetation', 'Benthic Lichen Saltwater Vegetation'),
('5.B.1', 'Aquatic Vegetation', 'Freshwater Aquatic Vegetation', 'Tropical Freshwater Aquatic Vegetation'),
('5.B.2', 'Aquatic Vegetation', 'Freshwater Aquatic Vegetation', 'Temperate to Polar Freshwater Aquatic Vegetation'),

('6.A.1', 'Open Rock Vegetation', 'Tropical Open Rock Vegetation', 'Tropical Cliff, Scree & Other Rock Vegetation'),
('6.B.1', 'Open Rock Vegetation', 'Temperate & Boreal Open Rock Vegetation', 'Temperate & Boreal Cliff, Scree & Other Rock Vegetation'),

('7.A.1', 'Agricultural & Developed Vegetation', 'Woody Agricultural Vegetation', 'Woody Horticultural Crop'),
('7.A.2', 'Agricultural & Developed Vegetation', 'Woody Agricultural Vegetation', 'Forest Plantation & Agroforestry'),
('7.A.3', 'Agricultural & Developed Vegetation', 'Woody Agricultural Vegetation', 'Woody Wetland Horticultural Crop'),

('7.B.1', 'Agricultural & Developed Vegetation', 'Herbaceous Agricultural Vegetation', 'Row & Close Grain Crop'),
('7.B.2', 'Agricultural & Developed Vegetation', 'Herbaceous Agricultural Vegetation', 'Pasture & Hay Field Crop'),
('7.B.3', 'Agricultural & Developed Vegetation', 'Herbaceous Agricultural Vegetation', 'Herbaceous Horticultural Crop'),
('7.B.4', 'Agricultural & Developed Vegetation', 'Herbaceous Agricultural Vegetation', 'Fallow Field & Weed Vegetation'),
('7.B.5', 'Agricultural & Developed Vegetation', 'Herbaceous Agricultural Vegetation', 'Herbaceous Wetland Crop'),

('7.C.1', 'Agricultural & Developed Vegetation', 'Herbaceous & Woody Developed Vegetation', 'Lawn, Garden & Recreational Vegetation'),
('7.C.2', 'Agricultural & Developed Vegetation', 'Herbaceous & Woody Developed Vegetation', 'Other Developed Vegetation'),
('7.C.3', 'Agricultural & Developed Vegetation', 'Herbaceous & Woody Developed Vegetation', 'Developed Wetland Vegetation'),

('7.D.1', 'Agricultural & Developed Vegetation', 'Agricultural & Developed Aquatic Vegetation', 'Agricultural Aquatic Vegetation'),
('7.D.2', 'Agricultural & Developed Vegetation', 'Agricultural & Developed Aquatic Vegetation', 'Urban & Recreational Aquatic Vegetation')
ON CONFLICT ON CONSTRAINT classification_pkey DO UPDATE
SET
  class = EXCLUDED.class,
  subclass = EXCLUDED.subclass,
  subsubclass = EXCLUDED.subsubclass;