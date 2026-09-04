-- Bucket Management

function AddPlayerToMainBucket(src)
    SetPlayerRoutingBucket(src, Config.MainBucket)
    DebugPrint("Player " .. src .. " added to main bucket " .. Config.MainBucket)
end

function RemovePlayerFromEventBucket(src)
    SetPlayerRoutingBucket(src, 0)
    DebugPrint("Player " .. src .. " bucket reset to 0")
end

function AssignPersonalBucket(src)
    local personalBucket = Config.PersonalBucketStart + src
    SetPlayerRoutingBucket(src, personalBucket)
    
    if EventState.players[src] then
        EventState.players[src].level5 = {
            startTime = os.time(),
            npcKills = 0,
            active = true,
            bucket = personalBucket,
            npcs = {}, -- store spawned NPC network IDs here
            killedNpcs = {} -- track which IDs have already been counted
        }
    end
    DebugPrint("Player " .. src .. " assigned personal bucket " .. personalBucket)
    return personalBucket
end

function CleanupPersonalBucketArea(src)
    if EventState.players[src] and EventState.players[src].level5 then
        local l5 = EventState.players[src].level5
        if l5.npcs then
            for _, netId in ipairs(l5.npcs) do
                local entity = NetworkGetEntityFromNetworkId(netId)
                if DoesEntityExist(entity) then
                    DeleteEntity(entity)
                end
            end
        end
        l5.active = false
        l5.npcs = {}
        DebugPrint("Cleaned up personal bucket entities for player " .. src)
    end
end
