-- levels/level3_lion_hunt/server.lua
-- Predator Zone Server Logic (Level 3)

local Level3 = {
    state = "IDLE",   
    tick = nil,        
    predators = {},     
    occupiedSlots = {}, 
    slotCooldowns = {}, 
    graceStart = 0      
}

local function GetPlayersInL3Proximity()
    local inArea = {}
    if not EventManager.State.active then return inArea end
    
    local cfg = Config.Levels[3]
    local zoneCenter = cfg.redZoneCenter or cfg.treasureBoxCoords
    local detectionRadius = cfg.redZoneRadius or 100.0

    local players = PlayerManager.GetPlayers()
    for src, data in pairs(players) do
        local ped = GetPlayerPed(src)
        if DoesEntityExist(ped) then
            local pCoords = GetEntityCoords(ped)
            local dist = #(pCoords - zoneCenter)
            if dist <= detectionRadius then
                table.insert(inArea, src)
            end
        end
    end
    return inArea
end

local function CleanupPredators()
    local players = PlayerManager.GetPlayers()
    for src, _ in pairs(players) do
        TriggerClientEvent("ng_event:client:StopPredatorSystem", src)
    end

    for _, p in ipairs(Level3.predators) do
        local ent = type(p) == "table" and p.entity or p
        if DoesEntityExist(ent) then DeleteEntity(ent) end
    end
    Level3.predators = {}
    Level3.occupiedSlots = {}

    local peds = GetAllPeds()
    for _, ped in ipairs(peds) do
        if Entity(ped).state and Entity(ped).state.isEventPredator then
            DeleteEntity(ped)
        end
    end
end

local function ResetState()
    CleanupPredators()
    Level3.state = "IDLE"
    Level3.occupiedSlots = {}
    Level3.slotCooldowns = {}
end

local function ActivateZone(playersInArea)
    if Level3.state == "ACTIVE" then return end
    Level3.state = "ACTIVE"
    for _, src in ipairs(playersInArea) do
        TriggerClientEvent("ng_event:client:StartPredatorSystem", src)
        InventoryManager.ClearPlayerInventory(src)
        InventoryManager.GiveLevelLoadout(src, 3)
    end
end

local function StartTick()
    if Level3.tick then return end

    Level3.tick = Citizen.CreateThread(function()
        local cfg = Config.Levels[3]
        local zoneCenter = cfg.redZoneCenter or cfg.treasureBoxCoords
        local redZoneRadius = cfg.redZoneRadius
        
        while EventManager.State.active and EventManager.State.unlockedLevels[3] do
            local playersInArea = GetPlayersInL3Proximity()

            if Level3.state == "ACTIVE" then
                for i = #Level3.predators, 1, -1 do
                    local p = Level3.predators[i]
                    local ent = type(p) == "table" and p.entity or p
                    local slot = type(p) == "table" and p.slot or nil

                    if not DoesEntityExist(ent) then
                         if slot then 
                            Level3.occupiedSlots[slot] = nil 
                            Level3.slotCooldowns[slot] = GetGameTimer()
                         end
                         table.remove(Level3.predators, i)
                    elseif GetEntityType(ent) ~= 1 or GetEntityHealth(ent) <= 0 then
                        local actualSlot = slot or (Entity(ent).state and Entity(ent).state.spawnSlot)
                        if actualSlot then
                            Level3.occupiedSlots[actualSlot] = nil
                            Level3.slotCooldowns[actualSlot] = GetGameTimer()
                        end
                        DeleteEntity(ent)
                        table.remove(Level3.predators, i)
                    end
                end

                if #playersInArea > 0 then
                    local predatorsToSpawn = cfg.maxPredators - #Level3.predators
                    if predatorsToSpawn > 0 then
                        for i = 1, #cfg.predatorSpawnCoords do
                            if #Level3.predators >= cfg.maxPredators then break end
                            
                            if not Level3.occupiedSlots[i] then
                                local readyToSpawn = not Level3.slotCooldowns[i] or (GetGameTimer() - Level3.slotCooldowns[i] >= (cfg.waveSpawnDelay or 10000))
                                
                                if readyToSpawn then
                                    local spawn = cfg.predatorSpawnCoords[i]
                                    local model = Config.Predators.Model
                                    local entity = CreatePed(4, model, spawn.x, spawn.y, spawn.z, spawn.w, true, true)
                                    
                                    local waitLimit = 0
                                    while not DoesEntityExist(entity) and waitLimit < 10 do
                                        Wait(50)
                                        waitLimit = waitLimit + 1
                                    end

                                    if DoesEntityExist(entity) then
                                        SetEntityRoutingBucket(entity, Config.MainBucket)
                                        Entity(entity).state:set('isEventPredator', true, true)
                                        Entity(entity).state:set('spawnSlot', i, true)
                                        Level3.occupiedSlots[i] = true
                                        Level3.slotCooldowns[i] = nil
                                        table.insert(Level3.predators, { entity = entity, slot = i })
                                        
                                        if DoesEntityExist(entity) then
                                            local success, netId = pcall(NetworkGetNetworkIdFromEntity, entity)
                                            if success and netId then
                                                local players = PlayerManager.GetPlayers()
                                                for pSrc, _ in pairs(players) do
                                                    TriggerClientEvent("ng_event:client:RegisterPredator", pSrc, netId, spawn)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            elseif Level3.state == "IDLE" then
                if #playersInArea > 0 then
                    ActivateZone(playersInArea)
                end
            end

            Wait(1500)
        end

        ResetState()
        Level3.tick = nil
    end)
end

function Level3.SetupPlayer(src)
    -- Handled by PlayerEnteredL3Zone triggers since setup happens on proximity
end

function Level3.PlayerDied(src)
    local data = PlayerManager.GetPlayer(src)
    if not data or data.confirmedLevel ~= 3 then return end

    local locs = Config.Levels[3].respawnLocs
    local loc = locs[math.random(1, #locs)]

    local ped = GetPlayerPed(src)
    InventoryManager.ClearPlayerInventory(src)
    InventoryManager.GiveLevelLoadout(src, 3) 
    if DoesEntityExist(ped) then
        Framework.RevivePlayer(src)
        SetEntityCoords(ped, loc.x, loc.y, loc.z, false, false, false, false)
        SetEntityHeading(ped, loc.w)
    end
end

function Level3.Cleanup()
    ResetState()
end

LevelManager.RegisterLevel(3, Level3)


RegisterNetEvent("ng_event:server:RegisterPredator", function(netId)
    local src = source
    if not netId then return end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        SetEntityRoutingBucket(entity, Config.MainBucket)
        Entity(entity).state:set('isEventPredator', true, true)
        table.insert(Level3.predators, { entity = entity, slot = nil })
    end
end)

RegisterNetEvent("ng_event:server:DeletePredator", function(netId)
    if not netId then return end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end)

RegisterNetEvent("ng_event:server:LootTreasure3", function()
    local src = source
    local data = PlayerManager.GetPlayer(src)
    if not data or data.confirmedLevel ~= 3 or data.tokens[3] then return end

    LevelManager.PlayerCompleted(src, 3)
    
    InventoryManager.ClearPlayerInventory(src)

    TriggerClientEvent("ng_event:client:ShowNotification", src, {
        title = "Event",
        description = "Level 3 Complete! Token acquired. Follow your GPS to Level 4.",
        type = "success"
    })
    TriggerClientEvent("ng_event:client:HideLevel3Blip", src)
    TriggerClientEvent("ng_event:client:ShowLevel4Blip", src)
end)

AddEventHandler('ng_event:server:UnlockLevel', function(level)
    if level == 3 then StartTick() end
end)

RegisterNetEvent("ng_event:server:PlayerEnteredL3Zone", function()
    local src = source
    local data = PlayerManager.GetPlayer(src)
    if not data then return end
    
    if data.pendingLevel == 3 then
        TransitionManager.ConfirmLevelEntry(src)
    end
    
    if data.confirmedLevel ~= 3 then return end

    TriggerClientEvent("ng_event:client:StartPredatorSystem", src)
    InventoryManager.ClearPlayerInventory(src)
    InventoryManager.GiveLevelLoadout(src, 3)

    if Level3.state == "IDLE" then
        local playersInArea = GetPlayersInL3Proximity()
        ActivateZone(playersInArea)
    end
end)
