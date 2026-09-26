-- ZoneLevelsForever settings. Edit the values below and /reload.
--
-- The first five are the defaults for the settings window and
-- Options -> AddOns -> ZoneLevelsForever. The comment above each one is the
-- name it has there. Changing a setting in the game saves your own value,
-- which wins over this file until you press "Reset to defaults".
local _, ns = ...

ns.Config = {
    -- "Show labels on continent maps"
    -- true = always shown, false = only while you hover a zone.
    showContinentLabels = false,

    -- "Label size on continent maps"
    -- 0.5-5, where 1.0 = normal UI font size.
    continentLabelSize = 1.5,

    -- "Label size on zone maps"
    -- 0.5-5, where 1.0 = normal UI font size.
    zoneLabelSize = 2.0,

    -- "Zone map label position, left to right"
    -- 0-100 %: 0 = left edge, 50 = middle, 100 = right edge.
    zoneLabelLeftToRight = 50,

    -- "Zone map label position, top to bottom"
    -- 0-100 %: 0 = top edge, 50 = middle, 100 = bottom edge.
    zoneLabelTopToBottom = 0,

    -- The settings below are only in this file.

    -- Which part of the zone map label sits at the position above, e.g. "TOP"
    -- (top centre), "TOPLEFT", "TOPRIGHT", "CENTER", "BOTTOM", "BOTTOMLEFT",
    -- "BOTTOMRIGHT".
    -- "TOP" with top to bottom = 0 keeps the whole label inside the map's top
    -- edge; "TOPLEFT" with left to right = 2 puts it in the top-left corner.
    zoneLabelAnchor = "TOP",

    -- Colours as "RRGGBB" hex (like in an image editor).
    colors = {
        zoneName = "FFD100",  -- zone name (Blizzard's gold)
        alliance = "3F8CFF",  -- "Alliance dominated" line on zone maps
        horde = "FF2626",     -- "Horde dominated" line on zone maps
        neutral = "68CCF0",   -- "Neutral" line on zone maps (sanctuary blue)

        -- Level range. false = colour by difficulty for your level
        -- (grey/green/yellow/orange/red), or a hex string for one fixed colour.
        levelRange = false,
    },
}
