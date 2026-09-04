local podiumCams = {} -- Store cameras for cleanup
local inPodiumSequence = false


RegisterNetEvent("ng_event:client:ShowPodium", function(participants)
    if not Config.Podium then return end
    
    inPodiumSequence = true
    local ped = PlayerPedId()
    local myServerId = GetPlayerServerId(PlayerId())
    local duration = Config.Podium.Duration or 15000

    -- Preparation: Hide the teleport and bucket switch
    DoScreenFadeOut(500)
    Wait(1000)

    -- Phase 1: Winners Podium
    print("Podium Phase 1: Winners")
    local myPlace = 0
    local myIndexInParticipants = 0
    local top3 = {}
    
    for i, p in ipairs(participants) do
        if p.source == myServerId then 
            myIndexInParticipants = i
            if p.place and p.place <= 3 then myPlace = p.place end
        end
        if p.place and p.place <= 3 then
            table.insert(top3, p)
        end
    end

    -- Hide standard HUD elements
    if GetResourceState("17mov_Hud") == "started" then
        exports["17mov_Hud"]:ToggleDisplay(false)
        exports["17mov_Hud"]:HideRadar(true)
    end
    DisplayHud(false)

    -- Freeze and prepare player
    ClearPedTasksImmediately(ped)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)

    -- Phase 1 Animations (Using rpemotes-reborn)
    local p1Winners = Config.Podium.Phase1WinnerAnimations
    local p1Crowd = Config.Podium.Phase1CrowdAnimation

    if myPlace > 0 and myPlace <= 3 and p1Winners[myPlace] then
        local coords = Config.Podium.WinnerCoords[myPlace]
        SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, false)
        SetEntityHeading(ped, coords.w or 0.0)
        exports["rpemotes-reborn"]:EmoteCommandStart(p1Winners[myPlace])
    else
        local crowdLocs = Config.Podium.ParticipantCoords
        if crowdLocs and #crowdLocs > 0 then
            local crowdIndex = math.max(1, myIndexInParticipants - 3)
            local locIndex = ((crowdIndex - 1) % #crowdLocs) + 1
            local loc = crowdLocs[locIndex]
            
            SetEntityCoords(ped, loc.x, loc.y, loc.z, false, false, false, false)
            SetEntityHeading(ped, loc.w or 0.0)
            if p1Crowd then
                exports["rpemotes-reborn"]:EmoteCommandStart(p1Crowd)
            else
                TaskStartScenarioInPlace(ped, "WORLD_HUMAN_CHEERING", 0, true)
            end
        end
    end

    DoScreenFadeIn(1000)

    -- Camera for Phase 1
    local startCam = Config.Podium.StartCamera
    local endCam = Config.Podium.EndCamera
    local cam1 = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cam1, startCam.coords.x, startCam.coords.y, startCam.coords.z)
    SetCamRot(cam1, startCam.rot.x, startCam.rot.y, startCam.rot.z, 2)
    local cam2 = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(cam2, endCam.coords.x, endCam.coords.y, endCam.coords.z)
    SetCamRot(cam2, endCam.rot.x, endCam.rot.y, endCam.rot.z, 2)

    podiumCams = {cam1, cam2}
    SetCamActive(cam1, true)
    RenderScriptCams(true, false, 0, true, true)
    SetCamActiveWithInterp(cam2, cam1, duration, 1, 1)

    -- Wait for Phase 1 to finish
    Wait(duration)

    -- CLEAR Phase 1 Emotes/Tasks
    exports["rpemotes-reborn"]:EmoteCancel()
    ClearPedTasksImmediately(ped)

    -- Phase 2: Finale Grid
    print("Podium Phase 2: Grid Finale Started")
    if not participants or #participants == 0 then
        print("Podium Error: No participants received!")
        DoScreenFadeIn(500)
        inPodiumSequence = false
        return
    end

    DoScreenFadeOut(1000)
    Wait(1000)

    -- Start Music Early during fade-out
    print("Podium: Starting Music UI")
    SendNUIMessage({
        action = "showCinematic",
        url = Config.Podium.MusicURL,
        volume = 0.5,
        loop = Config.Podium.LoopMusic or false
    })
    SetNuiFocus(true, true)

    -- Cleanup Phase 1 cams
    for _, cam in ipairs(podiumCams) do if DoesCamExist(cam) then DestroyCam(cam, false) end end
    podiumCams = {}

    -- Figure out specialized grid position
    local myIndexInParticipants = 0
    for i, p in ipairs(participants) do if p.source == myServerId then myIndexInParticipants = i break end end
    
    local myPlace = participants[myIndexInParticipants].place or 999
    local gridPos = {row = 0, col = 0}
    local maxPerRow = Config.Podium.Grid.MaxPerRow or 15
    local winnerCols = { [1] = 8, [2] = 9, [3] = 7 } -- 1st at 8, 2nd at 9, 3rd at 7
    
    if myPlace >= 1 and myPlace <= 3 then
        gridPos.row = 0
        gridPos.col = winnerCols[myPlace] - 1 -- 0-indexed for calculation
    else
        -- Fill others: Skip cols 7,8,9 in row 1
        local othersIndex = 0
        for i, p in ipairs(participants) do
            if not p.place or p.place > 3 then
                othersIndex = othersIndex + 1
                if p.source == myServerId then break end
            end
        end
        
        -- Calculate position skipping winner slots in row 0
        local currentIdx = 0
        local found = false
        for r = 0, 10 do -- iterate rows
            for c = 0, (maxPerRow - 1) do -- iterate cols
                local isWinnerSlot = (r == 0 and (c == 6 or c == 7 or c == 8)) -- cols 7,8,9
                if not isWinnerSlot then
                    currentIdx = currentIdx + 1
                    if currentIdx == othersIndex then
                        gridPos.row = r
                        gridPos.col = c
                        found = true
                        break
                    end
                end
            end
            if found then break end
        end
    end
    print("Podium: Assigned to Grid Row " .. gridPos.row .. " Col " .. (gridPos.col + 1))

    local gridBase = Config.TeleportOnEventEndCoords
    local spacingX = Config.Podium.Grid.SpacingX or 1.3
    local spacingY = Config.Podium.Grid.SpacingY or 1.5
    local currentRowWidth = (maxPerRow - 1) * spacingX
    local offsetX = (gridPos.col * spacingX) - (currentRowWidth / 2)
    local offsetY = gridPos.row * -spacingY
    local headingRad = math.rad(gridBase.w or 0.0)
    local cosH, sinH = math.cos(headingRad), math.sin(headingRad)
    local worldX = gridBase.x + (offsetX * cosH - offsetY * sinH)
    local worldY = gridBase.y + (offsetX * sinH + offsetY * cosH)
    
    -- Improved Grounding with safety and collision request
    print("Podium: Teleporting to Grid Position")
    RequestCollisionAtCoord(worldX, worldY, gridBase.z)
    SetEntityCoords(ped, worldX, worldY, gridBase.z + 1.0, false, false, false, false)
    
    local success, err = pcall(function()
        local timeout = 0
        local foundGround, groundZ = false, 0.0
        while not foundGround and timeout < 30 do
            Wait(100)
            foundGround, groundZ = GetGroundZFor_3dCoord(worldX, worldY, gridBase.z + 2.0, false)
            timeout = timeout + 1
        end
        if foundGround then
            SetEntityCoords(ped, worldX, worldY, groundZ, false, false, false, false)
        else
            PlaceObjectOnGroundProperly(ped)
        end
    end)
    if not success then print("Podium Grounding Error: " .. tostring(err)) end
    SetEntityHeading(ped, gridBase.w or 0.0)
    FreezeEntityPosition(ped, true) -- Prevent unwanted movement immediately

    -- Thread to disable controls while in the sequence
    Citizen.CreateThread(function()
        while inPodiumSequence do
            -- Disable Movement
            DisableControlAction(0, 30, true) -- move lr
            DisableControlAction(0, 31, true) -- move ud
            DisableControlAction(0, 32, true) -- move f
            DisableControlAction(0, 33, true) -- move b
            -- Disable Combat
            DisablePlayerFiring(PlayerId(), true)
            DisableControlAction(0, 24, true) -- attack
            DisableControlAction(0, 25, true) -- aim
            DisableControlAction(0, 140, true) -- melee
            DisableControlAction(0, 141, true) -- melee
            DisableControlAction(0, 142, true) -- melee
            -- Disable Misc
            DisableControlAction(0, 22, true) -- jump
            DisableControlAction(0, 23, true) -- enter vehicle
            DisableControlAction(0, 37, true) -- weapon wheel
            DisableControlAction(0, 44, true) -- cover
            DisableControlAction(0, 75, true) -- exit vehicle
            Wait(0)
        end
    end)

    -- Phase 2 Animations (Switch to Random Dance Pool for everyone)
    local p2Pool = Config.Podium.Phase2AnimationPool
    if p2Pool and #p2Pool > 0 then
        local emoteName = p2Pool[math.random(1, #p2Pool)]
        exports["rpemotes-reborn"]:EmoteCommandStart(emoteName)
    end

    print("Podium: Starting Dynamic Camera Sequence")
    -- Dynamic Cam Angles Pool
    local totalRows = math.ceil(#participants / maxPerRow)
    local gridDepth = (totalRows - 1) * spacingY
    local center = gridBase.xyz
    
    local h = gridBase.w or 0.0
    local rad = math.rad(h)
    local forward = vector3(-math.sin(rad), math.cos(rad), 0.0)
    local right = vector3(math.cos(rad), math.sin(rad), 0.0)
    local up = vector3(0.0, 0.0, 1.0)
    
    local camAngles = {
        -- Angle 1: High wide sweep from front-right (Extra Wide)
        {
            pos = center + (forward * 18.0) + (right * 18.0) + (up * 10.0),
            look = center + (up * 1.5),
            speed = 8000
        },
        -- Angle 2: Wide low-glide from front-left (Faster)
        {
            pos = center + (forward * 12.0) - (right * 15.0) + (up * 2.2),
            look = center + (up * 1.5),
            speed = 4000
        },
        -- Angle 3: Direct zoom (Medium Focus)
        {
            pos = center + (forward * 15.0) + (up * 3.5),
            look = center + (up * 1.5),
            speed = 3500,
            fov = 50.0 -- Wider FOV to see more players
        },
        -- Angle 4: Moving crane high-to-low across front
        {
            pos = center + (forward * 15.0) - (right * 8.0) + (up * 12.0),
            look = center + (up * 0.5),
            speed = 6000
        },
        -- Angle 5: Dynamic circling front-right (Wider)
        {
            pos = center + (forward * 10.0) + (right * 15.0) + (up * 4.0),
            look = center - (right * 2.0) + (up * 1.5),
            speed = 5000
        }
    }

    -- Determine sequence duration
    local p2Duration = Config.Podium.Phase2Duration
    if not p2Duration then
        print("Podium: Waiting for UI to detect music duration...")
        local timeout = 0
        while not detectedPhase2Duration and timeout < 100 do -- 10s timeout
            Wait(100)
            timeout = timeout + 1
        end
        p2Duration = detectedPhase2Duration or 30000 -- Fallback to 30s
    end
    print("Podium: Phase 2 Duration set to " .. tostring(p2Duration) .. "ms")
    
    -- Sync server
    TriggerServerEvent("ng_event:server:SetPodiumDuration", p2Duration)
    
    DoScreenFadeIn(1000)
    SetCinematicModeActive(true)

    local currentCamIdx = 1
    local activeCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local setCamData = function(cam, data)
        SetCamCoord(cam, data.pos.x, data.pos.y, data.pos.z)
        PointCamAtCoord(cam, data.look.x, data.look.y, data.look.z)
        if data.fov then SetCamFov(cam, data.fov) else SetCamFov(cam, 60.0) end
    end

    setCamData(activeCam, camAngles[1])
    SetCamActive(activeCam, true)
    RenderScriptCams(true, false, 0, true, true)
    table.insert(podiumCams, activeCam)

    local startTime = GetGameTimer()
    while (GetGameTimer() - startTime) < p2Duration and inPodiumSequence do
        local nextIdx = (currentCamIdx % #camAngles) + 1
        local camData = camAngles[nextIdx]
        
        local nextCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        setCamData(nextCam, camData)
        table.insert(podiumCams, nextCam)
        
        local interpTime = math.min(camData.speed, p2Duration - (GetGameTimer() - startTime))
        if interpTime < 500 then break end -- Too short to interp

        SetCamActiveWithInterp(nextCam, activeCam, interpTime, 1, 1)
        activeCam = nextCam
        currentCamIdx = nextIdx
        Wait(interpTime)
    end

    -- Tell server sequence is finished so it can clean up immediately
    print("Podium: Sequence Finished, notifying server for immediate cleanup.")
    TriggerServerEvent("ng_event:server:PodiumFinished")
end)

RegisterNUICallback("onDurationDetected", function(data, cb)
    detectedPhase2Duration = tonumber(data.duration)
    print("Podium: UI Detected Duration: " .. tostring(detectedPhase2Duration) .. "ms")
    cb("ok")
end)

RegisterNetEvent("ng_event:client:EventEnded", function()
    -- Original cleanup handled elsewhere, just add podium cleanup here
    if inPodiumSequence then
        inPodiumSequence = false
        local ped = PlayerPedId()
        
        -- Ensure screen is not black
        DoScreenFadeIn(500)

        -- Restore HUD/Radar
        if GetResourceState("17mov_Hud") == "started" then
            exports["17mov_Hud"]:ToggleDisplay(true)
            exports["17mov_Hud"]:HideRadar(false)
        end
        DisplayHud(true)
        -- Restore Focus
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "hideCinematic" })
        SetCinematicModeActive(false)

        -- Start easing out camera back to player
        RenderScriptCams(false, true, 2500, true, false)
        
        -- Non-blocking delay to clean up cameras after ease-out
        Citizen.CreateThread(function()
            Wait(2500)
            for _, cam in ipairs(podiumCams) do
                if DoesCamExist(cam) then
                    DestroyCam(cam, false)
                end
            end
            podiumCams = {}
            
            -- Reset player state after ease-out
            ClearPedTasksImmediately(ped)
            exports["rpemotes-reborn"]:EmoteCancel()
            SetEntityInvincible(ped, false)
            FreezeEntityPosition(ped, false)
            
            -- Ensure controls are re-enabled (though loop handles it)
            EnableAllControlActions(0)
        end)
    end
end)

-- Debug Command to find camera coordinates
local debugCam = nil

RegisterCommand("podiumcam", function(source, args)
    local isAdmin = lib.callback.await('ng_event:server:IsAdmin')
    if not isAdmin then
        TriggerEvent('ox_lib:notify', {title = 'Error', description = 'Unauthorized', type = 'error'})
        return
    end

    -- If no args, toggle a simple free cam for positioning
    if #args == 0 then
        if debugCam then
            RenderScriptCams(false, true, 500, true, false)
            DestroyCam(debugCam, false)
            debugCam = nil
            lib.notify({title = 'Debug Cam', description = 'Free-cam disabled.', type = 'inform'})
        else
            local coords = GetGameplayCamCoord()
            local rot = GetGameplayCamRot(2)
            debugCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
            SetCamCoord(debugCam, coords.x, coords.y, coords.z)
            SetCamRot(debugCam, rot.x, rot.y, rot.z, 2)
            SetCamActive(debugCam, true)
            RenderScriptCams(true, true, 500, true, false)
            lib.notify({title = 'Debug Cam', description = 'Free-cam enabled. WASD: Move, MOUSE: Rotate, SPACE/LCTRL: Up/Down.', type = 'inform'})
            
            Citizen.CreateThread(function()
                while debugCam do
                    Wait(0)
                    -- Rotation
                    local mouseX = GetDisabledControlNormal(1, 1) * -10.0
                    local mouseY = GetDisabledControlNormal(1, 2) * -10.0
                    local camRot = GetCamRot(debugCam, 2)
                    
                    local newPitch = camRot.x + mouseY
                    if newPitch > 89.0 then newPitch = 89.0 elseif newPitch < -89.0 then newPitch = -89.0 end
                    
                    SetCamRot(debugCam, newPitch, 0.0, camRot.z + mouseX, 2)

                    -- Movement
                    local speed = IsControlPressed(0, 21) and 2.0 or 0.5 -- Shift for boost
                    local pCoords = GetCamCoord(debugCam)
                    
                    -- Calculate forward and right vectors based on camera rotation
                    local pitch = math.rad(GetCamRot(debugCam, 2).x)
                    local yaw = math.rad(GetCamRot(debugCam, 2).z)
                    
                    local forward = vector3(
                        -math.sin(yaw) * math.abs(math.cos(pitch)),
                        math.cos(yaw) * math.abs(math.cos(pitch)),
                        math.sin(pitch)
                    )
                    
                    local right = vector3(
                        math.cos(yaw),
                        math.sin(yaw),
                        0.0
                    )

                    if IsControlPressed(0, 32) then -- W
                        pCoords = pCoords + (forward * speed)
                    end
                    if IsControlPressed(0, 33) then -- S
                        pCoords = pCoords - (forward * speed)
                    end
                    if IsControlPressed(0, 34) then -- A
                        pCoords = pCoords - (right * speed)
                    end
                    if IsControlPressed(0, 35) then -- D
                        pCoords = pCoords + (right * speed)
                    end
                    if IsControlPressed(0, 22) then -- Space
                        pCoords = pCoords + vector3(0.0, 0.0, speed)
                    end
                    if IsControlPressed(0, 36) then -- LCtrl
                        pCoords = pCoords - vector3(0.0, 0.0, speed)
                    end

                    SetCamCoord(debugCam, pCoords.x, pCoords.y, pCoords.z)
                    
                    -- Disable controls to prevent character movement/conflict
                    DisableControlAction(0, 30, true) -- Move LR
                    DisableControlAction(0, 31, true) -- Move UD
                    DisableControlAction(0, 32, true) -- Move F
                    DisableControlAction(0, 33, true) -- Move B
                    DisableControlAction(0, 1, true)  -- Look LR
                    DisableControlAction(0, 2, true)  -- Look UD
                    DisableControlAction(0, 24, true) -- Attack
                    DisableControlAction(0, 25, true) -- Aim
                end
            end)
        end
        return
    end

    local label = args[1] or "Camera"
    local coords, rot
    
    if debugCam then
        coords = GetCamCoord(debugCam)
        rot = GetCamRot(debugCam, 2)
    else
        coords = GetGameplayCamCoord()
        rot = GetGameplayCamRot(2)
    end

    local output = string.format("coords = vector3(%.2f, %.2f, %.2f), rot = vector3(%.2f, %.2f, %.2f)", 
        coords.x, coords.y, coords.z, rot.x, rot.y, rot.z)
    
    print("^2[PODIUM DEBUG] ^7" .. label .. ": " .. output)
    lib.notify({
        title = 'Podium Cam Debug',
        description = label .. ' settings printed to F8 console!',
        type = 'success'
    })
end)
