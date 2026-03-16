-- levels/level2_blood_arena/client.lua
-- Client logic for The Blood Arena

local Level2 = {}
local LevelZones = {}

function Level2.SetupZones()
    -- Hangar Entrance Interaction
    local id = Target.AddZone({
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
                    return LocalEventState and LocalEventState.level == 2 and LocalEventState.tokens[1]
                end
            }
        }
    })
    table.insert(LevelZones, id)
end

function Level2.Cleanup()
    for _, id in ipairs(LevelZones) do Target.RemoveZone(id) end
    LevelZones = {}
end

LevelManager.RegisterLevel(2, Level2)

local hangarBlip = nil

RegisterNetEvent("ng_event:client:ShowHangarBlip", function()
    if hangarBlip then RemoveBlip(hangarBlip) end
    
    local coords = Config.Levels[1].hangarCoords
    if coords then
        hangarBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
        SetBlipSprite(hangarBlip, 473) 
        SetBlipColour(hangarBlip, 5) 
        SetBlipScale(hangarBlip, 1.0)
        SetBlipAsShortRange(hangarBlip, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Event: Arena Entrance")
        EndTextCommandSetBlipName(hangarBlip)
        SetBlipRoute(hangarBlip, true)
        
        TriggerEvent("ng_event:client:ShowNotification", {title = "Event", description = "Hangar location marked on your GPS.", type = "inform"})
    end
end)

RegisterNetEvent("ng_event:client:HideHangarBlip", function()
    if hangarBlip then
        RemoveBlip(hangarBlip)
        hangarBlip = nil
    end
end)
