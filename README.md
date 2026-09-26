# ZoneLevelsForever

World of Warcraft Forever addon that shows recommended level ranges for each zone on the world map.

## Features

- Labels on the continent maps (Kalimdor, Eastern Kingdoms), with each zone's name and level range in the middle of the zone.
- The same label at the top of a zone's own map.
- Ranges for both factions. Your own faction's range is coloured by difficulty relative to your level, the same way Blizzard colours zone labels. The other faction's range is shown in that faction's colour, so on a PvP server you can see what level the enemy players in the area are likely to be.
- Labels stay the same size on screen at every map zoom level, and you can change that size.

Example label for an Alliance character:

![alt text](images/Map01.png)

![alt text](images/Map02.png)

```
Ashenvale
22-30
Horde 25-30
```

## Installation

Copy the `ZoneLevelsForever` folder to the `Interface/AddOns/` folder of your WoW Forever client and restart the game.

## Commands

| Command                                      | Description                                                              |
| -------------------------------------------- | ------------------------------------------------------------------------ |
| `/zonelevels`                                | Print the levelling guide for your faction                               |
| `/zonelevels alliance` / `/zonelevels horde` | Print the guide for a specific faction                                   |
| `/zonelevels scale`                          | Show the current label size                                              |
| `/zonelevels scale <0.5-5>`                  | Set the label size (1.0 = normal UI font size, default 1.5)              |
| `/zonelevels scale reset`                    | Reset the label size to the default                                      |
| `/zonelevels check`                          | List zones in the guide that haven't been found on any map opened so far |

The label size is saved per account in `ZoneLevelsForeverDB`.

## Customising the guide

The level ranges live in `Data.lua`, one table per faction:

```lua
{ 16, 20, { "Westfall", "Redridge Mountains", "Darkshore" } },
```

A zone's range on the map runs from the lowest to the highest level of every row the zone appears in.

Zones are matched by their **English** map names, so labels only show on an English client. If the client uses a different name for a zone, add it to `ns.Aliases` in `Data.lua`:

```lua
["The Barrens"] = { "The Barrens", "Northern Barrens", "Southern Barrens" },
```

Open both continent maps and run `/zonelevels check` to find zone names that don't match.
