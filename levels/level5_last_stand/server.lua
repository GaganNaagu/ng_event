-- levels/level5_last_stand/server.lua
-- Server logic for The Last Stand (Personal PvE Arena)

local Level5 = {}

function Level5.SetupPlayer(src)
    TriggerClientEvent("ng_event:client:ShowLevel5Blip", src)
end

function Level5.PlayerDied(src)
    local data = PlayerManager.GetPlayer(src)
    if not data or data.confirmedLevel ~= 5 then return end

    local l5data = data.level5
    if not l5data or not l5data.active then return end

    local cfg = Config.Levels[5]

    BucketManager.CleanupPersonalBucketArea(src)
    BucketManager.AddPlayerToMainBucket(src)

    local ped = GetPlayerPed(src)
    if DoesEntityExist(ped) then
        Framework.RevivePlayer(src)
        InventoryManager.ClearPlayerInventory(src)
        SetEntityCoords(ped, cfg.exitCoords.x, cfg.exitCoords.y, cfg.exitCoords.z, false, false, false, false)
        SetEntityHeading(ped, cfg.exitCoords.w)
    end

    TriggerClientEvent("ng_event:client:StopLevel5Instance", src)
    TriggerClientEvent("ng_event:client:ShowNotification", src, {
        title = "Level 5 Failed",
        description = "You were eliminated! Try again.",
        type = "error"
    })
end

function Level5.Cleanup()
    local players = PlayerManager.GetPlayers()
    for src, data in pairs(players) do
        if data.levelData and data.levelData.level5 and data.levelData.level5.active then
            BucketManager.CleanupPersonalBucketArea(src)
            BucketManager.AddPlayerToMainBucket(src)
        end
    end
end

LevelManager.RegisterLevel(5, Level5)

RegisterNetEvent("ng_event:server:RegisterL5NPC", function(netId)
    local src = source
    local data = PlayerManager.GetPlayer(src)
    if not data or not data.levelData or not data.levelData.level5 then return end

    local l5data = data.levelData.level5
    table.insert(l5data.npcs, netId)

    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        SetEntityRoutingBucket(entity, l5data.bucket)
    end
end)

RegisterNetEvent("ng_event:server:EnterLevel5", function()
    local src = source
    local data = PlayerManager.GetPlayer(src)
    if not data then return end
    
    if data.pendingLevel == 5 then
        TransitionManager.ConfirmLevelEntry(src)
    end
    
    if data.confirmedLevel ~= 5 or data.tokens[5] then return end

    if data.levelData and data.levelData.level5 and data.levelData.level5.active then
        return
    end

    local bucket = BucketManager.AssignPersonalBucket(src)
    local cfg = Config.Levels[5]

    VehicleManager.DeleteEventVehicle(src)

    InventoryManager.ClearPlayerInventory(src)
    InventoryManager.GiveLevelLoadout(src, 5)
    Framework.RevivePlayer(src)
    
    TriggerClientEvent("ng_event:client:FadeAndTeleport", src, cfg.arenaCoords, cfg.arenaCoords.w)

    TriggerClientEvent("ng_event:client:ShowNotification", src, {
        title = "Level 5",
        description = "Kill " .. cfg.killsRequired .. " enemies to escape!",
        type = "inform"
    })

    TriggerClientEvent("ng_event:client:StartLevel5Instance", src)
end)

RegisterNetEvent("ng_event:server:ReportNPCKillL5", function(netId)
    local src = source
    local data = PlayerManager.GetPlayer(src)
    if not data or data.confirmedLevel ~= 5 then return end

    local l5data = data.levelData.level5
    if not l5data or not l5data.active then return end

    if netId and netId ~= 0 then
        if l5data.killedNpcs[netId] then return end

        l5data.npcKills = l5data.npcKills + 1
        l5data.killedNpcs[netId] = true 
        
        InventoryManager.HandleKillReward(src, 5)

        TriggerClientEvent("ng_event:client:L5KillUpdate", src, l5data.npcKills, Config.Levels[5].killsRequired)

        local respawnCount = math.random(1, 2)
        TriggerClientEvent("ng_event:client:RespawnNPCsL5", src, respawnCount)

        if l5data.npcKills >= Config.Levels[5].killsRequired then
            local cfg = Config.Levels[5]

            BucketManager.CleanupPersonalBucketArea(src)
            BucketManager.AddPlayerToMainBucket(src)

            local ped = GetPlayerPed(src)
            if DoesEntityExist(ped) then
                Framework.RevivePlayer(src)
            end

            LevelManager.PlayerCompleted(src, 5)
            InventoryManager.ClearPlayerInventory(src)
            
            VehicleManager.ReplaceEventVehicle(src, Config.EventVehicles.finalVehicle, cfg.exitCoords)

            TriggerClientEvent("ng_event:client:StopLevel5Instance", src)
            TriggerClientEvent("ng_event:client:HideLevel5Blip", src)
            TriggerClientEvent("ng_event:client:ShowLevel6Blip", src)

            TriggerClientEvent("ng_event:client:ShowNotification", src, {
                title = "Level 5 Complete!",
                description = "Token acquired! Proceed to Level 6.",
                type = "success"
            })
        end
    end
end)
