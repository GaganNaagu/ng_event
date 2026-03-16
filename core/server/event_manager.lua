-- core/server/event_manager.lua
-- Manages the global event state, hosting, starting, and clean stopping.

EventManager = {}
EventManager.State = {
    active = false,
    hosting = false,
    id = 0,
    hostSource = 0,
    winners = {},
    liveWinners = {},
    history = {},    
    unlockedLevels = {},
    restrictedVehicleCount = 0
}

local HISTORY_FILE = "data/event_history.json"

function EventManager.LoadHistory()
    local content = LoadResourceFile(GetCurrentResourceName(), HISTORY_FILE)
    if content then
        local data = json.decode(content)
        if data then 
            EventManager.State.history = data 
            DebugPrint("Loaded " .. #data .. " history records from " .. HISTORY_FILE)
        else
            DebugPrint("Error: Failed to decode " .. HISTORY_FILE .. " content.")
        end
    else
        DebugPrint("No history file found (or empty), starting fresh.")
    end
end

function EventManager.SaveHistory()
    local jsonStr = json.encode(EventManager.State.history)
    local success = SaveResourceFile(GetCurrentResourceName(), HISTORY_FILE, jsonStr, -1)
    if success then
        DebugPrint("Successfully saved history to " .. HISTORY_FILE)
    else
        DebugPrint("Error: Failed to save history to " .. HISTORY_FILE)
    end
end

Citizen.CreateThread(function()
    Wait(100)
    EventManager.LoadHistory()
end)

function EventManager.HostEvent(source)
    if EventManager.State.active or EventManager.State.hosting then
        TriggerClientEvent("ng_event:client:ShowNotification", source, {title = "Error", description = "Event is already active or being hosted!", type = "error"})
        return false
    end

    EventManager.State.hosting = true
    EventManager.State.hostSource = source
    EventManager.State.id = Config.UseEventID and math.random(10, 99) or os.time()
    EventManager.State.winners = {}

    if PlayerManager then PlayerManager.ClearAllPlayers() end

    local desc = "An event is being hosted! Type /event to join!"
    if Config.UseEventID then
        desc = "An event is being hosted! Type /event (ID: " .. EventManager.State.id .. ") to join!"
    end

    TriggerClientEvent("ng_event:client:ShowNotification", -1, {
        title = "Event Hosting",
        description = desc,
        type = "inform"
    })
    DebugPrint("Event Hosting Started" .. (Config.UseEventID and (" with ID: " .. EventManager.State.id) or ""))
    return true
end

function EventManager.StartEvent(source, startLevel)
    if not EventManager.State.hosting then
        TriggerClientEvent("ng_event:client:ShowNotification", source, {title = "Error", description = "Host an event first!", type = "error"})
        return false
    end

    if EventManager.State.active then
        TriggerClientEvent("ng_event:client:ShowNotification", source, {title = "Error", description = "Event is already active!", type = "error"})
        return false
    end

    local participants = PlayerManager.GetPlayers()
    local playerCount = 0
    for _, _ in pairs(participants) do playerCount = playerCount + 1 end

    if playerCount == 0 then
        TriggerClientEvent("ng_event:client:ShowNotification", source, {title = "Error", description = "No players have joined!", type = "error"})
        return false
    end

    startLevel = startLevel or 1
    local maxLevels = Config.LevelOrder and #Config.LevelOrder or 6
    if startLevel < 1 or startLevel > maxLevels then
        TriggerClientEvent("ng_event:client:ShowNotification", source, {title = "Error", description = "Invalid level (1-"..maxLevels.." only)!", type = "error"})
        return false
    end

    EventManager.State.active = true
    EventManager.State.hosting = false

    for src, data in pairs(participants) do
        Framework.RevivePlayer(src)
        if BucketManager then BucketManager.AddPlayerToMainBucket(src) end
        if VehicleManager then VehicleManager.SpawnEventVehicle(src, Config.EventVehicles.initialVehicle, nil, startLevel == 1) end
        
        PlayerManager.InitializePlayerLevel(src, startLevel)

        TriggerClientEvent("ng_event:client:EventStarted", src)
        StateManager.UpdatePlayerEventState(src)
    end

    Wait(100)
    for i = 1, startLevel do
        LevelManager.UnlockLevel(i)
    end

    for pSrc, _ in pairs(participants) do
        LevelManager.TriggerCumulativeSetup(pSrc, startLevel)
        TriggerClientEvent("ng_event:client:PlaySound", pSrc)
    end

    DebugPrint("Event Started at Level " .. startLevel .. " with " .. playerCount .. " players.")
    return true
end

function EventManager.StopEvent()
    if not (EventManager.State.active or EventManager.State.hosting) then return end
    
    local sessionData = {
        id = EventManager.State.id,
        date = os.date("%Y-%m-%d %H:%M:%S"),
        leaderboard = {}
    }

    local participants = PlayerManager.GetPlayers()
    for src, data in pairs(participants) do
        local tokenCount = 0
        if data.tokens then
            for _, has in pairs(data.tokens) do
                if has then tokenCount = tokenCount + 1 end
            end
        end

        table.insert(sessionData.leaderboard, {
            name = GetPlayerName(src),
            source = src,
            level = data.confirmedLevel or 1,
            tokens = tokenCount,
            finished = data.finished or false,
            place = data.place
        })
    end

    table.sort(sessionData.leaderboard, function(a, b)
        if a.finished and not b.finished then return true end
        if not a.finished and b.finished then return false end
        if a.finished and b.finished then
            return (a.place or 999) < (b.place or 999)
        end
        if a.level ~= b.level then return a.level > b.level end
        return a.tokens > b.tokens
    end)

    table.insert(EventManager.State.history, 1, sessionData)
    if #EventManager.State.history > 30 then table.remove(EventManager.State.history) end
    EventManager.SaveHistory()

    if LevelManager then LevelManager.CleanupAllLevels() end

    for src, data in pairs(participants) do
        PlayerManager.RemovePlayer(src, false) 
    end
    
    EventManager.State.active = false
    EventManager.State.hosting = false
    EventManager.State.id = 0
    EventManager.State.winners = {}
    EventManager.State.liveWinners = {}
    EventManager.State.unlockedLevels = {}
    EventManager.State.hostSource = 0
    EventManager.State.restrictedVehicleCount = 0
    
    GlobalState.ng_event_unlockedLevels = {}
    
    PlayerManager.ClearAllPlayers()
    if VehicleManager then VehicleManager.CleanupAllEventVehicles() end
    
    DebugPrint("Event fully cleaned up and ended.")
end

exports("HostEvent", EventManager.HostEvent)
exports("StartEvent", EventManager.StartEvent)
exports("StopEvent", EventManager.StopEvent)
