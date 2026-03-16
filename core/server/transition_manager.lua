-- core/server/transition_manager.lua
-- Manages safe level transitions and authoritative respawn logic.

TransitionManager = {}

function TransitionManager.BeginLevelTransition(src, nextLevel, safeSpawn)
    local data = PlayerManager.GetPlayer(src)
    if not data then return end

    data.displayLevel = nextLevel
    data.pendingLevel = nextLevel
    data.transitioning = true
    
    if safeSpawn then
        data.lastSafeSpawn = safeSpawn
    end

    if StateManager then StateManager.UpdatePlayerEventState(src) end
    DebugPrint(string.format("^3[TRANSITION] Player %d began transition to Level %d (Display updated)^7", src, nextLevel))
end

function TransitionManager.ConfirmLevelEntry(src)
    local data = PlayerManager.GetPlayer(src)
    if not data or not data.transitioning or not data.pendingLevel then return end

    local oldLevel = data.confirmedLevel
    data.confirmedLevel = data.pendingLevel
    data.currentLevel = data.pendingLevel 
    data.transitioning = false
    data.pendingLevel = nil

    local ped = GetPlayerPed(src)
    if DoesEntityExist(ped) then
        data.lastSafeSpawn = GetEntityCoords(ped)
    end

    if StateManager then StateManager.UpdatePlayerEventState(src) end
    DebugPrint(string.format("^2[TRANSITION] Player %d confirmed entry to Level %d^7", src, data.confirmedLevel))
end

function TransitionManager.HandleEventDeath(src)
    local data = PlayerManager.GetPlayer(src)
    if not data then return end

    local ped = GetPlayerPed(src)
    local level = data.confirmedLevel

    DebugPrint(string.format("^1[DEATH] Player %d died. ConfirmedLevel: %d | Transitioning: %s^7", 
        src, level, tostring(data.transitioning)))

    if data.transitioning then
        Framework.RevivePlayer(src)
        if data.lastSafeSpawn then
            SetEntityCoords(ped, data.lastSafeSpawn.x, data.lastSafeSpawn.y, data.lastSafeSpawn.z, false, false, false, false)
        else
            local fallback = Config.TeleportOnEventEndCoords
            SetEntityCoords(ped, fallback.x, fallback.y, fallback.z, false, false, false, false)
            if fallback.w then SetEntityHeading(ped, fallback.w) end
        end
        TriggerClientEvent("ng_event:client:ShowNotification", src, {
            title = "Eliminated",
            description = "You were eliminated during transition! Re-enter properly.",
            type = "error"
        })
        return
    end

    if LevelManager then
        LevelManager.PlayerDied(src, level)
    end
end

RegisterNetEvent("ng_event:server:HandleDeath", function()
    TransitionManager.HandleEventDeath(source)
end)
