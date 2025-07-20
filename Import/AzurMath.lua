-- AzurMath
-- Author: HSbF6HSO3F
-- DateCreated: 2025/7/15 12:52:52
--------------------------------------------------------------
--||======================MetaTable=======================||--

-- AzurMath 用于数学相关的处理
AzurMath = {}

--||====================Based functions===================||--

--数字不小于其1位小数处理 (GamePlay, UI)
function AzurMath.Ceil(num)
    return math.ceil(num * 10) / 10
end

--数字不大于其1位小数处理 (GamePlay, UI)
function AzurMath.Floor(num)
    return math.floor(num * 10) / 10
end

-- 数字四舍五入 (GamePlay, UI)
function AzurMath.Round(num)
    return math.floor((num + 0.05) * 10) / 10
end

--||====================Modify functions==================||--

-- 将输入的数字按照百分比进行修正 (GamePlay, UI)
function AzurMath:ModifyByPercent(num, percent, effect)
    return self.Round(num * (effect and percent or (100 + percent)) / 100)
end

-- 将输入的数字按照当前游戏速度进行修正 (GamePlay, UI)
function AzurMath:ModifyBySpeed(num)
    local gameSpeed = GameInfo.GameSpeeds[GameConfiguration.GetGameSpeedType()]
    if gameSpeed then num = self.Round(num * gameSpeed.CostMultiplier / 100) end
    return num
end

--||====================Random functions==================||--

-- 随机数生成器，范围为[1,num] (GamePlay)
function AzurMath.GetRandNum(num)
    return Game.GetRandNum and (Game.GetRandNum(num) + 1) or 1
end

-- 随机数生成器，范围为[x,y] (GamePlay)
function AzurMath:GetRandom(x, y)
    y = math.max(x, y)
    if x == y then return x end
    local a = x - 1
    local n = y - a
    return self.GetRandNum(n) + a
end
