-- levels/level2_blood_arena/server.lua
-- Server logic for The Blood Arena

local Level2 = {}

function Level2.SetupPlayer(src)
    -- L2 uses hangar entrance interaction. Handled by client zones.
end

function Level2.PlayerDied(src)
    local data = PlayerManager.GetPlayer(src)
    if not data or data.confirmedLevel ~= 2 then return end

    local spawnLoc = Config.Levels[2].spawnLocs
    if type(spawnLoc) == "table" and #spawnLoc > 0 then
        spawnLoc = spawnLoc[math.random(1, #spawnLoc)]
    end

    if spawnLoc then
        Framework.RevivePlayer(src)
        
        InventoryManager.ClearPlayerInventory(src)
        InventoryManager.GiveLevelLoadout(src, 2)
        
        TriggerClientEvent("ng_event:client:FadeAndTeleport", src, spawnLoc, spawnLoc.w)
    end
end

function Level2.Cleanup()
    -- Any server-side cleanup
end

LevelManager.RegisterLevel(2, Level2)

RegisterNetEvent("baseevents:onPlayerKilled", function(killerId, data)
    local victim = source
    local killer = tonumber(killerId)

    local victimData = PlayerManager.GetPlayer(victim)
    local killerData = PlayerManager.GetPlayer(killer)

    if not victimData or not killerData then return end
    
    if killerData.confirmedLevel == 2 and victimData.confirmedLevel == 2 then
        killerData.arenaKills = (killerData.arenaKills or 0) + 1
        StateManager.UpdatePlayerEventState(killer)
        
        InventoryManager.HandleKillReward(killer, 2)
        
        TriggerClientEvent("ng_event:client:ShowNotification", killer, {
            title = "Kill", 
            description = "Kills: " .. killerData.arenaKills .. "/" .. Config.Levels[2].killsRequired, 
            type = "success"
        })
        
        if killerData.arenaKills >= Config.Levels[2].killsRequired then
            LevelManager.PlayerCompleted(killer, 2)
            
            TriggerClientEvent("ng_event:client:ShowNotification", killer, {title = "Success", description = "You got Token 2! Move to Lion Hill.", type = "success"})
            TriggerClientEvent("ng_event:client:SetPVPState", killer, false)
            
            InventoryManager.ClearPlayerInventory(killer)
            
            local ped = GetPlayerPed(killer)
            local targetSafe = Config.Levels[3] and Config.Levels[3].respawnLocs and Config.Levels[3].respawnLocs[1]
            if targetSafe then
                SetEntityCoords(ped, targetSafe.x, targetSafe.y, targetSafe.z, false, false, false, false)
            else
                local hangarCoords = Config.Levels[1].hangarCoords
                if hangarCoords then SetEntityCoords(ped, hangarCoords.x, hangarCoords.y, hangarCoords.z, false, false, false, false) end
            end
            
            TriggerClientEvent("ng_event:client:ShowLevel3Blip", killer)
        end
    end
end)

RegisterNetEvent("ng_event:server:EnterArena", function()
    local src = source
    local data = PlayerManager.GetPlayer(src)
    if not data then return end
    
    if not data.tokens[1] or data.pendingLevel ~= 2 then return end

    TransitionManager.ConfirmLevelEntry(src)
    
    InventoryManager.ClearPlayerInventory(src)
    InventoryManager.GiveLevelLoadout(src, 2)
    Framework.RevivePlayer(src)
    
    local spawnLocs = Config.Levels[2].spawnLocs
    local spawnLoc = spawnLocs[math.random(1, #spawnLocs)]
    if spawnLoc then
        TriggerClientEvent("ng_event:client:FadeAndTeleport", src, spawnLoc, spawnLoc.w)
    end
    
    TriggerClientEvent("ng_event:client:SetPVPState", src, true)
    TriggerClientEvent("ng_event:client:HideHangarBlip", src)
    TriggerClientEvent("ng_event:client:ShowNotification", src, {title = "Arena", description = "You have entered the Arena. PVP is now ENABLED!", type = "inform"})
end)

-- Legacy ReportPlayerKill for fallback if not using baseevents
RegisterNetEvent("ng_event:server:ReportPlayerKill", function(victimId)
    local killer = source
    local victim = tonumber(victimId)

    local victimData = PlayerManager.GetPlayer(victim)
    local killerData = PlayerManager.GetPlayer(killer)
    if not victimData or not killerData then return end
    
    if killerData.confirmedLevel == 2 and victimData.confirmedLevel == 2 then
        killerData.arenaKills = (killerData.arenaKills or 0) + 1
        StateManager.UpdatePlayerEventState(killer)
        
        InventoryManager.HandleKillReward(killer, 2)
        
        TriggerClientEvent("ng_event:client:ShowNotification", killer, {title = "Kill", description = "Kills: " .. killerData.arenaKills .. "/" .. Config.Levels[2].killsRequired, type = "success"})
        
        if killerData.arenaKills >= Config.Levels[2].killsRequired then
            LevelManager.PlayerCompleted(killer, 2)
            TriggerClientEvent("ng_event:client:ShowNotification", killer, {title = "Success", description = "You got Token 2! Move to Lion Hill.", type = "success"})
            TriggerClientEvent("ng_event:client:SetPVPState", killer, false)
            InventoryManager.ClearPlayerInventory(killer)
            
            local ped = GetPlayerPed(killer)
            local targetSafe = Config.Levels[3] and Config.Levels[3].respawnLocs and Config.Levels[3].respawnLocs[1]
            if targetSafe then
                SetEntityCoords(ped, targetSafe.x, targetSafe.y, targetSafe.z, false, false, false, false)
            else
                local hangarCoords = Config.Levels[1].hangarCoords
                if hangarCoords then SetEntityCoords(ped, hangarCoords.x, hangarCoords.y, hangarCoords.z, false, false, false, false) end
            end
            
            TriggerClientEvent("ng_event:client:ShowLevel3Blip", killer)
        end
    end
end)
