-- levels/level3_lion_hunt/client.lua
-- Treasure & Predator Zone Client Logic (Level 3)

local Level3 = {}
local level3Prop = nil
local Level3Active = false
local predators = {} 
local spawningActive = false
local level3Blip = nil
local redZoneBlip = nil
local redZoneSphere = nil

AddRelationshipGroup("event_predator")
SetRelationshipBetweenGroups(0, `event_predator`, `event_predator`)
SetRelationshipBetweenGroups(5, `event_predator`, `PLAYER`)
SetRelationshipBetweenGroups(5, `PLAYER`, `event_predator`)

local function ClearAllPredators()
    for i, p in ipairs(predators) do
        if DoesEntityExist(p.entity) then DeleteEntity(p.entity) end
        if p.blip then RemoveBlip(p.blip) end
    end
    predators = {}
end

local function GetPredatorDifficulty()
    local cfg = Config.Levels[3]
    return Config.Predators.Difficulty[cfg.difficulty] or Config.Predators.Difficulty["hard"]
end

local function SetupPredatorAttributes(ped)
    if not DoesEntityExist(ped) then return end
    
    SetEntityAsMissionEntity(ped, true, true)
    SetPedKeepTask(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetPedRelationshipGroupHash(ped, `event_predator`)
    SetPedCombatAttributes(ped, 46, true) 
    SetPedCombatAttributes(ped, 5, true)  
    SetPedCombatAttributes(ped, 16, true) 
    SetPedConfigFlag(ped, 183, true)      
    SetPedConfigFlag(ped, 142, true)      
    SetPedFleeAttributes(ped, 0, false)   
    SetAnimalMood(ped, 1)                 
    SetPedCombatAbility(ped, 2)           
    SetPedCombatRange(ped, 3)             
    
    local difficulty = GetPredatorDifficulty()
    SetPedMoveRateOverride(ped, difficulty.speedScale or 1.2)

    if difficulty.health then
        SetEntityMaxHealth(ped, difficulty.health)
        SetEntityHealth(ped, difficulty.health)
        SetPedArmour(ped, 100)
    end

    local blip = nil
    if Config.Debug then
        SetPedHasAiBlip(ped, true)
        blip = AddBlipForEntity(ped)
        SetBlipSprite(blip, 141)
        SetBlipColour(blip, 1)
        SetBlipScale(blip, 0.7)
    end
    return blip
end

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
            local blip = SetupPredatorAttributes(ped)
            table.insert(predators, { 
                entity = ped, 
                state = "GUARD", 
                netId = netId,
                blip = blip,
                spawnCoords = spawnCoords
            })
        end
    end
end)

local function StartPredatorSystem()
    if spawningActive then return end
    spawningActive = true

    local cfg = Config.Levels[3]
    local treasureCoords = cfg.treasureBoxCoords
    local redZoneRadius = cfg.redZoneRadius
    local difficulty = GetPredatorDifficulty()

    Citizen.CreateThread(function()
        while spawningActive and LocalEventState and LocalEventState.level == 3 do
            local activePlayers = GetActivePlayers()
            local validTargets = {}
            local zoneCenter = cfg.redZoneCenter or cfg.treasureBoxCoords
            
            for _, player in ipairs(activePlayers) do
                local pPed = GetPlayerPed(player)
                if DoesEntityExist(pPed) and not Framework.IsDead() then
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
                    if p.blip then RemoveBlip(p.blip) end
                    table.remove(predators, i)
                else
                    SetPedMoveRateOverride(p.entity, difficulty.speedScale or 1.2)

                    local predatorCoords = GetEntityCoords(p.entity)
                    local distToCenter = #(predatorCoords - zoneCenter)

                    if distToCenter > (redZoneRadius + 20.0) then
                        if p.state ~= "RETURN" then
                            p.state = "RETURN"
                            p.target = nil
                            ClearPedTasksImmediately(p.entity)
                            if p.spawnCoords then
                                SetEntityCoords(p.entity, p.spawnCoords.x, p.spawnCoords.y, p.spawnCoords.z, false, false, false, false)
                                SetEntityHeading(p.entity, p.spawnCoords.w or 0.0)
                            end
                        end
                    else
                        local closestPlayer = nil
                        local minDistance = 999999.0

                        for _, targetPed in ipairs(validTargets) do
                            local dist = #(predatorCoords - GetEntityCoords(targetPed))
                            if dist < minDistance then
                                minDistance = dist
                                closestPlayer = targetPed
                            end
                        end

                        if closestPlayer then
                            if p.target ~= closestPlayer then
                                p.state = "ATTACK"
                                p.target = closestPlayer
                                TaskCombatPed(p.entity, closestPlayer, 0, 16)
                            end
                        else
                            if p.state == "ATTACK" or (p.state == "RETURN" and distToCenter < 15.0) then
                                p.state = "GUARD"
                                p.target = nil
                                ClearPedTasks(p.entity)
                                TaskGoStraightToCoord(p.entity, zoneCenter.x, zoneCenter.y, zoneCenter.z, 1.0, 20000, 0.0, 0.0)
                            end
                        end
                    end
                end
            end
            Wait(1500)
        end
    end)
end

function Level3.SetupZones()
    Level3Active = true
    local cfg = Config.Levels[3]
    local coords = cfg.treasureBoxCoords
    local propHash = cfg.treasurePropHash
    
    ClearAreaOfObjects(coords.x, coords.y, coords.z, 2.0, 0)
    
    if not level3Prop or not DoesEntityExist(level3Prop) then
        lib.requestModel(propHash)
        level3Prop = CreateObject(propHash, coords.x, coords.y, coords.z, false, false, false)
        SetModelAsNoLongerNeeded(propHash)
        SetEntityHeading(level3Prop, 0.0)
        PlaceObjectOnGroundProperly(level3Prop)
        FreezeEntityPosition(level3Prop, true)
    end

    Target.AddLocalEntity(level3Prop, {
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
                    if RefreshUI then RefreshUI() end
                else
                    TriggerEvent("ng_event:client:ShowNotification", {
                        title = "Event",
                        description = "You failed the lockpick! Try again.",
                        type = "error"
                    })
                end
            end,
            canInteract = function()
                return LocalEventState and LocalEventState.level == 3 and not LocalEventState.tokens[3]
            end
        }
    })

    redZoneSphere = lib.zones.sphere({
        coords = cfg.redZoneCenter or coords,
        radius = Config.Levels[3].redZoneRadius,
        debug = Config.Debug,
        onEnter = function(self)
            if LocalEventState and LocalEventState.level == 3 then
                TriggerServerEvent("ng_event:server:PlayerEnteredL3Zone")
            end
        end
    })

    Citizen.CreateThread(function()
        local zoneCenter = cfg.redZoneCenter or coords
        while Level3Active do
            local pCoords = GetEntityCoords(PlayerPedId())
            local dist = #(pCoords - zoneCenter)
            
            if dist <= 200.0 then
                SetPedDensityMultiplierThisFrame(0.0)
                SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
                SetVehicleDensityMultiplierThisFrame(0.0)
                SetRandomVehicleDensityMultiplierThisFrame(0.0)
                SetParkedVehicleDensityMultiplierThisFrame(0.0)
            end

            if level3Prop and DoesEntityExist(level3Prop) then
                if LocalEventState and (LocalEventState.tokens[3] or LocalEventState.level > 3) then
                    Target.RemoveLocalEntity(level3Prop)
                    DeleteObject(level3Prop)
                    level3Prop = nil
                end
            end
            Wait(0)
        end
        if redZoneSphere then redZoneSphere:remove() end
    end)
end

function Level3.Cleanup()
    Level3Active = false
    spawningActive = false
    ClearAllPredators()
    if level3Prop and DoesEntityExist(level3Prop) then
        Target.RemoveLocalEntity(level3Prop)
        DeleteObject(level3Prop)
        level3Prop = nil
    end
    if level3Blip then RemoveBlip(level3Blip) level3Blip = nil end
    if redZoneBlip then RemoveBlip(redZoneBlip) redZoneBlip = nil end
    if redZoneSphere then redZoneSphere:remove() end
end

LevelManager.RegisterLevel(3, Level3)


RegisterNetEvent("ng_event:client:StartPredatorSystem", function()
    StartPredatorSystem()
end)

RegisterNetEvent("ng_event:client:StopPredatorSystem", function()
    spawningActive = false
    ClearAllPredators()
end)

RegisterNetEvent("ng_event:client:ShowLevel3Blip", function()
    if level3Blip then RemoveBlip(level3Blip) end
    if redZoneBlip then RemoveBlip(redZoneBlip) end
    
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
    
    local zoneCenter = Config.Levels[3].redZoneCenter or coords
    redZoneBlip = AddBlipForRadius(zoneCenter.x, zoneCenter.y, zoneCenter.z, Config.Levels[3].redZoneRadius)
    SetBlipColour(redZoneBlip, 1) 
    SetBlipAlpha(redZoneBlip, 128)

    TriggerEvent("ng_event:client:ShowNotification", {title = "Event", description = "Treasure marked on your GPS! Beware of the Red Zone.", type = "inform"})
end)

RegisterNetEvent("ng_event:client:HideLevel3Blip", function()
    if level3Blip then RemoveBlip(level3Blip) level3Blip = nil end
    if redZoneBlip then RemoveBlip(redZoneBlip) redZoneBlip = nil end
end)
