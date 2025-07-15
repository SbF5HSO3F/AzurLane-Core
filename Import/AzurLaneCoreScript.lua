-- AzurLaneCoreScript
-- Author: HSbF6HSO3F
-- DateCreated: 2024/10/10 21:10:53
--------------------------------------------------------------
--建立代码框架
AzurLaneCore = {}

--||====================GamePlay, UI======================||--
--通用函数

--判断领袖，玩家不为指定领袖类型则返回false (GamePlay, UI)
function AzurLaneCore.CheckLeaderMatched(playerID, leaderType)
    local pPlayerConfig = playerID and PlayerConfigurations[playerID]
    return pPlayerConfig and pPlayerConfig:GetLeaderTypeName() == leaderType
end

--判断文明，玩家文明不为指定文明类型则返回false (GamePlay, UI)
function AzurLaneCore.CheckCivMatched(playerID, civilizationType)
    local pPlayerConfig = playerID and PlayerConfigurations[playerID]
    return pPlayerConfig and pPlayerConfig:GetCivilizationTypeName() == civilizationType
end

--数字四舍五入处理 (GamePlay, UI)
function AzurLaneCore.Round(num)
    return math.floor((num + 0.05) * 10) / 10
end

--将输入的数字按照当前游戏速度进行修正 (GamePlay, UI)
function AzurLaneCore:ModifyBySpeed(num)
    local gameSpeed = GameInfo.GameSpeeds[GameConfiguration.GetGameSpeedType()]
    if gameSpeed then num = self.Round(num * gameSpeed.CostMultiplier / 100) end
    return num
end

--检查table中是否有指定元素 (GamePlay, UI)
function AzurLaneCore.include(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

--检查科技或者市政是否拥有提升 (GamePlay, UI)
function AzurLaneCore.HasBoost(techOrCivic)
    for boost in GameInfo.Boosts() do
        if techOrCivic == boost.TechnologyType or techOrCivic == boost.CivicType then
            return true
        end
    end
    return false
end

--获得玩家游戏进度。返回为百分比，需除以100 (GamePlay, UI)
function AzurLaneCore:GetPlayerProgress(playerID)
    local pPlayer = Players[playerID]
    if pPlayer == nil then return 0 end
    local playerTech = pPlayer:GetTechs()
    local techNum, techedNum = 0, 0
    for row in GameInfo.Technologies() do
        techNum = techNum + 1
        if playerTech:HasTech(row.Index) then
            techedNum = (techedNum or 0) + 1
        end
    end
    local playerCulture = pPlayer:GetCulture()
    local civicNum, civicedNum = 0, 0
    for row in GameInfo.Civics() do
        civicNum = civicNum + 1
        if playerCulture:HasCivic(row.Index) then
            civicedNum = (civicedNum or 0) + 1
        end
    end
    local civicProgress = civicNum ~= 0 and civicedNum / civicNum or 0
    local techProgress = techNum ~= 0 and techedNum / techNum or 0
    return self.Round(100 * math.max(techProgress, civicProgress))
end

--获取两个对象之间的距离 (GamePlay, UI)
function AzurLaneCore.GetDistance(object_1, object_2)
    local result = 0
    if object_1 and object_2 then
        result = Map.GetPlotDistance(
            object_1:GetX(), object_1:GetY(),
            object_2:GetX(), object_2:GetY()
        )
    end; return result
end

--获取A*算法的路径点 (GamePlay, UI)
function AzurLaneCore:GetAStarNode(sIndex, eIndex, parent)
    --获取单元格对象
    local startPlot = Map.GetPlotByIndex(sIndex)
    -- H/G 的默认值
    local H, G = 0, 0
    --如果有终点，计算H
    if eIndex then
        local endPlot = Map.GetPlotByIndex(eIndex)
        --计算距离
        H = self.GetDistance(startPlot, endPlot)
    end
    --如果有母节点，计算G
    if parent then
        G = self.GetPlotG(sIndex) + parent.G
    end
    --创建节点
    local node = {
        Index = sIndex,
        G = G,
        H = H,
        F = G + H,
        Parent = parent
    }; return node
end

--检测单元格是否满足A*算法的条件 (GamePlay, UI)
function AzurLaneCore.CheckPlot(pPlot, playerID)
    --can pass?
    if pPlot:IsImpassable() then return false end
    --is lake?
    if pPlot:IsLake() then return false end
    --is viasble?
    local visibility = PlayersVisibility[playerID]
    if not visibility:IsRevealed(pPlot:GetX(), pPlot:GetY()) then
        return false
    end; return true
end

--获取A*算法的路径点相邻单元格 (GamePlay, UI)
function AzurLaneCore:GetNodeNeighbor(node, eIndex, playerID)
    local neighbors = {}
    if node then
        local pPlot = Map.GetPlotByIndex(node.Index)
        local x, y = pPlot:GetX(), pPlot:GetY()
        for _, plot in ipairs(Map.GetAdjacentPlots(x, y)) do
            if self.CheckPlot(plot, playerID) then
                table.insert(neighbors, self:GetAStarNode(plot:GetIndex(), eIndex, node))
            end
        end
    end; return neighbors
end

--获取A*算法的单元格的G值 (GamePlay, UI)
function AzurLaneCore.GetPlotG(index)
    local pPlot = Map.GetPlotByIndex(index)
    return pPlot and (pPlot:GetRouteType() ~= -1 and 1 or (pPlot:IsWater() and 20 or 5)) or 5
end

--寻找F为最小值的节点 (GamePlay, UI)
function AzurLaneCore.GetMinFNode(openTable)
    local currentIndex = 1
    local current = openTable[currentIndex]
    for i = 2, #openTable do
        local currentNode = openTable[i]
        if currentNode.F < current.F or (currentNode.F == current.F and currentNode.H < current.H) then
            current = currentNode
            currentIndex = i
        end
    end
    return table.remove(openTable, currentIndex)
end

--获取相遇节点，没有相遇则返回nil (GamePlay, UI)
function AzurLaneCore.GetMeetNode(index, openTable)
    local meetNode = nil
    for _, node in ipairs(openTable) do
        if node.Index == index then
            meetNode = node
            break
        end
    end
    return meetNode
end

--构建路径 (GamePlay, UI)
function AzurLaneCore.BuildPath(path, node, meetNode)
    local pathFromStart = {}
    local pathFromEnd = {}
    --获得从起点到相遇点的路径
    while node do
        table.insert(pathFromStart, node.Index)
        node = node.Parent
    end
    --获得从终点到相遇点的路径
    node = meetNode.Parent
    while node do
        table.insert(pathFromEnd, node.Index)
        node = node.Parent
    end
    --倒转添加从起点到相遇点的路径
    for i = #pathFromStart, 1, -1 do
        table.insert(path, pathFromStart[i])
    end
    --添加从终点到相遇点的路径
    for i = 1, #pathFromEnd do
        table.insert(path, pathFromEnd[i])
    end
end

--扩展相邻节点 (GamePlay, UI)
function AzurLaneCore:ExpandNeighbors(node, openTable, closeSet, eIndex, playerID)
    --获取相邻节点
    for _, neighbor in ipairs(self:GetNodeNeighbor(node, eIndex, playerID)) do
        local neighborIndex = neighbor.Index
        --如果节点不在关闭集合中
        if not closeSet[neighborIndex] then
            --获取 G/H/F 值
            local G = neighbor.G
            local H = neighbor.H
            local F = neighbor.F
            --如果该节点位于开放表格中，更新 G/H/F 值
            local isInOpenTable = false
            for _, openNode in ipairs(openTable) do
                if openNode.Index == neighborIndex then
                    isInOpenTable = true
                    if G < openNode.G then
                        --update the G/H/F
                        openNode.G = G
                        openNode.H = H
                        openNode.F = F
                        openNode.Parent = node
                    end
                    break
                end
            end
            --否则加入开放表格
            if not isInOpenTable then
                neighbor.G = G
                neighbor.H = H
                neighbor.F = F
                neighbor.Parent = node
                table.insert(openTable, neighbor)
            end
        end
    end
end

--A*寻路算法，双向 (GamePlay, UI)
function AzurLaneCore:AStar(startX, startY, endX, endY, playerID)
    --返回的结果
    local results = {}
    --起点与终点，还有玩家ID不为nil
    if not (startX and startY and endX and endY and playerID) then return results end
    --获得起点单元格和终点单元格
    local s_plot = Map.GetPlot(startX, startY)
    local e_plot = Map.GetPlot(endX, endY)
    --起点与终点单元格不为nil或起点与终点相同
    if not (s_plot and e_plot) or s_plot == e_plot then return results end
    --获得起点和终点单元格的索引
    local s_index, e_index = s_plot:GetIndex(), e_plot:GetIndex()
    --初始化起点开始表格和关闭集合
    local openTableS, openTableE = {}, {}
    --初始化终点开始表格和关闭集合
    local closeSetS, closeSetE = {}, {}
    --起点开始表格加入起点节点
    table.insert(openTableS, self:GetAStarNode(s_index, e_index, nil))
    --终点开始表格加入终点节点
    table.insert(openTableE, self:GetAStarNode(e_index, s_index, nil))
    --中转节点和相遇节点
    local middleNode, meetNode = nil, nil
    --开始寻路
    while #openTableS > 0 and #openTableE > 0 do
        --获得F值最小的节点
        middleNode = self.GetMinFNode(openTableS)
        meetNode = self.GetMeetNode(middleNode.Index, openTableE)

        --如果中转节点和相遇节点都存在，则找到路径并返回
        if middleNode and meetNode then
            --build the path
            self.BuildPath(results, middleNode, meetNode)
            return results
        end

        closeSetS[middleNode.Index] = true
        --扩展相邻节点
        self:ExpandNeighbors(middleNode, openTableS, closeSetS, e_index, playerID)

        --获得F值最小的节点
        middleNode = self.GetMinFNode(openTableE)
        meetNode = self.GetMeetNode(middleNode.Index, openTableS)

        --如果中转节点和相遇节点都存在，则找到路径并返回
        if middleNode and meetNode then
            --build the path
            self.BuildPath(results, middleNode, meetNode)
            return results
        end

        closeSetE[middleNode.Index] = true
        --扩展相邻节点
        self:ExpandNeighbors(middleNode, openTableE, closeSetE, e_index, playerID)
    end
    return results
end

--比较单位，如果单位2强度高于单位1则返回true (GamePlay, UI)
function AzurLaneCore.CompareUnitDef(unit1Def, unit2Def)
    if unit1Def == nil then return true end
    if unit2Def == nil then return false end

    if unit1Def.Combat ~= unit2Def.Combat then
        return unit1Def.Combat < unit2Def.Combat
    end

    if unit1Def.RangedCombat ~= unit2Def.RangedCombat then
        return unit1Def.RangedCombat < unit2Def.RangedCombat
    end

    if unit1Def.Bombard ~= unit2Def.Bombard then
        return unit1Def.Bombard < unit2Def.Bombard
    end

    if unit1Def.Range ~= unit2Def.Range then
        return unit1Def.Range < unit2Def.Range
    end

    return unit1Def.BaseMoves < unit2Def.BaseMoves
end

--检查单位是否拥有战斗力 (GamePlay, UI)
function AzurLaneCore.HasStrength(unit)
    return unit and (unit:GetCombat() > 0 or unit:GetRangedCombat() > 0 or unit:GetBombardCombat() > 0)
end

--获取玩家宗教，已创建宗教则返回创建的宗教，没有则返回玩家的主流宗教，否则返回-1 (GamePlay, UI)
function AzurLaneCore.GetPlayerReligion(playerID)
    local pPlayer = Players[playerID]
    if pPlayer == nil then return -1 end
    local pPlayerReligion = Players[playerID]:GetReligion()
    if pPlayerReligion == nil then return -1 end
    if pPlayerReligion:GetReligionTypeCreated() ~= -1 then
        return pPlayerReligion:GetReligionTypeCreated()
    else
        return pPlayerReligion:GetReligionInMajorityOfCities()
    end
end

--判断单元格是否可以放置指定单位 (GamePlay, UI)
function AzurLaneCore.CanHaveUnit(plot, unitdef)
    if plot == nil then return false end
    local canHave = true
    for _, unit in ipairs(Units.GetUnitsInPlot(plot)) do
        if unit then
            local unitInfo = GameInfo.Units[unit:GetType()]
            if unitInfo then
                if unitInfo.IgnoreMoves == false then
                    if unitInfo.Domain == unitdef.Domain and unitInfo.FormationClass == unitdef.FormationClass then
                        canHave = false
                    end
                end
            end
        end
    end
    return canHave
end

--检查单位是否是军事单位 (GamePlay, UI)
function AzurLaneCore.IsMilitary(unit)
    if unit == nil then return false end
    local unitInfo = GameInfo.Units[unit:GetType()]
    if unitInfo == nil then return false end
    local unitFormation = unitInfo.FormationClass
    return unitFormation == 'FORMATION_CLASS_LAND_COMBAT'
        or unitFormation == 'FORMATION_CLASS_NAVAL'
        or unitFormation == 'FORMATION_CLASS_AIR'
end

--规范每回合价值显示 (GamePlay, UI)
function AzurLaneCore.FormatValue(value)
    if value == 0 then
        return Locale.ToNumber(value)
    else
        return Locale.Lookup("{1: number +#,###.#;-#,###.#}", value)
    end
end

--数字百分比修正 (GamePlay, UI)
function AzurLaneCore:ModifyByPercent(num, percent)
    return self.Round(num * (1 + percent / 100))
end

--获取玩家的区域数量 (GamePlay, UI)
function AzurLaneCore.GetPlayerDistrictCount(playerID, index)
    local pPlayer, count = Players[playerID], 0
    if not pPlayer then return count end
    local districts = pPlayer:GetDistricts()
    for _, district in districts:Members() do
        if district:GetType() == index and district:IsComplete() and (not district:IsPillaged()) then
            count = count + 1
        end
    end
    return count
end

--||=====================GamePlay=======================||--
--这些函数只可在GamePlay环境下使用

--随机数生成器，范围为[1,num+1] (GamePlay)
function AzurLaneCore.tableRandom(num)
    return Game.GetRandNum and (Game.GetRandNum(num) + 1) or 1
end

--玩家获得随机数量的尤里卡 (GamePlay)
function AzurLaneCore:GetRandomTechBoosts(playerID, iSource, num)
    local pPlayer = Players[playerID]
    local EraIndex = 1
    local playerTech = pPlayer:GetTechs()
    local limit = num or 1
    while limit > 0 do
        local EraType = nil
        for era in GameInfo.Eras() do
            if era.ChronologyIndex == EraIndex then
                EraType = era.EraType
                break
            end
        end
        if EraType then
            local techlist = {}
            for row in GameInfo.Technologies() do
                if not (playerTech:HasTech(row.Index) or
                        playerTech:HasBoostBeenTriggered(row.Index) or
                        not self.HasBoost(row.TechnologyType))
                    and row.EraType == EraType then
                    table.insert(techlist, row.Index)
                end
            end
            if #techlist > 0 then
                local iTech = techlist[self.tableRandom(#techlist)]
                playerTech:TriggerBoost(iTech, iSource)
                limit = limit - 1
            else
                EraIndex = (EraIndex or 0) + 1
            end
        else
            break
        end
    end
end

--玩家获得随机数量的鼓舞 (GamePlay)
function AzurLaneCore:GetRandomCivicBoosts(playerID, iSource, num)
    local pPlayer = Players[playerID]
    local EraIndex = 1
    local playerCulture = pPlayer:GetCulture()
    local limit = num or 1
    while limit > 0 do
        local EraType = nil
        for era in GameInfo.Eras() do
            if era.ChronologyIndex == EraIndex then
                EraType = era.EraType
                break
            end
        end
        if EraType then
            local civiclist = {}
            for row in GameInfo.Civics() do
                if not (playerCulture:HasCivic(row.Index) or
                        playerCulture:HasBoostBeenTriggered(row.Index) or
                        not self.HasBoost(row.CivicType))
                    and row.EraType == EraType then
                    table.insert(civiclist, row.Index)
                end
            end
            if #civiclist > 0 then
                local iCivic = civiclist[self.tableRandom(#civiclist)]
                playerCulture:TriggerBoost(iCivic, iSource)
                limit = limit - 1
            else
                EraIndex = (EraIndex or 0) + 1
            end
        else
            break
        end
    end
end

--对单位造成伤害，超出生命值则死亡 (GamePlay)
function AzurLaneCore.DamageUnit(unit, damage)
    local maxDamage = unit:GetMaxDamage()
    if (unit:GetDamage() + damage) >= maxDamage then
        unit:SetDamage(maxDamage)
        UnitManager.Kill(unit, false)
        return true
    else
        unit:ChangeDamage(damage)
        return false
    end
end

--传播宗教，以x,y为中心，向range范围内的城市施加pressure点宗教压力 (GamePlay)
function AzurLaneCore:SpreadReligion(playerID, x, y, range, pressure)
    local religion = self.GetPlayerReligion(playerID)
    if religion == -1 then return end
    for _, player in ipairs(Game.GetPlayers()) do
        local cities = player:GetCities()
        for _, city in cities:Members() do
            if city ~= nil and Map.GetPlotDistance(
                    x, y, city:GetX(), city:GetY()
                ) <= range then
                city:GetReligion():AddReligiousPressure(8, religion, pressure, playerID)
            end
        end
    end
end

--||=========================UI=========================||--

--获取城市生产详细信息 (UI)
function AzurLaneCore.GetProductionDetail(city)
    local details = { --城市生产详细信息
        --城市在生产什么
        Producting = false,
        IsBuilding = false,
        IsWonder   = false,
        IsDistrict = false,
        IsUnit     = false,
        IsProject  = false,
        --生产项目信息
        ItemType   = 'NONE',
        ItemName   = 'NONE',
        ItemIndex  = -1,
        --生产进度信息
        Progress   = 0,
        TotalCost  = 0,
        TurnsLeft  = 0
    }; if not city then return details end
    --获取城市生产队列，判断是否在生产
    local cityBuildQueue = city:GetBuildQueue()
    local productionHash = cityBuildQueue:GetCurrentProductionTypeHash()
    if productionHash ~= 0 then
        details.Producting = true
        --建筑、区域、单位、项目
        local pBuildingDef = GameInfo.Buildings[productionHash]
        local pDistrictDef = GameInfo.Districts[productionHash]
        local pUnitDef     = GameInfo.Units[productionHash]
        local pProjectDef  = GameInfo.Projects[productionHash]
        --判断城市当前进行的生产
        if pBuildingDef ~= nil then
            --获取索引，方便后续获取进度和总成本
            local index = pBuildingDef.Index
            --城市正在生产建筑
            details.IsBuilding = true
            --城市生产的建筑是奇观还是普通建筑
            details.IsWonder = pBuildingDef.IsWonder
            --城市生产的建筑类型
            details.ItemType = pBuildingDef.BuildingType
            --城市生产的建筑名称
            details.ItemName = Locale.Lookup(pBuildingDef.Name)
            --城市生产的建筑索引
            details.ItemIndex = index
            --生产进度和总成本
            details.Progress = cityBuildQueue:GetBuildingProgress(index)
            details.TotalCost = cityBuildQueue:GetBuildingCost(index)
        elseif pDistrictDef ~= nil then
            --获取索引，方便后续获取进度和总成本
            local index = pDistrictDef.Index
            --城市正在生产区域
            details.IsDistrict = true
            --城市生产的区域类型
            details.ItemType = pDistrictDef.DistrictType
            --城市生产的区域名称
            details.ItemName = Locale.Lookup(pDistrictDef.Name)
            --城市生产的区域索引
            details.ItemIndex = index
            --生产进度和总成本
            details.Progress = cityBuildQueue:GetDistrictProgress(index)
            details.TotalCost = cityBuildQueue:GetDistrictCost(index)
        elseif pUnitDef ~= nil then
            --获取索引，方便后续获取进度和总成本
            local index = pUnitDef.Index
            --城市正在生产单位
            details.IsUnit = true
            --城市生产的单位类型
            details.ItemType = pUnitDef.UnitType
            --城市生产的单位名称
            details.ItemName = Locale.Lookup(pUnitDef.Name)
            --城市生产的单位索引
            details.ItemIndex = index
            --生产进度
            details.Progress = cityBuildQueue:GetUnitProgress(index)
            --获取当前单位的军事形式，计算总成本
            local formation = cityBuildQueue:GetCurrentProductionTypeModifier()
            --是标准
            if formation == MilitaryFormationTypes.STANDARD_FORMATION then
                details.TotalCost = cityBuildQueue:GetUnitCost(index)
                --是军团
            elseif formation == MilitaryFormationTypes.CORPS_FORMATION then
                details.TotalCost = cityBuildQueue:GetUnitCorpsCost(index)
                --更新单位名称
                if pUnitDef.Domain == 'DOMAIN_SEA' then
                    details.ItemName = details.ItemName .. " " .. Locale.Lookup("LOC_UNITFLAG_FLEET_SUFFIX")
                else
                    details.ItemName = details.ItemName .. " " .. Locale.Lookup("LOC_UNITFLAG_CORPS_SUFFIX")
                end
                --是军队
            elseif formation == MilitaryFormationTypes.ARMY_FORMATION then
                details.TotalCost = cityBuildQueue:GetUnitArmyCost(index)
                --更新单位名称
                if pUnitDef.Domain == 'DOMAIN_SEA' then
                    details.ItemName = details.ItemName .. " " .. Locale.Lookup("LOC_UNITFLAG_ARMADA_SUFFIX")
                else
                    details.ItemName = details.ItemName .. " " .. Locale.Lookup("LOC_UNITFLAG_ARMY_SUFFIX")
                end
            end
        elseif pProjectDef ~= nil then
            --获取索引，方便后续获取进度和总成本
            local index = pProjectDef.Index
            --城市正在生产项目
            details.IsProject = true
            --城市生产的项目类型
            details.ItemType = pProjectDef.ProjectType
            --城市生产的项目名称
            details.ItemName = Locale.Lookup(pProjectDef.Name)
            --城市生产的项目索引
            details.ItemIndex = index
            --生产进度和总成本
            details.Progress = cityBuildQueue:GetProjectProgress(index)
            details.TotalCost = cityBuildQueue:GetProjectCost(index)
        end
        --生产所需回合
        details.TurnsLeft = cityBuildQueue:GetTurnsLeft()
    end
    return details
end
