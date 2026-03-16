-- Final Escape Logic
-- The core of this is already handled in main.lua inside the PlayerFinished event.

RegisterNetEvent("ng_event:server:ReachFinish", function()
    -- Forwarding it to the main player finished handler for centralized winners processing
    TriggerEvent("ng_event:server:PlayerFinished")
end)
