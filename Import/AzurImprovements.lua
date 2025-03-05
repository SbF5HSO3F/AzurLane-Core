-- AzurImprovements
-- Author: jjj
-- DateCreated: 2025/3/5 16:35:48
--------------------------------------------------------------
--||======================MetaTable=======================||--

--------------------------------------------------------------
-- AzurImprovement是管理改良的类，允许获取改良的限制
AzurImprovement = {
    Index    = -1,
    Type     = '',
    Name     = '',
    Icon     = '',
    Domain   = '',
    Terrains = {},
    Enforce  = false,
    Features = {},
    Resource = {}
}

function AzurImprovement:new(improvementDef)
    local object = {}
    setmetatable(object, self)
    self.__index    = self
    local improType = improvementDef.ImprovementType
    --改良的索引、类型、名称、图标
    object.Type     = improType
    object.Index    = improvementDef.Index
    object.Name     = improvementDef.Name
    object.Icon     = improvementDef.Icon
    object.Domain   = improvementDef.Domain
    object.Enforce  = improvementDef.EnforceTerrain
    --改良可上的地形和地貌
    object.Terrains = {}
    object.Features = {}
    object.Resource = {}
    --获取
    for row in GameInfo.Improvement_ValidTerrains() do
        if improType == row.ImprovementType then
            local terrainDef = GameInfo.Terrains[row.TerrainType]
            local terrain = { Index = terrainDef.Index, Name = terrainDef.Name }
            table.insert(object.Terrains, terrain)
        end
    end
    for row in GameInfo.Improvement_ValidFeatures() do
        if improType == row.ImprovementType then
            local featureDef = GameInfo.Features[row.FeatureType]
            local feature = { Index = featureDef.Index, Name = featureDef.Name }
            table.insert(object.Features, feature)
        end
    end
    for row in GameInfo.Improvement_ValidResources() do
        if improType == row.ImprovementType then
            local resourceDef = GameInfo.Resources[row.ResourceType]
            local resource = { Index = resourceDef.Index, MustRemoveFeature = row.MustRemoveFeature }
            table.insert(object.Resource, resource)
        end
    end
    return object
end

function AzurImprovement:newNoValid(improvementDef)
    local object = {}
    setmetatable(object, self)
    self.__index    = self
    local improType = improvementDef.ImprovementType
    --改良的索引、类型、名称、图标
    object.Type     = improType
    object.Index    = improvementDef.Index
    object.Name     = improvementDef.Name
    object.Icon     = improvementDef.Icon
    object.Domain   = improvementDef.Domain
    object.Enforce  = improvementDef.EnforceTerrain
    --改良可上的地形和地貌
    object.Terrains = {}
    object.Features = {}
    object.Resource = {}
    return object
end

--||====================Based functions===================||--

--获取该单元格可放置的改良
function AzurImprovement:GetPlaceable(plot)
    if self.Domain == 'DOMAIN_SEA' and not plot:IsWater() then
        return false
    end
    --检查地形
    local terrainType = plot:GetTerrainType()
    local terrainMatch = false
    for _, terrain in ipairs(self.Terrains) do
        if terrainType == terrain.Index then
            terrainMatch = true
            break
        end
    end
    if self.Enforce and not terrainMatch then return false end
    if terrainMatch then return true end
    --检查地貌
    local featureType = plot:GetFeatureType()
    for _, feature in ipairs(self.Features) do
        if featureType == feature.Index then return true end
    end
    --检查资源
    local hasFeature = featureType ~= -1
    local resourceType = plot:GetResourceType()
    for _, resource in ipairs(self.Resource) do
        if resourceType == resource.Index and not
            (hasFeature and resource.MustRemoveFeature) then
            return true
        end
    end
    return false
end

--||======================MetaTable=======================||--

--------------------------------------------------------------
-- AzurImprovements管理所有的改良，一般用于需要缓存的场合
AzurImprovements = { Improvements = {} }

function AzurImprovements:new()
    local object = {}
    setmetatable(object, self)
    self.__index        = self
    object.Improvements = {}
    --添加所有改良
    for improveDef in GameInfo.Improvements() do
        local improveType = improveDef.ImprovementType
        object.Improvements[improveType] = AzurImprovement:newNoValid(improveDef)
    end
    --关于地貌和地形的限制
    for row in GameInfo.Improvement_ValidTerrains() do
        local improvement = object.Improvements[row.ImprovementType]
        if improvement then
            local terrainDef = GameInfo.Terrains[row.TerrainType]
            local terrain = { Index = terrainDef.Index, Name = terrainDef.Name }
            table.insert(improvement.Terrains, terrain)
        end
    end
    for row in GameInfo.Improvement_ValidFeatures() do
        local improvement = object.Improvements[row.ImprovementType]
        if improvement then
            local featureDef = GameInfo.Features[row.FeatureType]
            local feature = { Index = featureDef.Index, Name = featureDef.Name }
            table.insert(improvement.Features, feature)
        end
    end
    for row in GameInfo.Improvement_ValidResources() do
        local improvement = object.Improvements[row.ImprovementType]
        if improvement then
            local resourceDef = GameInfo.Resources[row.ResourceType]
            local resource = { Index = resourceDef.Index, MustRemoveFeature = row.MustRemoveFeature }
            table.insert(improvement.Resource, resource)
        end
    end
    return object
end

--||====================Based functions===================||--

--获取某个改良
function AzurImprovements:GetImprovement(improvementType)
    return self.Improvements[improvementType]
end

--||=======================include========================||--

include('AzurImprovements_', true)
