-- modules/finale/client.lua
-- Client logic for grid calculation, cinematic camera, and podium animations.

GridCalculator = {}
CameraSystem = {}
PodiumManager = {}

-- GRID
function GridCalculator.CalculatePosition(participant, index)
    local ped = PlayerPedId()
    
    if participant.place and Config.Podium.WinnerCoords and Config.Podium.WinnerCoords[participant.place] then
        return Config.Podium.WinnerCoords[participant.place]
    end
    
    local cfg = Config.Podium.ParticipantCoords
    if not cfg then return GetEntityCoords(ped) end 
    
    local crowdStart = cfg.CrowdStart
    local ySpacing = cfg.RowSpacing or 1.5
    local xSpacing = cfg.ColSpacing or 1.5
    local itemsPerRow = cfg.ItemsPerRow or 5
    
    local row = math.floor((index - 1) / itemsPerRow)
    local col = (index - 1) % itemsPerRow
    
    local centerOffset = ((itemsPerRow - 1) / 2) * xSpacing
    
    local finalX = crowdStart.x + ((col * xSpacing) - centerOffset)
    local finalY = crowdStart.y + (row * ySpacing)
    local finalZ = crowdStart.z
    
    return vector4(finalX, finalY, finalZ, crowdStart.w or 0.0)
end

-- CAMERA
local activeCam = nil
local activeCam2 = nil

function CameraSystem.StartInterpolation(camStartCfg, camEndCfg, duration)
    if activeCam then DestroyCam(activeCam, false) end
    if activeCam2 then DestroyCam(activeCam2, false) end

    activeCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(activeCam, camStartCfg.xyz)
    SetCamRot(activeCam, camStartCfg.rotX, camStartCfg.rotY, camStartCfg.rotZ, 2)
    SetCamFov(activeCam, camStartCfg.fov or 60.0)

    activeCam2 = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(activeCam2, camEndCfg.xyz)
    SetCamRot(activeCam2, camEndCfg.rotX, camEndCfg.rotY, camEndCfg.rotZ, 2)
    SetCamFov(activeCam2, camEndCfg.fov or 60.0)

    RenderScriptCams(true, false, 0, true, false)
    SetCamActiveWithInterp(activeCam2, activeCam, duration, 1, 1)
end

function CameraSystem.FlashToTarget(camEndCfg)
    if activeCam then DestroyCam(activeCam, false) end
    if activeCam2 then DestroyCam(activeCam2, false) end

    activeCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(activeCam, camEndCfg.xyz)
    SetCamRot(activeCam, camEndCfg.rotX, camEndCfg.rotY, camEndCfg.rotZ, 2)
    SetCamFov(activeCam, camEndCfg.fov or 60.0)

    RenderScriptCams(true, false, 0, true, false)
end

function CameraSystem.StopCamera()
    RenderScriptCams(false, true, 1000, true, false)
    if activeCam then DestroyCam(activeCam, false) activeCam = nil end
    if activeCam2 then DestroyCam(activeCam2, false) activeCam2 = nil end
end

-- PODIUM
local podiumActive = false

function PodiumManager.IsPodiumActive()
    return podiumActive
end

RegisterNetEvent("ng_event:client:ShowPodium", function(participants)
    podiumActive = true
    local ped = PlayerPedId()

    DoScreenFadeOut(1000)
    Wait(1500)

    local myIndex = 1
    local myData = nil
    for i, p in ipairs(participants) do
        if p.source == GetPlayerServerId(PlayerId()) then
            myIndex = i
            myData = p
            break
        end
    end

    local pos = GridCalculator.CalculatePosition(myData, myIndex)
    SetEntityCoords(ped, pos.xyz, false, false, false, false)
    SetEntityHeading(ped, pos.w)

    Wait(1000)

    if myData.finished and myData.place and myData.place <= 3 then
        local anim = Config.Podium.Phase1WinnerAnimations[myData.place]
        if anim then exports['shared']:PlayEmote(anim) end
    else
        if Config.Podium.Phase1CrowdAnimation then
            exports['shared']:PlayEmote(Config.Podium.Phase1CrowdAnimation)
        end
    end

    local p1Duration = Config.Podium.Duration or 15000
    CameraSystem.StartInterpolation(Config.Podium.StartCamera, Config.Podium.EndCamera, p1Duration)

    DoScreenFadeIn(2000)

    SetTimeout(p1Duration, function()
        local p2Enabled = Config.Podium.Phase2Enabled
        if p2Enabled then
            local p2Duration = Config.Podium.Phase2Duration or 10000
            TriggerServerEvent("ng_event:server:SetPodiumDuration", p2Duration)

            DoScreenFadeOut(500)
            Wait(600)

            CameraSystem.FlashToTarget(Config.Podium.Phase2Camera)

            local dances = Config.Podium.Phase2DanceAnimations
            if dances and #dances > 0 then
                local randomDance = dances[math.random(1, #dances)]
                exports['shared']:PlayEmote(randomDance)
            end

            DoScreenFadeIn(1000)

            SetTimeout(p2Duration, function()
                PodiumManager.EndPodium()
            end)
        else
            PodiumManager.EndPodium()
        end
    end)
end)

function PodiumManager.EndPodium()
    DoScreenFadeOut(1000)
    Wait(1500)
    
    CameraSystem.StopCamera()
    exports['shared']:CancelEmote()
    podiumActive = false

    TriggerServerEvent("ng_event:server:PodiumFinished")
end
