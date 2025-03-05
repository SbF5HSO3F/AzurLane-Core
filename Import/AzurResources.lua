-- AzurResources
-- Author: HSbF6HSO3F
-- DateCreated: 2025/3/2 9:33:12
--------------------------------------------------------------
--||=======================include========================||--
include('AzurImprovements')

--||======================MetaTable=======================||--

--------------------------------------------------------------
-- AzurResource是有关资源的类，它允许更加简单的获取资源的可放置条件。
AzurResource = {
    Index        = -1,
    Type         = '',
    Class        = '',
    Name         = '',
    Icon         = '',
    Terrains     = {},
    Remove       = true,
    Features     = {},
    Improvements = {}
}

--创建新实例，根据资源定义
function AzurResource:newByDef(resourceDef)
    --错误处理
    if not resourceDef then return nil end
    --创建新实例
    local object = {}
    setmetatable(object, self)
    self.__index    = self
    local resource  = resourceDef.ResourceType
    object.Type     = resource
    object.Index    = resourceDef.Index
    object.Class    = resourceDef.ResourceClassType
    object.Name     = resourceDef.Name
    --图标设置
    object.Icon     = '[ICON_' .. resource .. ']'
    --遍历允许地形
    object.Terrains = {}
    for row in GameInfo.Resource_ValidTerrains() do
        if row.ResourceType == resource then
            local terrainDef = GameInfo.Terrains[row.TerrainType]
            local terrain = { Index = terrainDef.Index, Name = terrainDef.Name }
            table.insert(object.Terrains, terrain)
        end
    end
    --遍历允许地貌
    object.Features = {}
    for row in GameInfo.Resource_ValidFeatures() do
        if row.ResourceType == resource then
            local featureDef = GameInfo.Features[row.FeatureType]
            local feature = { Index = featureDef.Index, Name = featureDef.Name }
            table.insert(object.Features, feature)
        end
    end
    --改良是否必须移除地貌
    object.Remove = true
    --提升用改良设施
    object.Improvements = {}
    --遍历改良设施允许资源表
    for row in GameInfo.Improvement_ValidResources() do
        if row.ResourceType == resource then
            if row.MustRemoveFeature == false then
                object.Remove = false
            end
            if not (object.Remove and row.MustRemoveFeature) then
                local improveDef = GameInfo.Improvements[row.ImprovementType]
                local improvement = AzurImprovement:new(improveDef)
                table.insert(object.Improvements, improvement)
            end
        end
    end
    return object
end

--创建新实例，根据资源类型
function AzurResource:new(resourceType)
    --错误处理
    if not resourceType then return nil end
    --获取资源定义
    local def = GameInfo.Resources[resourceType]
    return self:newByDef(def)
end

--创建新实例，根据资源定义但没有限制
function AzurResource:newByDefNoValid(resourceDef)
    --错误处理
    if not resourceDef then return nil end
    --创建新实例
    local object = {}
    setmetatable(object, self)
    self.__index        = self
    local type          = resourceDef.ResourceType
    object.Type         = type
    object.Index        = resourceDef.Index
    object.Class        = resourceDef.ResourceClassType
    object.Name         = resourceDef.Name
    --图标设置
    object.Icon         = '[ICON_' .. type .. ']'
    --地形和地貌
    object.Terrains     = {}
    object.Remove       = true
    object.Features     = {}
    object.Improvements = {}
    return object
end

--||====================Based functions===================||--

--获取单元格是否可放置该资源
function AzurResource:GetPlaceable(plot)
    --检查地貌
    local featureType = plot:GetFeatureType()
    if featureType ~= -1 and self.Remove then return false end
    for _, feature in ipairs(self.Features) do
        if featureType == feature.Index then return true end
    end
    --检查地形
    local terrainType = plot:GetTerrainType()
    for _, terrain in ipairs(self.Terrains) do
        if terrainType == terrain.Index then return true end
    end
    return false
end

--获取资源可用改良设施
function AzurResource:GetImprovement(plot)
    for _, improvement in ipairs(self.Improvements) do
        if improvement:GetPlaceable(plot) then return improvement end
    end
    return false
end

--获取资源可放置条件功能性文本
function AzurResource:GetConditionsTooltip()
    local tooltip = Locale.Lookup("LOC_AZURLANE_RESOURCE_CONDITIONS")
    if self.Remove then
        tooltip = tooltip .. Locale.Lookup('LOC_AZURLANE_RESOURCE_NO_FEATURE')
    end
    tooltip = tooltip .. Locale.Lookup('LOC_AZURLANE_RESOURCE_TERRAIN')
    for _, terrain in ipairs(self.Terrains) do
        tooltip = tooltip .. Locale.Lookup('LOC_AZURLANE_RESOURCE_VAILD_TERRAIN', terrain.Name)
    end
    tooltip = tooltip .. Locale.Lookup('LOC_AZURLANE_RESOURCE_FEATURE')
    for _, feature in ipairs(self.Terrains) do
        tooltip = tooltip .. Locale.Lookup('LOC_AZURLANE_RESOURCE_VAILD_FEATURE', feature.Name)
    end
    return tooltip
end

--||======================MetaTable=======================||--

--------------------------------------------------------------
---AzurResources是AzurLaneCoreCode的资源管理类
---它允许按照要求检索GameInfo的资源信息，并通过一次性创建多个资源实例来提高效率。
AzurResources = { Resources = {} }

--创建新实例，根据资源类型列表
function AzurResources:new(resourceReq)
    local object = {}
    setmetatable(object, self)
    self.__index = self
    --初始化资源列表
    object.Resources = {}
    --遍历资源类型列表
    for def in GameInfo.Resources() do
        local match = false
        if def.Frequency ~= 0 or def.SeaFrequency ~= 0 then
            if resourceReq == true then
                match = true
            else
                if resourceReq[def.ResourceType] then
                    match = true
                end
                if resourceReq[def.ResourceClassType] then
                    match = true
                end
            end
        end
        if match then
            local resource = AzurResource:newByDefNoValid(def)
            object.Resources[def.ResourceType] = resource
        end
    end
    --创建地形和地貌限制
    for row in GameInfo.Resource_ValidTerrains() do
        local resource = object.Resources[row.ResourceType]
        if resource then
            local terrainDef = GameInfo.Terrains[row.TerrainType]
            local terrain = { Index = terrainDef.Index, Name = terrainDef.Name }
            table.insert(resource.Terrains, terrain)
        end
    end
    for row in GameInfo.Resource_ValidFeatures() do
        local resource = object.Resources[row.ResourceType]
        if resource then
            local featureDef = GameInfo.Features[row.FeatureType]
            local feature = { Index = featureDef.Index, Name = featureDef.Name }
            table.insert(resource.Features, feature)
        end
    end
    local improvements = AzurImprovements:new()
    --改良是否必须移除地貌
    for row in GameInfo.Improvement_ValidResources() do
        local resource = object.Resources[row.ResourceType]
        if resource then
            if row.MustRemoveFeature == false then
                resource.Remove = false
            end
            local improvement = improvements:GetImprovement(row.ImprovementType)
            table.insert(resource.Improvements, improvement)
        end
    end
    return object
end

--||====================Based functions===================||--

--获取资源实例
function AzurResources:GetResource(resourceType)
    return self.Resources[resourceType]
end

--获取该单元格可以放置的资源列表
function AzurResources:GetPlaceableResources(plot)
    local list = {}
    --地形
    for _, resource in pairs(self.Resources) do
        if resource:GetPlaceable(plot) then
            local def = {}
            def.Index = resource.Index
            def.Type  = resource.Type
            def.Name  = resource.Name
            def.Icon  = resource.Icon
            table.insert(list, def)
        end
    end
    return list
end

--||=======================include========================||--

include('AzurResources_', true)
