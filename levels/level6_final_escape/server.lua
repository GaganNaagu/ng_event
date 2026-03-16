-- levels/level6_final_escape/server.lua
-- Server logic for Final Escape

local Level6 = {}

function Level6.SetupPlayer(src)
    TriggerClientEvent("ng_event:client:ShowLevel6Blip", src)
end

function Level6.PlayerDied(src)
    local data = PlayerManager.GetPlayer(src)
    if not data or data.confirmedLevel ~= 6 then return end

    local ped = GetPlayerPed(src)
    local cfg = Config.Levels[5] 

    if cfg and cfg.exitCoords then
        Framework.RevivePlayer(src)
        SetEntityCoords(ped, cfg.exitCoords.x, cfg.exitCoords.y, cfg.exitCoords.z, false, false, false, false)
        SetEntityHeading(ped, cfg.exitCoords.w)
    end
end

function Level6.Cleanup()
    -- Nothing specific to clean up on the server for level 6
end

LevelManager.RegisterLevel(6, Level6)

RegisterNetEvent("ng_event:server:ReachFinish", function()
    local src = source
    local data = PlayerManager.GetPlayer(src)
    
    if data and data.confirmedLevel == 6 then
        TriggerEvent("ng_event:server:PlayerFinished", src) 
    end
end)
