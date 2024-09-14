local myname, ns = ...

local HBD = LibStub("HereBeDragons-2.0")
local HBDP = LibStub("HereBeDragons-Pins-2.0")

ns.KHAZALGAR = 2274
ns.ISLEOFDORN = 2248

local DelveMixin = {}
function DelveMixin:OnLoad(info)
	self.poiInfo = info
	self.areaPoiID = info.areaPoiID
	self.name = info.name
	self.description = info.description
	self.tooltipWidgetSet = info.tooltipWidgetSet
	self.iconWidgetSet = info.iconWidgetSet
	self.textureKit = info.uiTextureKit

	self:SetSize(32, 32)
	if not InCombatLockdown() then
		self:SetPassThroughButtons("LeftButton", "RightButton", "MiddleButton", "Button4", "Button5")
	end

	self.texture = self:CreateTexture(nil, "ARTWORK")
	self.texture:SetAllPoints()
	self.texture:SetAtlas(info.atlasName)

	self:SetScript("OnEnter", self.OnMouseEnter)
	self:SetScript("OnLeave", self.OnMouseLeave)

	-- self:AddIconWidgets()
end
function DelveMixin:OnMouseEnter()
	-- /dump C_AreaPoiInfo.GetAreaPOIInfo(2248, 7781)
	-- see: AreaPOIPinMixin:TryShowTooltip
	local verticalPadding
	local isTimed, hideTimer = C_AreaPoiInfo.IsAreaPOITimed(self.areaPoiID)
	local tooltip = GetAppropriateTooltip()
	tooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip_SetTitle(tooltip, self.name, HIGHLIGHT_FONT_COLOR)
	if self.description and self.description ~= "" then
		GameTooltip_AddNormalLine(tooltip, self.description)
	end
	if self.tooltipWidgetSet then
		local overflow = GameTooltip_AddWidgetSet(tooltip, self.tooltipWidgetSet, 10)
		if overflow then
			verticalPadding = -overflow
		end
	end
	tooltip:Show()
	if verticalPadding then
		tooltip:SetPadding(0, verticalPadding)
	end
end
function DelveMixin:OnMouseLeave()
	GetAppropriateTooltip():Hide()
end
DelveMixin.AddIconWidgets = MapCanvasPinMixin.AddIconWidgets


local already = {}
EventRegistry:RegisterCallback("WorldMapOnShow", function()
	-- all needed data should be loaded by now
	for _, mapInfo in ipairs(C_Map.GetMapChildrenInfo(ns.KHAZALGAR)) do
		if mapInfo.mapType == Enum.UIMapType.Zone then
			for _, delveID in ipairs(C_AreaPoiInfo.GetDelvesForMap(mapInfo.mapID)) do
				if not already[delveID] then
					local info = C_AreaPoiInfo.GetAreaPOIInfo(mapInfo.mapID, delveID)
					local x, y = info.position:GetXY()
					local tx, ty
					tx, ty = HBD:TranslateZoneCoordinates(x, y, mapInfo.mapID, ns.KHAZALGAR)
					if not tx then
						-- special-case, as HereBeDragons can't translate these due to the weird stacked-maps structure of Khaz Algar
						local minX, maxX, minY, maxY = C_Map.GetMapRectOnMap(mapInfo.mapID, ns.KHAZALGAR)
						tx = Lerp(minX, maxX, x)
						ty = Lerp(minY, maxY, y)
					end
					if tx and ty then
						local icon = CreateFrame("Frame")
						Mixin(icon, DelveMixin)
						icon:OnLoad(info)
						HBDP:AddWorldMapIconMap(myname, icon, ns.KHAZALGAR, tx, ty)
						already[delveID] = true
					end
				end
			end
		end
	end
end)
