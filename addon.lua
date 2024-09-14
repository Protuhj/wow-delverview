local myname, ns = ...

local HBD = LibStub("HereBeDragons-2.0")
local HBDP = LibStub("HereBeDragons-Pins-2.0")

ns.KHAZALGAR = 2274
ns.ISLEOFDORN = 2248

local DelveMixin = {}
function DelveMixin:OnLoad(info)
	self:SetSize(32, 32)

	self.texture = self:CreateTexture(nil, "ARTWORK")
	self.texture:SetAllPoints()
	self.texture:SetAtlas(info.atlasName)

	self:SetScript("OnEnter", self.OnMouseEnter)
	self:SetScript("OnLeave", self.OnMouseLeave)

	self.info = info
end
function DelveMixin:OnMouseEnter()
	local tooltip = GetAppropriateTooltip()
	tooltip:SetOwner(self, "ANCHOR_CURSOR")
	tooltip:AddLine(self.info.name)
	if self.info.description then
		tooltip:AddLine(self.info.description)
	end
	tooltip:Show()
end
function DelveMixin:OnMouseLeave()
	GetAppropriateTooltip():Hide()
end

EventUtil.ContinueOnAddOnLoaded("Blizzard_WorldMap", function()
	local points = {}
	local already = {}
	for _, mapInfo in ipairs(C_Map.GetMapChildrenInfo(ns.KHAZALGAR)) do
		if mapInfo.mapType == Enum.UIMapType.Zone then
			for _, delveID in ipairs(C_AreaPoiInfo.GetDelvesForMap(mapInfo.mapID)) do
				if not already[delveID] then
					already[delveID] = true
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
					end
				end
			end
		end
	end
end)
