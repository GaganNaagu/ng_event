-- modules/ui/server.lua

local function SyncUIData(target)
    local admin = PlayerManager.IsAdmin(target)
    local playerOwnData = nil
    
    local targetData = PlayerManager.GetPlayer(target)

    if targetData then
        playerOwnData = {
            level = targetData.confirmedLevel,
            tokens = targetData.tokens,
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
        local allPlayers = PlayerManager.GetPlayers()
        for src, data in pairs(allPlayers) do
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
                for _, w in ipairs(EventManager.State.liveWinners) do
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
        eventActive = EventManager.State.active,
        eventHosting = EventManager.State.hosting,
        isAdmin = admin,
        playerOwnData = playerOwnData,
        playersList = playersList,
        liveWinners = EventManager.State.liveWinners,
        history = admin and EventManager.State.history or nil,
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

lib.callback.register('ng_event:server:GetUIData', function(source)
    local admin = PlayerManager.IsAdmin(source)
    local playerOwnData = nil
    
    local targetData = PlayerManager.GetPlayer(source)

    if targetData then
        playerOwnData = {
            level = targetData.confirmedLevel,
            tokens = targetData.tokens,
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
        local allPlayers = PlayerManager.GetPlayers()
        for src, data in pairs(allPlayers) do
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
                for _, w in ipairs(EventManager.State.liveWinners) do
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
        eventActive = EventManager.State.active,
        eventHosting = EventManager.State.hosting,
        isAdmin = admin,
        playerOwnData = playerOwnData,
        playersList = playersList,
        liveWinners = EventManager.State.liveWinners,
        history = admin and EventManager.State.history or nil,
        hudPosition = (Config.HUD and Config.HUD.Position) or 'top-center'
    }
end)

RegisterNetEvent('event:ui:join', function()
    local src = source
    if PlayerManager.JoinEvent(src) then
        BroadcastSyncUIData()
    end
end)

RegisterNetEvent('event:ui:leave', function()
    local src = source
    if PlayerManager.LeaveEvent(src, "Left via UI") then
        TriggerClientEvent('ng_event:client:ShowNotification', src, {title = "Event", description = "You have left the event.", type = "inform"})
        BroadcastSyncUIData()
    end
end)

RegisterNetEvent('event:ui:host', function()
    local src = source
    if not PlayerManager.IsAdmin(src) then return end
    if EventManager.HostEvent(src) then
        BroadcastSyncUIData()
    end
end)

RegisterNetEvent('event:ui:start', function(_, level)
    local src = source
    if not PlayerManager.IsAdmin(src) then return end
    if EventManager.StartEvent(src, tonumber(level) or 1) then
        BroadcastSyncUIData()
    end
end)

RegisterNetEvent('event:ui:end', function()
    local src = source
    if not PlayerManager.IsAdmin(src) then return end
    TriggerEvent("ng_event:server:TriggerPodiumSequence")
    BroadcastSyncUIData()
end)

RegisterNetEvent('event:ui:forceAdvance', function(targetId)
    local src = source
    if not PlayerManager.IsAdmin(src) then return end
    local target = tonumber(targetId)
    local tData = PlayerManager.GetPlayer(target)
    if not tData then return end
    
    local current = tData.confirmedLevel
    if current < 6 then
        local nextLevel = current + 1
        
        InventoryManager.ClearPlayerInventory(target)
        
        TransitionManager.UpdateLevel(target, nextLevel, true)
        
        local spawn = nil
        if Config.Levels[nextLevel] and Config.Levels[nextLevel].spawnLocs then
            local locs = Config.Levels[nextLevel].spawnLocs
            spawn = locs[math.random(1, #locs)]
        end
        
        if spawn then
            local ped = GetPlayerPed(target)
            SetEntityCoords(ped, spawn.x, spawn.y, spawn.z, false, false, false, false)
            if spawn.w then SetEntityHeading(ped, spawn.w) end
        end

        TriggerClientEvent('ng_event:client:ShowNotification', src, {title = "Admin", description = "Advanced Player " .. target .. " to Level " .. nextLevel, type = "success"})
        SyncUIData(src)
        SyncUIData(target)
    end
end)

RegisterNetEvent('event:ui:removePlayer', function(targetId)
    local src = source
    if not PlayerManager.IsAdmin(src) then return end
    local target = tonumber(targetId)
    if PlayerManager.LeaveEvent(target, "Removed by Admin: " .. src) then
        TriggerClientEvent('ng_event:client:ShowNotification', target, {title = "Event", description = "You were removed from the event by an admin.", type = "error"})
        SyncUIData(src)
        SyncUIData(target)
    end
end)

RegisterNetEvent('event:ui:teleportSpawn', function(targetId)
    local src = source
    if not PlayerManager.IsAdmin(src) then return end
    local target = tonumber(targetId)
    local tData = PlayerManager.GetPlayer(target)
    if not tData then return end
    
    local level = tData.confirmedLevel
    local spawn = nil
    if Config.Levels[level] and Config.Levels[level].spawnLocs then
        local locs = Config.Levels[level].spawnLocs
        spawn = locs[math.random(1, #locs)]
    end
    
    if spawn then
        local ped = GetPlayerPed(target)
        SetEntityCoords(ped, spawn.x, spawn.y, spawn.z, false, false, false, false)
        if spawn.w then SetEntityHeading(ped, spawn.w) end
        TriggerClientEvent('ng_event:client:ShowNotification', src, {title = "Admin", description = "Teleported Player " .. target .. " to Spawn", type = "success"})
    end
end)

lib.addCommand('event', {
    help = 'Open Event Panel',
}, function(source, args, raw)
    local admin = PlayerManager.IsAdmin(source)
    local playerOwnData = nil
    
    local tData = PlayerManager.GetPlayer(source)
    if tData then
        playerOwnData = {
            level = tData.confirmedLevel,
            tokens = tData.tokens,
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
        local allPlayers = PlayerManager.GetPlayers()
        for src, d in pairs(allPlayers) do
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
                for _, w in ipairs(EventManager.State.liveWinners) do
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
        eventActive = EventManager.State.active,
        eventHosting = EventManager.State.hosting,
        isAdmin = admin,
        playerOwnData = playerOwnData,
        playersList = playersList,
        liveWinners = EventManager.State.liveWinners,
        history = admin and EventManager.State.history or nil,
        hudPosition = (Config.HUD and Config.HUD.Position) or 'top-center'
    }

    TriggerClientEvent('event:ui:open', source, data)
end)

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
    if source ~= 0 and not PlayerManager.IsAdmin(source) then
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

    local success = InventoryManager.RestorePlayerInventory(target)
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
