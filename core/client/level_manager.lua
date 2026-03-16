-- core/client/level_manager.lua
-- Client-side manager for organizing level logic modules.

LevelManager = {}
LevelManager.ActiveLevels = {}

function LevelManager.RegisterLevel(id, methods)
    LevelManager.ActiveLevels[id] = methods
end

function LevelManager.UnlockLevelForClient(level)
    if LevelManager.ActiveLevels[level] and LevelManager.ActiveLevels[level].SetupZones then
        LevelManager.ActiveLevels[level].SetupZones()
    end
end

RegisterNetEvent("ng_event:client:UnlockLevel", function(level)
    if not InEvent then return end
    LevelManager.UnlockLevelForClient(level)
end)

-- Execute generic steps from server 
RegisterNetEvent("ng_event:client:ExecuteStep", function(level, action, args)
    if not InEvent then return end
    if LevelManager.ActiveLevels[level] and LevelManager.ActiveLevels[level].ExecuteStep then
        LevelManager.ActiveLevels[level].ExecuteStep(action, args)
    end
end)

RegisterNetEvent("ng_event:client:EventEnded", function()
    for id, methods in pairs(LevelManager.ActiveLevels) do
        if methods.Cleanup then
            methods.Cleanup()
        end
    end
end)
