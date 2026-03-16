-- modules/vehicles/client.lua
-- Client side vehicle warp, restrict, and upgrade logic.

RegisterNetEvent("ng_event:client:HandleVehicleWarp", function(netId, warp)
    local ped = PlayerPedId()
    local timeout = GetGameTimer() + 5000
    while not NetworkDoesNetworkIdExist(netId) and GetGameTimer() < timeout do Wait(10) end
    
    if NetworkDoesNetworkIdExist(netId) then
        local veh = NetworkGetEntityFromNetworkId(netId)
        if warp then
            DoScreenFadeOut(500)
            Wait(600)
            TaskWarpPedIntoVehicle(ped, veh, -1)
            Wait(500)
            DoScreenFadeIn(1000)
        end
        
        SetVehicleModKit(veh, 0)
        SetVehicleMod(veh, 11, 3, false) -- Engine Level 4
        SetVehicleMod(veh, 12, 2, false) -- Brakes Level 3
        SetVehicleMod(veh, 13, 2, false) -- Transmission Level 3
        ToggleVehicleMod(veh, 18, true)  -- Turbo
        
        local model = GetEntityModel(veh)
        if model == GetHashKey("dubsta3") then
            SetVehicleColours(veh, 12, 12) -- Black
            SetVehicleTyresCanBurst(veh, false) 
        end
    end
end)

RegisterNetEvent("ng_event:client:ForceLeaveVehicle", function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        TaskLeaveVehicle(ped, veh, 16) 
        Citizen.CreateThread(function()
            Wait(100)
            if IsPedInAnyVehicle(ped, false) then
                ClearPedTasksImmediately(ped)
            end
        end)
    end
end)

RegisterNetEvent("ng_event:client:TeleportVehicle", function(netId, teleportCoords)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        if NetworkHasControlOfEntity(entity) then
            SetEntityCoords(entity, teleportCoords.x, teleportCoords.y, teleportCoords.z, false, false, false, false)
            SetVehicleOnGroundProperly(entity)
        else
            NetworkRequestControlOfEntity(entity)
            Citizen.CreateThread(function()
                local timeout = 0
                while not NetworkHasControlOfEntity(entity) and timeout < 10 do
                    Wait(50)
                    timeout = timeout + 1
                end
                SetEntityCoords(entity, teleportCoords.x, teleportCoords.y, teleportCoords.z, false, false, false, false)
                SetVehicleOnGroundProperly(entity)
            end)
        end
    end
end)
