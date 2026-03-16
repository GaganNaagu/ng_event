-- framework/qbox/server.lua
-- Abstraction layer for QBox framework (SERVER)

Framework = {}

function Framework.GetPlayer(src)
    return exports.qbx_core:GetPlayer(src)
end

function Framework.GetPlayerCitizenId(src)
    local Player = exports.qbx_core:GetPlayer(src)
    if Player and Player.PlayerData and Player.PlayerData.citizenid then
        return Player.PlayerData.citizenid
    end
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if string.find(id, "license:") then return id end
    end
    return tostring(src)
end

function Framework.RevivePlayer(src)
    exports.qbx_medical:Revive(src, true)
end

function Framework.ClearInventory(src)
    exports.ox_inventory:ClearInventory(src)
end

function Framework.GetInventory(src)
    return exports.ox_inventory:GetInventory(src)
end

function Framework.AddItem(src, item, amount, metadata, slot)
    exports.ox_inventory:AddItem(src, item, amount, metadata, slot)
end

function Framework.IsAdmin(src)
    return exports.qbx_core:HasPermission(src, 'admin') or IsPlayerAceAllowed(src, 'command')
end

