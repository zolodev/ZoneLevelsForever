-- ZoneLevelsForever: small settings window that can stay open next to the
-- world map, so changes show on the map right away. (Blizzard's Options
-- panel closes the map when it opens.)
local addonName, ns = ...

local config = ns.Config

-- Layout, in UI pixels. The template's inner frame starts 4 px from the left,
-- 24 px from the top (under the title bar), 6 px from the right and 4 px from
-- the bottom; PADDING is the space between that inner frame and the controls.
local WIDTH = 340
local PADDING = 16
local CONTENT_LEFT, CONTENT_RIGHT = 4 + PADDING, 6 + PADDING
local CONTENT_TOP, CONTENT_BOTTOM = 24 + PADDING, 4 + PADDING
local SPACING = 16       -- between controls
local LABEL_GAP = 6      -- between a slider's label and the slider
local VALUE_WIDTH = 40   -- room right of a slider for its value text
local SLIDER_WIDTH = WIDTH - CONTENT_LEFT - CONTENT_RIGHT - VALUE_WIDTH
local SLIDER_HEIGHT = 40 -- MinimalSliderWithSteppersTemplate
local CHECKBOX_HEIGHT = 26
local BUTTON_HEIGHT = 22

local SLIDER_KEYS = { "continentLabelSize", "zoneLabelSize", "zoneLabelLeftToRight", "zoneLabelTopToBottom" }

local panels = {}      -- every frame with controls on it, for UpdateSettingsWindow
local updating = false -- true while controls are set from code, to ignore their callbacks

local function FormatOneDecimal(value) return ("%.1f"):format(value) end
local function FormatPercent(value) return ("%d%%"):format(math.floor(value + 0.5)) end

-- Places a control at the next free row of the panel and moves the row down.
local function PlaceNext(panel, region, height)
    region:SetPoint("TOPLEFT", panel, "TOPLEFT", panel.left, -panel.nextY)
    panel.nextY = panel.nextY + height + SPACING
end

local function AddCheckbox(panel, key, label, onClick)
    local checkbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    checkbox:SetSize(CHECKBOX_HEIGHT, CHECKBOX_HEIGHT)
    checkbox.Text:SetFontObject("GameFontHighlight")
    checkbox.Text:SetText(label)
    checkbox:SetScript("OnClick", function(self) onClick(self:GetChecked()) end)
    PlaceNext(panel, checkbox, CHECKBOX_HEIGHT)
    panel.controls[key] = checkbox
end

-- A label with its slider right under it.
local function AddSlider(panel, key, label, minValue, maxValue, step, format, onChange)
    local text = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetText(label)
    text:SetPoint("TOPLEFT", panel, "TOPLEFT", panel.left, -panel.nextY)

    local slider = CreateFrame("Frame", nil, panel, "MinimalSliderWithSteppersTemplate")
    slider:SetSize(SLIDER_WIDTH, SLIDER_HEIGHT)
    slider:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -LABEL_GAP)
    slider:Init(config[key], minValue, maxValue, (maxValue - minValue) / step, {
        [MinimalSliderWithSteppersMixin.Label.Right] = CreateMinimalSliderFormatter(
            MinimalSliderWithSteppersMixin.Label.Right, format),
    })
    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        if not updating then onChange(key, value) end
    end, panel)

    panel.nextY = panel.nextY + text:GetStringHeight() + LABEL_GAP + SLIDER_HEIGHT + SPACING
    panel.controls[key] = slider
end

-- Adds every setting's control to panel, from (left, top) down. Returns the
-- y offset under the last control.
function ns.AddSettingsControls(panel, left, top)
    panel.left, panel.nextY, panel.controls = left, top, {}
    AddCheckbox(panel, "showContinentLabels", "Show labels on continent maps", ns.SetContinentLabels)
    AddSlider(panel, "continentLabelSize", "Label size on continent maps",
        ns.MIN_SCALE, ns.MAX_SCALE, 0.1, FormatOneDecimal, ns.SetLabelScale)
    AddSlider(panel, "zoneLabelSize", "Label size on zone maps",
        ns.MIN_SCALE, ns.MAX_SCALE, 0.1, FormatOneDecimal, ns.SetLabelScale)
    AddSlider(panel, "zoneLabelLeftToRight", "Zone map label position, left to right",
        0, 100, 1, FormatPercent, ns.SetSetting)
    AddSlider(panel, "zoneLabelTopToBottom", "Zone map label position, top to bottom",
        0, 100, 1, FormatPercent, ns.SetSetting)
    table.insert(panels, panel)
    return panel.nextY
end

-- Shows the current values on one panel.
local function UpdatePanel(panel)
    updating = true
    panel.controls.showContinentLabels:SetChecked(ns.ShowAllContinentLabels())
    for _, key in ipairs(SLIDER_KEYS) do
        panel.controls[key]:SetValue(config[key])
    end
    updating = false
end
ns.UpdateSettingsPanel = UpdatePanel

-- Called whenever a setting changes (map button, window, options panel,
-- /zonelevels), so every open panel shows the new values.
function ns.UpdateSettingsWindow()
    for _, panel in ipairs(panels) do
        if panel:IsVisible() then UpdatePanel(panel) end
    end
end

local window

local function CreateWindow()
    window = CreateFrame("Frame", nil, UIParent, "BasicFrameTemplateWithInset")
    window:SetPoint("CENTER", UIParent, "CENTER", 400, 0)
    window:SetFrameStrata("FULLSCREEN_DIALOG") -- above the world map and Options
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:SetScript("OnShow", UpdatePanel)
    window.TitleText:SetText(addonName)

    ns.AddSettingsControls(window, CONTENT_LEFT, CONTENT_TOP)

    local reset = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    reset:SetSize(160, BUTTON_HEIGHT)
    reset:SetText("Reset to defaults")
    reset:SetScript("OnClick", ns.ResetSettings)
    PlaceNext(window, reset, BUTTON_HEIGHT)

    -- nextY already includes SPACING after the last control; swap it for the bottom padding.
    window:SetSize(WIDTH, window.nextY - SPACING + CONTENT_BOTTOM)
    window:Hide()
end

function ns.ToggleSettingsWindow()
    if not window then CreateWindow() end
    window:SetShown(not window:IsShown())
end

-- Entry in the AddOns menu by the minimap (## AddonCompartmentFunc in the .toc).
-- Global because the game looks it up by name.
function ZoneLevelsForever_OnAddonCompartmentClick()
    ns.ToggleSettingsWindow()
end
