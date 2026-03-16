-- Listen to player death events if supported, else rely on a client event when they die in L2.
-- Assuming qbx_core or base fivem baseevents 'onPlayerDied' or 'onPlayerKilled'
-- Baseevents: `baseevents:onPlayerKilled` (killerId, data)
RegisterNetEvent("baseevents:onPlayerKilled", function(killerId, data)
    local victim = source
    local killer = tonumber(killerId)

    if not ValidatePlayer(victim) or not ValidatePlayer(killer) then return end
    
    -- Both must be in level 2
    if EventState.players[victim].confirmedLevel == 2 and EventState.players[killer].confirmedLevel == 2 then
        EventState.players[killer].arenaKills = EventState.players[killer].arenaKills + 1
        UpdatePlayerEventState(killer)
        
        HandleKillReward(killer, 2)
        
        TriggerClientEvent("ng_event:client:ShowNotification", killer, {title = "Kill", description = "Kills: " .. EventState.players[killer].arenaKills .. "/" .. Config.Levels[2].killsRequired, type = "success"})
        
        if EventState.players[killer].arenaKills >= Config.Levels[2].killsRequired then
            -- Grant Token 2
            EventState.players[killer].tokens[2] = true
            UpdatePlayerEventState(killer)
            local safeSpawn = Config.Levels[1].hangarCoords
            UpdateLevel(killer, 3, safeSpawn)
            
            TriggerClientEvent("ng_event:client:ShowNotification", killer, {title = "Success", description = "You got Token 2! Move to Lion Hill.", type = "success"})
            
            -- Disable PVP for individual
            TriggerClientEvent("ng_event:client:SetPVPState", killer, false)
            
            -- Moving to Level 3, wipe Level 2 inventory
            ClearPlayerInventory(killer)
            
            local ped = GetPlayerPed(killer)
            -- Just teleport them out of arena to L3 start to be safe
            SetEntityCoords(ped, Config.Levels[3].spawnArea.center.x, Config.Levels[3].spawnArea.center.y, Config.Levels[3].spawnArea.center.z, false, false, false, false)
        end
    end
end)

RegisterNetEvent("ng_event:server:EnterArena", function()
    local src = source
    if not ValidatePlayer(src) then return end
    
    -- Must have token 1 and already be in transition to level 2
    if not EventState.players[src].tokens[1] or EventState.players[src].pendingLevel ~= 2 then
        return
    end

    ConfirmLevelEntry(src)
    
    -- Level 2 starts: wipe and grant loadout
    ClearPlayerInventory(src)
    GiveLevelLoadout(src, 2)
    exports.qbx_medical:Revive(src, true)
    
    local spawnLoc = GetRandomLocation(Config.Levels[2].spawnLocs)
    if spawnLoc then
        TriggerClientEvent("ng_event:client:FadeAndTeleport", src, spawnLoc, spawnLoc.w)
    end
    
    TriggerClientEvent("ng_event:client:SetPVPState", src, true)
    TriggerClientEvent("ng_event:client:HideHangarBlip", src)
    TriggerClientEvent("ng_event:client:ShowNotification", src, {title = "Arena", description = "You have entered the Arena. PVP is now ENABLED!", type = "inform"})
end)

RegisterNetEvent("ng_event:server:RespawnPlayerL2", function()
    local src = source
    if not ValidatePlayer(src) then return end
    if EventState.players[src].confirmedLevel ~= 2 then return end

    local ped = GetPlayerPed(src)
    local spawnLoc = GetRandomLocation(Config.Levels[2].spawnLocs)
    if spawnLoc then
        exports.qbx_medical:Revive(src, true)
        
        -- Player respawned in Arena, regive the loadout
        ClearPlayerInventory(src)
        GiveLevelLoadout(src, 2)
        
        TriggerClientEvent("ng_event:client:FadeAndTeleport", src, spawnLoc, spawnLoc.w)
    end
end)

RegisterNetEvent("ng_event:server:ReportPlayerKill", function(victimId)
    local killer = source
    local victim = tonumber(victimId)

    if not ValidatePlayer(killer) or not EventState.players[victim] then return end
    
    -- Both must be in level 2 (Standard Arena)
    if EventState.players[killer].confirmedLevel == 2 and EventState.players[victim].confirmedLevel == 2 then
        EventState.players[killer].arenaKills = EventState.players[killer].arenaKills + 1
        UpdatePlayerEventState(killer)
        
        HandleKillReward(killer, 2)
        
        TriggerClientEvent("ng_event:client:ShowNotification", killer, {title = "Kill", description = "Kills: " .. EventState.players[killer].arenaKills .. "/" .. Config.Levels[2].killsRequired, type = "success"})
        
        if EventState.players[killer].arenaKills >= Config.Levels[2].killsRequired then
            -- Grant Token 2
            EventState.players[killer].tokens[2] = true
            UpdatePlayerEventState(killer)
            local safeSpawn = Config.Levels[1].hangarCoords
            UpdateLevel(killer, 3, safeSpawn)
            
            TriggerClientEvent("ng_event:client:ShowNotification", killer, {title = "Success", description = "You got Token 2! Move to Lion Hill.", type = "success"})
            
            -- Disable PVP for individual
            TriggerClientEvent("ng_event:client:SetPVPState", killer, false)
            
            -- Level 2 finished, clear items for transit to L3
            ClearPlayerInventory(killer)
            
            local ped = GetPlayerPed(killer)
            local hangarCoords = Config.Levels[1].hangarCoords
            exports.qbx_medical:Revive(killer, true)
            SetEntityCoords(ped, hangarCoords.x, hangarCoords.y, hangarCoords.z, false, false, false, false)
            TriggerClientEvent("ng_event:client:ShowLevel3Blip", killer)
        end
    end
end)
