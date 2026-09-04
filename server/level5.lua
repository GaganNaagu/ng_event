-- ============================================================
-- LEVEL 5 — ISOLATED PvE (Server)
-- Personal bucket per player, NPC wave, kill 5 or survive 2min
-- ============================================================

-- Client registers spawned NPCs
RegisterNetEvent("ng_event:server:RegisterL5NPC", function(netId)
    local src = source
    if not ValidatePlayer(src) then return end
    local l5data = EventState.players[src] and EventState.players[src].level5
    if not l5data then return end

    table.insert(l5data.npcs, netId)

    -- Set the entity's bucket to match the player's personal bucket
    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        SetEntityRoutingBucket(entity, l5data.bucket)
    end

    DebugPrint("^5[L5] Registered NPC NetID " .. netId .. " for player " .. src .. " (Bucket: " .. l5data.bucket .. ")^7")
end)

-- Player requests to enter Level 5 arena
RegisterNetEvent("ng_event:server:EnterLevel5", function()
    local src = source
    if not ValidatePlayer(src) then return end
    if EventState.players[src].pendingLevel == 5 then
        ConfirmLevelEntry(src)
    end
    
    if EventState.players[src].confirmedLevel ~= 5 then return end
    if EventState.players[src].tokens[5] then return end

    -- Check if already in a personal instance
    if EventState.players[src].level5 and EventState.players[src].level5.active then
        DebugPrint("^3[L5] Player " .. src .. " already in Level 5 instance^7")
        return
    end

    -- Assign personal bucket
    local bucket = AssignPersonalBucket(src)
    local cfg = Config.Levels[5]
    local ped = GetPlayerPed(src)

    -- Delete current event vehicle as they enter the combat arena on foot
    DeleteEventVehicle(src)

    -- Give L5 loadout
    ClearPlayerInventory(src)
    GiveLevelLoadout(src, 5)
    exports.qbx_medical:Revive(src, true)
    -- Teleport to arena inside personal bucket
    TriggerClientEvent("ng_event:client:FadeAndTeleport", src, cfg.arenaCoords, cfg.arenaCoords.w)

    TriggerClientEvent("ng_event:client:ShowNotification", src, {
        title = "Level 5",
        description = "Kill " .. cfg.killsRequired .. " enemies to escape!",
        type = "inform"
    })

    -- Start the instance
    TriggerClientEvent("ng_event:client:StartLevel5Instance", src)

    DebugPrint("^2[L5] Player " .. src .. " entered Level 5 (Bucket: " .. bucket .. ")^7")
end)

-- Player reports an NPC kill
RegisterNetEvent("ng_event:server:ReportNPCKillL5", function(netId)
    local src = source
    if not ValidatePlayer(src) then return end
    if EventState.players[src].confirmedLevel ~= 5 then return end

    local l5data = EventState.players[src].level5
    if not l5data or not l5data.active then 
        DebugPrint("^1[L5] Error: Player " .. src .. " reported kill but L5 data is inactive!^7")
        return 
    end

    if netId and netId ~= 0 then
        -- Prevent double counting
        if l5data.killedNpcs[netId] then 
            DebugPrint("^3[L5] NPC NetID " .. netId .. " already counted for player " .. src .. ", ignoring.^7")
            return 
        end

        l5data.npcKills = l5data.npcKills + 1
        l5data.killedNpcs[netId] = true -- Mark as counted
        
        HandleKillReward(src, 5)
        
        DebugPrint(string.format("^2[L5] Player %d confirmed kill (NetID: %d) | Kills: %d/%d^7",
            src, netId, l5data.npcKills, Config.Levels[5].killsRequired))

        TriggerClientEvent("ng_event:client:L5KillUpdate", src, l5data.npcKills, Config.Levels[5].killsRequired)

        -- Respawn 1-2 new NPCs
        local respawnCount = math.random(1, 2)
        TriggerClientEvent("ng_event:client:RespawnNPCsL5", src, respawnCount)

        if l5data.npcKills >= Config.Levels[5].killsRequired then
            CompleteLevel5(src, "kills")
        end
    else
        DebugPrint("^1[L5] Kill REJECTED: Invalid NetID reported by " .. src .. "^7")
    end
end)

-- Player died in Level 5
RegisterNetEvent("ng_event:server:PlayerDiedL5", function()
    local src = source
    if not ValidatePlayer(src) then return end
    if EventState.players[src].confirmedLevel ~= 5 then return end

    local l5data = EventState.players[src].level5
    if not l5data or not l5data.active then return end

    FailLevel5(src)
end)

-- ============================================================
-- COMPLETION / FAILURE
-- ============================================================

function CompleteLevel5(src, reason)
    if not EventState.players[src] then return end
    local l5data = EventState.players[src].level5
    if not l5data then return end

    local cfg = Config.Levels[5]

    -- Cleanup NPCs and bucket
    CleanupPersonalBucketArea(src)
    AddPlayerToMainBucket(src)

    -- Teleport to exit
    local ped = GetPlayerPed(src)
    if DoesEntityExist(ped) then
        exports.qbx_medical:Revive(src, true)
        -- Removing the instant SetEntityCoords so that HandleVehicleWarp's seamless fade-teleport can do it.
    end

    EventState.players[src].tokens[5] = true

    -- Wipe Level 5 inventory; Level 6 gives no items
    ClearPlayerInventory(src)
    
    UpdateLevel(src, 6)
    
    -- Replace with final event vehicle at the Level 5 exit location instead of Level 1 staging
    ReplaceEventVehicle(src, Config.EventVehicles.finalVehicle, cfg.exitCoords)

    TriggerClientEvent("ng_event:client:StopLevel5Instance", src)
    TriggerClientEvent("ng_event:client:HideLevel5Blip", src)
    TriggerClientEvent("ng_event:client:ShowLevel6Blip", src)

    TriggerClientEvent("ng_event:client:ShowNotification", src, {
        title = "Level 5 Complete!",
        description = "Token acquired by " .. reason .. "! Proceed to Level 6.",
        type = "success"
    })

    DebugPrint("^2[L5] Player " .. src .. " completed Level 5 (" .. reason .. ")^7")
end

function FailLevel5(src)
    if not EventState.players[src] then return end

    local cfg = Config.Levels[5]

    -- Cleanup NPCs and bucket
    CleanupPersonalBucketArea(src)
    AddPlayerToMainBucket(src)

    -- Teleport to exit
    local ped = GetPlayerPed(src)
    if DoesEntityExist(ped) then
        exports.qbx_medical:Revive(src, true)
        
        -- Failed, clear inventory. They can restart externally, which will re-trigger EnterLevel5
        ClearPlayerInventory(src)
        
        SetEntityCoords(ped, cfg.exitCoords.x, cfg.exitCoords.y, cfg.exitCoords.z, false, false, false, false)
        SetEntityHeading(ped, cfg.exitCoords.w)
    end

    TriggerClientEvent("ng_event:client:StopLevel5Instance", src)

    TriggerClientEvent("ng_event:client:ShowNotification", src, {
        title = "Level 5 Failed",
        description = "You were eliminated! Try again.",
        type = "error"
    })
    DebugPrint("^1[L5] Player " .. src .. " failed Level 5, reset to entry^7")
end

-- Cleanup hook
RegisterNetEvent("ng_event:server:CleanupLevel5", function()
    for src, data in pairs(EventState.players) do
        if data.level5 and data.level5.active then
            CleanupPersonalBucketArea(src)
            AddPlayerToMainBucket(src)
        end
    end
end)
