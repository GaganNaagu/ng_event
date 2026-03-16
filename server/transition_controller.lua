-- server/transition_controller.lua
-- Manages safe level transitions and authoritative respawn logic

---
-- Prepares a player for the next level visually without changing their respawn authority.
-- @param src number Player server ID.
-- @param nextLevel number The level the player is moving towards.
---
function BeginLevelTransition(src, nextLevel, safeSpawn)
    local data = EventState.players[src]
    if not data then return end

    data.displayLevel = nextLevel
    data.pendingLevel = nextLevel
    data.transitioning = true
    
    -- Update safe spawn if provided (checkpoint)
    if safeSpawn then
        data.lastSafeSpawn = safeSpawn
    end

    UpdatePlayerEventState(src)
    DebugPrint(string.format("^3[TRANSITION] Player %d began transition to Level %d (Display updated, Confirmation Pending)^7", src, nextLevel))
end

---
-- Confirms that a player has physically entered the next level via proper interaction.
-- Sets their respawn authority to the new level.
-- @param src number Player server ID.
---
function ConfirmLevelEntry(src)
    local data = EventState.players[src]
    if not data or not data.transitioning or not data.pendingLevel then
        return
    end

    local oldLevel = data.confirmedLevel
    data.confirmedLevel = data.pendingLevel
    data.currentLevel = data.pendingLevel -- Keep for legacy compatibility if needed
    data.transitioning = false
    data.pendingLevel = nil

    -- Update lastSafeSpawn based on new confirmed level
    local ped = GetPlayerPed(src)
    if DoesEntityExist(ped) then
        data.lastSafeSpawn = GetEntityCoords(ped)
    end

    UpdatePlayerEventState(src)
    DebugPrint(string.format("^2[TRANSITION] Player %d confirmed entry to Level %d (Respawn authority UPDATED)^7", src, data.confirmedLevel))
end

---
-- Centralized death handler for event players.
-- strictly follows confirmedLevel for respawn logic.
---
function HandleEventDeath(src)
    local data = EventState.players[src]
    if not data then return end

    local ped = GetPlayerPed(src)
    local level = data.confirmedLevel

    DebugPrint(string.format("^1[DEATH] Player %d died. ConfirmedLevel: %d | Transitioning: %s^7", 
        src, level, tostring(data.transitioning)))

    -- If they were transitioning, we strictly put them back to their last safe spawn of the OLD level
    if data.transitioning then
        exports.qbx_medical:Revive(src, true)
        if data.lastSafeSpawn then
            SetEntityCoords(ped, data.lastSafeSpawn.x, data.lastSafeSpawn.y, data.lastSafeSpawn.z, false, false, false, false)
        else
            -- Fallback to lobby if defined, otherwise end coords
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

    -- Standard level-specific respawn logic
    if level == 1 then
        TriggerEvent("ng_event:server:RespawnPlayerL1", src)
    elseif level == 2 then
        TriggerEvent("ng_event:server:RespawnPlayerL2", src)
    elseif level == 3 then
        TriggerEvent("ng_event:server:RespawnPlayerL3", src)
    elseif level == 4 then
        -- Level 4 death just resps at L3 -> L4 entry or similar? 
        -- For now, let's use lastSafeSpawn as a universal backup
        exports.qbx_medical:Revive(src, true)
        if data.lastSafeSpawn then
            SetEntityCoords(ped, data.lastSafeSpawn.x, data.lastSafeSpawn.y, data.lastSafeSpawn.z, false, false, false, false)
        end
    elseif level == 5 then
        -- Level 5 has its own failure logic
        TriggerEvent("ng_event:server:PlayerDiedL5", src)
    end
end

-- Net event for client to trigger global death
RegisterNetEvent("ng_event:server:HandleDeath", function()
    HandleEventDeath(source)
end)
