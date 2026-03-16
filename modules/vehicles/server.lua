-- modules/vehicles/server.lua
-- Tracking and restricting vehicles spawned for the event (SERVER).

VehicleManager = {}
local PlayerVehicles = {}

function VehicleManager.SpawnEventVehicle(src, model, coords, warp)
    if PlayerVehicles[src] then
        VehicleManager.DeleteEventVehicle(src)
    end
    
    local spawnCoords = coords
    if not spawnCoords then
        EventManager.State.vehicleSpawnIndex = (EventManager.State.vehicleSpawnIndex or 0) + 1
        local pointCount = #(Config.EventVehicles.SpawnPoints or {})
        local index = ((EventManager.State.vehicleSpawnIndex - 1) % pointCount) + 1
        spawnCoords = Config.EventVehicles.SpawnPoints[index]
    end

    local veh = CreateVehicle(model, spawnCoords.x, spawnCoords.y, spawnCoords.z, spawnCoords.w, true, true)
    
    local attempts = 0
    while not DoesEntityExist(veh) and attempts < 10 do
        Wait(50)
        attempts = attempts + 1
    end

    if DoesEntityExist(veh) then
        local netId = NetworkGetNetworkIdFromEntity(veh)
        PlayerVehicles[src] = netId
        TriggerClientEvent("ng_event:client:HandleVehicleWarp", src, netId, warp)
        local pData = PlayerManager.GetPlayer(src)
        local currentBucket = Config.MainBucket
        if pData and pData.levelData and pData.levelData.level5 and pData.levelData.level5.active then
            currentBucket = pData.levelData.level5.bucket
        end
        SetEntityRoutingBucket(veh, currentBucket)
        Entity(veh).state:set("isEventVehicle", true, true)
        DebugPrint("Spawned Event Vehicle (NetID: " .. netId .. ") for Player " .. src)
    end
end

function VehicleManager.DeleteEventVehicle(src)
    local netId = PlayerVehicles[src]
    if netId then
        local entity = NetworkGetEntityFromNetworkId(netId)
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
        PlayerVehicles[src] = nil
    end
end

function VehicleManager.ReplaceEventVehicle(src, model, coords)
    VehicleManager.SpawnEventVehicle(src, model, coords, true)
    DebugPrint("Replaced Event Vehicle for Player " .. src)
end

function VehicleManager.CleanupAllEventVehicles()
    for src, netId in pairs(PlayerVehicles) do
        local entity = NetworkGetEntityFromNetworkId(netId)
        if DoesEntityExist(entity) then
            DeleteEntity(entity)
        end
    end
    PlayerVehicles = {}
    
    local vehicles = GetAllVehicles()
    for _, veh in ipairs(vehicles) do
        if Entity(veh).state and Entity(veh).state.isEventVehicle then
            DeleteEntity(veh)
        end
    end
end

function VehicleManager.CheckEventVehicle(src)
    if PlayerVehicles[src] then
        local entity = NetworkGetEntityFromNetworkId(PlayerVehicles[src])
        if not DoesEntityExist(entity) then
            PlayerVehicles[src] = nil
        end
    end
end

RegisterNetEvent("ng_event:server:RestrictVehicle", function(netId, teleportCoords)
    local src = source
    if not netId then return end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(entity) then return end

    local occupants = {}
    local players = PlayerManager.GetPlayers()
    for playerSrc, _ in pairs(players) do
        local pPed = GetPlayerPed(playerSrc)
        if DoesEntityExist(pPed) and GetVehiclePedIsIn(pPed, false) == entity then
            table.insert(occupants, playerSrc)
        end
    end

    for _, playerSrc in ipairs(occupants) do
        TriggerClientEvent("ng_event:client:ForceLeaveVehicle", playerSrc)
    end

    Wait(300)

    EventManager.State.restrictedVehicleCount = (EventManager.State.restrictedVehicleCount or 0) + 1
    local offset = EventManager.State.restrictedVehicleCount * 3.5
    local modifiedCoords = vector3(teleportCoords.x + offset, teleportCoords.y, teleportCoords.z)
    
    TriggerClientEvent("ng_event:client:TeleportVehicle", src, netId, modifiedCoords)
end)
