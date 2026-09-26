-- ZoneLevelsForever settings. Edit the values below and /reload.
-- To try sizes live first, use /zonelevels scale continent <n> and
-- /zonelevels scale zone <n>; those last until /reload, then copy the
-- values you like into this file.
local _, ns = ...

ns.Config = {
    -- Label size on the world/continent map. 1.0 = normal UI font size.
    continentScale = 1.0,

    -- Label size on a zone's own map (zoomed in).
    zoneScale = 2.0,

    -- Position of the label on a zone's own map, as a fraction of the map:
    -- x: 0 = left edge, 0.5 = middle, 1 = right edge
    -- y: 0 = top edge,  0.5 = middle, 1 = bottom edge
    zoneLabelX = 0.5,
    zoneLabelY = 0.02,

    -- Which part of the label sits at that position, e.g. "TOP" (top centre),
    -- "TOPLEFT", "TOPRIGHT", "CENTER", "BOTTOM", "BOTTOMLEFT", "BOTTOMRIGHT".
    -- "TOP" with y = 0.02 keeps the whole label inside the map's top edge;
    -- "TOPLEFT" with x = 0.02 puts it in the top-left corner.
    zoneLabelAnchor = "TOP",

    -- Colours as "RRGGBB" hex (like in an image editor).
    colors = {
        zoneName = "FFD100",  -- zone name (Blizzard's gold)
        alliance = "3F8CFF",  -- "Alliance dominated" line on zone maps
        horde = "FF2626",     -- "Horde dominated" line on zone maps

        -- Level range. false = colour by difficulty for your level
        -- (grey/green/yellow/orange/red), or a hex string for one fixed colour.
        levelRange = false,
    },
}
