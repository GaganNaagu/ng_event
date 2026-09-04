InEvent = false
LocalEventState = {
    level = 0,
    tokens = {},
    arenaKills = 0,
    finished = false
}
RegisteredZones = {}
LevelZones = {
    [1] = {}, [2] = {}, [3] = {}, [4] = {}, [5] = {}, [6] = {}
} 

local ReportedKills = {} -- Track reported netIds locally to avoid spam

RegisterNetEvent("ng_event:client:EventStarted", function()
    InEvent = true
    TriggerEvent("ng_event:client:ShowUI")
    RefreshUI()
    -- Server triggers the initial level setup via UnlockLevel
end)

RegisterNetEvent("ng_event:client:EventEnded", function()
    InEvent = false
    TriggerEvent("ng_event:client:HideUI")
    TriggerEvent("ng_event:client:RemoveZones")
    TriggerEvent("ng_event:client:HideLevel1Blip")
    TriggerEvent("ng_event:client:HideHangarBlip")
    TriggerEvent("ng_event:client:HideLevel3Blip")
    TriggerEvent("ng_event:client:HideLevel4Blip")
    TriggerEvent("ng_event:client:HideLevel5Blip")
    TriggerEvent("ng_event:client:HideLevel6Blip")
    ReportedKills = {} -- Reset tracking
end)

-- Level 4 drowning disable
Citizen.CreateThread(function()
    local hadUnlimitedOxygen = false
    while true do
        Wait(1000)
        if InEvent and LocalEventState.level == 4 then
            local ped = PlayerPedId()
            SetPedDiesInWater(ped, false)
            SetPedMaxTimeUnderwater(ped, 1000.0)
            hadUnlimitedOxygen = true
        elseif hadUnlimitedOxygen then
            local ped = PlayerPedId()
            SetPedDiesInWater(ped, true)
            SetPedMaxTimeUnderwater(ped, 15.0)
            hadUnlimitedOxygen = false
        end
    end
end)

-- Global State Listener for Unlocked Levels
local ClientUnlockedLevels = {}

-- NUI Callbacks and initialization
-- Rejoin Recovery / Environment Setup
RegisterNetEvent("ng_event:client:SetupEventEnvironment", function()
    InEvent = true
    TriggerEvent("ng_event:client:ShowUI")
    DebugPrint("CLIENT: Event Environment Setup/Restored")
end)

local function OnPlayerLoaded()
    -- Tell NUI what our configured position is as early as possible so it doesn't default to top-center
    SendNUIMessage({
        action = "updateHUD",
        hudPosition = Config.HUD.Position
    })
    
    lib.callback('ng_event:server:GetEventState', false, function(state)
        if state and state.active then
            TriggerEvent("ng_event:client:SetupEventEnvironment")
        end
    end)
end

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    OnPlayerLoaded()
end)

RegisterNetEvent('qbx_core:client:onCharacterLoaded', function()
    OnPlayerLoaded()
end)

AddStateBagChangeHandler('ng_event_unlockedLevels', nil, function(bagName, key, value)
    if not InEvent then return end -- Only process for participants
    DebugPrint("CLIENT DEBUG: StateBag ng_event_unlockedLevels changed", bagName, key, json.encode(value))
    if not value then return end
    for level, unlocked in pairs(value) do
        if unlocked then
            TriggerEvent("ng_event:client:UnlockLevel", tonumber(level))
        end
    end
end)

RegisterNetEvent("ng_event:client:UnlockLevel", function(level)
    if not InEvent then return end -- Only process for participants
    level = tonumber(level)
    outLogic = string.format("CLIENT DEBUG: UnlockLevel received logic for level: %s", tostring(level))
    DebugPrint(outLogic)
    if ClientUnlockedLevels[level] then 
        DebugPrint("CLIENT DEBUG: Level " .. level .. " already setup, skipping.")
        return 
    end 
    
    -- Set to true IMMEDIATELY to prevent asynchronous thread yields inside Setup events 
    -- (like lib.requestModel) from allowing a second queued trigger to bypass the lock!
    ClientUnlockedLevels[level] = true
    
    DebugPrint("CLIENT DEBUG: Triggering Setup events for level: " .. level)
    if level == 1 then TriggerEvent("ng_event:client:SetupLevel1Zones")
    elseif level == 2 then TriggerEvent("ng_event:client:SetupLevel2Zones")
    elseif level == 3 then TriggerEvent("ng_event:client:SetupLevel3Zones")
    elseif level == 4 then TriggerEvent("ng_event:client:SetupLevel4Zones")
    elseif level == 5 then TriggerEvent("ng_event:client:SetupLevel5Zones")
    elseif level == 6 then TriggerEvent("ng_event:client:SetupLevel6Zones")
    end
    
    DebugPrint("Client received Level Unlock and Setup: " .. tostring(level))
end)

RegisterNetEvent("ng_event:client:RemoveZones", function()
    for _, id in ipairs(RegisteredZones) do
        exports.ox_target:removeZone(id)
    end
    for level, ids in pairs(LevelZones) do
        for _, id in ipairs(ids) do
            exports.ox_target:removeZone(id)
        end
    end
    RegisteredZones = {}
    LevelZones = {}
    ClientUnlockedLevels = {} -- Reset on cleanup
end)

-- Helper to clear specific level zones before re-adding
RegisterNetEvent("ng_event:client:ClearLevelZones", function(level)
    level = tonumber(level)
    if LevelZones[level] then
        for _, id in ipairs(LevelZones[level]) do
            exports.ox_target:removeZone(id)
        end
    end
    LevelZones[level] = {}
end)

-- PVP is now handled via individual client event to support multi-level states.
RegisterNetEvent("ng_event:client:SetPVPState", function(state)
    DebugPrint("CLIENT DEBUG: SetPVPState received logic for state: " .. (state and "Enabled" or "Disabled"))
    local ped = PlayerPedId()
    if state then
        SetCanAttackFriendly(ped, true, false)
        NetworkSetFriendlyFireOption(true)
    else
        SetCanAttackFriendly(ped, false, false)
        NetworkSetFriendlyFireOption(false)
    end
end)


-- Main enforcement loop
-- Citizen.CreateThread(function()
--     while true do
--         Wait(500)
--         if InEvent then
--             local ped = PlayerPedId()
            
--             -- Level 4 drowning disable
--             if CurrentLevel == 4 then
--                 SetPedDiesInWater(ped, false)
--                 SetPedMaxTimeUnderwater(ped, 1000.0)
--             else
--                 -- Restore default
--                 SetPedMaxTimeUnderwater(ped, 15.0)
--                 SetPedDiesInWater(ped, true)
--             end
--         end
--     end
-- end)

-- Death reporting
AddEventHandler("gameEventTriggered", function(name, args)
    if InEvent and name == "CEventNetworkEntityDamage" then
        local victim = args[1]
        local attacker = args[2]
        local isFatal = args[6] == 1

        if isFatal then
            if attacker == PlayerPedId() then
                -- I killed someone
                local entityModel = GetEntityModel(victim)
                if LocalEventState.level == 2 and IsPedAPlayer(victim) then
                    local player = NetworkGetPlayerIndexFromPed(victim)
                    if player ~= -1 then
                        local victimId = GetPlayerServerId(player)
                        TriggerServerEvent("ng_event:server:ReportPlayerKill", victimId)
                        TriggerEvent("ng_event:client:PlaySound", "Kill") -- Kill Sound
                    end
                elseif LocalEventState.level == 5 and not IsPedAPlayer(victim) then
                    local netId = NetworkGetNetworkIdFromEntity(victim)
                    DebugPrint("L5 KILL DEBUG: Victim NetID:", netId, "Already Reported:", ReportedKills[netId])
                    if netId and netId ~= 0 and not ReportedKills[netId] then
                        ReportedKills[netId] = true
                        TriggerServerEvent("ng_event:server:ReportNPCKillL5", netId)
                        TriggerEvent("ng_event:client:PlaySound", "Kill") -- Kill Sound
                    end
                end
            end
        end
    end
end)

-- NUI Action: Open Admin Panel
RegisterNetEvent("ng_event:client:OpenAdminPanel", function()
    lib.callback("ng_event:server:IsAdmin", false, function(isAdmin)
        if not isAdmin then
            TriggerEvent("ng_event:client:ShowNotification", {title = "Error", description = "You don't have permission!", type = "error"})
            return
        end
        uiVisible = true
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "setupUI",
            visible = true,
            isAdmin = true,
            app = 'adminPanel',
            hudPosition = Config.HUD.Position
        })
    end)
end)

-- NUI Action: Open Player Panel (Leave/Join)
RegisterNetEvent("ng_event:client:OpenPlayerPanel", function()
    uiVisible = true
    SetNuiFocus(true, true)
    
    lib.callback('ng_event:server:GetEventState', false, function(state)
        SendNUIMessage({
            action = "setupUI",
            visible = true,
            isAdmin = false,
            app = 'playerEvent',
            hudPosition = Config.HUD.Position,
            eventData = state
        })
    end)
end)

-- Centralized Death Handler
RegisterNetEvent('qbx_medical:client:onPlayerDied', function()
    if InEvent then
        TriggerServerEvent("ng_event:server:HandleDeath")
    end
end)

RegisterNetEvent('qbx_medical:client:onPlayerLaststand', function()
    if InEvent then
        TriggerServerEvent("ng_event:server:HandleDeath")
    end
end)

RegisterNetEvent("ng_event:client:ForceLeaveVehicle", function()
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    if veh ~= 0 then
        TaskLeaveVehicle(ped, veh, 16) -- Warp Out
        -- If they are somehow still in after a frame, clear tasks forcefully
        Citizen.CreateThread(function()
            Wait(100)
            if IsPedInAnyVehicle(ped, false) then
                ClearPedTasksImmediately(ped)
            end
        end)
    end
end)

RegisterNetEvent("ng_event:client:TeleportVehicle", function(netId, teleportCoords)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        -- Ensure we have network control to make the teleport stick
        if NetworkHasControlOfEntity(entity) then
            SetEntityCoords(entity, teleportCoords.x, teleportCoords.y, teleportCoords.z, false, false, false, false)
            SetVehicleOnGroundProperly(entity)
        else
            -- Request control then try again briefly
            NetworkRequestControlOfEntity(entity)
            Citizen.CreateThread(function()
                local timeout = 0
                while not NetworkHasControlOfEntity(entity) and timeout < 10 do
                    Wait(50)
                    timeout = timeout + 1
                end
                SetEntityCoords(entity, teleportCoords.x, teleportCoords.y, teleportCoords.z, false, false, false, false)
                SetVehicleOnGroundProperly(entity)
            end)
        end
    end
end)


RegisterNetEvent("ng_event:client:FadeAndTeleport", function(coords, heading)
    local ped = PlayerPedId()
    DoScreenFadeOut(500)
    Wait(600)
    
    SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
    if heading then
        SetEntityHeading(ped, heading)
    end
    
    Wait(500)
    DoScreenFadeIn(1000)
end)



-- Handle script restart/stop cleanup
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    InEvent = false
    TriggerEvent("ng_event:client:HideUI")
    TriggerEvent("ng_event:client:RemoveZones")
    TriggerEvent("ng_event:client:HideLevel1Blip")
    TriggerEvent("ng_event:client:HideHangarBlip")
    TriggerEvent("ng_event:client:HideLevel3Blip")
    TriggerEvent("ng_event:client:HideLevel4Blip")
    TriggerEvent("ng_event:client:HideLevel5Blip")
    TriggerEvent("ng_event:client:HideLevel6Blip")
end)
