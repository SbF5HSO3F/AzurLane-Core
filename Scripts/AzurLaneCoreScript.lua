-- AzurLaneCoreScript
-- Author: jjj
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

--随机数生成器，范围为[1,num+1] (GamePlay, UI)
function AzurLaneCore.tableRandom(num)
    return Game.GetRandNum and (Game.GetRandNum(num) + 1) or 1
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

--检测单元格是否满足A*算法的条件 (UI)
function AzurLaneCore.CheckPlot(pPlot)
    --can pass?
    if pPlot:IsImpassable() then return false end
    --is lake?
    if pPlot:IsLake() then return false end
    --is viasble?
    local visibility = PlayersVisibility[Game.GetLocalPlayer()]
    if not visibility:IsRevealed(pPlot:GetX(), pPlot:GetY()) then
        return false
    end; return true
end

--获取A*算法的路径点相邻单元格 (GamePlay, UI)
function AzurLaneCore:GetNodeNeighbor(node, eIndex)
    local neighbors = {}
    if node then
        local pPlot = Map.GetPlotByIndex(node.Index)
        local x, y = pPlot:GetX(), pPlot:GetY()
        for _, plot in ipairs(Map.GetAdjacentPlots(x, y)) do
            if self.CheckPlot(plot) then
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

--A*寻路算法 (GamePlay, UI)
function AzurLaneCore:AStar(startX, startY, endX, endY)
    --返回的结果
    local results = {}
    --起点与终点不为nil
    if not (startX and startY and endX and endY) then return results end
    --获得起点单元格和终点单元格
    local s_plot = Map.GetPlot(startX, startY)
    local e_plot = Map.GetPlot(endX, endY)
    --起点与终点单元格不为nil或起点与终点相同
    if not (s_plot and e_plot) or s_plot == e_plot then return results end
    --获得起点和终点单元格的索引
    local s_index, e_index = s_plot:GetIndex(), e_plot:GetIndex()
    --初始化开始表格和关闭集合
    local openTable, closeSet = {}, {}
    --开始表格加入起点节点
    table.insert(openTable, self:GetAStarNode(s_index, e_index, nil))
    --开始寻路
    while #openTable > 0 do
        --获得F值最小的节点
        local currentIndex = 1
        local current = openTable[currentIndex]
        for i = 2, #openTable do
            local currentNode = openTable[i]
            if currentNode.F < current.F or (currentNode.F == current.F and currentNode.H < current.H) then
                current = currentNode
                currentIndex = i
            end
        end

        table.remove(openTable, currentIndex)

        --达到终点，构造路径
        if current.Index == e_index then
            while current do
                table.insert(results, current.Index)
                current = current.Parent
            end
            return results
        end

        closeSet[current.Index] = true

        --获取节点相邻单元格
        for _, neighbor in ipairs(self:GetNodeNeighbor(current, e_index)) do
            local neighborIndex = neighbor.Index
            --如果不在关闭集合，进行处理
            if not closeSet[neighborIndex] then
                --获取 G/H/F 值
                local G = neighbor.G
                local H = neighbor.H
                local F = neighbor.F
                --如果在开放表格中，更新G值
                local isInOpenTable = false
                for _, openNode in ipairs(openTable) do
                    if openNode.Index == neighborIndex then
                        isInOpenTable = true
                        if G < openNode.G then
                            --更新 G/H/F 值
                            openNode.G = G
                            openNode.H = H
                            openNode.F = F
                            openNode.Parent = current
                        end
                        break
                    end
                end

                --如果不在开放表格中，加入开放表格
                if not isInOpenTable then
                    neighbor.G = G
                    neighbor.H = H
                    neighbor.F = F
                    neighbor.Parent = current
                    table.insert(openTable, neighbor)
                end
            end
        end
    end
    return results
end

--||=====================GamePlay=======================||--
--这些函数只可在GamePlay环境下使用

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
                        self.HasBoost(row.TechnologyType))
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
                        self.HasBoost(row.CivicType))
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
