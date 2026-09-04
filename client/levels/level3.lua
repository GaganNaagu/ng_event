-- ============================================================
-- TREASURE ZONE — CLIENT (Level 3)
-- ============================================================

local level3Prop = nil
local Level3Active = false
local predators = {} -- { { entity = nil, model = "" } }
local spawningActive = false


-- Initialize relationship groups
AddRelationshipGroup("event_predator")
SetRelationshipBetweenGroups(0, `event_predator`, `event_predator`) -- Neutral to each other
SetRelationshipBetweenGroups(5, `event_predator`, `PLAYER`) -- Hate players
SetRelationshipBetweenGroups(5, `PLAYER`, `event_predator`) -- Players hate predators

local function ClearAllPredators()
    for i, p in ipairs(predators) do
        if DoesEntityExist(p.entity) then
            DeleteEntity(p.entity)
        end
        if p.blip then
            RemoveBlip(p.blip)
        end
    end
    predators = {}
end

local function GetPredatorDifficulty()
    local cfg = Config.Levels[3]
    return Config.Predators.Difficulty[cfg.difficulty] or Config.Predators.Difficulty["hard"]
end

-- ============================================================
-- PREDATOR REGISTRATION & BEHAVIOR
-- ============================================================

local function SetupPredatorAttributes(ped)
    if not DoesEntityExist(ped) then return end
    
    -- Set Attributes (Client-side)
    SetEntityAsMissionEntity(ped, true, true)
    SetPedKeepTask(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedRelationshipGroupHash(ped, `event_predator`)
    SetPedCombatAttributes(ped, 46, true) -- Always fight
    SetPedCombatAttributes(ped, 5, true)  -- Can fight unarmed
    SetPedCombatAttributes(ped, 16, true) -- Don't stop for vehicles
    SetPedConfigFlag(ped, 183, true)      -- DontFleeOnRangeAttack
    SetPedConfigFlag(ped, 142, true)      -- Is a brave ped
    SetPedFleeAttributes(ped, 0, false)   -- Don't flee
    SetAnimalMood(ped, 1)                 -- Aggressive
    SetPedCombatAbility(ped, 2)           -- Professional combatant
    SetPedCombatRange(ped, 3)             -- Long
    
    local difficulty = GetPredatorDifficulty()
    SetPedMoveRateOverride(ped, difficulty.speedScale or 1.2)

    -- Apply Health & Armor
    if difficulty.health then
        SetEntityMaxHealth(ped, difficulty.health)
        SetEntityHealth(ped, difficulty.health)
        SetPedArmour(ped, 100)
    end

    -- Custom Debug Blip
    local blip = nil
    if Config.Debug then
        SetPedHasAiBlip(ped, true)
        blip = AddBlipForEntity(ped)
        SetBlipSprite(blip, 141) -- Lion/Cat sprite
        SetBlipColour(blip, 1)   -- Red
        SetBlipScale(blip, 0.7)
        BeginTextCommandSetBlipName("STRING")
        AddTextComponentString("DEBUG: Lion")
        EndTextCommandSetBlipName(blip)
    end
    return blip
end

-- New efficient registration event
RegisterNetEvent("ng_event:client:RegisterPredator", function(netId, spawnCoords)
    if not spawningActive then return end
    
    local wait = 0
    while not NetworkDoesNetworkIdExist(netId) and wait < 50 do
        Wait(100)
        wait = wait + 1
    end

    if NetworkDoesNetworkIdExist(netId) then
        local ped = NetworkGetEntityFromNetworkId(netId)
        if DoesEntityExist(ped) then
            DebugPrint("Registering New Guardian Predator (NetID: " .. netId .. ")")
            local blip = SetupPredatorAttributes(ped)
            table.insert(predators, { 
                entity = ped, 
                state = "GUARD", -- GUARD | ATTACK | RETURN
                netId = netId,
                blip = blip,
                spawnCoords = spawnCoords
            })
        end
    end
end)

local function StartPredatorSystem()
    if spawningActive then 
        DebugPrint("StartPredatorSystem called but already active.")
        return 
    end
    spawningActive = true
    DebugPrint("Starting Predator Guardian System for Level 3")

    local cfg = Config.Levels[3]
    local treasureCoords = cfg.treasureBoxCoords
    local redZoneRadius = cfg.redZoneRadius
    local difficulty = GetPredatorDifficulty()

    -- Hunting & Guardian Loop
    Citizen.CreateThread(function()
        DebugPrint("Guardian Logic Thread Started.")
        
        while spawningActive and InEvent do
            -- 1. Build list of valid player targets inside the zone
            local activePlayers = GetActivePlayers()
            local validTargets = {}
            local zoneCenter = cfg.redZoneCenter or cfg.treasureBoxCoords
            
            for _, player in ipairs(activePlayers) do
                local pPed = GetPlayerPed(player)
                if DoesEntityExist(pPed) and not IsPedDeadOrDying(pPed, 1) then
                    local pCoords = GetEntityCoords(pPed)
                    if #(pCoords - zoneCenter) <= redZoneRadius then
                        table.insert(validTargets, pPed)
                    end
                end
            end

            for i = #predators, 1, -1 do
                local p = predators[i]
                if not DoesEntityExist(p.entity) or IsPedDeadOrDying(p.entity, 1) then
                    if DoesEntityExist(p.entity) then
                        TriggerServerEvent("ng_event:server:DeletePredator", p.netId)
                    end
                    if p.blip then
                        RemoveBlip(p.blip)
                    end
                    table.remove(predators, i)
                else
                    -- Constantly apply movement speed to bypass default animal restrictions
                    SetPedMoveRateOverride(p.entity, difficulty.speedScale or 1.2)

                    local predatorCoords = GetEntityCoords(p.entity)
                    local distToCenter = #(predatorCoords - zoneCenter)

                    -- LEASH LOGIC: Force return if outside bounds
                    if distToCenter > (redZoneRadius + 20.0) then
                        if p.state ~= "RETURN" then
                            p.state = "RETURN"
                            p.target = nil
                            ClearPedTasksImmediately(p.entity)
                            if p.spawnCoords then
                                SetEntityCoords(p.entity, p.spawnCoords.x, p.spawnCoords.y, p.spawnCoords.z, false, false, false, false)
                                SetEntityHeading(p.entity, p.spawnCoords.w or 0.0)
                            end
                            DebugPrint("Predator leash triggered. Teleported back to Guard Post.")
                        end
                    else
                        -- FIND NEAREST PLAYER
                        local closestPlayer = nil
                        local minDistance = 999999.0

                        for _, targetPed in ipairs(validTargets) do
                            local dist = #(predatorCoords - GetEntityCoords(targetPed))
                            if dist < minDistance then
                                minDistance = dist
                                closestPlayer = targetPed
                            end
                        end

                        -- HAS A TARGET IN ZONE
                        if closestPlayer then
                            if p.target ~= closestPlayer then
                                p.state = "ATTACK"
                                p.target = closestPlayer
                                TaskCombatPed(p.entity, closestPlayer, 0, 16)
                                DebugPrint("Predator dynamically swapped to closest intruder!")
                            end
                        -- NO TARGETS IN ZONE -> RETURN TO GUARD
                        else
                            if p.state == "ATTACK" or (p.state == "RETURN" and distToCenter < 15.0) then
                                p.state = "GUARD"
                                p.target = nil
                                ClearPedTasks(p.entity)
                                TaskGoStraightToCoord(p.entity, zoneCenter.x, zoneCenter.y, zoneCenter.z, 1.0, 20000, 0.0, 0.0)
                                DebugPrint("No targets in zone. Returning to Guard position.")
                            end
                        end
                    end
                end
            end
            Wait(1500) -- Strict AI loop interval
        end
        DebugPrint("Guardian Logic Thread EXIT.")
    end)
end

-- ============================================================
-- ZONE SETUP
-- ============================================================
RegisterNetEvent("ng_event:client:SetupLevel3Zones", function()
    DebugPrint("RegisterNetEvent SetupLevel3Zones triggered.")
    if not InEvent then 
        DebugPrint("SetupLevel3Zones aborted: Not InEvent.")
        return 
    end
    Level3Active = true

    local cfg = Config.Levels[3]
    local coords = cfg.treasureBoxCoords

    -- 1. Treasure Prop
    local propHash = cfg.treasurePropHash
    
    -- FORCE CLEANUP: Wipe out any orphaned or previously spawned chests in the immediate area
    ClearAreaOfObjects(coords.x, coords.y, coords.z, 2.0, 0)
    
    if not level3Prop or not DoesEntityExist(level3Prop) then
        lib.requestModel(propHash)
        -- Set isNetwork to false (the first boolean) so clients don't duplicate networked props
        level3Prop = CreateObject(propHash, coords.x, coords.y, coords.z, false, false, false)
        SetModelAsNoLongerNeeded(propHash)
        SetEntityHeading(level3Prop, 0.0)
        PlaceObjectOnGroundProperly(level3Prop)
        FreezeEntityPosition(level3Prop, true)
    else
        DebugPrint("Treasure prop already exists locally. Preserving it.")
    end

    -- 2. ox_target on Entity
    exports.ox_target:addLocalEntity(level3Prop, {
        {
            name = 'ng_event_treasure3',
            icon = 'fas fa-box',
            label = 'Loot Treasure',
            distance = 2.5,
            onSelect = function()
                local minigame = Config.Levels[3].minigame
                local success = lib.skillCheck(minigame.difficulty, minigame.keys)

                if success then
                    TriggerServerEvent("ng_event:server:LootTreasure3")
                    RefreshUI()
                else
                    TriggerEvent("ng_event:client:ShowNotification", {
                        title = "Event",
                        description = "You failed the lockpick! Try again.",
                        type = "error"
                    })
                end
            end,
            canInteract = function()
                return InEvent and LocalEventState.level == 3 and not LocalEventState.tokens[3]
            end
        }
    })

    -- 3. Area Detection via ox_lib Sphere Zone
    local redZoneSphere = lib.zones.sphere({
        coords = cfg.redZoneCenter or coords,
        radius = Config.Levels[3].redZoneRadius,
        debug = Config.Debug,
        onEnter = function(self)
            if InEvent and LocalEventState.level == 3 then
                DebugPrint("Local Player entered Predator Zone.")
                TriggerServerEvent("ng_event:server:PlayerEnteredL3Zone")
            end
        end,
        onExit = function(self)
            if InEvent and LocalEventState.level == 3 then
                DebugPrint("Local Player left Predator Zone.")
                -- Additional logic if needed when exiting
            end
        end
    })

    Citizen.CreateThread(function()
        DebugPrint("Level 3 General Area Thread Started")
        local zoneCenter = cfg.redZoneCenter or coords
        
        while Level3Active and InEvent do
            local pCoords = GetEntityCoords(PlayerPedId())
            local dist = #(pCoords - zoneCenter)
            
            if dist <= 200.0 then
                -- Suppression of normal traffic/peds within 200m
                SetPedDensityMultiplierThisFrame(0.0)
                SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
                SetVehicleDensityMultiplierThisFrame(0.0)
                SetRandomVehicleDensityMultiplierThisFrame(0.0)
                SetParkedVehicleDensityMultiplierThisFrame(0.0)
            end

            -- Auto-hide prop when token collected
            if level3Prop and DoesEntityExist(level3Prop) then
                if LocalEventState.tokens[3] or LocalEventState.level > 3 then
                    DeleteObject(level3Prop)
                    level3Prop = nil
                end
            end
            Wait(0)
        end
        
        -- Cleanup zone when thread ends
        if redZoneSphere then redZoneSphere:remove() end
    end)
end)

-- ============================================================
-- PREDATOR SYNC EVENTS
-- ============================================================

RegisterNetEvent("ng_event:client:StartPredatorSystem", function()
    DebugPrint("Received StartPredatorSystem from server.")
    StartPredatorSystem()
end)

RegisterNetEvent("ng_event:client:StopPredatorSystem", function()
    DebugPrint("Received StopPredatorSystem from server.")
    spawningActive = false
    ClearAllPredators()
end)

-- ============================================================
-- ZONE CLEANUP
-- ============================================================
RegisterNetEvent("ng_event:client:RemoveZones", function()
    Level3Active = false
    spawningActive = false
    ClearAllPredators()
    if level3Prop and DoesEntityExist(level3Prop) then
        exports.ox_target:removeLocalEntity(level3Prop)
        DeleteObject(level3Prop)
        level3Prop = nil
    end
end)

-- ============================================================
-- BLIP MANAGEMENT
-- ============================================================
local level3Blip = nil

RegisterNetEvent("ng_event:client:ShowLevel3Blip", function()
    if not InEvent then return end
    if level3Blip then RemoveBlip(level3Blip) end
    local coords = Config.Levels[3].treasureBoxCoords
    level3Blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(level3Blip, 439)
    SetBlipColour(level3Blip, 5)
    SetBlipScale(level3Blip, 1.0)
    SetBlipAsShortRange(level3Blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Event: Treasure")
    EndTextCommandSetBlipName(level3Blip)
    SetBlipRoute(level3Blip, true)
    
    -- Red Zone Blip
    local zoneCenter = Config.Levels[3].redZoneCenter or coords
    local redZoneBlip = AddBlipForRadius(zoneCenter.x, zoneCenter.y, zoneCenter.z, Config.Levels[3].redZoneRadius)
    SetBlipColour(redZoneBlip, 1) -- Red
    SetBlipAlpha(redZoneBlip, 128)

    TriggerEvent("ng_event:client:ShowNotification", {title = "Event", description = "Treasure marked on your GPS! Beware of the Red Zone.", type = "inform"})
end)

RegisterNetEvent("ng_event:client:HideLevel3Blip", function()
    if level3Blip then RemoveBlip(level3Blip) level3Blip = nil end
end)

-- ============================================================
-- DEATH / RESPAWN HOOKS
-- ============================================================
RegisterNetEvent('qbx_medical:client:onPlayerDied', function()
    if InEvent and LocalEventState.level == 3 then
        TriggerServerEvent("ng_event:server:RespawnPlayerL3")
    end
end)

RegisterNetEvent('qbx_medical:client:onPlayerLaststand', function()
    if InEvent and LocalEventState.level == 3 then
        TriggerServerEvent("ng_event:server:RespawnPlayerL3")
    end
end)
