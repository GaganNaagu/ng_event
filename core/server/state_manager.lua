-- core/server/state_manager.lua
-- Central authority determining what data belongs in the global payload.

StateManager = {}

function StateManager.UpdatePlayerEventState(src)
    local data = PlayerManager.GetPlayer(src)
    if not data then return end
    
    local stateData = {
        level = data.displayLevel or 1,
        tokens = data.tokens or {},
        arenaKills = data.arenaKills or 0,
        finished = data.finished or false,
        place = data.place
    }
    
    Player(src).state:set('eventData', stateData, true)
end

function StateManager.ClearPlayerEventState(src)
    Player(src).state:set('eventData', nil, true)
end
