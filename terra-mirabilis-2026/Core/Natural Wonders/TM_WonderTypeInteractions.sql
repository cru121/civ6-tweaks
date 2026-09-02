/*
	Natural Wonder Type Interactions
	Authors: Terra Mirabilis fork

	Many natural wonders visually ARE a terrain type (mountain, marsh, reef, ...)
	but are coded as their own FEATURE on ordinary terrain, so effects that key on
	the "real" type ignore them. This module teaches the FIXABLE interactions to
	recognise the wonders. See WONDER_TYPES.md for the full catalog and rationale.

	Two interaction shapes are used:
	  A. Adjacency  -- generate AdjacentFeature adjacency-yield rows and attach to a
	     consumer district/improvement (e.g. Mountain -> Terrace Farm).
	  B. Requirement-widening -- add the wonder features to the "plot is <type>"
	     requirement sets that base effects already test, so those effects apply to
	     the wonder tiles too (e.g. Marsh -> Etemenanki / Lady of the Reeds).

	A shared classification table (TM_WonderTypes) drives both. Self-pruning: the
	JOIN on Features skips wonders whose feature is absent (missing DLC); EXISTS
	guards skip consumers/sets that are absent.
*/

-----------------------------------------------
-- Classification table (reused by each class block below)
-----------------------------------------------

CREATE TABLE IF NOT EXISTS TM_WonderTypes
(
	FeatureType TEXT NOT NULL,
	WonderClass TEXT NOT NULL,
	PRIMARY KEY (FeatureType, WonderClass)
);

-- MOUNTAIN class: mountains, volcanoes, and large rocky highlands / monoliths.
-- Ported from the Terrace mod's list, corrected per WONDER_TYPES.md:
--   REMOVED (not mountains): Paititi (legendary jungle city), Motlatse Canyon
--     (a canyon/gorge), Piopiotahi (a fjord);
--   ADDED (monolith, consistent with the Devils Tower / Gibraltar already listed): Uluru.
-- Borderline rocky highlands kept on purpose (Gibraltar, Devils Tower, Tsingy,
-- Wulingyuan, Yosemite) -- prune here if you decide they should not count.
INSERT OR IGNORE INTO TM_WonderTypes (FeatureType, WonderClass) VALUES
	('FEATURE_EVEREST',			'MOUNTAIN'),
	('FEATURE_KILIMANJARO',		'MOUNTAIN'),
	('FEATURE_MATTERHORN',		'MOUNTAIN'),
	('FEATURE_CERRO_DE_POTOSI',	'MOUNTAIN'),
	('FEATURE_KAILASH',			'MOUNTAIN'),
	('FEATURE_SINAI',			'MOUNTAIN'),
	('FEATURE_SRI_PADA',		'MOUNTAIN'),
	('FEATURE_VESUVIUS',		'MOUNTAIN'),
	('FEATURE_KRAKATOA',		'MOUNTAIN'),
	('FEATURE_ZHANGYE_DANXIA',	'MOUNTAIN'),
	('FEATURE_RORAIMA',			'MOUNTAIN'),
	('FEATURE_TORRES_DEL_PAINE','MOUNTAIN'),
	('FEATURE_GRAND_MESA',		'MOUNTAIN'),
	('FEATURE_EYJAFJALLAJOKULL','MOUNTAIN'),
	('FEATURE_DEVILSTOWER',		'MOUNTAIN'),
	('FEATURE_ULURU',			'MOUNTAIN'),
	('FEATURE_GIBRALTAR',		'MOUNTAIN'),
	('FEATURE_TSINGY',			'MOUNTAIN'),
	('FEATURE_WULINGYUAN',		'MOUNTAIN'),
	('FEATURE_YOSEMITE',		'MOUNTAIN');

-- MARSH class: wetland wonders that should count as Marsh for marsh-keyed effects.
-- Ubsunur Hollow is included as a wetland (it shares marsh's Move+1 / Def-2 profile);
-- drop it here if you consider it steppe/tundra rather than marsh.
INSERT OR IGNORE INTO TM_WonderTypes (FeatureType, WonderClass) VALUES
	('FEATURE_PANTANAL',		'MARSH'),
	('FEATURE_UBSUNUR_HOLLOW',	'MARSH');

-- REEF class: coral-reef wonders that should count as Reef for reef-keyed effects.
INSERT OR IGNORE INTO TM_WonderTypes (FeatureType, WonderClass) VALUES
	('FEATURE_BARRIER_REEF',	'REEF');

-- GEOTHERMAL class: geyser / thermal-spring / hydrothermal / mud-volcano wonders.
-- Gobustan (mud volcanoes) is borderline; drop it if you consider it not geothermal.
INSERT OR IGNORE INTO TM_WonderTypes (FeatureType, WonderClass) VALUES
	('FEATURE_OLD_FAITHFUL',	'GEOTHERMAL'),
	('FEATURE_PAMUKKALE',		'GEOTHERMAL'),
	('FEATURE_DALLOL',			'GEOTHERMAL'),
	('FEATURE_GOBUSTAN',		'GEOTHERMAL');

-- LAKE class: lake wonders the engine classifies as Coast (so Huey Teocalli's
-- IsLake check misses them). We are generous: Dead Sea and Lake Retba are real
-- lakes too. Crater Lake is a genuine engine lake (IsLake=true) and already works
-- with Huey natively, so it is intentionally NOT listed here. (Ik-Kil is a cenote
-- -- not a lake -- and Fountain of Youth is a land spring; both excluded.)
INSERT OR IGNORE INTO TM_WonderTypes (FeatureType, WonderClass) VALUES
	('FEATURE_LAKE_VICTORIA',	'LAKE'),
	('FEATURE_DEAD_SEA',		'LAKE'),
	('FEATURE_LAKE_RETBA',		'LAKE');

-----------------------------------------------
-- (A) MOUNTAIN -> Terrace Farm  (+1 Food per adjacent mountain natural wonder)
--
-- Consumer is Terrace Farm ONLY. Terra Mirabilis already grants every specialty
-- DISTRICT a standard adjacency from every natural wonder (TM_Globals.sql), so
-- adding Campus / Holy Site here would double up. Terrace Farm is an IMPROVEMENT,
-- untouched by that, and the base Inca "+1 Food per adjacent Mountain" checks
-- Mountain TERRAIN (which these flattened wonder tiles are not), so this neither
-- double-counts nor conflicts.
-----------------------------------------------

INSERT OR IGNORE INTO Adjacency_YieldChanges
		(ID,									Description,				YieldType,		YieldChange,	TilesRequired,	AdjacentFeature	)
SELECT	'TM_TF_' || F.FeatureType || '_FOOD',	'LOC_TM_TF_MOUNTAIN_NW_FOOD',	'YIELD_FOOD',	1,				1,				F.FeatureType
FROM	Features F
JOIN	TM_WonderTypes W ON W.FeatureType = F.FeatureType AND W.WonderClass = 'MOUNTAIN'
WHERE	EXISTS (SELECT 1 FROM Improvements WHERE ImprovementType = 'IMPROVEMENT_TERRACE_FARM');

INSERT OR IGNORE INTO Improvement_Adjacencies
		(ImprovementType,			YieldChangeId	)
SELECT	'IMPROVEMENT_TERRACE_FARM',	ID
FROM	Adjacency_YieldChanges
WHERE	ID LIKE 'TM_TF_%_FOOD'
AND		EXISTS (SELECT 1 FROM Improvements WHERE ImprovementType = 'IMPROVEMENT_TERRACE_FARM');

-----------------------------------------------
-- (B) MARSH -> marsh-keyed on-tile yield effects (requirement-widening)
--
-- Base effects grant yield to a plot when it passes a "plot has marsh/reeds"
-- requirement set. We add one REQUIREMENT_PLOT_FEATURE_TYPE_MATCHES per marsh
-- wonder and insert it into those sets, so the base effects apply to the wonder
-- tiles too (no yield duplication -- the base modifiers/amounts are reused).
-- Consumers covered (all are on-tile plot-yield effects gated by a "plot has
-- marsh"-type requirement set -- none is true adjacency):
--   * Lady of the Reeds and Marshes pantheon  -> PLOT_HAS_REEDS_REQUIREMENTS (+1 Production)
--   * Etemenanki wonder                        -> PLOT_HAS_MARSH_REQUIREMENTS  (+2 Science, +1 Production)
--   * Zoo building                             -> ZOO_MARSH_REQUIREMENTS       (+1 Science)
-- PLOT_HAS_REEDS_REQUIREMENTS is already TEST_ANY (just add ours); the other two are
-- TEST_ALL with a single member, so flip them to TEST_ANY (a no-op for that lone
-- member) before adding ours.
-- NOTE: this edits base-game requirement sets. Effect is exactly "these wonders now
-- count as marsh" for every consumer of those sets -- which is the intent.
-----------------------------------------------

-- One "plot has <wonder>" requirement per marsh wonder (mirrors REQUIRES_PLOT_HAS_MARSH).
INSERT OR IGNORE INTO Requirements
		(RequirementId,							RequirementType						)
SELECT	'REQ_TM_PLOT_HAS_' || W.FeatureType,	'REQUIREMENT_PLOT_FEATURE_TYPE_MATCHES'
FROM	TM_WonderTypes W
JOIN	Features F ON F.FeatureType = W.FeatureType
WHERE	W.WonderClass = 'MARSH';

INSERT OR IGNORE INTO RequirementArguments
		(RequirementId,							Name,			Value			)
SELECT	'REQ_TM_PLOT_HAS_' || W.FeatureType,	'FeatureType',	W.FeatureType
FROM	TM_WonderTypes W
JOIN	Features F ON F.FeatureType = W.FeatureType
WHERE	W.WonderClass = 'MARSH';

-- Lady of the Reeds: TEST_ANY set (marsh OR oasis OR floodplains) -- just add ours.
INSERT OR IGNORE INTO RequirementSetRequirements
		(RequirementSetId,				RequirementId						)
SELECT	'PLOT_HAS_REEDS_REQUIREMENTS',	'REQ_TM_PLOT_HAS_' || W.FeatureType
FROM	TM_WonderTypes W
JOIN	Features F ON F.FeatureType = W.FeatureType
WHERE	W.WonderClass = 'MARSH'
AND		EXISTS (SELECT 1 FROM RequirementSets WHERE RequirementSetId = 'PLOT_HAS_REEDS_REQUIREMENTS');

-- Etemenanki: PLOT_HAS_MARSH_REQUIREMENTS is TEST_ALL with a single member; switch it
-- to TEST_ANY (identical for that lone member) so our additions act as OR, then add ours.
UPDATE	RequirementSets
SET		RequirementSetType = 'REQUIREMENTSET_TEST_ANY'
WHERE	RequirementSetId = 'PLOT_HAS_MARSH_REQUIREMENTS';

INSERT OR IGNORE INTO RequirementSetRequirements
		(RequirementSetId,				RequirementId						)
SELECT	'PLOT_HAS_MARSH_REQUIREMENTS',	'REQ_TM_PLOT_HAS_' || W.FeatureType
FROM	TM_WonderTypes W
JOIN	Features F ON F.FeatureType = W.FeatureType
WHERE	W.WonderClass = 'MARSH'
AND		EXISTS (SELECT 1 FROM RequirementSets WHERE RequirementSetId = 'PLOT_HAS_MARSH_REQUIREMENTS');

-- Zoo: same TEST_ALL single-member set as Etemenanki -- flip to TEST_ANY, then add ours.
UPDATE	RequirementSets
SET		RequirementSetType = 'REQUIREMENTSET_TEST_ANY'
WHERE	RequirementSetId = 'ZOO_MARSH_REQUIREMENTS';

INSERT OR IGNORE INTO RequirementSetRequirements
		(RequirementSetId,			RequirementId						)
SELECT	'ZOO_MARSH_REQUIREMENTS',	'REQ_TM_PLOT_HAS_' || W.FeatureType
FROM	TM_WonderTypes W
JOIN	Features F ON F.FeatureType = W.FeatureType
WHERE	W.WonderClass = 'MARSH'
AND		EXISTS (SELECT 1 FROM RequirementSets WHERE RequirementSetId = 'ZOO_MARSH_REQUIREMENTS');

-----------------------------------------------
-- (C) REEF -> Aquarium  (+1 Science to reef tiles; requirement-widening)
--
-- AQUARIUM_REEF_SCIENCE is the same shape as the Zoo: an on-tile plot yield gated
-- by AQUARIUM_REEF_REQUIREMENTS (TEST_ALL, single member). Flip to TEST_ANY and add
-- the reef wonder. NOT widening the Campus reef adjacency (+2 Science): TM already
-- grants every district a standard adjacency from every natural wonder, so the
-- Barrier Reef is covered there; adding the base reef +2 on top would double up.
-----------------------------------------------

INSERT OR IGNORE INTO Requirements
		(RequirementId,							RequirementType						)
SELECT	'REQ_TM_PLOT_HAS_' || W.FeatureType,	'REQUIREMENT_PLOT_FEATURE_TYPE_MATCHES'
FROM	TM_WonderTypes W
JOIN	Features F ON F.FeatureType = W.FeatureType
WHERE	W.WonderClass = 'REEF';

INSERT OR IGNORE INTO RequirementArguments
		(RequirementId,							Name,			Value			)
SELECT	'REQ_TM_PLOT_HAS_' || W.FeatureType,	'FeatureType',	W.FeatureType
FROM	TM_WonderTypes W
JOIN	Features F ON F.FeatureType = W.FeatureType
WHERE	W.WonderClass = 'REEF';

UPDATE	RequirementSets
SET		RequirementSetType = 'REQUIREMENTSET_TEST_ANY'
WHERE	RequirementSetId = 'AQUARIUM_REEF_REQUIREMENTS';

INSERT OR IGNORE INTO RequirementSetRequirements
		(RequirementSetId,			RequirementId						)
SELECT	'AQUARIUM_REEF_REQUIREMENTS',	'REQ_TM_PLOT_HAS_' || W.FeatureType
FROM	TM_WonderTypes W
JOIN	Features F ON F.FeatureType = W.FeatureType
WHERE	W.WonderClass = 'REEF'
AND		EXISTS (SELECT 1 FROM RequirementSets WHERE RequirementSetId = 'AQUARIUM_REEF_REQUIREMENTS');

-----------------------------------------------
-- (D) GEOTHERMAL -> Fire Goddess (+2 Faith, on-tile) and Thermal Bath (+3 Tourism,
--     +2 Amenities to a city with one in its borders). Both requirement-widening;
--     neither is district adjacency, so no double-dip with TM's universal NW adjacency.
--
-- Fire Goddess' PLOT_HAS_GODDES_FIRE_REQUIREMENTS is already TEST_ANY (fissure OR
-- volcanic soil) -- just add ours. Thermal Bath's city set is TEST_ALL single-member
-- -- flip to TEST_ANY, then add per-wonder "city has >=1 <wonder>" requirements.
-- (Pamukkale is impassable so Fire Goddess is moot for it, but it still counts for
--  Thermal Bath's city-borders check.)
-----------------------------------------------

-- (i) per-wonder PLOT requirement -> Fire Goddess (on-tile Faith)
INSERT OR IGNORE INTO Requirements
		(RequirementId,							RequirementType						)
SELECT	'REQ_TM_PLOT_HAS_' || W.FeatureType,	'REQUIREMENT_PLOT_FEATURE_TYPE_MATCHES'
FROM	TM_WonderTypes W JOIN Features F ON F.FeatureType = W.FeatureType
WHERE	W.WonderClass = 'GEOTHERMAL';

INSERT OR IGNORE INTO RequirementArguments
		(RequirementId,							Name,			Value			)
SELECT	'REQ_TM_PLOT_HAS_' || W.FeatureType,	'FeatureType',	W.FeatureType
FROM	TM_WonderTypes W JOIN Features F ON F.FeatureType = W.FeatureType
WHERE	W.WonderClass = 'GEOTHERMAL';

INSERT OR IGNORE INTO RequirementSetRequirements
		(RequirementSetId,					RequirementId						)
SELECT	'PLOT_HAS_GODDES_FIRE_REQUIREMENTS',	'REQ_TM_PLOT_HAS_' || W.FeatureType
FROM	TM_WonderTypes W JOIN Features F ON F.FeatureType = W.FeatureType
WHERE	W.WonderClass = 'GEOTHERMAL'
AND		EXISTS (SELECT 1 FROM RequirementSets WHERE RequirementSetId = 'PLOT_HAS_GODDES_FIRE_REQUIREMENTS');

-- (ii) per-wonder CITY requirement -> Thermal Bath (city has >=1 in borders)
INSERT OR IGNORE INTO Requirements
		(RequirementId,							RequirementType				)
SELECT	'REQ_TM_CITY_HAS_' || W.FeatureType,	'REQUIREMENT_CITY_HAS_X_FEATURE_TYPE'
FROM	TM_WonderTypes W JOIN Features F ON F.FeatureType = W.FeatureType
WHERE	W.WonderClass = 'GEOTHERMAL';

INSERT OR IGNORE INTO RequirementArguments
		(RequirementId,							Name,			Value			)
SELECT	'REQ_TM_CITY_HAS_' || W.FeatureType,	'FeatureType',	W.FeatureType
FROM	TM_WonderTypes W JOIN Features F ON F.FeatureType = W.FeatureType
WHERE	W.WonderClass = 'GEOTHERMAL';

INSERT OR IGNORE INTO RequirementArguments
		(RequirementId,							Name,		Value	)
SELECT	'REQ_TM_CITY_HAS_' || W.FeatureType,	'Amount',	'1'
FROM	TM_WonderTypes W JOIN Features F ON F.FeatureType = W.FeatureType
WHERE	W.WonderClass = 'GEOTHERMAL';

UPDATE	RequirementSets
SET		RequirementSetType = 'REQUIREMENTSET_TEST_ANY'
WHERE	RequirementSetId = 'CITY_HAS_1_OR_MORE_GEOTHERMALFISSURE_REQUIREMENTS';

INSERT OR IGNORE INTO RequirementSetRequirements
		(RequirementSetId,									RequirementId						)
SELECT	'CITY_HAS_1_OR_MORE_GEOTHERMALFISSURE_REQUIREMENTS',	'REQ_TM_CITY_HAS_' || W.FeatureType
FROM	TM_WonderTypes W JOIN Features F ON F.FeatureType = W.FeatureType
WHERE	W.WonderClass = 'GEOTHERMAL'
AND		EXISTS (SELECT 1 FROM RequirementSets WHERE RequirementSetId = 'CITY_HAS_1_OR_MORE_GEOTHERMALFISSURE_REQUIREMENTS');

-----------------------------------------------
-- (E) LAKE -> Huey Teocalli extra Food/Production on lake tiles (requirement-widening)
--
-- Huey Teocalli boosts tiles passing REQUIRES_PLOT_IS_LAKE (engine IsLake -- a gen-time
-- water classification we cannot change). But that check sits in TEST_ALL single-member
-- sets, so we flip them to TEST_ANY and add the lake wonders by feature. This makes
-- Huey's Food/Production boost apply to their tiles WITHOUT changing IsLake.
-- Scope: yield boost only -- the +Amenity-per-adjacent-lake is intentionally not touched.
-----------------------------------------------

INSERT OR IGNORE INTO Requirements
		(RequirementId,							RequirementType						)
SELECT	'REQ_TM_PLOT_HAS_' || W.FeatureType,	'REQUIREMENT_PLOT_FEATURE_TYPE_MATCHES'
FROM	TM_WonderTypes W JOIN Features F ON F.FeatureType = W.FeatureType
WHERE	W.WonderClass = 'LAKE';

INSERT OR IGNORE INTO RequirementArguments
		(RequirementId,							Name,			Value			)
SELECT	'REQ_TM_PLOT_HAS_' || W.FeatureType,	'FeatureType',	W.FeatureType
FROM	TM_WonderTypes W JOIN Features F ON F.FeatureType = W.FeatureType
WHERE	W.WonderClass = 'LAKE';

-- Huey FOOD lake set (TEST_ALL single member -> TEST_ANY, then add ours)
UPDATE	RequirementSets
SET		RequirementSetType = 'REQUIREMENTSET_TEST_ANY'
WHERE	RequirementSetId = 'FOODHUEY_PLOT_IS_LAKE_REQUIREMENTS';

INSERT OR IGNORE INTO RequirementSetRequirements
		(RequirementSetId,						RequirementId						)
SELECT	'FOODHUEY_PLOT_IS_LAKE_REQUIREMENTS',	'REQ_TM_PLOT_HAS_' || W.FeatureType
FROM	TM_WonderTypes W JOIN Features F ON F.FeatureType = W.FeatureType
WHERE	W.WonderClass = 'LAKE'
AND		EXISTS (SELECT 1 FROM RequirementSets WHERE RequirementSetId = 'FOODHUEY_PLOT_IS_LAKE_REQUIREMENTS');

-- Huey PRODUCTION lake set (same treatment)
UPDATE	RequirementSets
SET		RequirementSetType = 'REQUIREMENTSET_TEST_ANY'
WHERE	RequirementSetId = 'PRODUCTIONHUEY_PLOT_IS_LAKE_REQUIREMENTS';

INSERT OR IGNORE INTO RequirementSetRequirements
		(RequirementSetId,							RequirementId						)
SELECT	'PRODUCTIONHUEY_PLOT_IS_LAKE_REQUIREMENTS',	'REQ_TM_PLOT_HAS_' || W.FeatureType
FROM	TM_WonderTypes W JOIN Features F ON F.FeatureType = W.FeatureType
WHERE	W.WonderClass = 'LAKE'
AND		EXISTS (SELECT 1 FROM RequirementSets WHERE RequirementSetId = 'PRODUCTIONHUEY_PLOT_IS_LAKE_REQUIREMENTS');
