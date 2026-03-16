-- levels/level1_trial_of_shock/client.lua
-- Client logic for Trial of Shock.

local Level1 = {}
local level1Blip = nil
local hangarBlip = nil
local isShocked = false
local LevelZones = {}

function Level1.CreateBlip()
    if level1Blip then RemoveBlip(level1Blip) end
    local cx, cy, cz = 0, 0, 0
    local panels = Config.Levels[1].panels
    for _, c in ipairs(panels) do
        cx = cx + c.x
        cy = cy + c.y
        cz = cz + c.z
    end
    cx, cy, cz = cx / #panels, cy / #panels, cz / #panels
    
    level1Blip = AddBlipForCoord(cx, cy, cz)
    SetBlipSprite(level1Blip, 354)
    SetBlipColour(level1Blip, 5) 
    SetBlipScale(level1Blip, 1.0)
    SetBlipAsShortRange(level1Blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Event: Trial of Shock")
    EndTextCommandSetBlipName(level1Blip)
    SetBlipRoute(level1Blip, true)
end

function Level1.SetupZones()
    Level1.CreateBlip()
    
    for i, coords in ipairs(Config.Levels[1].panels) do
        local id = Target.AddZone({
            coords = coords,
            radius = 1.0,
            debug = Config.Debug,
            options = {
                {
                    name = 'ng_event_panel_'..i,
                    icon = 'fas fa-bolt',
                    label = "Interact Panel",
                    distance = 2.0,
                    onSelect = function()
                        TriggerServerEvent("ng_event:server:InteractPanel", i)
                    end,
                    canInteract = function()
                        return LocalEventState and LocalEventState.level == 1 and not Framework.IsDead() and not Framework.IsLaststand() and not isShocked
                    end
                }
            }
        })
        table.insert(LevelZones, id)
    end
end

function Level1.Cleanup()
    if level1Blip then RemoveBlip(level1Blip) level1Blip = nil end
    if hangarBlip then RemoveBlip(hangarBlip) hangarBlip = nil end
    for _, id in ipairs(LevelZones) do Target.RemoveZone(id) end
    LevelZones = {}
end

LevelManager.RegisterLevel(1, Level1)

RegisterNetEvent("ng_event:client:ShowLevel1Blip", function()
    Level1.CreateBlip()
end)

RegisterNetEvent("ng_event:client:HideLevel1Blip", function()
    if level1Blip then RemoveBlip(level1Blip) level1Blip = nil end
end)

RegisterNetEvent("ng_event:client:ShowHangarBlip", function()
    if hangarBlip then RemoveBlip(hangarBlip) end
    local coords = Config.Levels[1].hangarCoords
    if coords then
        hangarBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(hangarBlip, 357)
        SetBlipColour(hangarBlip, 5) 
        SetBlipScale(hangarBlip, 1.0)
        SetBlipRoute(hangarBlip, true)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Event: Next Level")
        EndTextCommandSetBlipName(hangarBlip)
    end
end)

RegisterNetEvent("ng_event:client:TakeDamage", function(amount)
    local ped = PlayerPedId()

    if not Framework.IsDead() and not Framework.IsLaststand() then
        isShocked = true
        SetPedToRagdoll(ped, 3000, 3000, 0, true, true, false)
        StartScreenEffect("Dont_Taze_Me_Bro", 3000, false)
        ShakeGameplayCam("SMALL_EXPLOSION_SHAKE", 0.1)
        
        lib.requestNamedPtfxAsset("core")
        UseParticleFxAssetNextCall("core")
        local pfx = StartParticleFxLoopedOnEntity("ent_dst_electrical", ped, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, false, false, false)
        
        CreateThread(function()
            local endTime = GetGameTimer() + 3000
            while GetGameTimer() < endTime do
                if not DoesEntityExist(ped) or Framework.IsDead() then break end
                ApplyForceToEntity(ped, 1, math.random(-20, 20)/100.0, math.random(-20, 20)/100.0, math.random(0, 10)/100.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                Wait(50)
            end
        end)

        SetTimeout(3000, function()
            StopParticleFxLooped(pfx, false)
            isShocked = false
        end)
    end

    if GetEntityHealth(ped) - amount <= 0 then
       Framework.KillPlayer()
    else
        SetEntityHealth(ped, GetEntityHealth(ped) - amount)
    end
end)

Citizen.CreateThread(function()
    while true do
        local sleep = 1000
        if LocalEventState and LocalEventState.level == 1 then
            sleep = 0
            for _, coords in ipairs(Config.Levels[1].panels) do
                DrawMarker(2, coords.x, coords.y, coords.z + 0.5, 0.0, 0.0, 0.0, 0.0, 180.0, 0.0, 0.5, 0.5, 0.5, 255, 255, 0, 100, true, true, 2, false, nil, nil, false)
            end
        end
        Wait(sleep)
    end
end)
