local correctPanels = {}

function RandomizePanel()
    local cfg = Config.Levels[1]
    local count = #cfg.panels
    local targetCount = cfg.correctPanelsCount or 1
    
    correctPanels = {}
    local available = {}
    for i = 1, count do available[i] = i end
    
    for i = 1, targetCount do
        if #available == 0 then break end
        local r = math.random(1, #available)
        table.insert(correctPanels, available[r])
        table.remove(available, r)
    end
    
    DebugPrint("Level 1 Panels randomized to: " .. json.encode(correctPanels))
end

-- Initialize first round panel
Citizen.CreateThread(function()
    RandomizePanel()
end)

RegisterNetEvent("ng_event:server:InteractPanel", function(panelIndex)
    local src = source
    if not ValidatePlayer(src) then return end
    if EventState.players[src].confirmedLevel ~= 1 then return end
    
    -- Set checkpoint
    EventState.players[src].reachedL1Grid = true

    local isCorrect = false
    for _, idx in ipairs(correctPanels) do
        if idx == panelIndex then
            isCorrect = true
            break
        end
    end

    if isCorrect then
        -- Success
        EventState.players[src].tokens[1] = true
        local safeSpawn = Config.Levels[1].respawnLocs[1]
        UpdateLevel(src, 2, safeSpawn) -- Advance to level 2 immediately after level 1 panels
        UpdatePlayerEventState(src)
        
        TriggerClientEvent("ng_event:client:ShowNotification", src, {title = "Success", description = "You got Token 1! Travel to the hangar marked on your map to enter the Arena.", type = "success"})
        
        -- Trigger blip on client
        TriggerClientEvent("ng_event:client:HideLevel1Blip", src)
        TriggerClientEvent("ng_event:client:ShowHangarBlip", src)
    else
        -- Fail
        TriggerClientEvent("ng_event:client:ShowNotification", src, {title = "ZAP!", description = "Wrong panel!", type = "error"})
        
        -- Deal heavy damage or kill via client event
        TriggerClientEvent("ng_event:client:TakeDamage", src, 20)
    end
    RandomizePanel() -- Randomize for next player
end)

RegisterNetEvent("ng_event:server:RespawnPlayerL1", function(src)
    src = src or source
    if not ValidatePlayer(src) then return end
    local data = EventState.players[src]
    if data.confirmedLevel ~= 1 then return end

    local ped = GetPlayerPed(src)
    
    -- Check if they reached the grid (checkpoint or proximity)
    local gridLoc = Config.Levels[1].panels[1] -- Use first panel as center reference
    local pCoords = GetEntityCoords(ped)
    local reached = data.reachedL1Grid or (#(pCoords - gridLoc) < 150.0)

    local locs = reached and Config.Levels[1].respawnLocs or Config.Levels[1].spawnLocs
    local respawnLoc = GetRandomLocation(locs)

    if respawnLoc then
        exports.qbx_medical:Revive(src, true)
        SetEntityCoords(ped, respawnLoc.x, respawnLoc.y, respawnLoc.z, false, false, false, false)
        SetEntityHeading(ped, respawnLoc.w)
    end
end)
