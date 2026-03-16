local level1Blip = nil
local isShocked = false

local function CreateLevel1Blip()
    if level1Blip then RemoveBlip(level1Blip) end
    
    -- Calculate center of panels for blip
    local cx, cy, cz = 0, 0, 0
    local panels = Config.Levels[1].panels
    for _, c in ipairs(panels) do
        cx = cx + c.x
        cy = cy + c.y
        cz = cz + c.z
    end
    cx, cy, cz = cx / #panels, cy / #panels, cz / #panels
    
    level1Blip = AddBlipForCoord(cx, cy, cz)
    SetBlipSprite(level1Blip, 354) -- Lightning/Electricity
    SetBlipColour(level1Blip, 5) -- Yellow
    SetBlipScale(level1Blip, 1.0)
    SetBlipAsShortRange(level1Blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Event: Trial of Shock")
    EndTextCommandSetBlipName(level1Blip)
    SetBlipRoute(level1Blip, true)
end

RegisterNetEvent("ng_event:client:SetupLevel1Zones", function()
    if not InEvent then return end
    DebugPrint("LEVEL 1 DEBUG: SetupLevel1Zones event received!")
    -- Level 1 Panels
    
    CreateLevel1Blip()

    TriggerEvent("ng_event:client:ClearLevelZones", 1)

    for i, coords in ipairs(Config.Levels[1].panels) do
        local id = exports.ox_target:addSphereZone({
            coords = coords,
            radius = 1.0,
            debug = Config.Debug,
            options = {
                {
                    name = 'ng_event_panel_'..i,
                    icon = 'fas fa-bolt',
                    label = Config.Debug and "Interact Panel: " .. i or "Interact Panel",
                    distance = 2.0,
                    onSelect = function()
                        TriggerServerEvent("ng_event:server:InteractPanel", i)
                    end,
                    canInteract = function()
                        local isDead = exports.qbx_medical:IsDead()
                        local isLastStand = exports.qbx_medical:IsLaststand()
                        return InEvent and LocalEventState.level == 1 and not isDead and not isLastStand and not isShocked
                    end
                }
            }
        })
        table.insert(LevelZones[1], id)
        table.insert(RegisteredZones, id) -- Keep legacy fallback just in case
    end
end)

RegisterNetEvent("ng_event:client:HideLevel1Blip", function()
    if level1Blip then
        RemoveBlip(level1Blip)
        level1Blip = nil
    end
end)

RegisterNetEvent("ng_event:client:ShowLevel1Blip", function()
    if not InEvent then return end
    CreateLevel1Blip()
end)

-- Draw Markers for Level 1 Panels
Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        if InEvent and LocalEventState.level == 1 then
            sleep = 0
            for _, coords in ipairs(Config.Levels[1].panels) do
                DrawMarker(2, coords.x, coords.y, coords.z + 0.5, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.5, 0.5, 0.5, 255, 255, 0, 100, true, true, 2, false, nil, nil, false)
            end
        end
        Wait(sleep)
    end
end)

RegisterNetEvent("ng_event:client:TakeDamage", function(amount)
    local ped = PlayerPedId()
    DebugPrint("TakeDamage triggered: Amount="..tostring(amount))

    -- Stun/Shock Effects
    if not exports.qbx_medical:IsDead() and not exports.qbx_medical:IsLaststand() then
        isShocked = true
        DebugPrint("Shock stun triggered: falling on ground with sparks and jitter.")
        
        -- Make player fall to the ground
        SetPedToRagdoll(ped, 3000, 3000, 0, true, true, false)
        
        -- Distort screen
        StartScreenEffect("Dont_Taze_Me_Bro", 3000, false)
        ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.1)
        
        -- Add Sparks Particle
        lib.requestNamedPtfxAsset("core")
        UseParticleFxAssetNextCall("core")
        local pfx = StartParticleFxLoopedOnEntity("ent_dst_electrical", ped, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, false, false, false)
        
        -- Apply jitter/convulsions
        CreateThread(function()
            local endTime = GetGameTimer() + 3000
            while GetGameTimer() < endTime do
                if not DoesEntityExist(ped) or exports.qbx_medical:IsDead() then break end
                ApplyForceToEntity(ped, 1, 
                    math.random(-20, 20)/100.0, 
                    math.random(-20, 20)/100.0, 
                    math.random(0, 10)/100.0, 
                    0.0, 0.0, 0.0, 0, false, true, true, false, true)
                Wait(50)
            end
        end)

        SetTimeout(3000, function()
            StopParticleFxLooped(pfx, false)
            isShocked = false
            DebugPrint("Stun effect cleared.")
        end)
    end

    if GetEntityHealth(ped) - amount <= 0 then
       exports.qbx_medical:KillPlayer()
    end
    SetEntityHealth(ped, GetEntityHealth(ped) - amount)
end)





-- Respond to qbx_medical death/laststand for Level 1 respawn
RegisterNetEvent('qbx_medical:client:onPlayerDied', function()
    if InEvent and LocalEventState.level == 1 then
        TriggerServerEvent("ng_event:server:RespawnPlayerL1")
    end
end)

RegisterNetEvent('qbx_medical:client:onPlayerLaststand', function()
    if InEvent and LocalEventState.level == 1 then
        TriggerServerEvent("ng_event:server:RespawnPlayerL1")
    end
end)
