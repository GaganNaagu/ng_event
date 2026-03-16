-- core/server/level_manager.lua
-- Orchestrates the dynamic progression of level modules based on Config.LevelOrder.

LevelManager = {}
LevelManager.ActiveLevels = {} -- Allows extending/triggering methods dynamically

function LevelManager.RegisterLevel(id, methods)
    LevelManager.ActiveLevels[id] = methods
end

function LevelManager.UnlockLevel(level)
    if EventManager.State.unlockedLevels[level] then return end
    EventManager.State.unlockedLevels[level] = true
    GlobalState.ng_event_unlockedLevels = EventManager.State.unlockedLevels
    DebugPrint("SERVER DEBUG: Unlocking Level " .. level)
    
    TriggerEvent("ng_event:server:UnlockLevel", level)
    
    local players = PlayerManager.GetPlayers()
    for src, _ in pairs(players) do
        TriggerClientEvent("ng_event:client:UnlockLevel", src, level)
    end
end

function LevelManager.TriggerCumulativeSetup(src, currentLevel)
    for i = 1, currentLevel do
        if LevelManager.ActiveLevels[i] and LevelManager.ActiveLevels[i].SetupPlayer then
            LevelManager.ActiveLevels[i].SetupPlayer(src)
        end
    end
end

function LevelManager.PlayerDied(src, level)
    if not level then return end
    
    if LevelManager.ActiveLevels[level] and LevelManager.ActiveLevels[level].PlayerDied then
        LevelManager.ActiveLevels[level].PlayerDied(src)
    else
        DebugPrint("Warning: No specific death handler for Level " .. level .. ". Using fallback revive.")
        Framework.RevivePlayer(src)
        -- Fallback: Just revive them where they are if no level specific logic exists
    end
end

function LevelManager.PlayerCompleted(src, level)
    local data = PlayerManager.GetPlayer(src)
    if not data then return end

    if data.tokens[level] then return end
    data.tokens[level] = true

    if StateManager then StateManager.UpdatePlayerEventState(src) end

    local maxLevels = Config.LevelOrder and #Config.LevelOrder or 6

    if level < maxLevels then
        local nextLevel = level + 1
        TransitionManager.BeginLevelTransition(src, nextLevel)
        LevelManager.UnlockLevel(nextLevel)

        -- Pre-Setup the next level for the player server-side if needed
        if LevelManager.ActiveLevels[nextLevel] and LevelManager.ActiveLevels[nextLevel].SetupPlayer then
            LevelManager.ActiveLevels[nextLevel].SetupPlayer(src)
        end
    else
        -- If finished the final level, trigger finish
        TriggerEvent("ng_event:server:PlayerFinished", src)
    end
end

function LevelManager.CleanupAllLevels()
    for id, methods in pairs(LevelManager.ActiveLevels) do
        if methods.Cleanup then
            methods.Cleanup()
        end
    end
end

-- Used by specific level modules to signal generic completion
RegisterNetEvent("ng_event:server:LevelCompleted", function(level)
    local src = source
    if not EventManager.State.active or not PlayerManager.GetPlayer(src) then return end
    LevelManager.PlayerCompleted(src, level)
end)
