-- AzurYields
-- Author: HSbF6HSO3F
-- DateCreated: 2025/7/20 20:39:20
--------------------------------------------------------------
--||=======================include========================||--
include('AzurCore')

--||======================MetaTable=======================||--

AzurYields = {
    -- 默认
    ['DEFAULT'] = {
        Tooltip = 'LOC_AZURLANE_YIELD_GOLD',
        Floater = 'LOC_AZURLANE_YIELD_GOLD_FLOAT',
        GrantYieldAtXY = function(self, playerId, amount, x, y)
            local player = Players[playerId]
            if player == nil then return end
            -- 获得产出
            local treasury = player:GetTreasury()
            treasury:ChangeGoldBalance(amount)
            -- 世界文本
            local float = Locale.Lookup(self.Floater, amount)
            local messageData = {
                MessageType = 0,
                MessageText = float,
                PlotX       = x,
                PlotY       = y,
                Visibility  = RevealedState.VISIBLE,
            }; Game.AddWorldViewText(messageData)
        end,
        GetTooltip = function(self, amount)
            return Locale.Lookup(self.Tooltip, amount)
        end
    },
    -- 科技值
    ['YIELD_SCIENCE'] = {
        Tooltip = 'LOC_AZURLANE_YIELD_SCIENCE',
        Floater = 'LOC_AZURLANE_YIELD_SCIENCE_FLOAT',
        GrantYieldAtXY = function(self, playerId, amount, x, y)
            local player = Players[playerId]
            if player == nil then return end
            -- 获得产出
            local tech = player:GetTechs()
            tech:ChangeCurrentResearchProgress(amount)
            -- 世界文本
            local float = Locale.Lookup(self.Floater, amount)
            local messageData = {
                MessageType = 0,
                MessageText = float,
                PlotX       = x,
                PlotY       = y,
                Visibility  = RevealedState.VISIBLE,
            }; Game.AddWorldViewText(messageData)
        end,
        GetTooltip = function(self, amount)
            return Locale.Lookup(self.Tooltip, amount)
        end
    },
    -- 文化值
    ['YIELD_CULTURE'] = {
        Tooltip = 'LOC_AZURLANE_YIELD_CULTURE',
        Floater = 'LOC_AZURLANE_YIELD_CULTURE_FLOAT',
        GrantYieldAtXY = function(self, playerId, amount, x, y)
            local player = Players[playerId]
            if player == nil then return end
            -- 获得产出
            local culture = player:GetCulture()
            culture:ChangeCurrentCulturalProgress(amount)
            -- 世界文本
            local float = Locale.Lookup(self.Floater, amount)
            local messageData = {
                MessageType = 0,
                MessageText = float,
                PlotX       = x,
                PlotY       = y,
                Visibility  = RevealedState.VISIBLE,
            }; Game.AddWorldViewText(messageData)
        end,
        GetTooltip = function(self, amount)
            return Locale.Lookup(self.Tooltip, amount)
        end
    },
    -- 金币
    ['YIELD_GOLD'] = {
        Tooltip = 'LOC_AZURLANE_YIELD_GOLD',
        Floater = 'LOC_AZURLANE_YIELD_GOLD_FLOAT',
        GrantYieldAtXY = function(self, playerId, amount, x, y)
            local player = Players[playerId]
            if player == nil then return end
            -- 获得产出
            local treasury = player:GetTreasury()
            treasury:ChangeGoldBalance(amount)
            -- 世界文本
            local float = Locale.Lookup(self.Floater, amount)
            local messageData = {
                MessageType = 0,
                MessageText = float,
                PlotX       = x,
                PlotY       = y,
                Visibility  = RevealedState.VISIBLE,
            }; Game.AddWorldViewText(messageData)
        end,
        GetTooltip = function(self, amount)
            return Locale.Lookup(self.Tooltip, amount)
        end
    },
    -- 信仰值
    ['YIELD_FAITH'] = {
        Tooltip = 'LOC_AZURLANE_YIELD_FAITH',
        Floater = 'LOC_AZURLANE_YIELD_FAITH_FLOAT',
        GrantYieldAtXY = function(self, playerId, amount, x, y)
            local player = Players[playerId]
            if player == nil then return end
            -- 获得产出
            local religion = player:GetReligion()
            religion:ChangeFaithBalance(amount)
            -- 世界文本
            local float = Locale.Lookup(self.Floater, amount)
            local messageData = {
                MessageType = 0,
                MessageText = float,
                PlotX       = x,
                PlotY       = y,
                Visibility  = RevealedState.VISIBLE,
            }; Game.AddWorldViewText(messageData)
        end,
        GetTooltip = function(self, amount)
            return Locale.Lookup(self.Tooltip, amount)
        end
    },
    -- 生产力
    ['YIELD_PRODUCTION'] = {
        Tooltip = 'LOC_AZURLANE_YIELD_PRODUCTION',
        Floater = 'LOC_AZURLANE_YIELD_PRODUCTION_FLOAT',
        GrantYieldAtXY = function(self, playerId, amount, x, y)
            local player = Players[playerId]
            if player == nil then return end
            -- 获得产出
            local cities, city = player:GetCities(), nil
            if x == nil or y == nil then
                city = cities:GetCapitalCity()
            else
                city = cities:FindClosest(x, y)
            end
            if city == nil then return end
            city:GetBuildQueue():AddProgress(amount)
            -- 世界文本
            local float = Locale.Lookup(self.Floater, amount)
            local messageData = {
                MessageType = 0,
                MessageText = float,
                PlotX       = x,
                PlotY       = y,
                Visibility  = RevealedState.VISIBLE,
            }; Game.AddWorldViewText(messageData)
        end,
        GetTooltip = function(self, amount)
            return Locale.Lookup(self.Tooltip, amount)
        end
    }
}

--||====================Based functions===================||--

-- 获得产出对象
function AzurYields:GetYield(yieldType)
    if type(yieldType) ~= 'string' then
        return self['DEFAULT']
    end
    return self[yieldType] or self['DEFAULT']
end

-- 玩家获得特定产出
function AzurYields:GrantYieldAtXY(playerId, yieldType, amount, x, y)
    self:GetYield(yieldType):GrantYieldAtXY(playerId, amount, x, y)
end

--||=======================include========================||--
include('AzurYields_', true)