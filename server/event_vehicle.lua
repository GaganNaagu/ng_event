-- server/event_vehicle.lua

-- internal helper
local function GetPlayerIdObj(src)
    local Player = exports.qbx_core:GetPlayer(src)
    -- fallback to license if qbx_core not fully loaded or citizenid not found
    if Player and Player.PlayerData and Player.PlayerData.citizenid then
        return Player.PlayerData.citizenid
    end
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if string.find(id, "license:") then return id end
    end
    return tostring(src)
end

function SpawnEventVehicle(src, model, spawnCoords, isInitialStart)
    EventState.vehicles = EventState.vehicles or {}
    EventState.vehicleSpawnIndex = (EventState.vehicleSpawnIndex or 0) + 1
    local identifier = GetPlayerIdObj(src)
    local ped = GetPlayerPed(src)
    if not DoesEntityExist(ped) then return end
    
    local coords = spawnCoords or Config.EventVehicles.stagingCoords
    if not coords then return end

    -- Calculate grid spacing relative to heading
    local idx = (EventState.vehicleSpawnIndex - 1)
    
    local row = math.floor(idx / 10)
    local col = idx % 10
    
    -- Distances
    local dSide = (col * 4.0) - 18.0 -- Spread sideways relative to facing direction
    local dBack = (row * -8.0)       -- Spread backwards relative to facing direction (negative forward)
    
    local headingRad = math.rad(coords.w)
    local cosH = math.cos(headingRad)
    local sinH = math.sin(headingRad)
    
    -- standard 2d rotation matrix relative to (0,1) facing forwards
    local forwardX = -sinH
    local forwardY = cosH
    
    local rightX = cosH
    local rightY = sinH
    
    local safeX = coords.x + (rightX * dSide) + (forwardX * dBack)
    local safeY = coords.y + (rightY * dSide) + (forwardY * dBack)
    local safeZ = coords.z + 0.5 -- slightly higher to prevent clipping

    local modelHash = type(model) == "string" and joaat(model) or model
    DebugPrint("^3[Event Vehicles Debug] Step 1: Telling client to teleport to staging area first...^7")

    -- Instead of spawning now, tell the client to fade out and teleport there FIRST.
    TriggerClientEvent("ng_event:client:PrepareVehicleWarp", src, modelHash, safeX, safeY, safeZ, coords.w or 0.0, isInitialStart)
end

-- Step 2: Client has teleported and loaded the area. Now we spawn the vehicle.
RegisterNetEvent("ng_event:server:SpawnMyVehicle", function(modelHash, safeX, safeY, safeZ, heading, isInitialStart)
    local src = source
    EventState.vehicles = EventState.vehicles or {}
    local identifier = GetPlayerIdObj(src)
    local ped = GetPlayerPed(src)
    if not DoesEntityExist(ped) then return end
    
    DebugPrint("^3[Event Vehicles Debug] Step 3: Client arrived. Spawning vehicle...^7")
    local vehicle = CreateVehicle(modelHash, safeX, safeY, safeZ, heading, true, true)
    
    DebugPrint("^3[Event Vehicles Debug] CreateVehicle called. Entity ID: " .. tostring(vehicle) .. "^7")
    
    local waitLimit = 0
    while not DoesEntityExist(vehicle) and waitLimit < 20 do
        Wait(50)
        waitLimit = waitLimit + 1
    end

    DebugPrint("^3[Event Vehicles Debug] Wait limit reached. Entity Exists? " .. tostring(DoesEntityExist(vehicle)) .. "^7")

    if DoesEntityExist(vehicle) then
        local netId = NetworkGetNetworkIdFromEntity(vehicle)
        
        -- Randomize colors
        SetVehicleColours(vehicle, math.random(0, 159), math.random(0, 159))
        
        -- Freeze vector and setup correct dimension
        FreezeEntityPosition(vehicle, true)
        local bucket = GetPlayerRoutingBucket(src)
        SetEntityRoutingBucket(vehicle, bucket)
        
        DebugPrint("^3[Event Vehicles Debug] Vehicle frozen and bucket set to: " .. tostring(bucket) .. "^7")
        
        EventState.vehicles[identifier] = {
            entity = vehicle,
            netId = netId
        }

        -- Wait for client handling (warp & blip)
        TriggerClientEvent("ng_event:client:HandleVehicleWarp", src, netId, isInitialStart)
        
        -- Set Full Fuel (requires Entity to exist on server properly, lc_fuel export)
        pcall(function()
            exports["lc_fuel"]:SetFuel(vehicle, 100.0)
        end)
        
        DebugPrint("^2[Event Vehicles] Spawned " .. tostring(modelHash) .. " for player " .. src .. " (NetID: " .. netId .. ")^7")
    else
        DebugPrint("^1[Event Vehicles] Failed to spawn vehicle " .. tostring(modelHash) .. " for player " .. src .. "^7")
    end
end)

function ReplaceEventVehicle(src, model, spawnCoords)
    EventState.vehicles = EventState.vehicles or {}
    local identifier = GetPlayerIdObj(src)
    if EventState.vehicles[identifier] then
        local oldVeh = EventState.vehicles[identifier].entity
        if DoesEntityExist(oldVeh) then
            DeleteEntity(oldVeh)
        end
        TriggerClientEvent("ng_event:client:RemoveVehicleTracker", src)
    end
    SpawnEventVehicle(src, model, spawnCoords, false)
end

function DeleteEventVehicleByIdentifier(identifier, srcHint)
    EventState.vehicles = EventState.vehicles or {}
    if EventState.vehicles[identifier] then
        local veh = EventState.vehicles[identifier].entity
        if DoesEntityExist(veh) then
            DeleteEntity(veh)
        end
        EventState.vehicles[identifier] = nil
        
        if srcHint then
            TriggerClientEvent("ng_event:client:RemoveVehicleTracker", srcHint)
        end
        DebugPrint("^3[Event Vehicles] Deleted event vehicle for identifier " .. identifier .. "^7")
    end
end

function DeleteEventVehicle(src)
    local identifier = GetPlayerIdObj(src)
    DeleteEventVehicleByIdentifier(identifier, src)
end

function CleanupAllEventVehicles()
    EventState.vehicles = EventState.vehicles or {}
    for identifier, data in pairs(EventState.vehicles) do
        if DoesEntityExist(data.entity) then
            DeleteEntity(data.entity)
        end
    end
    EventState.vehicles = {}
    TriggerClientEvent("ng_event:client:RemoveVehicleTracker", -1)
    DebugPrint("^3[Event Vehicles] Cleaned up all event vehicles.^7")
end

-- Handle reconnects properly
RegisterNetEvent("ng_event:server:CheckEventVehicle", function()
    EventState.vehicles = EventState.vehicles or {}
    local src = source
    local identifier = GetPlayerIdObj(src)
    
    if EventState.vehicles[identifier] then
        local vehData = EventState.vehicles[identifier]
        if DoesEntityExist(vehData.entity) then
            -- Recreate the tracking blip for the reconnected player
            TriggerClientEvent("ng_event:client:RestoreVehicleTracker", src, vehData.netId)
            DebugPrint("^2[Event Vehicles] Restored vehicle connection for player " .. src .. "^7")
        end
    end
end)
