# ZoneLevelsForever

World of Warcraft Forever addon that shows recommended level ranges for each zone on the world map.

## Features

- Labels on the continent maps (Kalimdor, Eastern Kingdoms), with each zone's name and level range in the middle of the zone.
- A label at the top of a zone's own map, with an extra line when the zone is Alliance dominated (blue) or Horde dominated (red).
- The level range is coloured by difficulty relative to your level (grey/green/yellow/orange/red), the same way Blizzard colours zone labels. It updates when you level up.
- Your own faction's levelling guide is used. Zones that are only in the other faction's guide (e.g. The Barrens for Alliance) use that faction's range, so every zone gets a label.
- A round map button in the top-right corner of the world map toggles the continent labels. When they're off, a zone's label only shows while you hover the zone.
- Labels stay the same size on screen at every map zoom level, with separate sizes for continent and zone maps.

![Continent map with zone labels](images/Map01.png)

![Zone map with label](images/Map02.png)

Example label on the Swamp of Sorrows zone map:

```
Swamp of Sorrows
38-40
Horde dominated
```

## Installation

Copy the `ZoneLevelsForever` folder to the `Interface/AddOns/` folder of your WoW Forever client and restart the game.

## Commands

| Command                                      | Description                                                              |
| -------------------------------------------- | ------------------------------------------------------------------------ |
| `/zonelevels`                                | Print the levelling guide for your faction                               |
| `/zonelevels alliance` / `/zonelevels horde` | Print the guide for a specific faction                                   |
| `/zonelevels toggle`                         | Toggle the continent labels between always shown and shown on hover      |
| `/zonelevels scale`                          | Show the current label sizes                                             |
| `/zonelevels scale continent <0.5-5>`        | Try a label size on the continent maps (until `/reload`)                 |
| `/zonelevels scale zone <0.5-5>`             | Try a label size on zone maps (until `/reload`)                          |
| `/zonelevels check`                          | List zones in the guide that haven't been found on any map opened so far |

The map button setting is saved per account in `ZoneLevelsForeverDB`.

## Settings

Settings live in `Config.lua`. Edit them and `/reload`:

| Setting             | Default    | Description                                                                          |
| ------------------- | ---------- | ------------------------------------------------------------------------------------ |
| `continentScale`    | `1.0`      | Label size on the continent maps (1.0 = normal UI font size)                         |
| `zoneScale`         | `2.0`      | Label size on a zone's own map                                                       |
| `zoneLabelX`        | `0.5`      | Label position on a zone's own map (0 = left, 0.5 = middle, 1 = right)               |
| `zoneLabelY`        | `0.02`     | Label position on a zone's own map (0 = top, 0.5 = middle, 1 = bottom)               |
| `zoneLabelAnchor`   | `"TOP"`    | Which part of the label sits at that position, e.g. `"TOP"`, `"TOPLEFT"`, `"CENTER"` |
| `colors.zoneName`   | `"FFD100"` | Zone name colour                                                                     |
| `colors.alliance`   | `"3F8CFF"` | "Alliance dominated" colour                                                          |
| `colors.horde`      | `"FF2626"` | "Horde dominated" colour                                                             |
| `colors.levelRange` | `false`    | `false` = colour by difficulty, or a hex colour such as `"FFFFFF"`                   |

Colours are `"RRGGBB"` hex strings. To find a good label size, try values live with `/zonelevels scale continent <n>` or `/zonelevels scale zone <n>`, then copy the values you like into `Config.lua`.

## Customising the guide

Everything below lives in `Data.lua`.

**Level ranges** are one table per faction. Each row is a minimum level, a maximum level and the zones for that range:

```lua
{ 16, 20, { "Westfall", "Redridge Mountains", "Darkshore" } },
```

A zone's range on the map runs from the lowest to the highest level of every row the zone appears in.

**Zones added by WoW Forever** go in `ns.ExtraZones`, in the same row format, and apply to both factions:

```lua
{ 58, 60, { "Mount Hyjal" } },
```

**Faction territory** is set in `ns.Territory`. Zones not listed there are contested and get no extra line:

```lua
["Swamp of Sorrows"] = "Horde",
["Blasted Lands"] = "Alliance",
```

**Zone names** are matched by their English map names, so labels only show on an English client. Upper/lower case and a leading "The" are ignored. If the client uses a different name for a zone, add it to `ns.Aliases`:

```lua
["The Barrens"] = { "The Barrens", "Northern Barrens", "Southern Barrens" },
```

Open both continent maps and run `/zonelevels check` to find zone names that don't match.

## Files

| File               | Contents                                                                         |
| ------------------ | -------------------------------------------------------------------------------- |
| `Config.lua`       | Settings: label sizes, label position on zone maps and colours                   |
| `Data.lua`         | The levelling guide per faction, extra zones, name aliases and faction territory |
| `Core.lua`         | Zone lookup, label text, events and slash commands                               |
| `MapUI.lua`        | Everything drawn on the world map: labels, hover mode and the toggle button      |
| `Pin.xml`          | Template for the labels on the map                                               |
| `ToggleButton.xml` | Template for the round toggle button on the map                                  |

To change what's shown, edit `Config.lua` or `Data.lua` and `/reload`. The other files are code.
