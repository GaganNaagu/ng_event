RegisterNetEvent("ng_event:client:SetupLevel2Zones", function()
    if not InEvent then return end
    
    TriggerEvent("ng_event:client:ClearLevelZones", 2)
    
    -- Hangar Entrance Interaction
    local id = exports.ox_target:addSphereZone({
        coords = Config.Levels[1].hangarCoords,
        radius = 2.0,
        debug = Config.Debug,
        options = {
            {
                name = 'ng_event_hangar_entrance',
                icon = 'fas fa-door-open',
                label = 'Enter Arena',
                distance = 3.0,
                onSelect = function()
                    TriggerServerEvent("ng_event:server:EnterArena")
                end,
                canInteract = function()
                    return InEvent and LocalEventState.level == 2 and LocalEventState.tokens[1]
                end
            }
        }
    })
    table.insert(LevelZones[2], id)
    table.insert(RegisteredZones, id) -- Fallback
end)

-- Respond to qbx_medical death/laststand for Level 2 respawn
RegisterNetEvent('qbx_medical:client:onPlayerDied', function()
    if InEvent and LocalEventState.level == 2 then
        TriggerServerEvent("ng_event:server:RespawnPlayerL2")
    end
end)

RegisterNetEvent('qbx_medical:client:onPlayerLaststand', function()
    if InEvent and LocalEventState.level == 2 then
        TriggerServerEvent("ng_event:server:RespawnPlayerL2")
    end
end)


local hangarBlip = nil

RegisterNetEvent("ng_event:client:ShowHangarBlip", function()
    if hangarBlip then RemoveBlip(hangarBlip) end
    
    local coords = Config.Levels[1].hangarCoords
    hangarBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(hangarBlip, 473) -- Hangar sprite
    SetBlipColour(hangarBlip, 5) -- Yellow
    SetBlipScale(hangarBlip, 1.0)
    SetBlipAsShortRange(hangarBlip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Event: Arena Entrance")
    EndTextCommandSetBlipName(hangarBlip)
    SetBlipRoute(hangarBlip, true)
    
    TriggerEvent("ng_event:client:ShowNotification", {title = "Event", description = "Hangar location marked on your GPS.", type = "inform"})
end)

RegisterNetEvent("ng_event:client:HideHangarBlip", function()
    if hangarBlip then
        RemoveBlip(hangarBlip)
        hangarBlip = nil
    end
end)

