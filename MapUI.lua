-- ZoneLevelsForever: everything drawn on the world map. Labels on continent
-- and zone maps, hover mode, and the toggle button.
local addonName, ns = ...

local PIN_TEMPLATE = "ZoneLevelsForeverPinTemplate"
local config = ns.Config -- user settings, see Config.lua
local GetZone, FormatLabel = ns.GetZone, ns.FormatLabel
local ShowAllContinentLabels = ns.ShowAllContinentLabels

-- Map pin ---------------------------------------------------------------------
-- Global because Pin.xml references it by name.
ZoneLevelsForeverPinMixin = CreateFromMixins(MapCanvasPinMixin)

function ZoneLevelsForeverPinMixin:OnLoad()
    self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI")
end

-- anchor: which point of the label sits on the pin position ("TOP", "TOPLEFT"...).
function ZoneLevelsForeverPinMixin:OnAcquired(text, x, y, scale, anchor)
    anchor = anchor or "CENTER"
    self.Label:ClearAllPoints()
    self.Label:SetPoint(anchor)
    self.Label:SetJustifyH(anchor:find("LEFT") and "LEFT" or anchor:find("RIGHT") and "RIGHT" or "CENTER")
    self.Label:SetText(text)
    -- Same start and end scale = constant size on screen at every zoom level.
    self:SetScalingLimits(1, scale, scale)
    self:SetPosition(x, y)
    self:ApplyCurrentScale()
end

-- Data provider ---------------------------------------------------------------
local provider = CreateFromMixins(MapCanvasDataProviderMixin)

function provider:RemoveAllData()
    self:GetMap():RemoveAllPinsByTemplate(PIN_TEMPLATE)
end

function provider:AddContinentPin(map, continentID, zoneMapID, zoneName)
    local guideZone, range = GetZone(zoneName)
    if not range then return end

    local minX, maxX, minY, maxY = C_Map.GetMapRectOnMap(zoneMapID, continentID)
    if minX then
        map:AcquirePin(PIN_TEMPLATE, FormatLabel(zoneName, guideZone, range, false),
            (minX + maxX) / 2, (minY + maxY) / 2, config.continentLabelSize)
    end
end

-- All zones, or only the zone under the cursor when labels are toggled off.
function provider:AddContinentPins(map, continentID)
    if ShowAllContinentLabels() then
        for _, zone in ipairs(C_Map.GetMapChildrenInfo(continentID, Enum.UIMapType.Zone) or {}) do
            self:AddContinentPin(map, continentID, zone.mapID, zone.name)
        end
    elseif self.hoveredZone then
        self:AddContinentPin(map, continentID, self.hoveredZone.mapID, self.hoveredZone.name)
    end
end

function provider:RefreshAllData()
    self:RemoveAllData()

    local map = self:GetMap()
    local mapID = map:GetMapID()
    local info = mapID and C_Map.GetMapInfo(mapID)
    if not info then return end

    if info.mapType == Enum.UIMapType.Continent then
        self:AddContinentPins(map, mapID)
    elseif info.mapType == Enum.UIMapType.Zone then
        local zone, range = GetZone(info.name)
        if range then
            map:AcquirePin(PIN_TEMPLATE, FormatLabel(info.name, zone, range, true),
                config.zoneLabelLeftToRight / 100, config.zoneLabelTopToBottom / 100,
                config.zoneLabelSize, config.zoneLabelAnchor)
        end
    end
end

-- Zone under the cursor on a continent map, or nil. Same lookup as Blizzard's
-- own hover label (AreaLabelDataProvider.lua).
local function GetHoveredZone(map)
    if not map:IsCanvasMouseFocus() then return end
    local mapID = map:GetMapID()
    local x, y = map:GetNormalizedCursorPosition()
    local info = C_Map.GetMapInfoAtPosition(mapID, x, y)
    if info and info.mapID ~= mapID then return info end
end

-- Hover mode: redraw only when the zone under the cursor changes.
local function UpdateHover()
    local map = provider:GetMap()
    local info = map and C_Map.GetMapInfo(map:GetMapID() or 0)
    local hovered = info and info.mapType == Enum.UIMapType.Continent and GetHoveredZone(map)
    local hoveredID = hovered and hovered.mapID
    local currentID = provider.hoveredZone and provider.hoveredZone.mapID
    if hoveredID ~= currentID then
        provider.hoveredZone = hovered or nil
        provider:RefreshAllData()
    end
end

-- Redraws the labels if the map is open.
function ns.RefreshMap()
    if WorldMapFrame and WorldMapFrame:IsShown() then
        provider:RefreshAllData()
    end
end

-- Toggle button ---------------------------------------------------------------
local toggleButton

function ns.UpdateToggleButton()
    if not toggleButton then return end
    local on = ShowAllContinentLabels()
    toggleButton.ActiveTexture:SetShown(on)
    toggleButton.Icon:SetDesaturated(not on)
end

local function ShowToggleTooltip(button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip_SetTitle(GameTooltip, addonName)
    GameTooltip_AddNormalLine(GameTooltip, ShowAllContinentLabels()
        and "Zone levels are shown on the continent maps."
        or "Zone levels are shown when you hover a zone.")
    GameTooltip_AddInstructionLine(GameTooltip, "Left-click to toggle.")
    GameTooltip_AddInstructionLine(GameTooltip, "Right-click for settings.")
    GameTooltip:Show()
end

function ns.SetContinentLabels(on)
    ZoneLevelsForeverDB.showContinentLabels = on
    ns.UpdateToggleButton()
    ns.RefreshMap()
    ns.UpdateSettingsWindow()
    if toggleButton and toggleButton:IsMouseOver() then
        ShowToggleTooltip(toggleButton)
    end
end

function ns.ToggleContinentLabels()
    ns.SetContinentLabels(not ShowAllContinentLabels())
end

-- Below Blizzard's round buttons in the top-right corner of the map.
local function CreateToggleButton()
    local map = WorldMapFrame
    local above = map.WorldMapTrackingPinButton or map.WorldMapTrackingOptionsButton
    toggleButton = CreateFrame("Button", nil, map, "ZoneLevelsForeverToggleButtonTemplate")
    if above then
        toggleButton:SetPoint("TOPRIGHT", above, "BOTTOMRIGHT", 0, 0)
    else
        toggleButton:SetPoint("TOPRIGHT", map:GetCanvasContainer(), "TOPRIGHT", -4, -2)
    end
    toggleButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    toggleButton:SetScript("OnClick", function(_, button)
        if button == "RightButton" then
            ns.ToggleSettingsWindow()
        else
            ns.ToggleContinentLabels()
        end
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
    end)
    toggleButton:SetScript("OnEnter", ShowToggleTooltip)
    toggleButton:SetScript("OnLeave", GameTooltip_Hide)
    ns.UpdateToggleButton()
end

EventUtil.ContinueOnAddOnLoaded("Blizzard_WorldMap", function()
    WorldMapFrame:AddDataProvider(provider)
    CreateToggleButton()

    -- Hover checks only run while the map is open and labels are toggled off.
    local hoverFrame = CreateFrame("Frame", nil, WorldMapFrame)
    hoverFrame:SetScript("OnUpdate", function()
        if not ShowAllContinentLabels() then UpdateHover() end
    end)
end)
