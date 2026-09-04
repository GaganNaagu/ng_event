-- ============================================================
-- NUI BRIDGE & CHAT COMMANDS
-- ============================================================

local isUiOpen = false

local function ToggleUI(visible, appName, eventData, isAdmin)
    isUiOpen = visible
    SetNuiFocus(visible, visible)
    
    SendNUIMessage({
        action = "setupUI",
        visible = visible,
        app = appName or 'eventPanel',
        eventData = eventData or {},
        isAdmin = isAdmin or false
    })
end

-- ============================================================
-- NUI CALLBACKS
-- ============================================================

RegisterNUICallback('hideUI', function(data, cb)
    ToggleUI(false)
    cb({})
end)

-- Admin Action Callbacks
RegisterNUICallback('event:ui:action', function(data, cb)
    TriggerServerEvent('event:ui:' .. data.action, data.targetId, data.extra)
    cb({})
end)

-- Periodic Sync fallback (2 seconds)
CreateThread(function()
    while true do
        Wait(2000)
        if isUiOpen then
            lib.callback('ng_event:server:GetUIData', false, function(data)
                if data and isUiOpen then
                    SendNUIMessage({
                        action = "updateUIData",
                        eventActive = data.eventActive,
                        eventHosting = data.eventHosting,
                        playersList = data.playersList,
                        playerOwnData = data.playerOwnData,
                        liveWinners = data.liveWinners,
                        history = data.history
                    })
                end
            end)
        end
    end
end)

-- ============================================================
-- EVENT HANDLERS
-- ============================================================

RegisterNetEvent('event:ui:open', function(data)
    ToggleUI(true, 'eventPanel', data, data.isAdmin)
end)

-- Reactive update event from server
RegisterNetEvent('event:ui:update', function(data)
    if isUiOpen then
        SendNUIMessage({
            action = "updateUIData",
            eventActive = data.eventActive,
            eventHosting = data.eventHosting,
            playersList = data.playersList,
            playerOwnData = data.playerOwnData,
            liveWinners = data.liveWinners,
            history = data.history
        })
    end
end)
