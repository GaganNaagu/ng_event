EventState = {
    active = false,
    hosting = false,
    id = 0,
    players = {},
    winners = {}, -- Live winners sources (for logic)
    liveWinners = {}, -- Persistent winners of the current/last session {name, source, time, place}
    history = {},    -- Loaded from JSON
    maxWinners = Config.MaxWinners,
    bucket = Config.MainBucket,
    unlockedLevels = {},
    hostSource = 0
}

GlobalState.ng_event_unlockedLevels = {}
EventState.stopping = false -- Flag to prevent double podium

function IsAdmin(src)
    if not src or src == 0 then return false end
    local identifiers = GetPlayerIdentifiers(src)
    if not identifiers then return false end
    
    for _, adminId in ipairs(Config.Admins or {}) do
        for _, playerId in ipairs(identifiers) do
            if playerId == adminId then
                return true
            end
        end
    end
    return false
end

local HISTORY_FILE = "data/event_history.json"

function SaveHistory()
    local jsonStr = json.encode(EventState.history)
    local success = SaveResourceFile(GetCurrentResourceName(), HISTORY_FILE, jsonStr, -1)
    if success then
        DebugPrint("Successfully saved history to " .. HISTORY_FILE)
    else
        DebugPrint("Error: Failed to save history to " .. HISTORY_FILE)
    end
end

function LoadHistory()
    local content = LoadResourceFile(GetCurrentResourceName(), HISTORY_FILE)
    if content then
        local data = json.decode(content)
        if data then 
            EventState.history = data 
            DebugPrint("Loaded " .. #data .. " history records from " .. HISTORY_FILE)
        else
            DebugPrint("Error: Failed to decode " .. HISTORY_FILE .. " content.")
        end
    else
        DebugPrint("No history file found (or empty), starting fresh.")
    end
end

-- Load history on startup
Citizen.CreateThread(function()
    Wait(100)
    LoadHistory()
end)

-- Utility function for validation
function ValidatePlayer(src)
    return EventState.active and EventState.players[src]
end

-- Helper to get a random location from a table or a single vector
function GetRandomLocation(locs)
    if not locs then return nil end
    if type(locs) ~= "table" then return locs end
    if #locs == 0 then return nil end
    return locs[math.random(1, #locs)]
end

function getTableSize(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function UpdateLevel(src, level, safeSpawn)
    if not EventState.players[src] then return end
    
    BeginLevelTransition(src, level, safeSpawn)
    
    if not EventState.unlockedLevels[level] then
        UnlockLevel(level)
    end
end

function UnlockLevel(level)
    if EventState.unlockedLevels[level] then return end
    EventState.unlockedLevels[level] = true
    GlobalState.ng_event_unlockedLevels = EventState.unlockedLevels
    DebugPrint("SERVER DEBUG: Unlocking Level " .. level)
    
    -- Notify other server scripts (e.g. Lion Controller)
    TriggerEvent("ng_event:server:UnlockLevel", level)
    
    -- Direct trigger to ensure participants get it immediately without waiting for statebag sync
    for src, _ in pairs(EventState.players) do
        TriggerClientEvent("ng_event:client:UnlockLevel", src, level)
    end
end

-- Server-Authoritative Heartbeat Sync (Enforces state every 10 seconds)
Citizen.CreateThread(function()
    while true do
        Wait(10000)
        if EventState.active then
            for src, _ in pairs(EventState.players) do
                UpdatePlayerEventState(src)
            end
        end
    end
end)

-- Allow client to "fetch" data when needed (e.g. on join or reconnect)
RegisterNetEvent("ng_event:server:RequestSync", function()
    local src = source
    UpdatePlayerEventState(src)
end)

local podiumTimerId = 0
local podiumFinaleActive = false

-- Print winners to discord/console, cleanup, teleport out
function StopEvent()
    if not (EventState.active or EventState.hosting) then return end
    
    podiumTimerId = podiumTimerId + 1 -- Invalidates any pending podium timeouts
    
    -- Capture Session Data for History
    local sessionData = {
        id = EventState.id,
        date = os.date("%Y-%m-%d %H:%M:%S"),
        leaderboard = {}
    }

    -- Build the leaderboard from current players
    for src, data in pairs(EventState.players) do
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

    -- Sort leaderboard (Finished first, then by level, then tokens)
    table.sort(sessionData.leaderboard, function(a, b)
        if a.finished and not b.finished then return true end
        if not a.finished and b.finished then return false end
        if a.finished and b.finished then
            return (a.place or 999) < (b.place or 999)
        end
        if a.level ~= b.level then return a.level > b.level end
        return a.tokens > b.tokens
    end)

    -- Prepend to history
    table.insert(EventState.history, 1, sessionData)
    if #EventState.history > 30 then -- Keep last 30 sessions
        table.remove(EventState.history)
    end
    SaveHistory()

    -- Cleanup all levels (defined in respective files)
    TriggerEvent("ng_event:server:CleanupLevel3")
    TriggerEvent("ng_event:server:CleanupLevel5")

    -- Teleport and reset buckets
    for src, data in pairs(EventState.players) do
        local ped = GetPlayerPed(src)
        if ped > 0 then
            -- Reset bucket back to default (0)
            SetPlayerRoutingBucket(src, 0)
            -- Clear StateBag
            ClearPlayerEventState(src)
            
            -- SKIP TELEPORT if we are in the podium finale
            if not podiumFinaleActive and Config.TeleportOnEventEnd then
                SetEntityCoords(ped, Config.TeleportOnEventEndCoords.x, Config.TeleportOnEventEndCoords.y, Config.TeleportOnEventEndCoords.z, false, false, false, false)
                if Config.TeleportOnEventEndCoords.w then SetEntityHeading(ped, Config.TeleportOnEventEndCoords.w) end
            end
            
            -- Reset PVP/Freeze
            TriggerClientEvent("ng_event:client:SetPVPState", src, true)
            FreezeEntityPosition(ped, false)
        end
        
        -- Restore inventory
        RestorePlayerInventory(src)

        -- Clear level specific states
        CleanupPersonalBucketArea(src)
        
        -- Cleanup personal vehicle
        DeleteEventVehicle(src)
        
        -- Notify Client to hide HUD/Reset UI state
        TriggerClientEvent("ng_event:client:EventEnded", src)
    end
    
    -- Clear global state
    EventState.active = false
    EventState.hosting = false
    EventState.stopping = false
    EventState.id = 0
    EventState.winners = {}
    EventState.liveWinners = {}
    EventState.unlockedLevels = {}
    EventState.hostSource = 0
    EventState.vehicleSpawnIndex = 0
    EventState.restrictedVehicleCount = 0
    GlobalState.ng_event_unlockedLevels = {}
    
    EventState.players = {}
    EventState.disconnectedPlayers = {}
    
    CleanupAllEventVehicles()
    podiumFinaleActive = false -- Final reset
    DebugPrint("Event fully cleaned up and ended.")
end

RegisterNetEvent("ng_event:server:PlayerFinished", function()
    local src = source
    if not ValidatePlayer(src) then return end
    
    if EventState.players[src].pendingLevel == 6 then
        ConfirmLevelEntry(src)
    end

    if EventState.players[src].confirmedLevel ~= 6 then return end
    if EventState.players[src].finished then return end

    -- Optional Token Validation
    local hasAll = true
    for i=1, 5 do
        if not EventState.players[src].tokens[i] then
            hasAll = false
            break
        end
    end

    if not hasAll then
        DebugPrint("Player " .. src .. " tried to finish without all tokens!")
    end

    -- Record the finish
    table.insert(EventState.winners, src)
    EventState.players[src].finished = true
    
    local place = #EventState.winners
    EventState.players[src].place = place -- Store place for session history
    local cfg = Config.Levels[6]

    -- Detailed Winner Info
    local winnerInfo = {
        name = GetPlayerName(src),
        source = src,
        time = os.date("%Y-%m-%d %H:%M:%S"),
        place = place,
        eventId = EventState.id
    }
    table.insert(EventState.liveWinners, winnerInfo)
    
    -- Winner auto-save to history is now handled by session stop
    -- table.insert(EventState.history, 1, winnerInfo) 

    -- Teleport or Bucket Change for standard finish (before podium)
    local ped = GetPlayerPed(src)
    if cfg.winnerCoords then
        SetEntityCoords(ped, cfg.winnerCoords.x, cfg.winnerCoords.y, cfg.winnerCoords.z, false, false, false, false)
        if cfg.winnerCoords.w then SetEntityHeading(ped, cfg.winnerCoords.w) end
    end
    
    local winBucket = cfg.winnerBucket or 1
    SetPlayerRoutingBucket(src, winBucket)
    
    -- Notify only event participants
    for pSrc, _ in pairs(EventState.players) do
        TriggerClientEvent("ng_event:client:ShowNotification", pSrc, {title = "Event Result", description = GetPlayerName(src) .. " finished in Place #" .. place .. "!", type = "success"})
        TriggerClientEvent("ng_event:client:UpdateWinners", pSrc, place, #EventState.players)
    end
    
    -- Update all UIs
    TriggerEvent("event:ui:BroadcastSync")
    
end)

function TriggerPodiumSequence()
    DebugPrint("TriggerPodiumSequence called.")
    if not EventState.active or EventState.stopping then 
        DebugPrint("Podium aborted: Event active? " .. tostring(EventState.active) .. " | Stopping? " .. tostring(EventState.stopping))
        return 
    end
    EventState.stopping = true
    DebugPrint("Podium initiating...")
    
    -- Send all participants and their progress for grid layout
    local participants = {}
    for src, data in pairs(EventState.players) do
        local tokenCount = 0
        if data.tokens then
            for _, has in pairs(data.tokens) do
                if has then tokenCount = tokenCount + 1 end
            end
        end

        table.insert(participants, {
            source = src,
            name = GetPlayerName(src),
            finished = data.finished or false,
            place = data.place or 999,
            level = data.confirmedLevel or 1,
            tokens = tokenCount
        })
    end

    -- Sort for consistent grid (winners in front rows)
    table.sort(participants, function(a, b)
        if a.finished and not b.finished then return true end
        if not a.finished and b.finished then return false end
        if a.finished and b.finished then
            return (a.place or 999) < (b.place or 999)
        end
        if a.level ~= b.level then return a.level > b.level end
        return a.tokens > b.tokens
    end)
    
    -- Trigger client-side podium logic for all players
    podiumFinaleActive = true
    for src, _ in pairs(EventState.players) do
        -- UNIFY BUCKETS: Move everyone to main event bucket so they can see each other
        AddPlayerToMainBucket(src)
        
        -- Cleanup personal buckets (Level 5)
        CleanupPersonalBucketArea(src)

        TriggerClientEvent("ng_event:client:ShowNotification", src, {title = "Event Over", description = "The event has concluded! Initiating finale...", type = "inform"})
        -- Clear UI
        TriggerClientEvent("ng_event:client:HideUI", src)
        -- Start Podium with full participants list
        TriggerClientEvent("ng_event:client:ShowPodium", src, participants)
    end
    
    DebugPrint("Finale triggered for " .. getTableSize(EventState.players) .. " players. Waiting for duration...")
    
    -- Wait for the sequence to play fully (Podium + 2-Phase Finale)
    -- This is the default timer; it can be overridden by clients via 'SetPodiumDuration'
    local duration = (Config.Podium and Config.Podium.Duration or 15000) * 4 -- Increased safety default
    
    podiumTimerId = podiumTimerId + 1
    local currentId = podiumTimerId
    SetTimeout(duration, function()
        if podiumTimerId == currentId then
            StopEvent()
        end
    end)
end

function HostEvent(source)
    local target = source
    if EventState.active or EventState.hosting then
        TriggerClientEvent("ng_event:client:ShowNotification", source, {title = "Error", description = "Event is already active or being hosted!", type = "error"})
        return false
    end

    EventState.hosting = true
    EventState.hostSource = source
    EventState.id = Config.UseEventID and math.random(10, 99) or os.time()
    EventState.players = {}
    EventState.disconnectedPlayers = {}
    EventState.winners = {}

    local desc = "An event is being hosted! Type /event to join!"
    if Config.UseEventID then
        desc = "An event is being hosted! Type /event (ID: " .. EventState.id .. ") to join!"
    end

    TriggerClientEvent("ng_event:client:ShowNotification", -1, {
        title = "Event Hosting",
        description = desc,
        type = "inform"
    })
    DebugPrint("Event Hosting Started" .. (Config.UseEventID and (" with ID: " .. EventState.id) or ""))
    return true
end

function StartEvent(source, level)
    if not EventState.hosting then
        TriggerClientEvent("ng_event:client:ShowNotification", source, {title = "Error", description = "Host an event first!", type = "error"})
        return false
    end

    if EventState.active then
        TriggerClientEvent("ng_event:client:ShowNotification", source, {title = "Error", description = "Event is already active!", type = "error"})
        return false
    end

    local playerCount = 0
    for src, _ in pairs(EventState.players) do
        playerCount = playerCount + 1
    end

    if playerCount == 0 then
        TriggerClientEvent("ng_event:client:ShowNotification", source, {title = "Error", description = "No players have joined!", type = "error"})
        return false
    end

    local startLevel = level or 1
    if startLevel < 1 or startLevel > 6 then
        TriggerClientEvent("ng_event:client:ShowNotification", source, {title = "Error", description = "Invalid level (1-6 only)!", type = "error"})
        return false
    end

    EventState.active = true
    EventState.hosting = false

    -- 1. Initialize player states and mark them as "InEvent" on client
    for src, data in pairs(EventState.players) do
        -- Revive players at the start
        exports.qbx_medical:Revive(src, true)
        
        AddPlayerToMainBucket(src)
        
        -- Spawn event vehicle and trigger fade/warp sequence
        SpawnEventVehicle(src, Config.EventVehicles.initialVehicle, nil, startLevel == 1)
        
        if startLevel > 1 then
            -- If skip-starting, they are "at" the previous level logically (for respawns/setup)
            -- but "pending" the start level so they can enter it properly.
            data.confirmedLevel = startLevel - 1
            data.displayLevel = startLevel
            data.currentLevel = startLevel
            data.pendingLevel = startLevel
            data.transitioning = true
        else
            data.confirmedLevel = 1
            data.displayLevel = 1
            data.currentLevel = 1
            data.pendingLevel = nil
            data.transitioning = false
        end
        
        for i = 1, startLevel - 1 do
            data.tokens[i] = true
        end

        TriggerClientEvent("ng_event:client:EventStarted", src)
        UpdatePlayerEventState(src)
    end

    -- 2. Unlock the levels up to start level (This triggers SetupZones on clients)
    Wait(100)
    for i = 1, startLevel do
        UnlockLevel(i)
    end

    -- 3. Level-specific setup (Blips, Tokens, PVP - NO TELEPORT)
    for pSrc, _ in pairs(EventState.players) do
        TriggerCumulativeLevelSetup(pSrc, startLevel)
        TriggerClientEvent("ng_event:client:PlaySound", pSrc)
    end

    DebugPrint("Event Started at Level " .. startLevel .. " with " .. playerCount .. " players.")
    
    if startLevel == 1 then
        -- Tell clients to start 3-2-1-GO synchronized countdown after waiting for warp
        Citizen.CreateThread(function()
            Wait(6000)
            for src, _ in pairs(EventState.players) do
                TriggerClientEvent("ng_event:client:StartCountdown", src)
            end
        end)
    end
    
    return true
end

function JoinEvent(source, id)
    if not EventState.hosting then
        TriggerClientEvent("ng_event:client:ShowNotification", source, {title = "Error", description = "No event is currently being hosted!", type = "error"})
        return false
    end

    if EventState.active then
        TriggerClientEvent("ng_event:client:ShowNotification", source, {title = "Error", description = "Event has already started!", type = "error"})
        return false
    end

    if Config.UseEventID and id and (tonumber(id) ~= EventState.id) then
        TriggerClientEvent("ng_event:client:ShowNotification", source, {title = "Error", description = "Invalid Event ID!", type = "error"})
        return false
    end

    if EventState.players[source] then
        TriggerClientEvent("ng_event:client:ShowNotification", source, {title = "Info", description = "You have already joined!", type = "inform"})
        return false
    end

    EventState.players[source] = {
        currentLevel = 1,
        confirmedLevel = 1,
        displayLevel = 1,
        pendingLevel = nil,
        transitioning = false,
        lastSafeSpawn = nil,
        reachedL1Grid = false,
        tokens = {false, false, false, false, false},
        arenaKills = 0,
        level5 = nil,
        finished = false
    }

    UpdatePlayerEventState(source)

    if EventState.hostSource > 0 then
        TriggerClientEvent("ng_event:client:ShowNotification", EventState.hostSource, {
            title = "Event Join",
            description = "Player " .. source .. " has joined the event!",
            type = "inform"
        })
    end

    TriggerClientEvent("ng_event:client:ShowNotification", source, {title = "Success", description = "You joined the event! Wait for it to start.", type = "success"})
    DebugPrint("Player " .. source .. " joined the event host.")
    
    -- Save and wipe inventory to prepare for the event
    SavePlayerInventory(source)
    ClearPlayerInventory(source)
    
    return true
end

function LeaveEvent(source, reason)
    if not EventState.players[source] then return false end
    
    local ped = GetPlayerPed(source)
    if ped > 0 then
        -- Reset Bucket
        SetPlayerRoutingBucket(source, 0)
        -- Clear State Bags
        ClearPlayerEventState(source)
        -- Teleport back if configured
        if Config.TeleportOnEventEnd then
            SetEntityCoords(ped, Config.TeleportOnEventEndCoords.x, Config.TeleportOnEventEndCoords.y, Config.TeleportOnEventEndCoords.z, false, false, false, false)
            if Config.TeleportOnEventEndCoords.w then SetEntityHeading(ped, Config.TeleportOnEventEndCoords.w) end
        end
        -- Reset PVP/Freeze
        TriggerClientEvent("ng_event:client:SetPVPState", source, true)
        FreezeEntityPosition(ped, false)
    end

    -- Restore inventory when leaving the event
    RestorePlayerInventory(source)

    -- Clear level specific states if needed
    CleanupPersonalBucketArea(source)
    
    -- Final state wipe
    EventState.players[source] = nil
    
    -- Cleanup personal persistent vehicle
    DeleteEventVehicle(source)
    
    -- Notify Client to hide HUD/Reset UI state
    TriggerClientEvent("ng_event:client:EventEnded", source)
    
    if reason then
        DebugPrint("Player " .. source .. " left event. Reason: " .. reason)
    end
    
    return true
end

-- Utility to get a solid identifier for persistence
local function GetPlayerCitizenId(src)
    local Player = exports.qbx_core:GetPlayer(src)
    if Player and Player.PlayerData and Player.PlayerData.citizenid then
        return Player.PlayerData.citizenid
    end
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if string.find(id, "license:") then return id end
    end
    return tostring(src)
end

-- Handle player disconnect
AddEventHandler("playerDropped", function(reason)
    local src = source
    if EventState.players[src] then
        local citizenid = GetPlayerCitizenId(src)
        
        -- Store the state in a persistent table keyed by citizenid
        EventState.disconnectedPlayers = EventState.disconnectedPlayers or {}
        EventState.disconnectedPlayers[citizenid] = EventState.players[src]
        
        -- Remove from active players via memory, but do NOT run LeaveEvent logic 
        -- so they keep UI options and vehicles when they return.
        EventState.players[src] = nil
        
        DebugPrint("Player " .. src .. " dropped. Event state retained for " .. citizenid .. ". Reason: " .. reason)
    end
end)

-- Handle reconnects by checking when players join the server or character spawns
local function RecoverPlayerEventState(src)
    local citizenid = GetPlayerCitizenId(src)

    if EventState.active and EventState.disconnectedPlayers and EventState.disconnectedPlayers[citizenid] then
        -- Restore state to the new source
        EventState.players[src] = EventState.disconnectedPlayers[citizenid]
        EventState.disconnectedPlayers[citizenid] = nil
        
        -- Put them back in the event state accurately
        if EventState.players[src].level5 and EventState.players[src].level5.active then
            local bucket = EventState.players[src].level5.bucket
            SetPlayerRoutingBucket(src, bucket)
            DebugPrint("Player " .. src .. " reconnected and restored to personal bucket " .. bucket)
        else
            AddPlayerToMainBucket(src)
        end
        
        UpdatePlayerEventState(src)
        TriggerClientEvent("ng_event:client:EventStarted", src)
        
        -- Re-trigger their cumulative setup so blips, PVP, and targets match their level
        local level = EventState.players[src].confirmedLevel
        TriggerCumulativeLevelSetup(src, level)
        
        -- Restore their vehicle
        TriggerEvent("ng_event:server:CheckEventVehicle", src)
        
        DebugPrint("Player " .. src .. " (" .. citizenid .. ") reconnected and event state was fully restored to Level " .. level)
    end
end

RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    RecoverPlayerEventState(source)
end)

RegisterNetEvent('qbx_core:server:onPlayerLoaded', function(src)
    RecoverPlayerEventState(src)
end)

-- Handle script restart/stop cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    StopEvent()
end)

-- Callback for NUI admin check
lib.callback.register('ng_event:server:IsAdmin', function(source)
    return IsAdmin(source)
end)

-- Callback for fetching EventState
lib.callback.register('ng_event:server:GetEventState', function(source)
    return EventState
end)

-- Debug Command to Test Finale immediately
lib.addCommand('testfinale', {
    help = 'Test the Finale Cinematic (Admin Only)',
    params = {},
}, function(source, args, raw)
    if not IsAdmin(source) then
        return TriggerClientEvent('ng_event:client:ShowNotification', source, {title = "Error", description = "Unauthorized", type = "error"})
    end

    DebugPrint("Admin " .. source .. " triggered a finale test.")
    
    -- Force start a mock state
    EventState.active = true
    EventState.stopping = false
    EventState.players = {}
    EventState.winners = {}
    EventState.liveWinners = {}

    -- Add the admin as Winner 1
    EventState.players[source] = {
        tokens = {true, true, true, true, true},
        confirmedLevel = 6,
        finished = true,
        place = 1
    }
    table.insert(EventState.winners, source)
    table.insert(EventState.liveWinners, {
        name = GetPlayerName(source),
        source = source,
        time = os.date("%Y-%m-%d %H:%M:%S"),
        place = 1
    })

    -- Add nearby players as generic participants
    local coords = GetEntityCoords(GetPlayerPed(source))
    local nearby = lib.getNearbyPlayers(coords, 50.0)
    if nearby then
        for _, p in ipairs(nearby) do
            if p.id ~= source then
                EventState.players[p.id] = {
                    tokens = {true, true, true, false, false},
                    confirmedLevel = 5,
                    finished = false
                }
            end
        end
    end

    -- Trigger the sequence
    TriggerPodiumSequence()
    TriggerClientEvent('ng_event:client:ShowNotification', source, {title = "Debug", description = "Finale Test Started with " .. (nearby and #nearby or 0) .. " nearby players.", type = "success"})
end)

-- Server-side Vehicle Restriction (Handles passengers and teleport safely)
RegisterNetEvent("ng_event:server:RestrictVehicle", function(netId, teleportCoords)
    local src = source
    if not netId then return end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if not DoesEntityExist(entity) then return end

    -- Check all event participants to see who is in this specific vehicle
    local occupants = {}
    for playerSrc, _ in pairs(EventState.players) do
        local pPed = GetPlayerPed(playerSrc)
        if DoesEntityExist(pPed) and GetVehiclePedIsIn(pPed, false) == entity then
            table.insert(occupants, playerSrc)
        end
    end

    -- Tell everyone to get out FIRST
    for _, playerSrc in ipairs(occupants) do
        TriggerClientEvent("ng_event:client:ForceLeaveVehicle", playerSrc)
    end

    -- Small wait to ensure clients process the leave task before the driver teleports the car
    Wait(300)

    -- Calculate an offset so vehicles don't spawn on top of each other
    EventState.restrictedVehicleCount = (EventState.restrictedVehicleCount or 0) + 1
    local offset = EventState.restrictedVehicleCount * 3.5
    local modifiedCoords = vector3(teleportCoords.x + offset, teleportCoords.y, teleportCoords.z)
    
    -- Tell the DRIVER (sender) to teleport the car
    TriggerClientEvent("ng_event:client:TeleportVehicle", src, netId, modifiedCoords)
end)

RegisterNetEvent("ng_event:server:SetPodiumDuration", function(p2Duration)
    if not EventState.active then return end
    
    local src = source
    local p1Duration = Config.Podium.Duration or 15000
    local totalDuration = p1Duration + p2Duration + 1000 -- 1s safety buffer
    
    if totalDuration > 300000 then totalDuration = 300000 end -- Max 5 mins safety
    
    DebugPrint("Server: Adjusting podium duration to " .. totalDuration .. "ms based on client feedback.")
    
    podiumTimerId = podiumTimerId + 1
    local currentId = podiumTimerId
    
    SetTimeout(totalDuration, function()
        if podiumTimerId == currentId then
            StopEvent()
        end
    end)
end)

RegisterNetEvent("ng_event:server:PodiumFinished", function()
    DebugPrint("Server: Podium finished notification received (Client " .. source .. "). Stopping immediately.")
    StopEvent()
end)
