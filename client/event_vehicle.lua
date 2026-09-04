-- client/event_vehicle.lua

local vehicleBlip = nil

RegisterNetEvent("ng_event:client:PrepareVehicleWarp", function(modelHash, x, y, z, heading, isInitialStart)
    local ped = PlayerPedId()
    
    -- Step 2: Screen Fade Transition & Teleport
    DebugPrint("[Event Vehicles Debug] Step 2: Fading out and teleporting to target coords...")
    DoScreenFadeOut(1000)
    Wait(1000) -- Wait for fade to complete

    SetEntityCoords(ped, x, y, z, false, false, false, false)
    Wait(1000) -- Give the client a full second to load collisions and the surrounding area in the new dimension

    -- Tell server we are here and ready for the vehicle to spawn
    DebugPrint("[Event Vehicles Debug] Arrived safely at " .. tostring(x) .. ", " .. tostring(y) .. ". Requesting vehicle spawn from server...")
    TriggerServerEvent("ng_event:server:SpawnMyVehicle", modelHash, x, y, z, heading, isInitialStart)
end)

RegisterNetEvent("ng_event:client:HandleVehicleWarp", function(vehicleNetId, isInitialStart)
    local ped = PlayerPedId()
    DebugPrint("[Event Vehicles Debug] Step 4: HandleVehicleWarp called with NetID: " .. tostring(vehicleNetId))

    local vehicle = nil
    local waitLimit = 0
    while not NetworkDoesNetworkIdExist(vehicleNetId) and waitLimit < 50 do
        Wait(100)
        waitLimit = waitLimit + 1
    end
    DebugPrint("[Event Vehicles Debug] Wait limit reached. Network ID exists? " .. tostring(NetworkDoesNetworkIdExist(vehicleNetId)))

    if NetworkDoesNetworkIdExist(vehicleNetId) then
        -- We must wait for the entity to physically stream to the client and be recognized as a true vehicle
        local streamWait = 0
        vehicle = NetToVeh(vehicleNetId)
        while (not DoesEntityExist(vehicle) or not IsEntityAVehicle(vehicle)) and streamWait < 50 do
            Wait(100)
            vehicle = NetToVeh(vehicleNetId)
            streamWait = streamWait + 1
        end
        
        DebugPrint("[Event Vehicles Debug] Converted to local vehicle entity: " .. tostring(vehicle) .. ". Does entity exist? " .. tostring(DoesEntityExist(vehicle)))
        
        if DoesEntityExist(vehicle) and IsEntityAVehicle(vehicle) then
            -- Wait another brief moment to ensure physics/collision is ready before warping
            Wait(500)
            
            -- Warp player into driver seat
            TaskWarpPedIntoVehicle(ped, vehicle, -1)
            if isInitialStart then
                FreezeEntityPosition(vehicle, true) -- Kept frozen for the synchronized countdown
            else
                FreezeEntityPosition(vehicle, false) -- Free movement for level transitions
            end
            
            -- Force Fuel safely
            if DoesEntityExist(vehicle) then
                SetVehicleFuelLevel(vehicle, 100.0)
                pcall(function() exports['lc_fuel']:SetFuel(vehicle, 100.0) end)
            end

            -- Attempt to give Keys (Various QBox/QBCore standard forms)
            local plate = GetVehicleNumberPlateText(vehicle)
            TriggerEvent("vehiclekeys:client:SetOwner", plate)
            
            -- Create Tracker
            CreateVehicleTracker(vehicle)
        end
    end

    DoScreenFadeIn(1000)
end)

RegisterNetEvent("ng_event:client:RestoreVehicleTracker", function(vehicleNetId)
    local waitLimit = 0
    while not NetworkDoesNetworkIdExist(vehicleNetId) and waitLimit < 20 do
        Wait(100)
        waitLimit = waitLimit + 1
    end

    if NetworkDoesNetworkIdExist(vehicleNetId) then
        local vehicle = NetToVeh(vehicleNetId)
        if DoesEntityExist(vehicle) then
            CreateVehicleTracker(vehicle)
        end
    end
end)

RegisterNetEvent("ng_event:client:RemoveVehicleTracker", function()
    RemoveVehicleTracker()
end)

function CreateVehicleTracker(vehicle)
    RemoveVehicleTracker() -- Clean up old if any
    
    vehicleBlip = AddBlipForEntity(vehicle)
    SetBlipSprite(vehicleBlip, 225) -- Car blip
    SetBlipColour(vehicleBlip, 3)   -- Blue
    SetBlipScale(vehicleBlip, 0.8)
    SetBlipAsShortRange(vehicleBlip, false)
    SetBlipDisplay(vehicleBlip, 4) -- Show on both main map and minimap
    SetBlipHighDetail(vehicleBlip, true)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Event Vehicle")
    EndTextCommandSetBlipName(vehicleBlip)
end

RegisterNetEvent("ng_event:client:StartCountdown", function()
    local ped = PlayerPedId()
    
    local sf = RequestScaleformMovie("COUNTDOWN")
    while not HasScaleformMovieLoaded(sf) do
        Wait(10)
    end

    local function showNumber(textStr, r, g, b)
        BeginScaleformMovieMethod(sf, "FADE_MP")
        PushScaleformMovieFunctionParameterString(textStr)
        PushScaleformMovieFunctionParameterInt(r)
        PushScaleformMovieFunctionParameterInt(g)
        PushScaleformMovieFunctionParameterInt(b)
        EndScaleformMovieMethod()
    end

    for i = 3, 1, -1 do
        PlaySoundFrontend(-1, "3_2_1", "HUD_MINI_GAME_SOUNDSET", true)
        showNumber(tostring(i), 255, 100, 0)
        local timer = GetGameTimer() + 1000
        while GetGameTimer() < timer do
            DrawScaleformMovieFullscreen(sf, 255, 255, 255, 255, 0)
            Wait(0)
        end
    end

    PlaySoundFrontend(-1, "GO", "HUD_MINI_GAME_SOUNDSET", true)
    showNumber("GO", 0, 255, 0)
    
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        -- Unfreeze their event vehicle!
        FreezeEntityPosition(veh, false)
    else
        FreezeEntityPosition(ped, false)
    end

    local timer = GetGameTimer() + 1500
    while GetGameTimer() < timer do
        DrawScaleformMovieFullscreen(sf, 255, 255, 255, 255, 0)
        Wait(0)
    end
end)

function RemoveVehicleTracker()
    if vehicleBlip and DoesBlipExist(vehicleBlip) then
        RemoveBlip(vehicleBlip)
    end
    vehicleBlip = nil
end
