-- AzurDebug
-- Author: HSbF6HSO3F
-- DateCreated: 2025/7/15 11:01:15
--------------------------------------------------------------
--||======================MetaTable=======================||--

AzurDebug = {}

--||====================Based functions===================||--

function AzurDebug:printd(t, tab, title)
    if type(t) == 'table' then
        tab = tab or ''
        if title then print(title) end
        local td = {}
        for k, v in pairs(t) do
            if type(v) == 'table' then
                table.insert(td, { tab .. '├', k, true })
            else
                table.insert(td, { tab .. '├', k, tostring(v) })
            end
        end
        local c = #td
        if c == 0 then return end
        td[c][1] = tab .. '└'
        for i, str in ipairs(td) do
            if str[3] == true then
                local tabs = tab .. (i == c and ' ' or '│')
                local index = str[2]
                self:printd(t[index], tabs, str[1] .. index)
            else
                print(str[1] .. str[2] .. ': ' .. str[3])
            end
        end
    else
        print((tab or '') .. (title and (title .. ': ') or '') .. tostring(t))
    end
end
