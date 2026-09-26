-- ZoneLevelsForever: writes recommended level ranges on the world map.
local addonName, ns = ...

local PIN_TEMPLATE = "ZoneLevelsForeverPinTemplate"
local MIN_SCALE, MAX_SCALE = 0.5, 5 -- limits for /zonelevels scale
local config = ns.Config -- user settings, see Config.lua

-- Data ------------------------------------------------------------------------
local function GetFaction()
    return UnitFactionGroup("player") == "Horde" and "Horde" or "Alliance"
end

local function GetOtherFaction()
    return GetFaction() == "Horde" and "Alliance" or "Horde"
end

-- zone name -> { min, max }, merged from every row the zone appears in.
local function AddRows(ranges, rows)
    for _, row in ipairs(rows) do
        local minLevel, maxLevel, zones = row[1], row[2], row[3]
        for _, zone in ipairs(zones) do
            local range = ranges[zone]
            if range then
                range.min = math.min(range.min, minLevel)
                range.max = math.max(range.max, maxLevel)
            else
                ranges[zone] = { min = minLevel, max = maxLevel }
            end
        end
    end
end

local rangesByFaction = {}
for faction, rows in pairs(ns.Guide) do
    local ranges = {}
    AddRows(ranges, rows)
    AddRows(ranges, ns.ExtraZones)
    rangesByFaction[faction] = ranges
end

-- Matching key for a zone name: lower case, without a leading "the ",
-- so "The Badlands" and "Badlands" match each other.
local function NameKey(name)
    return (name:lower():gsub("^the%s+", ""))
end

-- name key -> guide zone name
local guideZoneByMapName = {}
for _, ranges in pairs(rangesByFaction) do
    for zone in pairs(ranges) do
        for _, mapName in ipairs(ns.Aliases[zone] or { zone }) do
            guideZoneByMapName[NameKey(mapName)] = zone
        end
    end
end

local unmatchedMapNames = {} -- zones on the maps with no guide entry, for /zonelevels check

local seenZones = {} -- guide zones that have been matched to a map, for /zonelevels check

-- Returns the guide zone name and its level range. Uses your own faction's
-- range, or the other faction's for zones only in their guide (e.g. The Barrens).
local function GetZone(mapName)
    local zone = guideZoneByMapName[NameKey(mapName)]
    if not zone then
        unmatchedMapNames[mapName] = true
        return
    end
    local range = rangesByFaction[GetFaction()][zone] or rangesByFaction[GetOtherFaction()][zone]
    if range then seenZones[zone] = true end
    return zone, range
end

local playerLevel = UnitLevel("player")

local function Colorize(hex, text)
    return "|cff" .. hex .. text .. "|r"
end

-- Same colouring as Blizzard's own zone labels (AreaLabelDataProvider.lua).
local function GetDifficultyColorCode(range)
    local color
    if playerLevel < range.min then
        color = GetQuestDifficultyColor(range.min)
    elseif playerLevel > range.max then
        color = GetQuestDifficultyColor(range.max - 2)
    else
        color = QuestDifficultyColors["difficult"]
    end
    return RGBTableToColorCode(color)
end

local function FormatRange(range)
    local text = ("%d-%d"):format(range.min, range.max)
    local fixed = config.colors.levelRange
    if fixed then
        return Colorize(fixed, text)
    end
    return GetDifficultyColorCode(range) .. text .. "|r"
end

-- "Name" / "16-20", plus "Horde dominated" when showTerritory is set.
local function FormatLabel(name, zone, range, showTerritory)
    local colors = config.colors
    local lines = { Colorize(colors.zoneName, name), FormatRange(range) }
    local faction = showTerritory and ns.Territory[zone]
    if faction then
        table.insert(lines, Colorize(colors[faction:lower()], faction .. " dominated"))
    end
    return table.concat(lines, "\n")
end

-- Map pin ---------------------------------------------------------------------
-- Global because Pin.xml references it by name.
ZoneLevelsForeverPinMixin = CreateFromMixins(MapCanvasPinMixin)

function ZoneLevelsForeverPinMixin:OnLoad()
    self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI")
end

-- anchor: which point of the label sits on the pin position ("TOP", "TOPLEFT"...).
function ZoneLevelsForeverPinMixin:OnAcquired(text, x, y, scale, anchor)
    anchor = anchor or "CENTER"
    self.Label:ClearAllPoints()
    self.Label:SetPoint(anchor)
    self.Label:SetJustifyH(anchor:find("LEFT") and "LEFT" or anchor:find("RIGHT") and "RIGHT" or "CENTER")
    self.Label:SetText(text)
    -- Same start and end scale = constant size on screen at every zoom level.
    self:SetScalingLimits(1, scale, scale)
    self:SetPosition(x, y)
    self:ApplyCurrentScale()
end

-- Data provider ---------------------------------------------------------------
local provider = CreateFromMixins(MapCanvasDataProviderMixin)

function provider:RemoveAllData()
    self:GetMap():RemoveAllPinsByTemplate(PIN_TEMPLATE)
end

function provider:AddContinentPins(map, continentID)
    local zones = C_Map.GetMapChildrenInfo(continentID, Enum.UIMapType.Zone)
    if not zones then return end

    for _, zone in ipairs(zones) do
        local guideZone, range = GetZone(zone.name)
        if range then
            local minX, maxX, minY, maxY = C_Map.GetMapRectOnMap(zone.mapID, continentID)
            if minX then
                map:AcquirePin(PIN_TEMPLATE, FormatLabel(zone.name, guideZone, range, false),
                    (minX + maxX) / 2, (minY + maxY) / 2, config.continentScale)
            end
        end
    end
end

function provider:RefreshAllData()
    self:RemoveAllData()

    local map = self:GetMap()
    local mapID = map:GetMapID()
    local info = mapID and C_Map.GetMapInfo(mapID)
    if not info then return end

    if info.mapType == Enum.UIMapType.Continent then
        self:AddContinentPins(map, mapID)
    elseif info.mapType == Enum.UIMapType.Zone then
        local zone, range = GetZone(info.name)
        if range then
            map:AcquirePin(PIN_TEMPLATE, FormatLabel(info.name, zone, range, true),
                config.zoneLabelX, config.zoneLabelY, config.zoneScale, config.zoneLabelAnchor)
        end
    end
end

local function RefreshIfShown()
    if WorldMapFrame and WorldMapFrame:IsShown() then
        provider:RefreshAllData()
    end
end

EventUtil.ContinueOnAddOnLoaded("Blizzard_WorldMap", function()
    WorldMapFrame:AddDataProvider(provider)
end)

-- Events ----------------------------------------------------------------------
local frame = CreateFrame("Frame")
local handlers = {}

function handlers.PLAYER_LEVEL_UP(level)
    playerLevel = level -- UnitLevel still returns the old level during this event
    RefreshIfShown()
end

function handlers.PLAYER_ENTERING_WORLD()
    playerLevel = UnitLevel("player")
    RefreshIfShown()
end

frame:SetScript("OnEvent", function(_, event, ...) handlers[event](...) end)
frame:RegisterEvent("PLAYER_LEVEL_UP")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Slash command ---------------------------------------------------------------
local function PrintGuide(faction)
    faction = faction or GetFaction()
    print(("|cffffd100%s|r levelling guide (%s):"):format(addonName, faction))
    for _, row in ipairs(ns.Guide[faction]) do
        local text = row.note or table.concat(row[3], " / ")
        print(("  %d-%d  %s"):format(row[1], row[2], text))
    end
end

local function PrintUnmatched()
    local missing = {}
    for _, zone in pairs(guideZoneByMapName) do
        if not seenZones[zone] and not tContains(missing, zone) then
            table.insert(missing, zone)
        end
    end
    table.sort(missing)
    if #missing == 0 then
        print(addonName .. ": every guide zone has been found on the map.")
    else
        print(addonName .. ": not found on any map opened so far (open both continent maps first):")
        print("  " .. table.concat(missing, ", "))
    end

    local names = GetKeysArray(unmatchedMapNames)
    if #names > 0 then
        table.sort(names)
        print(addonName .. ": zones on the map without guide data (exact map names):")
        print("  " .. table.concat(names, ", "))
    end
end

SLASH_ZONELEVELSFOREVER1 = "/zonelevels"
-- Session-only size change, for finding a good value to put in Config.lua.
local SCALE_KEYS = { continent = "continentScale", zone = "zoneScale" }

local function SetScale(arg)
    local which, value = arg:match("^(%a+)%s*(%S*)$")
    local key = SCALE_KEYS[which]
    local scale = tonumber(value)
    if not (key and scale) then
        print(("%s: continent %.2f, zone %.2f. Use /zonelevels scale continent|zone <%.1f-%d>."):format(
            addonName, config.continentScale, config.zoneScale, MIN_SCALE, MAX_SCALE))
        return
    end
    config[key] = Clamp(scale, MIN_SCALE, MAX_SCALE)
    print(("%s: %s scale set to %.2f until /reload. Put it in Config.lua to keep it."):format(
        addonName, which, config[key]))
    RefreshIfShown()
end

SlashCmdList.ZONELEVELSFOREVER = function(msg)
    local command, arg = msg:match("^(%S*)%s*(.-)$")
    if command == "check" then
        PrintUnmatched()
    elseif command == "scale" then
        SetScale(arg)
    elseif command == "horde" or command == "alliance" then
        PrintGuide(command == "horde" and "Horde" or "Alliance")
    else
        PrintGuide()
    end
end
