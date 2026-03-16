local activeZones = {}
local restrictCooldown = 0

local function CleanupZones()
    for _, zone in ipairs(activeZones) do
        if zone and zone.remove then
            zone:remove()
        end
    end
    activeZones = {}
end

local function SetupRestrictorZones()
    CleanupZones()
    
    if not Config.VehicleRestrictedZones then return end

    for _, zoneData in ipairs(Config.VehicleRestrictedZones) do
        local zoneId = lib.zones.sphere({
            coords = zoneData.coords,
            radius = zoneData.radius,
            debug = Config.Debug,
            onEnter = function()
                if not InEvent then return end
                
                -- Check if level restriction applies
                local currentLevel = LocalEventState and LocalEventState.level
                local levelValid = false
                if not zoneData.activeLevels then
                    levelValid = true
                else
                    for _, lvl in ipairs(zoneData.activeLevels) do
                        if lvl == currentLevel then
                            levelValid = true
                            break
                        end
                    end
                end

                if not levelValid then return end

                local ped = PlayerPedId()
                if IsPedInAnyVehicle(ped, false) then
                    local veh = GetVehiclePedIsIn(ped, false)
                    
                    if veh ~= 0 then
                        local isDriver = GetPedInVehicleSeat(veh, -1) == ped

                        if isDriver then
                            if GetGameTimer() > restrictCooldown then
                                restrictCooldown = GetGameTimer() + 5000 -- 5s cooldown
                                local netId = NetworkGetNetworkIdFromEntity(veh)
                                TriggerServerEvent("ng_event:server:RestrictVehicle", netId, zoneData.carTeleportCoords)
                                
                                TriggerEvent("ng_event:client:ShowNotification", {
                                    title = "Restricted Area",
                                    description = "Vehicles are not allowed here! Your car has been towed.",
                                    type = "error"
                                })
                            end
                        else
                            -- Non-drivers just warp out locally to be safe
                            TaskLeaveVehicle(ped, veh, 16)
                        end
                    end
                end
            end
        })
        table.insert(activeZones, zoneId)
    end
end

-- Initialize on start if already in event
Citizen.CreateThread(function()
    Wait(1000)
    if InEvent then
        SetupRestrictorZones()
    end
end)

RegisterNetEvent("ng_event:client:EventStarted", function()
    -- Small delay to ensure Config and state are ready
    Wait(1000)
    SetupRestrictorZones()
end)

RegisterNetEvent("ng_event:client:EventEnded", function()
    CleanupZones()
end)

-- Resource stop cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        CleanupZones()
    end
end)
