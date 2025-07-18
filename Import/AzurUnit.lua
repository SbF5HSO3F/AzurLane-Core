-- AzurUnit
-- Author: HSbF6HSO3F
-- DateCreated: 2025/7/15 11:07:45
--------------------------------------------------------------
--||=======================include========================||--
include('AzurLaneCoreScript')

--||======================MetaTable=======================||--

-- AzurUnit 用于处理单位相关的功能
AzurUnit = {}

function AzurUnit:new(unit)
    local object = {}
    self.__index = self
    setmetatable(object, self)
    self.Unit    = unit
    self.UnitDef = GameInfo.Units[unit:GetType()]
    return object
end

--||====================Based functions===================||--

--检查单位是否拥有战斗力 (GamePlay, UI)
function AzurUnit:HasStrength()
    local unit = self.Unit
    return unit and (unit:GetCombat() > 0 or unit:GetRangedCombat() > 0 or unit:GetBombardCombat() > 0)
end

-- 检查单位是否是军事单位 (GamePlay, UI)
function AzurUnit:IsMilitary()
    local unitInfo = self.UnitDef
    if unitInfo == nil then return false end
    local unitFormation = unitInfo.FormationClass
    return unitFormation == 'FORMATION_CLASS_LAND_COMBAT'
        or unitFormation == 'FORMATION_CLASS_NAVAL'
        or unitFormation == 'FORMATION_CLASS_AIR'
end

--比较单位，如果新单位强度高与本单位则返回true (GamePlay, UI)
function AzurUnit:CompareUnitDef(newDef)
    if newDef == nil then return false end
    local oldDef = self.UnitDef
    if oldDef == nil then return true end
    -- 近战战斗力比较
    if oldDef.Combat ~= newDef.Combat then
        return oldDef.Combat < newDef.Combat
    end
    -- 远程战斗力比较
    if oldDef.RangedCombat ~= newDef.RangedCombat then
        return oldDef.RangedCombat < newDef.RangedCombat
    end
    -- 轰炸战斗力比较
    if oldDef.Bombard ~= newDef.Bombard then
        return oldDef.Bombard < newDef.Bombard
    end
    -- 攻击范围比较
    if oldDef.Range ~= newDef.Range then
        return oldDef.Range < newDef.Range
    end
    -- 移动速度比较
    return oldDef.BaseMoves < newDef.BaseMoves
end

--获取单位可用能力 (GamePlay, UI)
function AzurUnit:QueryUsableAbilities()
    local unit = self.Unit
    --获取tag表
    local tags = { CLASS_ALL_UNITS = true }
    if self:HasStrength() then
        tags.CLASS_ALL_COMBAT_UNITS = true
    end
    local type = self.UnitDef.UnitType
    for row in GameInfo.TypeTags() do
        if row.Type == type then
            tags[row.Tag] = true
        end
    end
    --获取能力键表
    local abilityTag = {}
    for row in GameInfo.UnitAbilities() do
        local abilityType = row.UnitAbilityType
        for r in GameInfo.TypeTags() do
            if r.Type == abilityType and tags[r.Tag] == true then
                abilityTag[row.Index] = true
            end
        end
    end
    --获取单位已拥有能力
    local unitAbility = unit:GetAbility()
    local hasAbilities = unitAbility:GetAbilities()
    for _, v in ipairs(hasAbilities) do
        abilityTag[v] = nil
    end
    --键值对转换
    local abilities = {}
    for index, _ in pairs(abilityTag) do
        table.insert(abilities, index)
    end
    return abilities
end

--获取单位可用能力 (GamePlay)
function AzurUnit:GetUsableAbilities()
    local abilities = {}
    local unitAbility = self.Unit:GetAbility()
    for row in GameInfo.UnitAbilities() do
        local index = row.Index
        if unitAbility:CanHaveAbility(index)
            and not unitAbility:HasAbility(index) then
            table.insert(abilities, index)
        end
    end
    return abilities
end

--单位获得随机能力 (GamePlay)
function AzurUnit:GetRandomAbility()
    local abilities = self:GetUsableAbilities()
    if #abilities == 0 then return false end

    local random = abilities[AzurLaneCore.tableRandom(#abilities)]
    local unit = self.Unit
    unit:GetAbility():ChangeAbilityCount(random, 1)
    --add the float text
    local abilityDef = GameInfo.UnitAbilities[random]

    local show = abilityDef.ShowFloatTextWhenEarned
    local name = abilityDef.Name

    if show ~= true and name and name ~= Locale.Lookup(name) then
        local message = Locale.Lookup(name)
        --add the message text
        local messageData = {
            MessageType = 0,
            MessageText = message,
            PlotX       = unit:GetX(),
            PlotY       = unit:GetY(),
            Visibility  = RevealedState.VISIBLE,
        }; Game.AddWorldViewText(messageData)
    end
    return true
end
