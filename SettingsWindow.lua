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

local window
local controls = {}   -- key -> checkbox or slider, for UpdateSettingsWindow
local updating = false -- true while controls are set from code, to ignore their callbacks
local nextY           -- top of the next control, from the window's top edge

local function FormatOneDecimal(value) return ("%.1f"):format(value) end
local function FormatPercent(value) return ("%d%%"):format(math.floor(value + 0.5)) end

-- Places a control at the next free row and moves the row down.
local function PlaceNext(region, height)
    region:SetPoint("TOPLEFT", window, "TOPLEFT", CONTENT_LEFT, -nextY)
    nextY = nextY + height + SPACING
end

local function AddCheckbox(key, label, onClick)
    local checkbox = CreateFrame("CheckButton", nil, window, "UICheckButtonTemplate")
    checkbox:SetSize(CHECKBOX_HEIGHT, CHECKBOX_HEIGHT)
    checkbox.Text:SetFontObject("GameFontHighlight")
    checkbox.Text:SetText(label)
    checkbox:SetScript("OnClick", function(self) onClick(self:GetChecked()) end)
    PlaceNext(checkbox, CHECKBOX_HEIGHT)
    controls[key] = checkbox
end

-- A label with its slider right under it.
local function AddSlider(key, label, minValue, maxValue, step, format, onChange)
    local text = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetText(label)
    text:SetPoint("TOPLEFT", window, "TOPLEFT", CONTENT_LEFT, -nextY)

    local slider = CreateFrame("Frame", nil, window, "MinimalSliderWithSteppersTemplate")
    slider:SetSize(SLIDER_WIDTH, SLIDER_HEIGHT)
    slider:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -LABEL_GAP)
    slider:Init(config[key], minValue, maxValue, (maxValue - minValue) / step, {
        [MinimalSliderWithSteppersMixin.Label.Right] = CreateMinimalSliderFormatter(
            MinimalSliderWithSteppersMixin.Label.Right, format),
    })
    slider:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
        if not updating then onChange(key, value) end
    end, window)

    nextY = nextY + text:GetStringHeight() + LABEL_GAP + SLIDER_HEIGHT + SPACING
    controls[key] = slider
end

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
    window:SetScript("OnShow", ns.UpdateSettingsWindow)
    window.TitleText:SetText(addonName)

    nextY = CONTENT_TOP
    AddCheckbox("showContinentLabels", "Show labels on continent maps", ns.SetContinentLabels)
    AddSlider("continentLabelSize", "Label size on continent maps",
        ns.MIN_SCALE, ns.MAX_SCALE, 0.1, FormatOneDecimal, ns.SetLabelScale)
    AddSlider("zoneLabelSize", "Label size on zone maps",
        ns.MIN_SCALE, ns.MAX_SCALE, 0.1, FormatOneDecimal, ns.SetLabelScale)
    AddSlider("zoneLabelLeftToRight", "Zone map label position, left to right",
        0, 100, 1, FormatPercent, ns.SetSetting)
    AddSlider("zoneLabelTopToBottom", "Zone map label position, top to bottom",
        0, 100, 1, FormatPercent, ns.SetSetting)

    local reset = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    reset:SetSize(160, BUTTON_HEIGHT)
    reset:SetText("Reset to defaults")
    reset:SetScript("OnClick", ns.ResetSettings)
    PlaceNext(reset, BUTTON_HEIGHT)

    -- nextY already includes SPACING after the last control; swap it for the bottom padding.
    window:SetSize(WIDTH, nextY - SPACING + CONTENT_BOTTOM)
    window:Hide()
end

-- Shows the current values; called when the window opens and whenever a
-- setting changes elsewhere (map button, options panel, /zonelevels).
function ns.UpdateSettingsWindow()
    if not (window and window:IsShown()) then return end
    updating = true
    controls.showContinentLabels:SetChecked(ns.ShowAllContinentLabels())
    for _, key in ipairs({ "continentLabelSize", "zoneLabelSize", "zoneLabelLeftToRight", "zoneLabelTopToBottom" }) do
        controls[key]:SetValue(config[key])
    end
    updating = false
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
