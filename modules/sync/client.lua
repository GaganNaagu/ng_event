-- modules/sync/client.lua
-- Centralized replication listener for StateBags on the Client.

AddStateBagChangeHandler('eventData', nil, function(bagName, key, value, _reserved, replicated)
    if not value then return end
    local plySource = tonumber(bagName:gsub('player:', ''), 10)
    
    if plySource == GetPlayerServerId(PlayerId()) then
        LocalEventState = LocalEventState or {}
        LocalEventState.level = value.level
        LocalEventState.tokens = value.tokens
        LocalEventState.arenaKills = value.arenaKills
        LocalEventState.finished = value.finished
        LocalEventState.place = value.place

        if RefreshUI then
            RefreshUI()
        end
    end
end)

AddStateBagChangeHandler('ng_event_unlockedLevels', nil, function(bagName, key, value)
    if not InEvent then return end 
    if not value then return end
    
    for level, unlocked in pairs(value) do
        if unlocked then
            if LevelManager then
                LevelManager.UnlockLevelForClient(tonumber(level))
            end
        end
    end
end)
