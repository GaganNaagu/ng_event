-- server/state_sync.lua
-- Production-ready StateBag synchronization for ng_event

---
-- Synchronizes a player's private EventState to their client via StateBags.
-- @param src number The player server ID.
---
function UpdatePlayerEventState(src)
    if not EventState.players[src] then 
        DebugPrint("Warning: UpdatePlayerEventState called for non-existent player " .. tostring(src))
        return 
    end

    local data = EventState.players[src]
    local PlayerObj = Player(src)

    -- Extracting only public/necessary data for the client
    PlayerObj.state:set('eventData', {
        level = data.displayLevel,
        tokens = data.tokens,
        arenaKills = data.arenaKills,
        finished = data.finished
    }, true) -- Replication ENABLED (third param true)

    DebugPrint("StateBag sync Sent for ID " .. src .. " | Level: " .. data.currentLevel)
end

---
-- Clears the player's event state bag.
-- @param src number The player server ID.
---
function ClearPlayerEventState(src)
    Player(src).state:set('eventData', nil, true)
    DebugPrint("StateBag cleared for ID " .. src)
end
