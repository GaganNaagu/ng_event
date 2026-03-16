-- modules/teleport/client.lua
-- Provides seamless screen wipe transitions.

TeleportModule = {}

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
