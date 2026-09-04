local uiActive = false
local currentWinners = 0
local maxWinners = Config.MaxWinners

-- Level 5 dynamic UI state
Level5Kills = 0
Level5KillsRequired = Config.Levels[5].killsRequired or 5

function RefreshUI()
    if not uiActive then return end
    
    local lvl = LocalEventState.level or 1
    local lvlName = "Waiting..."
    local lvlDesc = ""
    
    if Config.Levels[lvl] then
        lvlName = Config.Levels[lvl].name or lvlName
        lvlDesc = Config.Levels[lvl].description or lvlDesc
    end

    local extraInfo = nil
    if lvl == 2 then
        extraInfo = string.format("Kills: %d/%d", LocalEventState.arenaKills or 0, Config.Levels[2].killsRequired)
    elseif lvl == 5 then
        extraInfo = string.format("Kills: %d/%d", Level5Kills, Level5KillsRequired)
    end
    
    SendNUIMessage({
        action = "updateHUD",
        visible = true,
        hudData = {
            lvlName = lvlName,
            lvlDescription = lvlDesc,
            currentWinners = currentWinners,
            maxWinners = maxWinners,
            extraInfo = extraInfo
        },
        hudPosition = Config.HUD.Position
    })
end

RegisterNetEvent("ng_event:client:ShowUI", function()
    uiActive = true
    RefreshUI()
end)

RegisterNetEvent("ng_event:client:HideUI", function()
    uiActive = false
    SendNUIMessage({
        action = "updateHUD",
        visible = false
    })
    currentWinners = 0
end)

-- Sound Bridge
RegisterNetEvent("ng_event:client:PlaySound", function(soundType)
    local cfg = Config.Audio[soundType or "Notification"]
    if not cfg then return end
    
    SendNUIMessage({
        action = "playSound",
        url = cfg.Url,
        volume = cfg.Volume
    })
end)

-- Custom Notification Bridge
RegisterNetEvent("ng_event:client:ShowNotification", function(data)
    -- Also play notification sound
    TriggerEvent("ng_event:client:PlaySound", "Notification")
    
    SendNUIMessage({
        action = "showNotification",
        title = data.title,
        description = data.description,
        type = data.type or "inform"
    })
end)

RegisterNetEvent("ng_event:client:UpdateWinners", function(count, max)
    currentWinners = count
    maxWinners = max
    RefreshUI()
end)

-- Ensure HUD position is sent when resource restarts
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        SendNUIMessage({
            action = "updateHUD",
            hudPosition = Config.HUD.Position
        })
    end
end)
