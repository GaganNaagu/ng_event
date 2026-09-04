-- ============================================================
-- LEVEL 5 — ISOLATED PvE (Client)
-- Target entry, NPC spawning, kill reporting, timer, blips
-- ============================================================

local Level5Active = false
local level5Npcs = {}
local level5Blip = nil
local level5EntryTarget = nil

-- Relationship Group for Level 5 Enemies
AddRelationshipGroup("L5_ENEMY")
SetRelationshipBetweenGroups(1, `L5_ENEMY`, `L5_ENEMY`) -- NPCs respect each other
SetRelationshipBetweenGroups(5, `L5_ENEMY`, `PLAYER`)   -- NPCs hate player
SetRelationshipBetweenGroups(5, `PLAYER`, `L5_ENEMY`)   -- Player group hates them

-- ============================================================
-- ZONE SETUP (triggered when Level 5 is unlocked or reached)
-- ============================================================
RegisterNetEvent("ng_event:client:SetupLevel5Zones", function()
    if not InEvent then return end
    -- Restore entry blip and target if they exist
    TriggerEvent("ng_event:client:ShowLevel5Blip")
end)

-- Show Level 5 entry blip + target
RegisterNetEvent("ng_event:client:ShowLevel5Blip", function()
    if not InEvent then return end
    local cfg = Config.Levels[5]
    local entry = cfg.entryCoords

    -- Blip
    if level5Blip then RemoveBlip(level5Blip) end
    level5Blip = AddBlipForCoord(entry.x, entry.y, entry.z)
    SetBlipSprite(level5Blip, 310)
    SetBlipColour(level5Blip, 1) -- Red
    SetBlipScale(level5Blip, 1.0)
    SetBlipAsShortRange(level5Blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Event: Isolated Combat")
    EndTextCommandSetBlipName(level5Blip)
    SetBlipRoute(level5Blip, true)

    -- Entry target (ox_target sphere at entry point)
    if level5EntryTarget then
        exports.ox_target:removeZone(level5EntryTarget)
    end
    level5EntryTarget = exports.ox_target:addSphereZone({
        coords = vector3(entry.x, entry.y, entry.z),
        radius = 2.0,
        debug = Config.Debug,
        options = {
            {
                name = 'ng_event_l5_entry',
                icon = 'fas fa-door-open',
                label = 'Enter Isolated Arena',
                distance = 3.0,
                onSelect = function()
                    TriggerServerEvent("ng_event:server:EnterLevel5")
                end,
                canInteract = function()
                    return InEvent and LocalEventState.level == 5 and not LocalEventState.tokens[5]
                end
            }
        }
    })

    TriggerEvent("ng_event:client:ShowNotification", {title = "Event", description = "Isolated Combat Arena marked on GPS!", type = "inform"})
end)

RegisterNetEvent("ng_event:client:HideLevel5Blip", function()
    if level5Blip then RemoveBlip(level5Blip) level5Blip = nil end
    if level5EntryTarget then
        exports.ox_target:removeZone(level5EntryTarget)
        level5EntryTarget = nil
    end
end)

-- ============================================================
-- INSTANCE START (Server confirmed, spawn NPCs)
-- ============================================================

local function SetupNPCAI(ped)
    SetPedRelationshipGroupHash(ped, `L5_ENEMY`)
    
    SetPedCombatAttributes(ped, 46, true) -- AlwaysFight
    SetPedCombatAttributes(ped, 5, true)  -- CanFightArmedPedsWhenNotArmed
    SetPedCombatAbility(ped, 100)
    SetPedCombatMovement(ped, 2) -- Aggressive/Offensive
    SetPedCombatRange(ped, 2) -- Far
    SetPedFleeAttributes(ped, 0, false)
    SetPedAsEnemy(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedDropsWeaponsWhenDead(ped, false)
    SetPedAccuracy(ped, 100)
    SetPedArmour(ped, 50)
    SetEntityMaxHealth(ped, 100)
    SetEntityHealth(ped, 100)
    
    -- Disable 1-shot headshots & suppress easy ragdolls
    SetPedSuffersCriticalHits(ped, false)
    SetPedCanRagdoll(ped, false)
    SetPedCanRagdollFromPlayerImpact(ped, false)

    -- SetPedHasAiBlip(ped, true)
    -- SetPedAiBlipHasCone(ped, false)
    
    SetEntityAsMissionEntity(ped, true, true) -- Prevent despawning

    TaskCombatPed(ped, cache.ped, 0, 16)
end

local function SpawnSingleNPC(index, coords, cfg)
    local modelHash = cfg.npcHash
    lib.requestModel(modelHash)
    
    local ped = CreatePed(4, modelHash, coords.x, coords.y, coords.z, coords.w, true, true)
    
    if cfg.npcWeapon then
        GiveWeaponToPed(ped, GetHashKey(cfg.npcWeapon), 250, false, true)
    end
    
    SetupNPCAI(ped)

    local netId = lib.waitFor(function()
        if not NetworkGetEntityIsNetworked(ped) then
            NetworkRegisterEntityAsNetworked(ped)
        else
            local nId = PedToNet(ped)
            if NetworkDoesNetworkIdExist(nId) then
                return nId
            end
        end
    end, nil, false)

    if netId then
        SetNetworkIdCanMigrate(netId, true)
        TriggerServerEvent("ng_event:server:RegisterL5NPC", netId)
    end

    SetModelAsNoLongerNeeded(modelHash)
    return { entity = ped, netId = netId, alive = true, spawnIndex = index, coords = coords }
end

RegisterNetEvent("ng_event:client:StartLevel5Instance", function()
    Level5Active = true
    level5Npcs = {}

    local cfg = Config.Levels[5]
    local spawnCount = cfg.maxNpcs or #cfg.npcSpawnCoords

    -- Initial Spawn
    for i = 1, spawnCount do
        -- If we have fewer coords than maxNpcs, cycle through coords
        local coordIndex = ((i - 1) % #cfg.npcSpawnCoords) + 1
        local coords = cfg.npcSpawnCoords[coordIndex]
        level5Npcs[i] = SpawnSingleNPC(i, coords, cfg)
    end

    DebugPrint("LEVEL 5 DEBUG: Spawned initial " .. spawnCount .. " NPCs")

    -- Initialize UI state
    Level5Kills = 0
    Level5KillsRequired = cfg.killsRequired
    RefreshUI()

    -- Thread 1: Kill detection, Respawn & Task Refresh (checks every 500ms)
    Citizen.CreateThread(function()
        local lastTaskRefresh = GetGameTimer()
        while Level5Active and InEvent do
            local now = GetGameTimer()
            local refreshTasks = (now - lastTaskRefresh) > 5000 -- Refresh tasks every 5s

            for i, npc in pairs(level5Npcs) do
                if npc.alive and npc.entity and DoesEntityExist(npc.entity) then
                    if GetEntityHealth(npc.entity) <= 0 then
                        npc.alive = false
                        
                        -- Immediate deletion after death to keep arena clean
                        Citizen.CreateThread(function()
                            Wait(2000) -- Wait 2s for some ragdoll/death animation feel then delete
                            if DoesEntityExist(npc.entity) then
                                DeleteEntity(npc.entity)
                            end
                        end)
                    elseif refreshTasks then
                        -- Push to player location
                        TaskCombatPed(npc.entity, cache.ped, 0, 16)
                    end
                end
            end

            if refreshTasks then lastTaskRefresh = now end
            Wait(500)
        end
    end)
end)

-- Respawn NPCs handler
RegisterNetEvent("ng_event:client:RespawnNPCsL5", function(count)
    if not Level5Active or not InEvent then return end
    local cfg = Config.Levels[5]
    
    DebugPrint("[L5] Respawning " .. count .. " new NPCs")
    for i = 1, count do
        local coordIndex = math.random(1, #cfg.npcSpawnCoords)
        local coords = cfg.npcSpawnCoords[coordIndex]
        
        -- Append to the end of the list
        local nextIndex = #level5Npcs + 1
        level5Npcs[nextIndex] = SpawnSingleNPC(nextIndex, coords, cfg)
    end
end)

-- ============================================================
-- INSTANCE STOP (cleanup NPCs)
-- ============================================================
RegisterNetEvent("ng_event:client:StopLevel5Instance", function()
    Level5Active = false

    -- Delete all NPCs
    for i, npc in pairs(level5Npcs) do
        if npc.entity and DoesEntityExist(npc.entity) then
            DeleteEntity(npc.entity)
        end
    end
    level5Npcs = {}

    DebugPrint("LEVEL 5 DEBUG: Instance stopped, NPCs cleaned up")
end)

-- ============================================================
-- KILL / TIME UPDATES FROM SERVER
-- ============================================================
RegisterNetEvent("ng_event:client:L5KillUpdate", function(kills, required)
    Level5Kills = kills
    Level5KillsRequired = required
    RefreshUI()
end)

RegisterNetEvent("ng_event:client:L5TimeUpdate", function(remaining, kills, required)
    Level5TimeRemaining = remaining
    Level5Kills = kills
    Level5KillsRequired = required
    RefreshUI()
end)

-- ============================================================
-- DEATH HANDLER (fail Level 5)
-- ============================================================
RegisterNetEvent('qbx_medical:client:onPlayerDied', function()
    if InEvent and LocalEventState.level == 5 and Level5Active then
        TriggerServerEvent("ng_event:server:PlayerDiedL5")
    end
end)

RegisterNetEvent('qbx_medical:client:onPlayerLaststand', function()
    if InEvent and LocalEventState.level == 5 and Level5Active then
        TriggerServerEvent("ng_event:server:PlayerDiedL5")
    end
end)

-- ============================================================
-- CLEANUP
-- ============================================================
RegisterNetEvent("ng_event:client:RemoveZones", function()
    Level5Active = false
    for i, npc in pairs(level5Npcs) do
        if npc.entity and DoesEntityExist(npc.entity) then
            DeleteEntity(npc.entity)
        end
    end
    level5Npcs = {}

    if level5Blip then RemoveBlip(level5Blip) level5Blip = nil end
    if level5EntryTarget then
        exports.ox_target:removeZone(level5EntryTarget)
        level5EntryTarget = nil
    end
end)
