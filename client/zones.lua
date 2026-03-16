local zones = {}

RegisterNetEvent("ng_event:client:SetupZones", function()
    -- Level 1 Panels
    for i, coords in ipairs(Config.Levels[1].panels) do
        exports.ox_target:addSphereZone({
            coords = coords,
            radius = 1.0,
            debug = Config.Debug,
            options = {
                {
                    name = 'ng_event_panel_'..i,
                    icon = 'fas fa-bolt',
                    label = 'Interact Panel',
                    distance = 2.0,
                    onSelect = function()
                        TriggerServerEvent("ng_event:server:InteractPanel", i)
                    end,
                    canInteract = function()
                        local isDead = exports.qbx_medical:isDead()
                        DebugPrint("Panel " .. i .. " can interact: " .. tostring(InEvent) .. " " .. tostring(CurrentLevel) .. " Dead: " .. tostring(isDead))
                        return InEvent and CurrentLevel == 1 and not isDead
                    end
                }
            }
        })
        table.insert(zones, 'ng_event_panel_'..i)
    end

    -- Level 3 Treasure
    exports.ox_target:addSphereZone({
        coords = Config.Levels[3].treasureBoxCoords,
        radius = 1.5,
        debug = Config.Debug,
        options = {
            {
                name = 'ng_event_treasure3',
                icon = 'fas fa-box',
                label = 'Loot Treasure',
                distance = 2.5,
                onSelect = function()
                    TriggerServerEvent("ng_event:server:LootTreasure3")
                    CurrentLevel = 4 -- Optimistic update
                    RefreshUI()
                end,
                canInteract = function()
                    DebugPrint("Treasure 3 can interact: " .. tostring(InEvent) .. " " .. tostring(CurrentLevel))
                    return InEvent and CurrentLevel == 3
                end
            }
        }
    })
    table.insert(zones, 'ng_event_treasure3')

    -- Level 4 Treasure
    exports.ox_target:addSphereZone({
        coords = Config.Levels[4].treasureBoxCoords,
        radius = 1.5,
        debug = Config.Debug,
        options = {
            {
                name = 'ng_event_treasure4',
                icon = 'fas fa-box',
                label = 'Loot Underwater Treasure',
                distance = 2.5,
                onSelect = function()
                    TriggerServerEvent("ng_event:server:LootTreasure4")
                end,
                canInteract = function()
                    DebugPrint("Treasure 4 can interact: " .. tostring(InEvent) .. " " .. tostring(CurrentLevel))
                    return InEvent and CurrentLevel == 4
                end
            }
        }
    })
    table.insert(zones, 'ng_event_treasure4')

    -- Level 6 Finish Markers
    for i, coords in ipairs(Config.Levels[6].finishMarkers) do
        exports.ox_target:addSphereZone({
            coords = coords,
            radius = 2.0,
            debug = Config.Debug,
            options = {
                {
                    name = 'ng_event_escape_'..i,
                    icon = 'fas fa-flag-checkered',
                    label = 'Escape (Finish)',
                    distance = 3.0,
                    onSelect = function()
                        TriggerServerEvent("ng_event:server:ReachFinish")
                    end,
                    canInteract = function()
                        DebugPrint("Escape " .. i .. " can interact: " .. tostring(InEvent) .. " " .. tostring(CurrentLevel))
                        return InEvent and CurrentLevel == 6
                    end
                }
            }
        })
        table.insert(zones, 'ng_event_escape_'..i)
    end
end)

RegisterNetEvent("ng_event:client:RemoveZones", function()
    for _, id in ipairs(zones) do
        exports.ox_target:removeZone(id)
    end
    zones = {}
end)
