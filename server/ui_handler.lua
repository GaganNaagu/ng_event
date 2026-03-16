-- Server-side UI Handler for ng_event
-- Handles all NUI-driven actions with direct function calls

-- Helper to push update to anyone with UI open
local function SyncUIData(target)

    local admin = IsAdmin(target)
    local playerOwnData = nil
    
    if EventState.players[target] then
        local p = EventState.players[target]
        playerOwnData = {
            level = p.confirmedLevel,
            tokens = p.tokens,
            inEvent = true
        }
    else
        playerOwnData = {
            level = 1,
            tokens = {false, false, false, false, false},
            inEvent = false
        }
    end

    local playersList = {}
    if admin then
        for src, data in pairs(EventState.players) do
            local tokenCount = 0
            for _, v in ipairs(data.tokens) do if v then tokenCount = tokenCount + 1 end end
            
            local pReturn = {
                source = src,
                name = GetPlayerName(src),
                level = data.confirmedLevel,
                tokens = tokenCount,
                kills = data.arenaKills or 0,
                finished = data.finished or false,
                place = nil,
                time = nil
            }
            if data.finished then
                for _, w in ipairs(EventState.liveWinners) do
                    if w.source == src then
                        pReturn.place = w.place
                        pReturn.time = w.time
                        break
                    end
                end
            end
            table.insert(playersList, pReturn)
        end
    end

    TriggerClientEvent('event:ui:update', target, {
        eventActive = EventState.active,
        eventHosting = EventState.hosting,
        isAdmin = admin,
        playerOwnData = playerOwnData,
        playersList = playersList,
        liveWinners = EventState.liveWinners,
        history = admin and EventState.history or nil,
        hudPosition = (Config.HUD and Config.HUD.Position) or 'top-center'
    })
end

local function BroadcastSyncUIData()
    local players = GetPlayers()
    for i=1, #players do
        local src = tonumber(players[i])
        SyncUIData(src)
    end
end

AddEventHandler("event:ui:BroadcastSync", function()
    BroadcastSyncUIData()
end)

-- Callback to fetch initial data for the UI
lib.callback.register('ng_event:server:GetUIData', function(source)
    local admin = IsAdmin(source)
    local playerOwnData = nil
    
    if EventState.players[source] then
        local p = EventState.players[source]
        playerOwnData = {
            level = p.confirmedLevel,
            tokens = p.tokens,
            inEvent = true
        }
    else
        playerOwnData = {
            level = 1,
            tokens = {false, false, false, false, false},
            inEvent = false
        }
    end

    local playersList = {}
    if admin then
        for src, data in pairs(EventState.players) do
            local tokenCount = 0
            for _, v in ipairs(data.tokens) do if v then tokenCount = tokenCount + 1 end end
            
            local pReturn = {
                source = src,
                name = GetPlayerName(src),
                level = data.confirmedLevel,
                tokens = tokenCount,
                kills = data.arenaKills or 0,
                finished = data.finished or false,
                place = nil,
                time = nil
            }
            if data.finished then
                for _, w in ipairs(EventState.liveWinners) do
                    if w.source == src then
                        pReturn.place = w.place
                        pReturn.time = w.time
                        break
                    end
                end
            end
            table.insert(playersList, pReturn)
        end
    end

    return {
        eventActive = EventState.active,
        eventHosting = EventState.hosting,
        isAdmin = admin,
        playerOwnData = playerOwnData,
        playersList = playersList,
        liveWinners = EventState.liveWinners,
        history = admin and EventState.history or nil,
        hudPosition = (Config.HUD and Config.HUD.Position) or 'top-center'
    }
end)

-- Join Event
RegisterNetEvent('event:ui:join', function()
    local src = source
    if JoinEvent(src) then
        BroadcastSyncUIData()
    end
end)

-- Leave Event
RegisterNetEvent('event:ui:leave', function()
    local src = source
    if LeaveEvent(src, "Left via UI") then
        TriggerClientEvent('ng_event:client:ShowNotification', src, {title = "Event", description = "You have left the event.", type = "inform"})
        BroadcastSyncUIData()
    end
end)

-- Admin Actions
RegisterNetEvent('event:ui:host', function()
    local src = source
    if not IsAdmin(src) then return end
    if HostEvent(src) then
        BroadcastSyncUIData()
    end
end)

RegisterNetEvent('event:ui:start', function(_, level)
    local src = source
    if not IsAdmin(src) then return end
    if StartEvent(src, tonumber(level) or 1) then
        BroadcastSyncUIData()
    end
end)

RegisterNetEvent('event:ui:end', function()
    local src = source
    if not IsAdmin(src) then return end
    TriggerPodiumSequence()
    BroadcastSyncUIData()
end)

RegisterNetEvent('event:ui:forceAdvance', function(targetId)
    local src = source
    if not IsAdmin(src) then return end
    local target = tonumber(targetId)
    if not EventState.players[target] then return end
    
    local current = EventState.players[target].confirmedLevel
    if current < 6 then
        local nextLevel = current + 1
        
        -- Cleanup current level items/weapons
        ClearPlayerInventory(target)
        
        UpdateLevel(target, nextLevel, true)
        -- Do NOT call ConfirmLevelEntry(target) here. 
        -- UpdateLevel already triggers BeginLevelTransition which sets 'transitioning' = true.
        TeleportPlayerToLevelStart(target, nextLevel)
        TriggerCumulativeLevelSetup(target, nextLevel)
        TriggerClientEvent('ng_event:client:ShowNotification', src, {title = "Admin", description = "Advanced Player " .. target .. " to Level " .. nextLevel, type = "success"})
        SyncUIData(src)
        SyncUIData(target)
    end
end)

RegisterNetEvent('event:ui:removePlayer', function(targetId)
    local src = source
    if not IsAdmin(src) then return end
    local target = tonumber(targetId)
    if LeaveEvent(target, "Removed by Admin: " .. src) then
        TriggerClientEvent('ng_event:client:ShowNotification', target, {title = "Event", description = "You were removed from the event by an admin.", type = "error"})
        SyncUIData(src)
        SyncUIData(target)
    end
end)

RegisterNetEvent('event:ui:teleportSpawn', function(targetId)
    local src = source
    if not IsAdmin(src) then return end
    local target = tonumber(targetId)
    if not EventState.players[target] then return end
    
    local level = EventState.players[target].confirmedLevel
    local spawn = nil
    if Config.Levels[level] and Config.Levels[level].spawnLocs then
        spawn = GetRandomLocation(Config.Levels[level].spawnLocs)
    end
    
    if spawn then
        local ped = GetPlayerPed(target)
        SetEntityCoords(ped, spawn.x, spawn.y, spawn.z, false, false, false, false)
        if spawn.w then SetEntityHeading(ped, spawn.w) end
        TriggerClientEvent('ng_event:client:ShowNotification', src, {title = "Admin", description = "Teleported Player " .. target .. " to Spawn", type = "success"})
    end
end)

-- Command to Open Event Panel
lib.addCommand('event', {
    help = 'Open Event Panel',
}, function(source, args, raw)
    local admin = IsAdmin(source)
    local playerOwnData = nil
    
    if EventState.players[source] then
        local p = EventState.players[source]
        playerOwnData = {
            level = p.confirmedLevel,
            tokens = p.tokens,
            inEvent = true
        }
    else
        playerOwnData = {
            level = 1,
            tokens = {false, false, false, false, false},
            inEvent = false
        }
    end

    local playersList = {}
    if admin then
        for src, d in pairs(EventState.players) do
            local tokenCount = 0
            for _, v in ipairs(d.tokens) do if v then tokenCount = tokenCount + 1 end end
            local pReturn = {
                source = src,
                name = GetPlayerName(src),
                level = d.confirmedLevel,
                tokens = tokenCount,
                kills = d.arenaKills or 0,
                finished = d.finished or false,
                place = nil,
                time = nil
            }
            if d.finished then
                for _, w in ipairs(EventState.liveWinners) do
                    if w.source == src then
                        pReturn.place = w.place
                        pReturn.time = w.time
                        break
                    end
                end
            end
            table.insert(playersList, pReturn)
        end
    end

    local data = {
        eventActive = EventState.active,
        eventHosting = EventState.hosting,
        isAdmin = admin,
        playerOwnData = playerOwnData,
        playersList = playersList,
        liveWinners = EventState.liveWinners,
        history = admin and EventState.history or nil,
        hudPosition = (Config.HUD and Config.HUD.Position) or 'top-center'
    }

    TriggerClientEvent('event:ui:open', source, data)
end)

-- Manual Inventory Recovery Command
lib.addCommand('recoverinventory', {
    help = 'Manually restore a players inventory from event backup',
    params = {
        {
            name = 'target',
            type = 'number',
            help = 'Player Server ID',
            optional = false,
        },
    },
}, function(source, args, raw)
    if source ~= 0 and not IsAdmin(source) then
        return
    end

    local target = tonumber(args.target)
    if not target or target == 0 then
        if source ~= 0 then
            TriggerClientEvent('ng_event:client:ShowNotification', source, {title = "Admin", description = "Invalid Target ID", type = "error"})
        else
            print("Invalid Target ID")
        end
        return
    end

    local success = RestorePlayerInventory(target)
    if success then
        if source ~= 0 then
            TriggerClientEvent('ng_event:client:ShowNotification', source, {title = "Admin", description = "Inventory restored for player " .. target, type = "success"})
        else
            print("Inventory restored for player " .. target)
        end
    else
        if source ~= 0 then
            TriggerClientEvent('ng_event:client:ShowNotification', source, {title = "Admin", description = "No inventory backup found for player " .. target, type = "error"})
        else
            print("No inventory backup found for player " .. target)
        end
    end
end)
