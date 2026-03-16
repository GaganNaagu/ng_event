-- modules/buckets/server.lua
-- Handles assigning players to the main event bucket or isolating them into personal instances.

BucketManager = {}

function BucketManager.AssignPersonalBucket(src)
    local bucket = Config.PersonalBucketStart + src
    SetPlayerRoutingBucket(src, bucket)
    
    local data = PlayerManager.GetPlayer(src)
    if data then
        data.levelData = data.levelData or {}
        data.levelData.level5 = data.levelData.level5 or {}
        data.levelData.level5.bucket = bucket
        data.levelData.level5.active = true
        data.levelData.level5.npcKills = 0
        data.levelData.level5.npcs = {}
        data.levelData.level5.killedNpcs = {}
    end
    
    return bucket
end

function BucketManager.AddPlayerToMainBucket(src)
    SetPlayerRoutingBucket(src, Config.MainBucket)
    
    local data = PlayerManager.GetPlayer(src)
    if data and data.levelData and data.levelData.level5 then
        data.levelData.level5.active = false
    end
end

function BucketManager.CleanupPersonalBucketArea(src)
    local data = PlayerManager.GetPlayer(src)
    if data and data.levelData and data.levelData.level5 then
        local l5data = data.levelData.level5
        if l5data.npcs then
            for _, netId in ipairs(l5data.npcs) do
                local entity = NetworkGetEntityFromNetworkId(netId)
                if DoesEntityExist(entity) then
                    DeleteEntity(entity)
                end
            end
        end
        l5data.npcs = {}
        l5data.killedNpcs = {}
        l5data.active = false
    end
end
