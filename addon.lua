local myname, ns = ...

DelverViewDataProviderMixin = CreateFromMixins(CVarMapCanvasDataProviderMixin, AreaPOIDataProviderMixin)
DelverViewDataProviderMixin:Init("showDelveEntrancesOnMap")

function DelverViewDataProviderMixin:RemoveAllData()
	self:GetMap():RemoveAllPinsByTemplate("DelverViewPinTemplate")
end

function DelverViewDataProviderMixin:OnShow()
	CVarMapCanvasDataProviderMixin.OnShow(self)
	AreaPOIDataProviderMixin.OnShow(self)
end

function DelverViewDataProviderMixin:OnHide()
	CVarMapCanvasDataProviderMixin.OnHide(self)
	AreaPOIDataProviderMixin.OnHide(self)
end

function DelverViewDataProviderMixin:OnEvent(event, ...)
	CVarMapCanvasDataProviderMixin.OnEvent(self, event, ...)
	AreaPOIDataProviderMixin.OnEvent(self, event, ...)
end

function DelverViewDataProviderMixin:RefreshAllData(fromOnShow)
	self:RemoveAllData()

	if not self:IsCVarSet() then
		return
	end

	local mapID = self:GetMap():GetMapID()

	local mapInfo = C_Map.GetMapInfo(mapID)
	if not (mapInfo and mapInfo.mapType == Enum.UIMapType.Continent) then
		return
	end

	for _, mapInfo in ipairs(C_Map.GetMapChildrenInfo(mapID)) do
		if mapInfo.mapType == Enum.UIMapType.Zone then
			for _, delveID in ipairs(C_AreaPoiInfo.GetDelvesForMap(mapInfo.mapID)) do
				local info = C_AreaPoiInfo.GetAreaPOIInfo(mapInfo.mapID, delveID)
				local minX, maxX, minY, maxY = C_Map.GetMapRectOnMap(mapInfo.mapID, mapID)
				if info and minX then
					local x, y = info.position:GetXY()
					local tx = Lerp(minX, maxX, x)
					local ty = Lerp(minY, maxY, y)
					info.position:SetXY(tx, ty)
					info.dataProvider = self
					self:GetMap():AcquirePin("DelverViewPinTemplate", info)
				end
			end
		end
	end
end


local DelvePinMixin = DelveEntrancePinMixin:CreateSubPin("PIN_FRAME_LEVEL_DELVE_ENTRANCE")
_G.DelverViewPinMixin = DelvePinMixin
function DelvePinMixin:SetPassThroughButtons(...)
	if not InCombatLockdown() then return WorldMapFrame.SetPassThroughButtons(self, ...) end
end
function DelvePinMixin:DoesMapTypeAllowSuperTrack()
	-- Default is to not allow on continent maps, but the user has really explicitly asked for these to be here, so...
	local mapInfo = C_Map.GetMapInfo(self:GetMap():GetMapID())
	if mapInfo then
		return mapInfo.mapType >= Enum.UIMapType.Continent
	end
end

EventUtil.ContinueOnAddOnLoaded("Blizzard_WorldMap", function()
	WorldMapFrame:AddDataProvider(CreateFromMixins(DelverViewDataProviderMixin))
end)
