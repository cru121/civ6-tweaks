/*
	Grand Mesa
	Authors: ChimpanG, Deliverator
*/

-----------------------------------------------
-- Effects for Natural Wonders
-- Effect: Units ignore [ICON_Movement] Movement penalties in Forest for any Civilization that owns this tile.
--
-- Delivered as a granted UnitAbility so the effect is VISIBLE on the unit (see
-- TM_Matterhorn.sql / TM_FountainOfYouth.sql for the same pattern): visible
-- (Inactive=0), revoked when the owner loses Grand Mesa (Permanent=0 + the
-- ALL_PLAYERS_ATTACH gated by REQSET_TM_PLAYER_HAS_FEATURE_GRAND_MESA), applies
-- to all units (CLASS_ALL_UNITS). The ability carries base-game
-- MODIFIER_PLAYER_UNIT_ADJUST_IGNORE_TERRAIN_COST (Ignore='true' -- boolean, not
-- integer 1; Type='FOREST'), mirroring RANGER_IGNORE_FOREST_MOVEMENT_PENALTY.
--
-- NOTE: still Forest only (Type=FOREST). The tile text says "Forest or Jungle";
-- Jungle is not yet covered -- tracked as a loose end in ISSUES.md (I11 notes).
-----------------------------------------------

	UPDATE	Features
	SET		Description = 'LOC_TM_FEATURE_GRAND_MESA_EFFECT_DESCRIPTION'
	WHERE	FeatureType = 'FEATURE_GRAND_MESA'
	AND EXISTS (SELECT * FROM TM_UserSettings WHERE Setting = 'NW_EFFECTS' AND Value = 1);

	INSERT INTO GameModifiers (ModifierId)
	SELECT	'MODIFIER_TM_FEATURE_GRAND_MESA_ATTACH_PLAYERS'
	WHERE EXISTS (SELECT * FROM TM_UserSettings WHERE Setting = 'NW_EFFECTS' AND Value = 1);

-----------------------------------------------
-- Types
-----------------------------------------------

INSERT INTO Types
		(Type,								Kind			)
VALUES	('ABILITY_TM_FEATURE_GRAND_MESA',	'KIND_ABILITY'	);

-----------------------------------------------
-- Tags
-----------------------------------------------

INSERT INTO Tags
		(Tag,								Vocabulary		)
VALUES	('ABILITY_TM_FEATURE_GRAND_MESA',	'ABILITY_CLASS'	);

-----------------------------------------------
-- TypeTags
-----------------------------------------------

INSERT INTO TypeTags
		(Type,								Tag					)
VALUES	('ABILITY_TM_FEATURE_GRAND_MESA',	'CLASS_ALL_UNITS'	);

-----------------------------------------------
-- UnitAbilities
-----------------------------------------------

INSERT INTO UnitAbilities
		(UnitAbilityType,					Name,										Description,										Inactive,	ShowFloatTextWhenEarned,	Permanent	)
VALUES	('ABILITY_TM_FEATURE_GRAND_MESA',	'LOC_ABILITY_TM_FEATURE_GRAND_MESA_NAME',	'LOC_ABILITY_TM_FEATURE_GRAND_MESA_DESCRIPTION',	1,			0,							0			);

-----------------------------------------------
-- UnitAbilityModifiers
-----------------------------------------------

INSERT INTO UnitAbilityModifiers
		(UnitAbilityType,					ModifierId										)
VALUES	('ABILITY_TM_FEATURE_GRAND_MESA',	'MODIFIER_TM_FEATURE_GRAND_MESA_IGNORE_FOREST'	);

-----------------------------------------------
-- Modifiers
-----------------------------------------------

INSERT INTO Modifiers
		(ModifierId,										ModifierType,											OwnerRequirementSetId,					SubjectRequirementSetId						)
VALUES	('MODIFIER_TM_FEATURE_GRAND_MESA_ATTACH_PLAYERS',	'MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER',					'REQSET_TM_MAP_HAS_FEATURE_GRAND_MESA',	'REQSET_TM_PLAYER_HAS_FEATURE_GRAND_MESA'	),
		('MODIFIER_TM_FEATURE_GRAND_MESA_GRANT_ABILITY',	'MODIFIER_PLAYER_UNITS_GRANT_ABILITY',					NULL,									'UNIT_IS_DOMAIN_LAND'										),
		('MODIFIER_TM_FEATURE_GRAND_MESA_IGNORE_FOREST',	'MODIFIER_PLAYER_UNIT_ADJUST_IGNORE_TERRAIN_COST',		NULL,									NULL										);

-----------------------------------------------
-- ModifierArguments
-----------------------------------------------

INSERT INTO ModifierArguments
		(ModifierId,										Name,			Value											)
VALUES	('MODIFIER_TM_FEATURE_GRAND_MESA_ATTACH_PLAYERS',	'ModifierId',	'MODIFIER_TM_FEATURE_GRAND_MESA_GRANT_ABILITY'	),
		('MODIFIER_TM_FEATURE_GRAND_MESA_GRANT_ABILITY',	'AbilityType',	'ABILITY_TM_FEATURE_GRAND_MESA'					),
		('MODIFIER_TM_FEATURE_GRAND_MESA_IGNORE_FOREST',	'Ignore',		'true'											),
		('MODIFIER_TM_FEATURE_GRAND_MESA_IGNORE_FOREST',	'Type',			'FOREST'										);
