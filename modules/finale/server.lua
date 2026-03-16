-- modules/finale/server.lua
-- Orchestrates animations and sequence timings (SERVER).

PodiumManager = {}

function PodiumManager.IsPodiumActive()
    return EventManager.State.stopping
end

local podiumFinaleActive = false
local podiumTimerId = 0

function PodiumManager.TriggerPodiumSequence()
    DebugPrint("TriggerPodiumSequence called.")
    if not EventManager.State.active or EventManager.State.stopping then 
        return 
    end
    EventManager.State.stopping = true
    
    local participants = {}
    local players = PlayerManager.GetPlayers()
    for src, data in pairs(players) do
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

    table.sort(participants, function(a, b)
        if a.finished and not b.finished then return true end
        if not a.finished and b.finished then return false end
        if a.finished and b.finished then
            return (a.place or 999) < (b.place or 999)
        end
        if a.level ~= b.level then return a.level > b.level end
        return a.tokens > b.tokens
    end)
    
    podiumFinaleActive = true
    for src, _ in pairs(players) do
        BucketManager.AddPlayerToMainBucket(src)
        BucketManager.CleanupPersonalBucketArea(src)

        TriggerClientEvent("ng_event:client:ShowNotification", src, {title = "Event Over", description = "The event has concluded! Initiating finale...", type = "inform"})
        TriggerClientEvent("ng_event:client:HideUI", src)
        TriggerClientEvent("ng_event:client:ShowPodium", src, participants)
    end
    
    local duration = (Config.Podium and Config.Podium.Duration or 15000) * 4 
    
    podiumTimerId = podiumTimerId + 1
    local currentId = podiumTimerId
    SetTimeout(duration, function()
        if podiumTimerId == currentId then
            EventManager.StopEvent()
        end
    end)
end

RegisterNetEvent("ng_event:server:SetPodiumDuration", function(p2Duration)
    if not EventManager.State.active then return end
    
    local p1Duration = Config.Podium.Duration or 15000
    local totalDuration = p1Duration + p2Duration + 1000 
    
    if totalDuration > 300000 then totalDuration = 300000 end 
    
    podiumTimerId = podiumTimerId + 1
    local currentId = podiumTimerId
    
    SetTimeout(totalDuration, function()
        if podiumTimerId == currentId then
            EventManager.StopEvent()
        end
    end)
end)

RegisterNetEvent("ng_event:server:PodiumFinished", function()
    EventManager.StopEvent()
end)
