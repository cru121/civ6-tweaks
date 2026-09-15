-- =====================================================================
--  TM_UbsunurHollow.lua
--  PROTOTYPE fix for ISSUES.md I16 (Ubsunur Hollow).
--
--  Intent: the civ that owns Ubsunur Hollow gets a free Inspiration
--  (civic boost) whenever it earns a Great General.
--
--  Why this exists: the data-driven effect (EFFECT_GRANT_BOOST_WITH_
--  GREAT_PERSON / MODTYPE_TM_GP_BOOST) is Eureka-only -- it has no
--  CivicBoost argument, so it can never grant an Inspiration. See I16.
--  There is no SQL path; granting a civic boost on a GP-earned trigger
--  is only reachable from a gameplay script via PlayerCulture:TriggerBoost.
--
--  STATUS: verified in-game (owner test). This is the mod's FIRST gameplay
--  script (only NaturalWonderGenerator.lua, a map script, existed before),
--  so it is intentionally self-contained and defensive.
--
--  API references (Sukritact Civ VI Modding Knowledge Base, master):
--    Events.UnitGreatPersonCreated(playerID, unitID, gpClassID, gpIndividualID)
--    PlayerCulture:TriggerBoost           (script-callable)
--    PlayerCulture:HasBoostBeenTriggered  (script-callable)
--    PlayerCulture:GetProgressingCivic    (script-callable)
-- =====================================================================

-- ---------------------------------------------------------------------
-- Config / cached lookups
-- ---------------------------------------------------------------------

local FEATURE_UBSUNUR = "FEATURE_UBSUNUR_HOLLOW"
local GP_CLASS_GENERAL = "GREAT_PERSON_CLASS_GENERAL"

local m_iUbsunurFeature   = nil   -- feature Index, resolved once
local m_iGeneralClass     = nil   -- great person class Index, resolved once
local m_iUbsunurPlot      = -1    -- cached plot index of the wonder (-1 = unknown/absent)
local m_bUbsunurSearched  = false -- have we scanned the map yet?
local m_tCivicHasBoost    = nil   -- set of civic Index -> true for civics that define a boost

-- ---------------------------------------------------------------------
-- Setting gate: honor NW_EFFECTS just like the SQL side does.
-- TM_UserSettings is loaded into the in-game DB (modinfo line ~144),
-- so GameInfo.TM_UserSettings is expected to be readable here.
-- Fail OPEN (enabled) if we cannot read it, since NW effects are the point.
-- ---------------------------------------------------------------------
local function AreNWEffectsEnabled()
    local ok, enabled = pcall(function()
        if GameInfo.TM_UserSettings == nil then return true end
        local row = GameInfo.TM_UserSettings["NW_EFFECTS"]
        if row == nil then return true end
        return tonumber(row.Value) == 1
    end)
    if not ok then return true end
    return enabled
end

-- ---------------------------------------------------------------------
-- Resolve GameInfo indices (nil-safe).
-- ---------------------------------------------------------------------
local function ResolveStatics()
    if GameInfo.Features[FEATURE_UBSUNUR] then
        m_iUbsunurFeature = GameInfo.Features[FEATURE_UBSUNUR].Index
    end
    if GameInfo.GreatPersonClasses[GP_CLASS_GENERAL] then
        m_iGeneralClass = GameInfo.GreatPersonClasses[GP_CLASS_GENERAL].Index
    end

    -- Build the set of civics that actually have a boost defined, so we
    -- never try to boost a civic that has no Inspiration.
    m_tCivicHasBoost = {}
    for row in GameInfo.Boosts() do
        if row.CivicType ~= nil then
            local civic = GameInfo.Civics[row.CivicType]
            if civic ~= nil then
                m_tCivicHasBoost[civic.Index] = true
            end
        end
    end
end

-- ---------------------------------------------------------------------
-- Locate Ubsunur Hollow on the map (features never move, so cache it).
-- Returns the plot index or -1.
-- ---------------------------------------------------------------------
local function FindUbsunurPlot()
    if m_bUbsunurSearched then return m_iUbsunurPlot end
    m_bUbsunurSearched = true

    if m_iUbsunurFeature == nil then return -1 end

    local iCount = Map.GetPlotCount()
    for i = 0, iCount - 1 do
        local pPlot = Map.GetPlotByIndex(i)
        if pPlot ~= nil and pPlot:GetFeatureType() == m_iUbsunurFeature then
            m_iUbsunurPlot = i
            return i
        end
    end
    return -1
end

-- ---------------------------------------------------------------------
-- Grant one free Inspiration to a player.
-- Prefers the civic they are currently researching (most useful & least
-- surprising); otherwise the first eligible boostable civic.
--
-- PlayerCulture:TriggerBoost(iCivicIndex) triggers that civic's Inspiration.
-- (Confirmed in-game; the KB documents the method as script-callable but
-- lists no arguments, so the civic-index signature was verified by testing.)
-- ---------------------------------------------------------------------
local function GrantInspiration(playerID)
    local pPlayer = Players[playerID]
    if pPlayer == nil then return end
    local pCulture = pPlayer:GetCulture()
    if pCulture == nil then return end

    local function tryBoost(iCivic)
        if iCivic == nil or iCivic < 0 then return false end
        if not m_tCivicHasBoost[iCivic] then return false end
        if pCulture:HasBoostBeenTriggered(iCivic) then return false end
        local ok = pcall(function() pCulture:TriggerBoost(iCivic) end)
        return ok
    end

    -- 1) currently-progressing civic
    local iProgressing = pCulture:GetProgressingCivic()
    if tryBoost(iProgressing) then return end

    -- 2) fall back to the first eligible civic with an untriggered boost
    for row in GameInfo.Civics() do
        if tryBoost(row.Index) then return end
    end
end

-- ---------------------------------------------------------------------
-- Event handler: Great Person created (earned).
-- ---------------------------------------------------------------------
local function OnGreatPersonCreated(playerID, unitID, gpClassID, gpIndividualID)
    if m_iGeneralClass == nil or gpClassID ~= m_iGeneralClass then return end
    if playerID == nil or playerID < 0 then return end

    local iPlot = FindUbsunurPlot()
    if iPlot < 0 then return end   -- wonder not on this map

    local pPlot = Map.GetPlotByIndex(iPlot)
    if pPlot == nil then return end
    if pPlot:GetOwner() ~= playerID then return end  -- earner must own the wonder

    GrantInspiration(playerID)
end

-- ---------------------------------------------------------------------
-- Init
-- ---------------------------------------------------------------------
local function Initialize()
    if not AreNWEffectsEnabled() then
        return   -- respect NW_EFFECTS = 0, same as the SQL effect gate
    end

    ResolveStatics()
    if m_iUbsunurFeature == nil or m_iGeneralClass == nil then
        return   -- feature/class not present (e.g. XP1 not installed) -> nothing to do
    end

    if Events == nil or Events.UnitGreatPersonCreated == nil then
        return   -- event unavailable in this context
    end
    Events.UnitGreatPersonCreated.Add(OnGreatPersonCreated)
end

Initialize()
