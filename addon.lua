local myname, ns = ...

local provider

local extra_children = {
	-- Note: this is only needed for zones where a child-of-child is relevant,
	-- and the child-of-child will have data from GetMapRectOnMap
	[2274] = { -- Khaz Algar
		2339, -- Dornogal (technically a child of Isle of Dorn)
		2346, -- Undermine (technically a child of Ringing Deeps)
	},
}

EventUtil.ContinueOnAddOnLoaded(myname, function()
	DelverViewDB = DelverViewDB or {}
end)

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

	if not self:IsCVarSet() or InCombatLockdown() then
		return
	end

	local mapID = self:GetMap():GetMapID()

	local mapInfo = C_Map.GetMapInfo(mapID)
	if not (mapInfo and mapInfo.mapType == Enum.UIMapType.Continent) then
		return
	end

	for _, mapInfo in ipairs(C_Map.GetMapChildrenInfo(mapID)) do
		if mapInfo.mapType == Enum.UIMapType.Zone then
			self:AddDelvesForMap(mapID, mapInfo)
		end
	end
	if extra_children[mapID] then
		for _, childID in ipairs(extra_children[mapID]) do
			self:AddDelvesForMap(mapID, C_Map.GetMapInfo(childID))
		end
	end
end

function DelverViewDataProviderMixin:AddDelvesForMap(parentMapID, mapInfo)
	if not mapInfo then return end
	for _, delveID in ipairs(C_AreaPoiInfo.GetDelvesForMap(mapInfo.mapID)) do
		local info = C_AreaPoiInfo.GetAreaPOIInfo(mapInfo.mapID, delveID)
		local minX, maxX, minY, maxY = C_Map.GetMapRectOnMap(mapInfo.mapID, parentMapID)
		if info and minX and (info.atlasName == "delves-bountiful" or not DelverViewDB.only_bountiful) then
			local x, y = info.position:GetXY()
			local tx = Lerp(minX, maxX, x)
			local ty = Lerp(minY, maxY, y)
			info.position:SetXY(tx, ty)
			info.dataProvider = self
			self:GetMap():AcquirePin("DelverViewPinTemplate", info)
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
	provider = CreateFromMixins(DelverViewDataProviderMixin)
	WorldMapFrame:AddDataProvider(provider)
end)

local function isChecked(key)
	return DelverViewDB[key]
end
local function setChecked(key)
	DelverViewDB[key] = not DelverViewDB[key]
	provider:RefreshAllData()
end
Menu.ModifyMenu("MENU_WORLD_MAP_TRACKING", function(owner, rootDescription, contextData)
	local mapInfo = C_Map.GetMapInfo(owner:GetParent():GetMapID())
	if mapInfo and mapInfo.mapType == Enum.UIMapType.Continent then
		-- "%s Only"
		local title = RACE_CLASS_ONLY:format(C_QuestLog.GetTitleForQuestID(81514) or "Bountiful Delves")
		rootDescription:CreateDivider()
		local check = rootDescription:CreateCheckbox(title, isChecked, setChecked, "only_bountiful")
		check:SetTooltip(function(tooltip, elementDescription)
			-- this display style is from BlizzardWorldMapTemplates.lua,
			-- altered to account for SetTooltip not giving us access to the
			-- same things that SetOnEnter does.
			local owner = tooltip:GetOwner()
			tooltip:ClearAllPoints()
			tooltip:SetPoint("RIGHT", owner, "LEFT", -3, 0)
			tooltip:SetOwner(owner, "ANCHOR_PRESERVE")

			GameTooltip_SetTitle(tooltip, title)
			GameTooltip_AddNormalLine(tooltip, DELVES_GREAT_VAULT_DESCRIPTION_SEASON_STARTED)
			tooltip:AddDoubleLine(" ", myname, 1, 1, 1, 0, 1, 1)
		end)
	end
end)
