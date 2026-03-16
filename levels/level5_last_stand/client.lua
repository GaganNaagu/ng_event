-- levels/level5_last_stand/client.lua
-- Client logic for The Last Stand (Personal PvE Arena)

local Level5 = {}

local Level5Active = false
local level5Npcs = {}
local level5Blip = nil
local level5EntryTarget = nil

AddRelationshipGroup("L5_ENEMY")
SetRelationshipBetweenGroups(1, `L5_ENEMY`, `L5_ENEMY`) 
SetRelationshipBetweenGroups(5, `L5_ENEMY`, `PLAYER`)   
SetRelationshipBetweenGroups(5, `PLAYER`, `L5_ENEMY`)   

function Level5.SetupZones()
    TriggerEvent("ng_event:client:ShowLevel5Blip")
end

function Level5.Cleanup()
    Level5Active = false
    for i, npc in pairs(level5Npcs) do
        if npc.entity and DoesEntityExist(npc.entity) then
            DeleteEntity(npc.entity)
        end
    end
    level5Npcs = {}

    if level5Blip then RemoveBlip(level5Blip) level5Blip = nil end
    if level5EntryTarget then
        Target.RemoveZone(level5EntryTarget)
        level5EntryTarget = nil
    end
end

LevelManager.RegisterLevel(5, Level5)

RegisterNetEvent("ng_event:client:ShowLevel5Blip", function()
    local cfg = Config.Levels[5]
    local entry = cfg.entryCoords

    if level5Blip then RemoveBlip(level5Blip) end
    level5Blip = AddBlipForCoord(entry.x, entry.y, entry.z)
    SetBlipSprite(level5Blip, 310)
    SetBlipColour(level5Blip, 1) 
    SetBlipScale(level5Blip, 1.0)
    SetBlipAsShortRange(level5Blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Event: Isolated Combat")
    EndTextCommandSetBlipName(level5Blip)
    SetBlipRoute(level5Blip, true)

    if level5EntryTarget then Target.RemoveZone(level5EntryTarget) end
    level5EntryTarget = Target.AddZone({
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
                    return LocalEventState and LocalEventState.level == 5 and not LocalEventState.tokens[5]
                end
            }
        }
    })

    TriggerEvent("ng_event:client:ShowNotification", {title = "Event", description = "Isolated Combat Arena marked on GPS!", type = "inform"})
end)

RegisterNetEvent("ng_event:client:HideLevel5Blip", function()
    if level5Blip then RemoveBlip(level5Blip) level5Blip = nil end
    if level5EntryTarget then
        Target.RemoveZone(level5EntryTarget)
        level5EntryTarget = nil
    end
end)

local function SetupNPCAI(ped)
    SetPedRelationshipGroupHash(ped, `L5_ENEMY`)
    
    SetPedCombatAttributes(ped, 46, true) 
    SetPedCombatAttributes(ped, 5, true)  
    SetPedCombatAbility(ped, 100)
    SetPedCombatMovement(ped, 2) 
    SetPedCombatRange(ped, 2) 
    SetPedFleeAttributes(ped, 0, false)
    SetPedAsEnemy(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedDropsWeaponsWhenDead(ped, false)
    SetPedAccuracy(ped, 100)
    SetPedArmour(ped, 50)
    SetEntityMaxHealth(ped, 100)
    SetEntityHealth(ped, 100)
    
    SetPedSuffersCriticalHits(ped, false)
    SetPedCanRagdoll(ped, false)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    
    SetEntityAsMissionEntity(ped, true, true) 

    local plyPed = PlayerPedId()
    TaskCombatPed(ped, plyPed, 0, 16)
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

    for i = 1, spawnCount do
        local coordIndex = ((i - 1) % #cfg.npcSpawnCoords) + 1
        local coords = cfg.npcSpawnCoords[coordIndex]
        level5Npcs[i] = SpawnSingleNPC(i, coords, cfg)
    end

    Level5Kills = 0
    Level5KillsRequired = cfg.killsRequired
    if RefreshUI then RefreshUI() end

    Citizen.CreateThread(function()
        local lastTaskRefresh = GetGameTimer()
        while Level5Active do
            local now = GetGameTimer()
            local refreshTasks = (now - lastTaskRefresh) > 5000 
            local plyPed = PlayerPedId()

            for i, npc in pairs(level5Npcs) do
                if npc.alive and npc.entity and DoesEntityExist(npc.entity) then
                    if GetEntityHealth(npc.entity) <= 0 then
                        npc.alive = false
                        
                        Citizen.CreateThread(function()
                            Wait(2000) 
                            if DoesEntityExist(npc.entity) then
                                DeleteEntity(npc.entity)
                            end
                        end)
                    elseif refreshTasks then
                        TaskCombatPed(npc.entity, plyPed, 0, 16)
                    end
                end
            end

            if refreshTasks then lastTaskRefresh = now end
            Wait(500)
        end
    end)
end)

RegisterNetEvent("ng_event:client:RespawnNPCsL5", function(count)
    if not Level5Active then return end
    local cfg = Config.Levels[5]
    
    for i = 1, count do
        local coordIndex = math.random(1, #cfg.npcSpawnCoords)
        local coords = cfg.npcSpawnCoords[coordIndex]
        local nextIndex = #level5Npcs + 1
        level5Npcs[nextIndex] = SpawnSingleNPC(nextIndex, coords, cfg)
    end
end)

RegisterNetEvent("ng_event:client:StopLevel5Instance", function()
    Level5Active = false

    for i, npc in pairs(level5Npcs) do
        if npc.entity and DoesEntityExist(npc.entity) then
            DeleteEntity(npc.entity)
        end
    end
    level5Npcs = {}
end)

RegisterNetEvent("ng_event:client:L5KillUpdate", function(kills, required)
    Level5Kills = kills
    Level5KillsRequired = required
    if RefreshUI then RefreshUI() end
end)
