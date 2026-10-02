-- ZoneLevelsForever: settings panel under Options -> AddOns. Same controls as
-- the settings window (SettingsWindow.lua), which can stay open next to the map.
--
-- The panel is a frame of our own (a "canvas" category), not a list of Blizzard
-- setting controls: the Options search skips canvas panels. Settings in the
-- search results run addon code when they are shown, and that blocks Blizzard
-- settings shown in the same results (searching for "con" or "contrast").
local addonName, ns = ...

local LEFT, TOP = 16, 16
local GAP = 16

local panel = CreateFrame("Frame")

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", LEFT, -TOP)
title:SetText(addonName)

local open = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
open:SetSize(160, 22)
open:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -GAP)
open:SetText("Settings window")
open:SetScript("OnClick", ns.ToggleSettingsWindow)

local hint = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
hint:SetPoint("LEFT", open, "RIGHT", 10, 0)
hint:SetPoint("RIGHT", panel, "RIGHT", -LEFT, 0)
hint:SetJustifyH("LEFT")
hint:SetText("Stays open when you close Options, so you can see changes live on the world map.")

local controlsTop = TOP + title:GetStringHeight() + GAP + open:GetHeight() + GAP * 2
ns.AddSettingsControls(panel, LEFT, controlsTop)

panel:SetScript("OnShow", ns.UpdateSettingsPanel)

-- Called by Options when it opens, and by its "Defaults" button.
function panel:OnRefresh()
    ns.UpdateSettingsPanel(self)
end

function panel:OnDefault()
    ns.ResetSettings()
end

local category = Settings.RegisterCanvasLayoutCategory(panel, addonName)
Settings.RegisterAddOnCategory(category)
