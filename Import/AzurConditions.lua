-- AzurConditions
-- Author: HSbF6HSO3F
-- DateCreated: 2025/3/6 14:13:23
--------------------------------------------------------------
--||======================MetaTable=======================||--

-- AzurConditions用于创建条件判断的文本，用于游戏的显示
AzurConditions = {}

--||===================local variables====================||--

local tab1 = '[ICON_AzurTab0]' -- '├'
local tab2 = '[ICON_AzurTab1]' -- '│'
local tab3 = '[ICON_AzurTab2]' -- '└'
local tab4 = '[ICON_AzurTab3]' -- ' '

--||====================Based functions===================||--

--获取条件集合的标题
function AzurConditions:GetTitle(conditions)
    if conditions.Title then
        return conditions.Title
    else
        if conditions.All == true then
            return Locale.Lookup('LOC_AZURLANE_CONDITIONS_AND')
        else
            return Locale.Lookup('LOC_AZURLANE_CONDITIONS_OR')
        end
    end
end

--创建条件判断的文本
function AzurConditions:Create(conditions, tab, output)
    --制表字符
    tab = tab or ''
    --定义输出的文本集合
    local tooltips = {}
    --定义条件的表
    local sets = {}
    for i, set in ipairs(conditions.Sets) do
        if type(set) == 'table' then
            table.insert(sets, { tab .. tab1, i, true })
        else
            table.insert(sets, { tab .. tab1, i, set })
        end
    end
    --完毕，获取条件数量
    local sc = #sets
    if sc == 0 then return '' end
    --设置最后一个元素的分隔符
    sets[sc][1] = tab .. tab3
    --遍历条件
    for i, set in ipairs(sets) do
        --如果该条件是条件集合，则递归调用
        if set[3] == true then
            --设置缩进
            local ntab = tab .. (i == sc and tab4 or tab2)
            local subset = conditions.Sets[set[2]]
            --获取子条件集合
            local subSets = self:Create(subset, ntab)
            --如果子条件集合不为空，则添加到tooltips中
            if subSets ~= '' then
                local title = self:GetTitle(subset)
                table.insert(tooltips, set[1] .. title)
                for _, t in ipairs(subSets) do
                    table.insert(tooltips, t)
                end
            end
        else
            --否则，直接添加到tooltips中
            table.insert(tooltips, set[1] .. set[3])
        end
    end
    --如果输出为true，则返回tooltips，否则返回数组或字符串
    if output == true then
        local tooltip = ''
        for _, tip in ipairs(tooltips) do
            tooltip = tooltip .. '[NEWLINE]' .. tip
        end
        return tooltip
    else
        return tooltips
    end
end

--创建条件判断的文本，附带标题
function AzurConditions:CreateTooltip(conditions)
    local title = '[NEWLINE]' .. self:GetTitle(conditions)
    return title .. self:Create(conditions, nil, true)
end
