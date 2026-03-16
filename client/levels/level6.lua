local level6Entities = {}

RegisterNetEvent("ng_event:client:SetupLevel6Zones", function()
    if not InEvent then return end
    local cfg = Config.Levels[6]
    local model = cfg.finishEntityModel
    lib.requestModel(model)

    for i, coords in ipairs(cfg.finishMarkers) do
        local ent
        if cfg.finishEntityType == 'ped' then
            ent = CreatePed(4, model, coords.x, coords.y, coords.z, coords.w, false, false)
            SetEntityInvincible(ent, true)
            SetBlockingOfNonTemporaryEvents(ent, true)
            FreezeEntityPosition(ent, true)
        else
            ent = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)
            SetEntityHeading(ent, coords.w)
            FreezeEntityPosition(ent, true)
        end

        exports.ox_target:addLocalEntity(ent, {
            {
                name = 'ng_event_escape_'..i,
                icon = 'fas fa-flag-checkered',
                label = 'Escape (Finish)',
                distance = 3.0,
                onSelect = function()
                    TriggerServerEvent("ng_event:server:PlayerFinished")
                end,
                canInteract = function()
                    return InEvent and LocalEventState.level == 6 and LocalEventState.tokens[5]
                end
            }
        })
        table.insert(level6Entities, ent)
    end
    SetModelAsNoLongerNeeded(model)
end)

RegisterNetEvent("ng_event:client:RemoveZones", function()
    for _, ent in ipairs(level6Entities) do
        if DoesEntityExist(ent) then
            exports.ox_target:removeLocalEntity(ent)
            if IsEntityAPed(ent) then
                DeleteEntity(ent)
            else
                DeleteObject(ent)
            end
        end
    end
    level6Entities = {}
end)
-- Blip & Waypoint (shown after Level 5 success)
local level6Blip_Bridge = nil
local level6Blips_Finish = {}

RegisterNetEvent("ng_event:client:ShowLevel6Blip", function()
    if not InEvent then return end
    
    if level6Blip_Bridge then RemoveBlip(level6Blip_Bridge) end
    for _, blip in ipairs(level6Blips_Finish) do
        if blip then RemoveBlip(blip) end
    end
    level6Blips_Finish = {}
    
    local cfg = Config.Levels[6]
    
    -- Blip 1: Entrance of bridge to Cayo Island
    local bridgeCoords = cfg.blipCoords
    if bridgeCoords then
        level6Blip_Bridge = AddBlipForCoord(bridgeCoords.x, bridgeCoords.y, bridgeCoords.z)
        SetBlipSprite(level6Blip_Bridge, 126) -- Checkered flag
        SetBlipColour(level6Blip_Bridge, 2) -- Green
        SetBlipScale(level6Blip_Bridge, 1.0)
        SetBlipAsShortRange(level6Blip_Bridge, false)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("Event: Bridge Entrance")
        EndTextCommandSetBlipName(level6Blip_Bridge)
        SetBlipRoute(level6Blip_Bridge, true)
    end
    
    -- Blip 2: Finish coords where ped spawns (on ALL finish markers)
    if cfg.finishMarkers then
        for _, finishCoords in ipairs(cfg.finishMarkers) do
            local finishBlip = AddBlipForCoord(finishCoords.x, finishCoords.y, finishCoords.z)
            SetBlipSprite(finishBlip, 126) -- Checkered flag
            SetBlipColour(finishBlip, 1) -- Red to distinguish the final ped
            SetBlipScale(finishBlip, 1.0)
            SetBlipAsShortRange(finishBlip, false)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Event: Escape Vehicle / Target")
            EndTextCommandSetBlipName(finishBlip)
            table.insert(level6Blips_Finish, finishBlip)
        end
    end

    TriggerEvent("ng_event:client:ShowNotification", {title = "Final Step", description = "The escape points are marked on your GPS!", type = "inform"})
end)

RegisterNetEvent("ng_event:client:HideLevel6Blip", function()
    if level6Blip_Bridge then RemoveBlip(level6Blip_Bridge) level6Blip_Bridge = nil end
    for _, blip in ipairs(level6Blips_Finish) do
        if blip then RemoveBlip(blip) end
    end
    level6Blips_Finish = {}
end)
