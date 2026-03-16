-- core/server/player_manager.lua
-- Manages joining, leaving, disconnecting, and death routing.

PlayerManager = {}

local players = {}
local disconnectedPlayers = {}

function PlayerManager.GetPlayers()
    return players
end

function PlayerManager.GetPlayer(src)
    return players[src]
end

function PlayerManager.ClearAllPlayers()
    players = {}
    disconnectedPlayers = {}
end

function PlayerManager.JoinEvent(source, id)
    if not EventManager.State.hosting then
        TriggerClientEvent("ng_event:client:ShowNotification", source, {title = "Error", description = "No event is currently being hosted!", type = "error"})
        return false
    end

    if EventManager.State.active then
        TriggerClientEvent("ng_event:client:ShowNotification", source, {title = "Error", description = "Event has already started!", type = "error"})
        return false
    end

    if Config.UseEventID and id and (tonumber(id) ~= EventManager.State.id) then
        TriggerClientEvent("ng_event:client:ShowNotification", source, {title = "Error", description = "Invalid Event ID!", type = "error"})
        return false
    end

    if players[source] then
        TriggerClientEvent("ng_event:client:ShowNotification", source, {title = "Info", description = "You have already joined!", type = "inform"})
        return false
    end

    players[source] = {
        currentLevel = 1,
        confirmedLevel = 1,
        displayLevel = 1,
        pendingLevel = nil,
        transitioning = false,
        lastSafeSpawn = nil,
        tokens = {},
        arenaKills = 0,
        finished = false,
        levelData = {} 
    }
    
    local totalLevels = Config.LevelOrder and #Config.LevelOrder or 6
    for i=1, totalLevels do
        players[source].tokens[i] = false
    end

    if StateManager then StateManager.UpdatePlayerEventState(source) end

    if EventManager.State.hostSource > 0 then
        TriggerClientEvent("ng_event:client:ShowNotification", EventManager.State.hostSource, {
            title = "Event Join",
            description = "Player " .. source .. " has joined the event!",
            type = "inform"
        })
    end

    TriggerClientEvent("ng_event:client:ShowNotification", source, {title = "Success", description = "You joined the event! Wait for it to start.", type = "success"})
    
    if InventoryManager then
        InventoryManager.SavePlayerInventory(source)
        InventoryManager.ClearPlayerInventory(source)
    end
    return true
end

function PlayerManager.RemovePlayer(source, force)
    if not players[source] and not force then return false end
    
    local ped = GetPlayerPed(source)
    if DoesEntityExist(ped) then
        SetPlayerRoutingBucket(source, 0)
        if StateManager then StateManager.ClearPlayerEventState(source) end
        
        if Config.TeleportOnEventEnd and not (PodiumManager and PodiumManager.IsPodiumActive()) then
            SetEntityCoords(ped, Config.TeleportOnEventEndCoords.x, Config.TeleportOnEventEndCoords.y, Config.TeleportOnEventEndCoords.z, false, false, false, false)
            if Config.TeleportOnEventEndCoords.w then SetEntityHeading(ped, Config.TeleportOnEventEndCoords.w) end
        end
        
        TriggerClientEvent("ng_event:client:SetPVPState", source, true)
        FreezeEntityPosition(ped, false)
    end

    if InventoryManager then InventoryManager.RestorePlayerInventory(source) end
    if BucketManager then BucketManager.CleanupPersonalBucketArea(source) end
    if VehicleManager then VehicleManager.DeleteEventVehicle(source) end

    players[source] = nil
    TriggerClientEvent("ng_event:client:EventEnded", source)

    return true
end

function PlayerManager.InitializePlayerLevel(src, startLevel)
    local data = players[src]
    if not data then return end
    
    if startLevel > 1 then
        data.confirmedLevel = startLevel - 1
        data.displayLevel = startLevel
        data.currentLevel = startLevel
        data.pendingLevel = startLevel
        data.transitioning = true
    else
        data.confirmedLevel = 1
        data.displayLevel = 1
        data.currentLevel = 1
        data.pendingLevel = nil
        data.transitioning = false
    end
    
    for i = 1, startLevel - 1 do
        data.tokens[i] = true
    end
end

AddEventHandler("playerDropped", function(reason)
    local src = source
    if players[src] then
        local citizenid = Framework.GetPlayerCitizenId(src)
        disconnectedPlayers[citizenid] = players[src]
        players[src] = nil
        DebugPrint("Player " .. src .. " dropped. Event state retained for " .. citizenid .. ".")
    end
end)

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    PlayerManager.RecoverPlayer(source)
end)

RegisterNetEvent('qbx_core:server:onPlayerLoaded', function(src)
    PlayerManager.RecoverPlayer(src)
end)

function PlayerManager.RecoverPlayer(src)
    local citizenid = Framework.GetPlayerCitizenId(src)
    if EventManager.State.active and disconnectedPlayers[citizenid] then
        players[src] = disconnectedPlayers[citizenid]
        disconnectedPlayers[citizenid] = nil
        
        if players[src].levelData and players[src].levelData.level5 and players[src].levelData.level5.active then
            SetPlayerRoutingBucket(src, players[src].levelData.level5.bucket)
        else
            if BucketManager then BucketManager.AddPlayerToMainBucket(src) end
        end
        
        if StateManager then StateManager.UpdatePlayerEventState(src) end
        TriggerClientEvent("ng_event:client:EventStarted", src)
        
        local level = players[src].confirmedLevel
        if LevelManager then LevelManager.TriggerCumulativeSetup(src, level) end
        if VehicleManager then VehicleManager.CheckEventVehicle(src) end
        DebugPrint("Player " .. src .. " reconnected and event state restored to Level " .. level)
    end
end
