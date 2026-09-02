/*
	Matterhorn
	Authors: ChimpanG, Deliverator
*/

-----------------------------------------------
-- Effects for Natural Wonders
-- Effect: Units ignore Movement penalties on Hills for any Civilization that owns this tile.
--
-- The movement effect is delivered as a granted UnitAbility (not a raw player-
-- unit modifier) so that it is VISIBLE on the unit, like Giant's Causeway. The
-- ability is:
--   * shown when granted -> UnitAbilities.Inactive = 1 (NOT innate). Inactive=0 makes
--                       the ability innate to every CLASS_ALL_UNITS unit (i.e. everyone,
--                       always); a granted Inactive=1 ability still displays on the unit
--                       (cf. Giant's Causeway / ABILITY_SPEAR_OF_FIONN).
--   * revocable      -> UnitAbilities.Permanent = 0, so losing Matterhorn removes
--                       it from all your units (the ALL_PLAYERS_ATTACH is gated by
--                       REQSET_TM_PLAYER_HAS_FEATURE_MATTERHORN)
--   * all units      -> TypeTag CLASS_ALL_UNITS (preserves prior scope)
-- The ability carries the base-game MODIFIER_PLAYER_UNIT_ADJUST_IGNORE_TERRAIN_COST
-- (Ignore='true' -- must be the boolean, not integer 1; Type='HILLS'), mirroring
-- base-game ALPINE_IGNORE_HILLS_MOVEMENT_PENALTY / MOD_IGNORE_TERRAIN_COST.
-- Pattern mirrors TM_FountainOfYouth.sql. (Fixes I7; adds visibility.)
-----------------------------------------------

UPDATE	Features
SET		Description = 'LOC_TM_FEATURE_MATTERHORN_DESCRIPTION'
WHERE	FeatureType = 'FEATURE_MATTERHORN';

	UPDATE	Features
	SET		Description = 'LOC_TM_FEATURE_MATTERHORN_EFFECT_DESCRIPTION'
	WHERE	FeatureType = 'FEATURE_MATTERHORN'
	AND EXISTS (SELECT * FROM TM_UserSettings WHERE Setting = 'NW_EFFECTS' AND Value = 1);

	INSERT INTO GameModifiers (ModifierId)
	SELECT	'MODIFIER_TM_FEATURE_MATTERHORN_ATTACH_PLAYERS'
	WHERE EXISTS (SELECT * FROM Features WHERE FeatureType = 'FEATURE_MATTERHORN')
	AND EXISTS (SELECT * FROM TM_UserSettings WHERE Setting = 'NW_EFFECTS' AND Value = 1);

	-- Original Effect
	DELETE FROM GameModifiers
	WHERE ModifierId IN ('MATTERHORN_ADJACENT_UNITS_GRANT_ABILITY')
	AND EXISTS (SELECT * FROM TM_UserSettings WHERE Setting = 'NW_EFFECTS' AND Value = 1);

	UPDATE	Features
	SET		Description = 'LOC_TM_FEATURE_MATTERHORN_ORIGINAL_EFFECT_DESCRIPTION'
	WHERE	FeatureType = 'FEATURE_MATTERHORN'
	AND EXISTS (SELECT * FROM TM_UserSettings WHERE Setting = 'NW_EFFECTS' AND Value = 0);

-----------------------------------------------
-- Types
-----------------------------------------------

INSERT INTO Types
		(Type,								Kind			)
VALUES	('ABILITY_TM_FEATURE_MATTERHORN',	'KIND_ABILITY'	);

-----------------------------------------------
-- Tags
-----------------------------------------------

INSERT INTO Tags
		(Tag,								Vocabulary		)
VALUES	('ABILITY_TM_FEATURE_MATTERHORN',	'ABILITY_CLASS'	);

-----------------------------------------------
-- TypeTags
-----------------------------------------------

INSERT INTO TypeTags
		(Type,								Tag					)
VALUES	('ABILITY_TM_FEATURE_MATTERHORN',	'CLASS_ALL_UNITS'	);

-----------------------------------------------
-- UnitAbilities
-----------------------------------------------

INSERT INTO UnitAbilities
		(UnitAbilityType,					Name,										Description,										Inactive,	ShowFloatTextWhenEarned,	Permanent	)
VALUES	('ABILITY_TM_FEATURE_MATTERHORN',	'LOC_ABILITY_TM_FEATURE_MATTERHORN_NAME',	'LOC_ABILITY_TM_FEATURE_MATTERHORN_DESCRIPTION',	1,			0,							0			);

-----------------------------------------------
-- UnitAbilityModifiers
-----------------------------------------------

INSERT INTO UnitAbilityModifiers
		(UnitAbilityType,					ModifierId									)
VALUES	('ABILITY_TM_FEATURE_MATTERHORN',	'MODIFIER_TM_FEATURE_MATTERHORN_MOVEMENT'	);

-----------------------------------------------
-- Modifiers
-----------------------------------------------

INSERT INTO Modifiers (ModifierId, ModifierType, OwnerRequirementSetId, SubjectRequirementSetId)
SELECT	'MODIFIER_TM_FEATURE_MATTERHORN_ATTACH_PLAYERS',
		'MODIFIER_ALL_PLAYERS_ATTACH_MODIFIER',
		'REQSET_TM_MAP_HAS_FEATURE_MATTERHORN',
		'REQSET_TM_PLAYER_HAS_FEATURE_MATTERHORN'
WHERE EXISTS (SELECT * FROM Features WHERE FeatureType = 'FEATURE_MATTERHORN');

INSERT INTO Modifiers
		(ModifierId,										ModifierType,											SubjectRequirementSetId	)
VALUES	('MODIFIER_TM_FEATURE_MATTERHORN_GRANT_ABILITY',	'MODIFIER_PLAYER_UNITS_GRANT_ABILITY',					'UNIT_IS_DOMAIN_LAND'					),
		('MODIFIER_TM_FEATURE_MATTERHORN_MOVEMENT',			'MODIFIER_PLAYER_UNIT_ADJUST_IGNORE_TERRAIN_COST',		NULL					);

-----------------------------------------------
-- ModifierArguments
-----------------------------------------------

INSERT INTO ModifierArguments (ModifierId, Name, Value)
SELECT	'MODIFIER_TM_FEATURE_MATTERHORN_ATTACH_PLAYERS',
		'ModifierId',
		'MODIFIER_TM_FEATURE_MATTERHORN_GRANT_ABILITY'
WHERE EXISTS (SELECT * FROM Features WHERE FeatureType = 'FEATURE_MATTERHORN');

INSERT INTO ModifierArguments
		(ModifierId,										Name,			Value							)
VALUES	('MODIFIER_TM_FEATURE_MATTERHORN_GRANT_ABILITY',	'AbilityType',	'ABILITY_TM_FEATURE_MATTERHORN'	),
		('MODIFIER_TM_FEATURE_MATTERHORN_MOVEMENT',		'Ignore',		'true'							),
		('MODIFIER_TM_FEATURE_MATTERHORN_MOVEMENT',		'Type',			'HILLS'							);
