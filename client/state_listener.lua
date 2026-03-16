-- client/state_listener.lua
-- Production-ready StateBag listener for ng_event

local previousLevel = 0

AddStateBagChangeHandler('eventData', nil, function(bagName, key, value)
    -- bagName format for players: "player:123"
    local playerNetId = tonumber((bagName:gsub('player:', '')))
    
    -- Check if the change belongs to the LOCAL player
    if playerNetId == GetPlayerServerId(PlayerId()) then
        if value then
            local newLevel = value.level
            
            -- Level 2 Advanced Medical Control
            if newLevel == 2 and previousLevel ~= 2 then
                -- exports.qbx_medical:SetAdvancedMedicalDisabled(true)
                DebugPrint("Advanced Medical DISABLED for Level 2")
            elseif newLevel ~= 2 and previousLevel == 2 then
                -- exports.qbx_medical:SetAdvancedMedicalDisabled(false)
                DebugPrint("Advanced Medical ENABLED (Exited Level 2)")
            end
            
            previousLevel = newLevel

            -- Update local state
            LocalEventState.level = value.level
            LocalEventState.tokens = value.tokens
            LocalEventState.arenaKills = value.arenaKills
            LocalEventState.finished = value.finished
            
            DebugPrint("LocalEventState updated | Level: " .. tostring(LocalEventState.level))
            
            -- Trigger UI Refresh (defined in client/ui.lua)
            if RefreshUI then
                RefreshUI()
            end
        else
            -- Cleanup Advanced Medical on reset
            if previousLevel == 2 then
                -- exports.qbx_medical:SetAdvancedMedicalDisabled(false)
                DebugPrint("Advanced Medical ENABLED (Event Ended/Left)")
            end
            previousLevel = 0

            -- Reset local state if bag is cleared
            LocalEventState = {
                level = 0,
                tokens = {},
                arenaKills = 0,
                finished = false
            }
            if RefreshUI then RefreshUI() end
            DebugPrint("LocalEventState reset (Bag Cleared)")
        end
    end
end)
