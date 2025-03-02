-- AzurResources
-- Author: HSbF6HSO3F
-- DateCreated: 2025/3/2 9:33:12
--------------------------------------------------------------

--------------------------------------------------------------
-- AzurResources是有关资源的类，它允许更加简单的获取资源的可放置条件。
AzurResources = {
    Index    = -1,
    Type     = '',
    Class    = '',
    Name     = '',
    Icon     = '',
    Terrains = {},
    Features = {}
}

--||======================MetaTable=======================||--

--创建新实例，根据资源定义
function AzurResources:newByDef(resourceDef)
    --错误处理
    if not resourceDef then return nil end
    --创建新实例
    local object = {}
    setmetatable(object, self)
    self.__index = self
    local type   = resourceDef.ResourceType
    object.Type  = type
    object.Index = resourceDef.Index
    object.Class = resourceDef.ResourceClassType
    object.Name  = resourceDef.Name
    --图标设置
    object.Icon  = '[ICON_' .. type .. ']'
    --遍历允许地形
    for row in GameInfo.Resource_ValidTerrains() do
        if row.ResourceType == type then
            local terrainDef = GameInfo.Terrains[row.TerrainType]
            local terrain = { Index = terrainDef.Index, Name = terrainDef.Name }
            table.insert(object.Terrains, terrain)
        end
    end
    --遍历允许地貌
    for row in GameInfo.Resource_ValidFeatures() do
        if row.ResourceType == type then
            local featureDef = GameInfo.Features[row.FeatureType]
            local feature = { Index = featureDef.Index, Name = featureDef.Name }
            table.insert(object.Features, feature)
        end
    end
    return object
end

--创建新实例，根据资源类型
function AzurResources:new(resourceType)
    --错误处理
    if not resourceType then return nil end
    --获取资源定义
    local def = GameInfo.Resources[resourceType]
    return self:newByDef(def)
end

--||====================Based functions===================||--

--获取单元格是否可放置该资源
function AzurResources:GetPlaceable(plot)
    --检查地形
    local terrainType = plot:GetTerrainType()
    for _, terrain in ipairs(self.Terrains) do
        if terrainType == terrain.Index then return true end
    end
    --检查地貌
    local featureType = plot:GetFeatureType()
    for _, feature in ipairs(self.Features) do
        if featureType == feature.Index then return true end
    end
    return false
end

--获取资源可放置条件功能性文本
function AzurResources:GetConditionsTooltip()
    local tooltip = Locale.Lookup("LOC_AZURLANE_RESOURCE_CONDITIONS")
    for _, terrain in ipairs(self.Terrains) do
        tooltip = tooltip .. Locale.Lookup('LOC_AZURLANE_RESOURCE_VAILD_TERRAIN', terrain.Name)
    end
    for _, feature in ipairs(self.Features) do
        tooltip = tooltip .. Locale.Lookup('LOC_AZURLANE_RESOURCE_VAILD_FEATURE', feature.Name)
    end
    return tooltip
end

--||=======================include========================||--

include('AzurResources_', true)
