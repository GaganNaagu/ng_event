-- levels/level4_abyssal_descent/server.lua
-- Server logic for Abyssal Descent (Underwater Chest Search)

local Level4 = {
    activeChest = 0 
}

local function ShuffleChest()
    local count = #Config.Levels[4].chestLocations
    local newIndex = math.random(1, count)
    
    if newIndex == Level4.activeChest and count > 1 then
        newIndex = (newIndex % count) + 1
    end
    Level4.activeChest = newIndex
    DebugPrint("^5[L4-CHEST] Token shuffled to chest " .. Level4.activeChest .. " / " .. count .. "^7")
end

function Level4.SetupPlayer(src)
    -- Start logic handled on client side based on proxy or level confirm
end

function Level4.PlayerDied(src)
    local data = PlayerManager.GetPlayer(src)
    if not data or data.confirmedLevel ~= 4 then return end

    local ped = GetPlayerPed(src)
    local loc = Config.Levels[4].spawnCoords

    if loc then
        Framework.RevivePlayer(src)
        SetEntityCoords(ped, loc.x, loc.y, loc.z, false, false, false, false)
        SetEntityHeading(ped, loc.w)
    end
end

function Level4.Cleanup()
    Level4.activeChest = 0
end

LevelManager.RegisterLevel(4, Level4)

AddEventHandler('ng_event:server:UnlockLevel', function(level)
    if level == 4 then
        ShuffleChest()
    end
end)

RegisterNetEvent("ng_event:server:LootChest4", function(chestIndex)
    local src = source
    local data = PlayerManager.GetPlayer(src)
    if not data then return end
    
    if data.pendingLevel == 4 then
        TransitionManager.ConfirmLevelEntry(src)
    end
    
    if data.confirmedLevel ~= 4 or data.tokens[4] then return end
    if type(chestIndex) ~= "number" then return end

    if chestIndex == Level4.activeChest then
        LevelManager.PlayerCompleted(src, 4)

        TriggerClientEvent("ng_event:client:ShowNotification", src, {
            title = "Event",
            description = "Correct chest! Token 4 acquired. Follow GPS to Level 5.",
            type = "success"
        })
        TriggerClientEvent("ng_event:client:HideLevel4Blip", src)
        TriggerClientEvent("ng_event:client:ShowLevel5Blip", src)

        ShuffleChest()
    else
        TriggerClientEvent("ng_event:client:ShowNotification", src, {
            title = "Event",
            description = "Empty chest! The token is hidden elsewhere...",
            type = "error"
        })
    end
end)
