-- ============================================================
-- LEVEL 4 — UNDERWATER MULTI-CHEST (Client)
-- Spawns all chests, debug blips, chest highlights, dive gear
-- ============================================================

local level4Props = {}    -- { [1] = entity, [2] = entity, ... }
local level4Blips = {}    -- Debug blips per chest
local Level4Active = false

-- Dive Gear State
local diveGear = {
    mask = 0,
    tank = 0,
    equipped = false
}

-- ============================================================
-- DIVE GEAR (Unlimited Oxygen for Level 4)
-- ============================================================

local function deleteDiveGear()
    if diveGear.mask ~= 0 then
        local m = diveGear.mask
        SetEntityAsMissionEntity(m, true, true)
        DetachEntity(m, false, true)
        DeleteObject(m)
        diveGear.mask = 0
    end
    if diveGear.tank ~= 0 then
        local t = diveGear.tank
        SetEntityAsMissionEntity(t, true, true)
        DetachEntity(t, false, true)
        DeleteObject(t)
        diveGear.tank = 0
    end
end

local function attachDiveGear()
    local maskModel = `p_d_scuba_mask_s`
    local tankModel = `p_s_scuba_tank_s`
    lib.requestModel(maskModel)
    lib.requestModel(tankModel)

    diveGear.tank = CreateObject(tankModel, 1.0, 1.0, 1.0, true, true, false) -- Networked for visibility
    DebugPrint("LEVEL 4 DEBUG: Created scuba tank object:", diveGear.tank)
    SetEntityAsMissionEntity(diveGear.tank, true, true)
    SetNetworkIdCanMigrate(ObjToNet(diveGear.tank), false)
    SetEntityCollision(diveGear.tank, false, false)
    local bone1 = GetPedBoneIndex(cache.ped, 24818)
    AttachEntityToEntity(diveGear.tank, cache.ped, bone1, -0.25, -0.25, 0.0, 180.0, 90.0, 0.0, true, true, false, false, 2, true)
    DebugPrint("LEVEL 4 DEBUG: Attached tank to bone 24818")

    diveGear.mask = CreateObject(maskModel, 1.0, 1.0, 1.0, true, true, false) -- Networked for visibility
    DebugPrint("LEVEL 4 DEBUG: Created scuba mask object:", diveGear.mask)
    SetEntityAsMissionEntity(diveGear.mask, true, true)
    SetNetworkIdCanMigrate(ObjToNet(diveGear.mask), false)
    SetEntityCollision(diveGear.mask, false, false)
    local bone2 = GetPedBoneIndex(cache.ped, 12844)
    AttachEntityToEntity(diveGear.mask, cache.ped, bone2, 0.0, 0.0, 0.0, 180.0, 90.0, 0.0, true, true, false, false, 2, true)
    DebugPrint("LEVEL 4 DEBUG: Attached mask to bone 12844")

    SetModelAsNoLongerNeeded(maskModel)
    SetModelAsNoLongerNeeded(tankModel)
end

local function enableDiveGear()
    if diveGear.equipped then return end
    deleteDiveGear()
    attachDiveGear()
    SetEnableScuba(cache.ped, true)
    SetPedMaxTimeUnderwater(cache.ped, 2000.0)
    diveGear.equipped = true
    DebugPrint("LEVEL 4 DEBUG: Dive gear equipped (unlimited oxygen)")
end

local function disableDiveGear()
    if not diveGear.equipped then return end
    SetEnableScuba(cache.ped, false)
    SetPedMaxTimeUnderwater(cache.ped, 15.0)
    SetPedDiesInWater(cache.ped, true)
    deleteDiveGear()
    diveGear.equipped = false
    DebugPrint("LEVEL 4 DEBUG: Dive gear removed")
end

-- ============================================================
-- ZONE SETUP
-- ============================================================

RegisterNetEvent("ng_event:client:SetupLevel4Zones", function()
    if not InEvent then return end
    local cfg = Config.Levels[4]
    local propHash = cfg.treasurePropHash
    lib.requestModel(propHash)
    Level4Active = true

    -- Cleanup any existing ones first
    for _, p in pairs(level4Props) do if DoesEntityExist(p) then DeleteObject(p) end end
    level4Props = {}

    for i, coords in ipairs(cfg.chestLocations) do
        local prop = CreateObject(propHash, coords.x, coords.y, coords.z, false, false, false) -- Local for client performance
        DebugPrint("LEVEL 4 DEBUG: Created chest prop #"..i, prop)
        SetEntityAsMissionEntity(prop, true, true)
        SetEntityHeading(prop, math.random(0, 360) + 0.0)
        PlaceObjectOnGroundProperly(prop)
        FreezeEntityPosition(prop, true)

        -- ox_target on each chest entity
        local chestIndex = i
        exports.ox_target:addLocalEntity(prop, {
            {
                name = 'ng_event_chest4_' .. i,
                icon = 'fas fa-box-open',
                label = 'Search Chest',
                distance = 4,
                onSelect = function()
                    TriggerServerEvent("ng_event:server:LootChest4", chestIndex)
                end,
                canInteract = function()
                    return InEvent and LocalEventState.level == 4 and not LocalEventState.tokens[4]
                end
            }
        })

        level4Props[i] = prop

        -- Debug blip per chest
        if Config.Debug then
            local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
            SetBlipSprite(blip, 1)
            SetBlipColour(blip, 5)  -- Yellow
            SetBlipScale(blip, 0.6)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Chest #" .. i)
            EndTextCommandSetBlipName(blip)
            level4Blips[i] = blip
        end
    end

    SetModelAsNoLongerNeeded(propHash)
    DebugPrint("LEVEL 4 DEBUG: Spawned " .. #cfg.chestLocations .. " treasure chests")

    -- Auto-equip dive gear + chest highlight thread
    Citizen.CreateThread(function()
        local highlightRange = 15.0
        local gotToken = false

        DebugPrint("LEVEL 4 DEBUG: Monitoring thread started. Waiting for player to reach Level 4 context...")

        while Level4Active and InEvent do
            local ped = cache.ped
            local currentLevel = LocalEventState.level

            if currentLevel == 4 then
                -- PLAYER IS CURRENTLY AT LEVEL 4
                
                -- 1. Scuba Gear: Only equip if in water or swimming
                local inWater = IsEntityInWater(ped) or IsPedSwimming(ped) or IsPedSwimmingUnderWater(ped)
                if inWater then
                    if not diveGear.equipped then
                        enableDiveGear()
                    end
                    -- Constant refresh while at Level 4 and in water
                    SetEnableScuba(ped, true)
                    SetPedMaxTimeUnderwater(ped, 2000.0)
                else
                    --surfaced/on land, but still in Level 4 area? 
                    -- We can keep it equipped if they want, but usually it looks better to remove if they are far from water.
                    -- For now, let's just leave it if they already have it, or remove if they are 'really' on land.
                    if diveGear.equipped and not IsPedSwimming(ped) and GetEntityHeightAboveGround(ped) > 2.0 then
                        -- disableDiveGear() -- Optional: keep it on until they finish the level?
                    end
                end

                -- 2. Chest proximity highlight (outline glow)
                local playerCoords = GetEntityCoords(ped)
                highlightedProps = highlightedProps or {}

                for i, prop in pairs(level4Props) do
                    if prop and DoesEntityExist(prop) then
                        local dist = #(playerCoords - GetEntityCoords(prop))
                        if dist <= highlightRange then
                            if not highlightedProps[i] then
                                DebugPrint(string.format("LEVEL 4 DEBUG: Near chest %d (dist: %.2f) - Outline ON", i, dist))
                                SetEntityDrawOutline(prop, true)
                                SetEntityDrawOutlineColor(255, 215, 0, 255)
                                highlightedProps[i] = true
                            end
                        else
                            if highlightedProps[i] then
                                DebugPrint(string.format("LEVEL 4 DEBUG: Left chest %d (dist: %.2f) - Outline OFF", i, dist))
                                SetEntityDrawOutline(prop, false)
                                highlightedProps[i] = nil
                            end
                        end
                    end
                end
                Wait(500)
            
            elseif currentLevel > 4 then
                -- PLAYER HAS COMPLETED LEVEL 4
                if not gotToken then
                    gotToken = true
                    DebugPrint("LEVEL 4 DEBUG: Token acquired (Level "..currentLevel.."), keeping oxygen until surface.")
                end

                if IsPedSwimmingUnderWater(ped) then
                    SetEnableScuba(ped, true)
                    SetPedMaxTimeUnderwater(ped, 2000.0)
                    Wait(500)
                else
                    DebugPrint("LEVEL 4 DEBUG: Player surfaced/finished, terminating Level 4 logic.")
                    disableDiveGear()
                    
                    -- Explicitly clear outlines that might be stuck on before exiting
                    for k, prop in pairs(level4Props) do
                        if DoesEntityExist(prop) then
                            SetEntityDrawOutline(prop, false)
                        end
                    end
                    highlightedProps = {}
                    
                    -- Explicitly clear debug blips if they exist
                    for k, blip in pairs(level4Blips) do
                        if DoesBlipExist(blip) then RemoveBlip(blip) end
                    end
                    level4Blips = {}
                    
                    break
                end
            else
                -- PLAYER IS NOT YET AT LEVEL 4 (e.g. still at Level 1-3)
                -- Just wait for them to progress
                Wait(2000)
            end
        end

        -- Final Cleanup
        disableDiveGear()
    end)
end)

-- ============================================================
-- CLEANUP
-- ============================================================
RegisterNetEvent("ng_event:client:RemoveZones", function()
    Level4Active = false
    disableDiveGear()

    for i, prop in pairs(level4Props) do
        if prop and DoesEntityExist(prop) then
            SetEntityDrawOutline(prop, false)
            exports.ox_target:removeLocalEntity(prop)
            DeleteObject(prop)
        end
    end
    level4Props = {}

    for i, blip in pairs(level4Blips) do
        if blip then RemoveBlip(blip) end
    end
    level4Blips = {}
end)

-- ============================================================
-- BLIP & WAYPOINT (shown after Level 3 loot)
-- ============================================================
local level4Blip = nil
local level4RadiusBlip = nil

RegisterNetEvent("ng_event:client:ShowLevel4Blip", function()
    if not InEvent then return end
    if level4Blip then RemoveBlip(level4Blip) end
    if level4RadiusBlip then RemoveBlip(level4RadiusBlip) end

    -- Calculate center point from all chest locations
    local chests = Config.Levels[4].chestLocations
    local cx, cy, cz = 0, 0, 0
    for _, c in ipairs(chests) do
        cx = cx + c.x
        cy = cy + c.y
        cz = cz + c.z
    end
    cx, cy, cz = cx / #chests, cy / #chests, cz / #chests

    -- Calculate radius (max distance from center to any chest + padding)
    local maxDist = 0
    for _, c in ipairs(chests) do
        local d = #(vector3(cx, cy, cz) - c)
        if d > maxDist then maxDist = d end
    end
    local radius = maxDist + 10.0

    -- Radius blip (circle on map)
    level4RadiusBlip = AddBlipForRadius(cx, cy, cz, radius)
    SetBlipColour(level4RadiusBlip, 3)
    SetBlipAlpha(level4RadiusBlip, 128)

    -- Center point blip with waypoint
    level4Blip = AddBlipForCoord(cx, cy, cz)
    SetBlipSprite(level4Blip, 439)
    SetBlipColour(level4Blip, 3)
    SetBlipScale(level4Blip, 1.0)
    SetBlipAsShortRange(level4Blip, false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Event: Underwater Trial")
    EndTextCommandSetBlipName(level4Blip)
    SetBlipRoute(level4Blip, true)

    TriggerEvent("ng_event:client:ShowNotification", {title = "Event", description = "Search for the correct chest in the marked area!", type = "inform"})
end)

RegisterNetEvent("ng_event:client:HideLevel4Blip", function()
    if level4Blip then RemoveBlip(level4Blip) level4Blip = nil end
    if level4RadiusBlip then RemoveBlip(level4RadiusBlip) level4RadiusBlip = nil end
end)
