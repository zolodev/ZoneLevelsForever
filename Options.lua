-- ZoneLevelsForever: settings panel under Options -> AddOns. Same settings as
-- the settings window (SettingsWindow.lua), which can stay open next to the map.
local addonName, ns = ...

local config, defaults = ns.Config, ns.Defaults
local category, layout = Settings.RegisterVerticalLayoutCategory(addonName)
local variables = {} -- setting variable names, to refresh the panel after a reset

local function AddButton(name, buttonText, onClick, tooltip)
    layout:AddInitializer(CreateSettingsButtonInitializer(name, buttonText, onClick, tooltip, true))
end

AddButton("Settings window", "Open", ns.ToggleSettingsWindow,
    "Opens a settings window that stays open when you close Options, so you can open the world map next to it and see changes live.")

-- Continent labels: always shown, or only on hover (same as the map button).
do
    local variable = "ZONELEVELSFOREVER_CONTINENT_LABELS"
    table.insert(variables, variable)
    local setting = Settings.RegisterProxySetting(category, variable,
        Settings.VarType.Boolean, "Show labels on continent maps", defaults.showContinentLabels,
        ns.ShowAllContinentLabels, ns.SetContinentLabels)
    Settings.CreateCheckbox(category, setting,
        "When off, a zone's label only shows while you hover the zone.")
end

local function AddSlider(key, name, minValue, maxValue, step, format, onChange, tooltip)
    local variable = "ZONELEVELSFOREVER_" .. key:upper()
    table.insert(variables, variable)
    local setting = Settings.RegisterProxySetting(category, variable,
        Settings.VarType.Number, name, defaults[key],
        function() return config[key] end,
        function(value) onChange(key, value) end)
    local options = Settings.CreateSliderOptions(minValue, maxValue, step)
    options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right, format)
    Settings.CreateSlider(category, setting, options, tooltip)
end

local function FormatOneDecimal(value) return ("%.1f"):format(value) end
local function FormatPercent(value) return ("%d%%"):format(math.floor(value + 0.5)) end

AddSlider("continentLabelSize", "Label size on continent maps", ns.MIN_SCALE, ns.MAX_SCALE, 0.1,
    FormatOneDecimal, ns.SetLabelScale, "1.0 = normal UI font size.")
AddSlider("zoneLabelSize", "Label size on zone maps", ns.MIN_SCALE, ns.MAX_SCALE, 0.1,
    FormatOneDecimal, ns.SetLabelScale, "1.0 = normal UI font size.")
AddSlider("zoneLabelLeftToRight", "Zone map label position, left to right", 0, 100, 1,
    FormatPercent, ns.SetSetting, "0% = left edge, 100% = right edge.")
AddSlider("zoneLabelTopToBottom", "Zone map label position, top to bottom", 0, 100, 1,
    FormatPercent, ns.SetSetting, "0% = top edge, 100% = bottom edge.")

AddButton("Reset settings", "Reset",
    function()
        ns.ResetSettings()
        for _, variable in ipairs(variables) do
            Settings.NotifyUpdate(variable) -- show the reset values in the panel
        end
    end,
    "Resets every setting above to the values in Config.lua.")

Settings.RegisterAddOnCategory(category)
