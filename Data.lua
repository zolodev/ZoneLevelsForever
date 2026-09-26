-- Levelling guide per faction. Each row: minLevel, maxLevel, zones.
-- Zone names must match the English map names used by the client.
local _, ns = ...

local ALLIANCE_START = { "Elwynn Forest", "Dun Morogh", "Teldrassil" }
local HORDE_START = { "Durotar", "Mulgore", "Tirisfal Glades" }

ns.Guide = {
    Alliance = {
        { 1, 6,   ALLIANCE_START },
        { 6, 10,  ALLIANCE_START, note = "Same starting zone" },
        { 10, 12, { "Westfall", "Loch Modan", "Darkshore" } },
        { 12, 16, { "Westfall", "Loch Modan", "Darkshore" } },
        { 16, 20, { "Westfall", "Redridge Mountains", "Darkshore" }, note = "Westfall, then Redridge" },
        { 20, 22, { "Redridge Mountains", "Duskwood", "Wetlands" } },
        { 22, 25, { "Duskwood", "Wetlands", "Ashenvale" } },
        { 25, 30, { "Duskwood", "Wetlands", "Ashenvale" } },
        { 30, 32, { "Wetlands", "Arathi Highlands" }, note = "Wetlands, then Arathi Highlands" },
        { 32, 35, { "Stranglethorn Vale", "Arathi Highlands" } },
        { 35, 38, { "Stranglethorn Vale", "Desolace", "Alterac Mountains", "Dustwallow Marsh" } },
        { 38, 40, { "Badlands", "Swamp of Sorrows", "Stranglethorn Vale", "Dustwallow Marsh" } },
        { 40, 42, { "Stranglethorn Vale", "Arathi Highlands", "Badlands", "Dustwallow Marsh" } },
        { 42, 45, { "Tanaris", "Feralas", "Stranglethorn Vale", "Dustwallow Marsh" } },
        { 45, 48, { "Feralas", "The Hinterlands", "Tanaris", "Azshara" } },
        { 48, 50, { "Tanaris", "Blasted Lands", "Searing Gorge", "Azshara" } },
        { 50, 52, { "Searing Gorge", "Un'Goro Crater", "Azshara" } },
        { 52, 54, { "Un'Goro Crater", "Felwood", "Azshara" } },
        { 54, 56, { "Felwood", "Winterspring", "Burning Steppes" } },
        { 56, 57, { "Western Plaguelands", "Burning Steppes" } },
        { 57, 60, { "Eastern Plaguelands", "Western Plaguelands", "Winterspring" } },
    },
    Horde = {
        { 1, 6,   HORDE_START },
        { 6, 10,  HORDE_START, note = "Same starting zone" },
        { 10, 12, { "The Barrens", "Silverpine Forest" } },
        { 12, 16, { "The Barrens", "Silverpine Forest" } },
        { 16, 20, { "The Barrens", "Stonetalon Mountains" } },
        { 20, 25, { "The Barrens", "Hillsbrad Foothills" }, note = "The Barrens, then Hillsbrad Foothills" },
        { 25, 30, { "Thousand Needles", "Hillsbrad Foothills", "Ashenvale" } },
        { 30, 32, { "Thousand Needles", "Desolace" } },
        { 32, 35, { "Stranglethorn Vale", "Desolace" } },
        { 35, 38, { "Stranglethorn Vale", "Arathi Highlands", "Dustwallow Marsh" } },
        { 38, 40, { "Badlands", "Swamp of Sorrows", "Stranglethorn Vale", "Dustwallow Marsh" } },
        { 40, 42, { "Stranglethorn Vale", "Tanaris", "Dustwallow Marsh" } },
        { 42, 45, { "Tanaris", "Feralas", "Dustwallow Marsh" } },
        { 45, 48, { "Feralas", "The Hinterlands", "Azshara" } },
        { 48, 50, { "Tanaris", "Searing Gorge", "Blasted Lands", "Azshara" } },
        { 50, 52, { "Un'Goro Crater", "Felwood", "Azshara" } },
        { 52, 54, { "Felwood", "Burning Steppes", "Azshara" } },
        { 54, 56, { "Western Plaguelands", "Winterspring" } },
        { 56, 58, { "Eastern Plaguelands", "Burning Steppes" } },
        { 58, 60, { "Eastern Plaguelands", "Winterspring", "Silithus" } },
    },
}

-- Guide name -> map names, for zones the client may split or rename.
ns.Aliases = {
    ["The Barrens"] = { "The Barrens", "Northern Barrens", "Southern Barrens" },
    ["Stranglethorn Vale"] = { "Stranglethorn Vale", "Northern Stranglethorn", "The Cape of Stranglethorn" },
}

-- Zones added by WoW Forever, same for both factions. Each row: minLevel, maxLevel, zones.
ns.ExtraZones = {
    -- Kalimdor
    { 58, 60, { "Mount Hyjal" } },

    -- Eastern Kingdoms
    { 36, 44, { "Riverglades" } },
}

-- Which faction dominates a zone, shown as an extra line on the zone's own map.
-- Zones not listed are contested and get no line.
ns.Territory = {
    -- Kalimdor: Alliance
    ["Teldrassil"] = "Alliance",
    ["Darkshore"] = "Alliance",
    ["Dustwallow Marsh"] = "Alliance",

    -- Kalimdor: Horde
    ["Durotar"] = "Horde",
    ["Mulgore"] = "Horde",
    ["The Barrens"] = "Horde",
    ["Stonetalon Mountains"] = "Horde",
    ["Thousand Needles"] = "Horde",
    ["Azshara"] = "Horde",

    -- Eastern Kingdoms: Alliance
    ["Elwynn Forest"] = "Alliance",
    ["Dun Morogh"] = "Alliance",
    ["Westfall"] = "Alliance",
    ["Loch Modan"] = "Alliance",
    ["Redridge Mountains"] = "Alliance",
    ["Duskwood"] = "Alliance",
    ["Wetlands"] = "Alliance",
    ["Blasted Lands"] = "Alliance",

    -- Eastern Kingdoms: Horde
    ["Tirisfal Glades"] = "Horde",
    ["Silverpine Forest"] = "Horde",
    ["Swamp of Sorrows"] = "Horde",
    ["Badlands"] = "Horde",
}
