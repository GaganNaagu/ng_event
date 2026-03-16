-- ============================================================
-- PREDATOR ZONE — SERVER STATE MACHINE (Level 3)
-- State: IDLE → ACTIVE → IDLE
-- ============================================================

local L3 = {
    state = "IDLE",   -- IDLE | ACTIVE
    tick = nil,        -- Thread handle
    predators = {},     -- Server-side pool of spawned peds
    occupiedSlots = {}, -- { [slotIndex] = true }
    slotCooldowns = {}, -- { [slotIndex] = timestamp }
    graceStart = 0      -- Grace period timer
}


-- ============================================================
-- HELPERS
-- ============================================================

local function GetPlayersInL3Proximity()
    local inArea = {}
    if not EventState.active then return inArea end
    
    local cfg = Config.Levels[3]
    local zoneCenter = cfg.redZoneCenter or cfg.treasureCoords or cfg.treasureBoxCoords
    local detectionRadius = cfg.redZoneRadius or 100.0 -- Ensure it uses the redZoneRadius or 100

    for src, data in pairs(EventState.players) do
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

-- ============================================================
-- CLEANUP
-- ============================================================

local function CleanupPredators()
    -- Tell all event players to stop predator system
    for src, _ in pairs(EventState.players) do
        TriggerClientEvent("ng_event:client:StopPredatorSystem", src)
    end

    -- Clear server-side predator pool
    for _, p in ipairs(L3.predators) do
        local ent = type(p) == "table" and p.entity or p
        if DoesEntityExist(ent) then
            DeleteEntity(ent)
        end
    end
    L3.predators = {}
    L3.occupiedSlots = {}

    -- Failsafe sweep for any peds marked as predators
    local peds = GetAllPeds()
    for _, ped in ipairs(peds) do
        if Entity(ped).state.isEventPredator then
            DeleteEntity(ped)
        end
    end
end

local function ResetState()
    CleanupPredators()
    L3.state = "IDLE"
    L3.occupiedSlots = {}
    L3.slotCooldowns = {}
    DebugPrint("Level 3 State → IDLE")
end

-- ============================================================
-- ACTIVATION
-- ============================================================

local function ActivateZone(playersInArea)
    if L3.state == "ACTIVE" then return end
    L3.state = "ACTIVE"
    DebugPrint("Activating Level 3 Zone. Initial Activation.")

    for _, src in ipairs(playersInArea) do
        -- Notify and give loadout to initial batch
        TriggerClientEvent("ng_event:client:StartPredatorSystem", src)
        ClearPlayerInventory(src)
        GiveLevelLoadout(src, 3)
    end
end

-- ============================================================
-- TICK
-- ============================================================

local function StartTick()
    if L3.tick then 
        DebugPrint("StartTick called but tick already running.")
        return 
    end
    DebugPrint("Starting Level 3 Server Tick.")

    L3.tick = Citizen.CreateThread(function()
        local cfg = Config.Levels[3]
        local zoneCenter = cfg.redZoneCenter or cfg.treasureCoords or cfg.treasureBoxCoords
        local redZoneRadius = cfg.redZoneRadius
        
        while EventState.active and EventState.unlockedLevels[3] do
            local playersInArea = GetPlayersInL3Proximity()
            -- DebugPrint("L3 Tick | State: " .. L3.state .. " | Players in area: " .. #playersInArea)

            if L3.state == "ACTIVE" then
                -- Cleanup dead or existing ones from pool
                for i = #L3.predators, 1, -1 do
                    local p = L3.predators[i]
                    local ent = type(p) == "table" and p.entity or p
                    local slot = type(p) == "table" and p.slot or nil

                    if not DoesEntityExist(ent) then
                         if slot then 
                            L3.occupiedSlots[slot] = nil 
                            L3.slotCooldowns[slot] = GetGameTimer()
                         end
                         table.remove(L3.predators, i)
                         DebugPrint("Predator missing. Slot cleaned. Starting 10s cooldown.")
                    elseif GetEntityType(ent) ~= 1 or GetEntityHealth(ent) <= 0 then
                        -- Entity exists but is dead or invalid type
                        local actualSlot = slot or Entity(ent).state.spawnSlot
                        if actualSlot then
                            L3.occupiedSlots[actualSlot] = nil
                            L3.slotCooldowns[actualSlot] = GetGameTimer()
                        end
                        -- Explicitly delete the entity to remove the dead body
                        DeleteEntity(ent)
                        table.remove(L3.predators, i)
                        DebugPrint("Predator died. Slot " .. (actualSlot or "unknown") .. " starting 10s cooldown. Entity deleted.")
                    end
                end

                if #playersInArea > 0 then
                    local predatorsToSpawn = cfg.maxPredators - #L3.predators
                    if predatorsToSpawn > 0 then
                        for i = 1, #cfg.predatorSpawnCoords do
                            if #L3.predators >= cfg.maxPredators then break end
                            
                            -- Check if slot is free and cooldown (10s) has passed
                            if not L3.occupiedSlots[i] then
                                local readyToSpawn = not L3.slotCooldowns[i] or (GetGameTimer() - L3.slotCooldowns[i] >= (cfg.waveSpawnDelay or 10000))
                                
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
                                        L3.occupiedSlots[i] = true
                                        L3.slotCooldowns[i] = nil
                                        table.insert(L3.predators, { entity = entity, slot = i })
                                        
                                        -- Defensive check before getting network ID
                                        if DoesEntityExist(entity) then
                                            local success, netId = pcall(NetworkGetNetworkIdFromEntity, entity)
                                            if success and netId then
                                                for pSrc, _ in pairs(EventState.players) do
                                                    TriggerClientEvent("ng_event:client:RegisterPredator", pSrc, netId, spawn)
                                                end
                                            else
                                                DebugPrint("Error: Failed to get NetID for predator in slot " .. i)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            elseif L3.state == "IDLE" then
                if #playersInArea > 0 then
                    ActivateZone(playersInArea)
                end
            end

            -- CONTROLLED SPAWN COOLDOWN (1500ms as requested)
            Wait(1500)
        end

        ResetState()
        L3.tick = nil
        DebugPrint("Level 3 Tick stopped")
    end)
end

-- ============================================================
-- NET EVENTS
-- ============================================================

-- Client used to register zombies, now server handles it mostly
-- Keeping event for manual spawn support if needed
RegisterNetEvent("ng_event:server:RegisterPredator", function(netId)
    local src = source
    if not netId then return end

    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        SetEntityRoutingBucket(entity, Config.MainBucket)
        Entity(entity).state:set('isEventPredator', true, true)
        table.insert(L3.predators, { entity = entity, slot = nil }) -- Add to global pool as object
        DebugPrint("Predator registered (NetID: " .. netId .. ") by client " .. src)
    end
end)

-- Delete networked predator from a client request
RegisterNetEvent("ng_event:server:DeletePredator", function(netId)
    if not netId then return end
    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
        DebugPrint("Deleted Dead Predator Entity (NetID: " .. netId .. ")")
    end
end)

-- Player tries to loot the treasure
RegisterNetEvent("ng_event:server:LootTreasure3", function()
    local src = source
    if not ValidatePlayer(src) then return end
    if EventState.players[src].confirmedLevel ~= 3 then return end
    if EventState.players[src].tokens[3] then return end -- Already looted

    EventState.players[src].tokens[3] = true
    local safeSpawn = Config.Levels[3].respawnLocs[1]
    UpdateLevel(src, 4, safeSpawn)
    
    -- Level 3 Complete: Wipe inventory for Level 4
    ClearPlayerInventory(src)

    TriggerClientEvent("ng_event:client:ShowNotification", src, {
        title = "Event",
        description = "Level 3 Complete! Token acquired. Follow your GPS to Level 4.",
        type = "success"
    })
    TriggerClientEvent("ng_event:client:HideLevel3Blip", src)
    TriggerClientEvent("ng_event:client:ShowLevel4Blip", src)

    DebugPrint("^2[PREDATOR] Player " .. src .. " looted treasure. Advancing to Level 4.^7")
end)

-- Level 3 respawn
RegisterNetEvent("ng_event:server:RespawnPlayerL3", function()
    local src = source
    if not ValidatePlayer(src) then return end
    if EventState.players[src].confirmedLevel ~= 3 then return end

    local locs = Config.Levels[3].respawnLocs
    local loc = locs[math.random(1, #locs)]

    local ped = GetPlayerPed(src)
    ClearPlayerInventory(src)
    if DoesEntityExist(ped) then
        exports.qbx_medical:Revive(src)
        
        SetEntityCoords(ped, loc.x, loc.y, loc.z, false, false, false, false)
        SetEntityHeading(ped, loc.w)
    end
end)

-- ============================================================
-- INTEGRATION HOOKS
-- ============================================================

AddEventHandler('ng_event:server:UnlockLevel', function(level)
    if level == 3 then StartTick() end
end)

RegisterNetEvent("ng_event:server:PlayerEnteredL3Zone", function()
    local src = source
    if not ValidatePlayer(src) then return end
    if EventState.players[src].pendingLevel == 3 then
        ConfirmLevelEntry(src)
    end
    
    if EventState.players[src].confirmedLevel ~= 3 then return end

    -- Always ensure the player gets their system started and loadout given
    -- This handles late entry into an already active zone
    TriggerClientEvent("ng_event:client:StartPredatorSystem", src)
    ClearPlayerInventory(src)
    GiveLevelLoadout(src, 3)
    
    DebugPrint("^2[PREDATOR] Player " .. src .. " entered Level 3 Zone. System started & Loadout given.^7")

    if L3.state == "IDLE" then
        local playersInArea = GetPlayersInL3Proximity()
        ActivateZone(playersInArea)
    end
end)

RegisterNetEvent("ng_event:server:CleanupLevel3", function()
    ResetState()
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        ResetState()
    end
end)
