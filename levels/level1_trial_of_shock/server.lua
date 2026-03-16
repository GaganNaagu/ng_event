-- levels/level1_trial_of_shock/server.lua
-- Server logic for Trial of Shock.

local Level1 = {}
local correctPanels = {}

function Level1.RandomizePanel()
    local cfg = Config.Levels[1]
    local targetCount = cfg.correctPanelsCount or 1
    
    correctPanels = {}
    local available = {}
    for i = 1, #cfg.panels do available[i] = i end
    
    for i = 1, targetCount do
        if #available == 0 then break end
        local r = math.random(1, #available)
        table.insert(correctPanels, available[r])
        table.remove(available, r)
    end
end

function Level1.SetupPlayer(src)
    TriggerClientEvent("ng_event:client:ShowLevel1Blip", src)
    if InventoryManager then InventoryManager.GiveLevelLoadout(src, 1) end
end

function Level1.PlayerDied(src)
    local data = PlayerManager.GetPlayer(src)
    if not data or data.confirmedLevel ~= 1 then return end

    local ped = GetPlayerPed(src)
    local gridLoc = Config.Levels[1].panels[1] 
    local pCoords = GetEntityCoords(ped)
    local reached = data.reachedL1Grid or (#(pCoords - gridLoc) < 150.0)

    local locs = reached and Config.Levels[1].respawnLocs or Config.Levels[1].spawnLocs
    local respawnLoc = nil
    if type(locs) == "table" and #locs > 0 then
        respawnLoc = locs[math.random(1, #locs)]
    else
        respawnLoc = locs
    end

    if respawnLoc then
        Framework.RevivePlayer(src)
        SetEntityCoords(ped, respawnLoc.x, respawnLoc.y, respawnLoc.z, false, false, false, false)
        SetEntityHeading(ped, respawnLoc.w)
    end
end

function Level1.Cleanup()
    -- Any server-side cleanup
end

LevelManager.RegisterLevel(1, Level1)

-- Init
Citizen.CreateThread(function()
    Level1.RandomizePanel()
end)

RegisterNetEvent("ng_event:server:InteractPanel", function(panelIndex)
    local src = source
    local data = PlayerManager.GetPlayer(src)
    if not data or data.confirmedLevel ~= 1 then return end
    
    data.reachedL1Grid = true

    local isCorrect = false
    for _, idx in ipairs(correctPanels) do
        if idx == panelIndex then isCorrect = true break end
    end

    if isCorrect then
        TriggerClientEvent("ng_event:client:ShowNotification", src, {title = "Success", description = "You got Token 1! Travel to the hangar marked on your map to enter the Arena.", type = "success"})
        TriggerClientEvent("ng_event:client:HideLevel1Blip", src)
        TriggerClientEvent("ng_event:client:ShowHangarBlip", src)
        
        LevelManager.PlayerCompleted(src, 1)
    else
        TriggerClientEvent("ng_event:client:ShowNotification", src, {title = "ZAP!", description = "Wrong panel!", type = "error"})
        TriggerClientEvent("ng_event:client:TakeDamage", src, 20)
    end
    Level1.RandomizePanel() 
end)
