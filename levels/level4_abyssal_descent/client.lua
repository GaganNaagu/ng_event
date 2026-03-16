-- levels/level4_abyssal_descent/client.lua
-- Client logic for Abyssal Descent (Underwater Chest Search)

local Level4 = {}

local level4Props = {}    
local level4Blips = {}    
local Level4Active = false
local highlightedProps = {}

local diveGear = {
    mask = 0,
    tank = 0,
    equipped = false
}

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

    local ped = PlayerPedId()
    diveGear.tank = CreateObject(tankModel, 1.0, 1.0, 1.0, true, true, false) 
    SetEntityAsMissionEntity(diveGear.tank, true, true)
    SetNetworkIdCanMigrate(ObjToNet(diveGear.tank), false)
    SetEntityCollision(diveGear.tank, false, false)
    local bone1 = GetPedBoneIndex(ped, 24818)
    AttachEntityToEntity(diveGear.tank, ped, bone1, -0.25, -0.25, 0.0, 180.0, 90.0, 0.0, true, true, false, false, 2, true)

    diveGear.mask = CreateObject(maskModel, 1.0, 1.0, 1.0, true, true, false) 
    SetEntityAsMissionEntity(diveGear.mask, true, true)
    SetNetworkIdCanMigrate(ObjToNet(diveGear.mask), false)
    SetEntityCollision(diveGear.mask, false, false)
    local bone2 = GetPedBoneIndex(ped, 12844)
    AttachEntityToEntity(diveGear.mask, ped, bone2, 0.0, 0.0, 0.0, 180.0, 90.0, 0.0, true, true, false, false, 2, true)

    SetModelAsNoLongerNeeded(maskModel)
    SetModelAsNoLongerNeeded(tankModel)
end

local function enableDiveGear()
    if diveGear.equipped then return end
    deleteDiveGear()
    attachDiveGear()
    SetEnableScuba(PlayerPedId(), true)
    SetPedMaxTimeUnderwater(PlayerPedId(), 2000.0)
    diveGear.equipped = true
end

local function disableDiveGear()
    if not diveGear.equipped then return end
    SetEnableScuba(PlayerPedId(), false)
    SetPedMaxTimeUnderwater(PlayerPedId(), 15.0)
    SetPedDiesInWater(PlayerPedId(), true)
    deleteDiveGear()
    diveGear.equipped = false
end

function Level4.SetupZones()
    local cfg = Config.Levels[4]
    local propHash = cfg.treasurePropHash
    lib.requestModel(propHash)
    Level4Active = true

    for _, p in pairs(level4Props) do if DoesEntityExist(p) then DeleteObject(p) end end
    level4Props = {}

    for i, coords in ipairs(cfg.chestLocations) do
        local prop = CreateObject(propHash, coords.x, coords.y, coords.z, false, false, false) 
        SetEntityAsMissionEntity(prop, true, true)
        SetEntityHeading(prop, math.random(0, 360) + 0.0)
        PlaceObjectOnGroundProperly(prop)
        FreezeEntityPosition(prop, true)

        local chestIndex = i
        Target.AddLocalEntity(prop, {
            {
                name = 'ng_event_chest4_' .. i,
                icon = 'fas fa-box-open',
                label = 'Search Chest',
                distance = 4,
                onSelect = function()
                    TriggerServerEvent("ng_event:server:LootChest4", chestIndex)
                end,
                canInteract = function()
                    return LocalEventState and LocalEventState.level == 4 and not LocalEventState.tokens[4]
                end
            }
        })

        level4Props[i] = prop

        if Config.Debug then
            local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
            SetBlipSprite(blip, 1)
            SetBlipColour(blip, 5)  
            SetBlipScale(blip, 0.6)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString("Chest #" .. i)
            EndTextCommandSetBlipName(blip)
            level4Blips[i] = blip
        end
    end

    SetModelAsNoLongerNeeded(propHash)

    Citizen.CreateThread(function()
        local highlightRange = 15.0
        local gotToken = false

        while Level4Active do
            local ped = PlayerPedId()
            if not LocalEventState then
                Wait(2000)
                goto continue
            end
            
            local currentLevel = LocalEventState.level

            if currentLevel == 4 then
                local inWater = IsEntityInWater(ped) or IsPedSwimming(ped) or IsPedSwimmingUnderWater(ped)
                if inWater then
                    if not diveGear.equipped then enableDiveGear() end
                    SetEnableScuba(ped, true)
                    SetPedMaxTimeUnderwater(ped, 2000.0)
                end

                local playerCoords = GetEntityCoords(ped)

                for i, prop in pairs(level4Props) do
                    if prop and DoesEntityExist(prop) then
                        local dist = #(playerCoords - GetEntityCoords(prop))
                        if dist <= highlightRange then
                            if not highlightedProps[i] then
                                SetEntityDrawOutline(prop, true)
                                SetEntityDrawOutlineColor(255, 215, 0, 255)
                                highlightedProps[i] = true
                            end
                        else
                            if highlightedProps[i] then
                                SetEntityDrawOutline(prop, false)
                                highlightedProps[i] = nil
                            end
                        end
                    end
                end
                Wait(500)
            
            elseif currentLevel > 4 then
                if not gotToken then gotToken = true end

                if IsPedSwimmingUnderWater(ped) then
                    SetEnableScuba(ped, true)
                    SetPedMaxTimeUnderwater(ped, 2000.0)
                    Wait(500)
                else
                    disableDiveGear()
                    
                    for k, prop in pairs(level4Props) do
                        if DoesEntityExist(prop) then
                            SetEntityDrawOutline(prop, false)
                        end
                    end
                    highlightedProps = {}
                    
                    for k, blip in pairs(level4Blips) do
                        if DoesBlipExist(blip) then RemoveBlip(blip) end
                    end
                    level4Blips = {}
                    
                    break
                end
            else
                Wait(2000)
            end
            
            ::continue::
        end

        disableDiveGear()
    end)
end

function Level4.Cleanup()
    Level4Active = false
    disableDiveGear()

    for i, prop in pairs(level4Props) do
        if prop and DoesEntityExist(prop) then
            SetEntityDrawOutline(prop, false)
            Target.RemoveLocalEntity(prop)
            DeleteObject(prop)
        end
    end
    level4Props = {}

    for i, blip in pairs(level4Blips) do
        if blip then RemoveBlip(blip) end
    end
    level4Blips = {}
    
    TriggerEvent("ng_event:client:HideLevel4Blip")
end

LevelManager.RegisterLevel(4, Level4)

local level4Blip = nil
local level4RadiusBlip = nil

RegisterNetEvent("ng_event:client:ShowLevel4Blip", function()
    if level4Blip then RemoveBlip(level4Blip) end
    if level4RadiusBlip then RemoveBlip(level4RadiusBlip) end

    local chests = Config.Levels[4].chestLocations
    local cx, cy, cz = 0, 0, 0
    for _, c in ipairs(chests) do
        cx = cx + c.x
        cy = cy + c.y
        cz = cz + c.z
    end
    cx, cy, cz = cx / #chests, cy / #chests, cz / #chests

    local maxDist = 0
    for _, c in ipairs(chests) do
        local d = #(vector3(cx, cy, cz) - c)
        if d > maxDist then maxDist = d end
    end
    local radius = maxDist + 10.0

    level4RadiusBlip = AddBlipForRadius(cx, cy, cz, radius)
    SetBlipColour(level4RadiusBlip, 3)
    SetBlipAlpha(level4RadiusBlip, 128)

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
