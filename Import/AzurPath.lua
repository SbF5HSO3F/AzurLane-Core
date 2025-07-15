-- AzurPath
-- Author: HSbF6HSO3F
-- DateCreated: 2025/7/15 11:01:40
--------------------------------------------------------------
--||=======================include========================||--
include('AzurLaneCoreScript')

--||======================MetaTable=======================||--

-- AzurPath 用于使用双向A*算法创建游戏内路径
AzurPath = {}

--||====================Based functions===================||--

--检测单元格是否满足A*算法的条件 (GamePlay, UI)
function AzurPath.CheckPlot(pPlot, playerID)
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

--获取A*算法的单元格的G值 (GamePlay, UI)
function AzurPath.GetPlotG(index)
    local pPlot = Map.GetPlotByIndex(index)
    return pPlot and (pPlot:GetRouteType() ~= -1 and 1 or (pPlot:IsWater() and 20 or 5)) or 5
end

--获取A*算法的路径点 (GamePlay, UI)
function AzurPath:GetAStarNode(sIndex, eIndex, parent)
    --获取单元格对象
    local startPlot = Map.GetPlotByIndex(sIndex)
    -- H/G 的默认值
    local H, G = 0, 0
    --如果有终点，计算H
    if eIndex then
        local endPlot = Map.GetPlotByIndex(eIndex)
        --计算距离
        H = AzurLaneCore.GetDistance(startPlot, endPlot)
    end
    --如果有母节点，计算G
    if parent then G = self.GetPlotG(sIndex) + parent.G end
    --创建节点
    return { Index = sIndex, G = G, H = H, F = G + H, Parent = parent }
end

--获取A*算法的路径点相邻单元格 (GamePlay, UI)
function AzurPath:GetNodeNeighbor(node, eIndex, playerID)
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

--寻找F为最小值的节点 (GamePlay, UI)
function AzurPath.GetMinFNode(openTable)
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
function AzurPath.GetMeetNode(index, openTable)
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
function AzurPath.BuildPath(path, node, meetNode)
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
function AzurPath:ExpandNeighbors(node, openTable, closeSet, eIndex, playerID)
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
function AzurPath:AStar(startX, startY, endX, endY, playerID)
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
