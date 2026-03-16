-- server/level_setup.lua
-- Centralized logic for level-specific blips, PVP, and other setups

function TriggerCumulativeLevelSetup(src, level)
    if not EventState.players[src] then return end
    
    DebugPrint("SERVER: Triggering Cumulative Setup for Player " .. src .. " to Level " .. level)
    
    -- 1. Cleanup all blips first to ensure we only show the current objective
    TriggerClientEvent("ng_event:client:HideLevel1Blip", src)
    TriggerClientEvent("ng_event:client:HideHangarBlip", src)
    TriggerClientEvent("ng_event:client:HideLevel3Blip", src)
    TriggerClientEvent("ng_event:client:HideLevel4Blip", src)
    TriggerClientEvent("ng_event:client:HideLevel5Blip", src)
    TriggerClientEvent("ng_event:client:HideLevel6Blip", src)

    -- 2. Unlock all levels up to the current one (Triggers zone setups on client)
    -- We use a direct client trigger here because Global Unlock might have already happened, 
    -- but this specific rejoining client needs to re-run its local setup logic.
    for i = 1, level do
        TriggerClientEvent("ng_event:client:UnlockLevel", src, i)
    end
    
    -- 3. Grant tokens for all previous levels
    for i = 1, level - 1 do
        EventState.players[src].tokens[i] = true
    end
    UpdatePlayerEventState(src)

    -- 4. Progressive Blip setup
    if level == 1 then
        TriggerClientEvent("ng_event:client:ShowLevel1Blip", src)
    elseif level == 2 then
        -- Players at Level 2 objective need to go to the Hangar to enter the Arena
        TriggerClientEvent("ng_event:client:ShowHangarBlip", src)
    elseif level == 3 then
        TriggerClientEvent("ng_event:client:ShowLevel3Blip", src)
    elseif level == 4 then
        TriggerClientEvent("ng_event:client:ShowLevel4Blip", src)
    elseif level == 5 then
        TriggerClientEvent("ng_event:client:ShowLevel5Blip", src)
    elseif level == 6 then
        TriggerClientEvent("ng_event:client:ShowLevel6Blip", src)
    end

    -- 5. Set PVP State
    local pvp = (level == 2)
    TriggerClientEvent("ng_event:client:SetPVPState", src, pvp)
    
    DebugPrint("SERVER: Cumulative Setup Complete for Player " .. src)
end

function TeleportPlayerToLevelStart(src, level)
    local ped = GetPlayerPed(src)
    if not DoesEntityExist(ped) then return end
    
    local spawn = nil
    if level == 1 then
        spawn = GetRandomLocation(Config.Levels[1].spawnLocs)
    elseif level == 2 then
        spawn = Config.Levels[1].hangarCoords -- Entrance to Arena
    elseif level == 3 then
        spawn = Config.Levels[1].hangarCoords -- Safe base for Lion Hill
    elseif level == 4 then
        spawn = Config.Levels[4].spawnCoords
    elseif level == 5 then
        spawn = Config.Levels[5].entryCoords
    elseif level == 6 then
        local cfgL5 = Config.Levels[5]
        local cfgL6 = Config.Levels[6]
        -- Use Level 5 exit coords for the vehicle spawn if available, otherwise fallback to level 6 blip
        local spawnCoords = (cfgL5 and cfgL5.exitCoords) or cfgL6.blipCoords
        ReplaceEventVehicle(src, Config.EventVehicles.finalVehicle, spawnCoords)
        return -- ReplaceEventVehicle handles its own warp sequence
    end

    if spawn then
        SetEntityCoords(ped, spawn.x, spawn.y, spawn.z, false, false, false, false)
        if spawn.w then SetEntityHeading(ped, spawn.w) end
        if EventState.players[src] then
            EventState.players[src].lastSafeSpawn = spawn
        end
        DebugPrint("SERVER: Teleported Player " .. src .. " to Level " .. level .. " start.")
    end
end
