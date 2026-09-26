-- ZoneLevelsForever: zone data, label text, events and slash commands.
-- Everything drawn on the world map is in MapUI.lua.
local addonName, ns = ...

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

-- All labels on continent maps, or only on hover. Your saved choice (map button,
-- options panel, /zonelevels toggle), else the default from Config.lua.
local function ShowAllContinentLabels()
    local saved = ZoneLevelsForeverDB and ZoneLevelsForeverDB.showContinentLabels
    if saved == nil then
        return config.showContinentLabels == true
    end
    return saved
end

-- Settings that can be changed in game. Config.lua has the defaults; changes
-- from the settings window, options panel or /zonelevels are saved in
-- ZoneLevelsForeverDB and override them.
local SAVED_KEYS = { "continentLabelSize", "zoneLabelSize", "zoneLabelLeftToRight", "zoneLabelTopToBottom" }
ns.MIN_SCALE, ns.MAX_SCALE = MIN_SCALE, MAX_SCALE

-- The values from Config.lua, kept before saved settings override them.
ns.Defaults = { showContinentLabels = config.showContinentLabels == true }
for _, key in ipairs(SAVED_KEYS) do
    ns.Defaults[key] = config[key]
end

function ns.SetSetting(key, value)
    config[key] = value
    ZoneLevelsForeverDB[key] = value
    ns.RefreshMap()
    ns.UpdateSettingsWindow()
    return value
end

function ns.SetLabelScale(key, scale)
    return ns.SetSetting(key, Clamp(scale, MIN_SCALE, MAX_SCALE))
end

-- Forgets every saved setting, so the values from Config.lua apply again.
function ns.ResetSettings()
    ZoneLevelsForeverDB.showContinentLabels = nil
    for _, key in ipairs(SAVED_KEYS) do
        ZoneLevelsForeverDB[key] = nil
        config[key] = ns.Defaults[key]
    end
    ns.UpdateToggleButton()
    ns.RefreshMap()
    ns.UpdateSettingsWindow()
end

-- Shared with MapUI.lua and Options.lua.
ns.GetZone = GetZone
ns.FormatLabel = FormatLabel
ns.ShowAllContinentLabels = ShowAllContinentLabels

-- Events ----------------------------------------------------------------------
local frame = CreateFrame("Frame")
local handlers = {}

function handlers.ADDON_LOADED(name)
    if name ~= addonName then return end
    ZoneLevelsForeverDB = ZoneLevelsForeverDB or {}
    for _, key in ipairs(SAVED_KEYS) do
        config[key] = ZoneLevelsForeverDB[key] or config[key]
    end
    -- Settings saved under the names used before version 1.2.0.
    for _, oldKey in ipairs({ "continentScale", "zoneScale", "zoneLabelX", "zoneLabelY" }) do
        ZoneLevelsForeverDB[oldKey] = nil
    end
    frame:UnregisterEvent("ADDON_LOADED")
    ns.UpdateToggleButton()
end

function handlers.PLAYER_LEVEL_UP(level)
    playerLevel = level -- UnitLevel still returns the old level during this event
    ns.RefreshMap()
end

function handlers.PLAYER_ENTERING_WORLD()
    playerLevel = UnitLevel("player")
    ns.RefreshMap()
end

frame:SetScript("OnEvent", function(_, event, ...) handlers[event](...) end)
frame:RegisterEvent("ADDON_LOADED")
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
local SCALE_KEYS = { continent = "continentLabelSize", zone = "zoneLabelSize" }

local function SetScale(arg)
    local which, value = arg:match("^(%a+)%s*(%S*)$")
    local key = SCALE_KEYS[which]
    local scale = tonumber(value)
    if not (key and scale) then
        print(("%s: continent %.2f, zone %.2f. Use /zonelevels scale continent|zone <%.1f-%d>."):format(
            addonName, config.continentLabelSize, config.zoneLabelSize, MIN_SCALE, MAX_SCALE))
        return
    end
    print(("%s: %s scale set to %.2f."):format(addonName, which, ns.SetLabelScale(key, scale)))
end

SlashCmdList.ZONELEVELSFOREVER = function(msg)
    local command, arg = msg:match("^(%S*)%s*(.-)$")
    if command == "check" then
        PrintUnmatched()
    elseif command == "toggle" then
        ns.ToggleContinentLabels()
    elseif command == "scale" then
        SetScale(arg)
    elseif command == "options" then
        ns.ToggleSettingsWindow()
    elseif command == "reset" then
        ns.ResetSettings()
        print(addonName .. ": settings reset to the values in Config.lua.")
    elseif command == "horde" or command == "alliance" then
        PrintGuide(command == "horde" and "Horde" or "Alliance")
    else
        PrintGuide()
    end
end
