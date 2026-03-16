-- framework/qbox/client.lua
-- Abstraction layer for QBox framework (CLIENT)

Framework = {}

function Framework.IsDead()
    return exports.qbx_medical:IsDead()
end

function Framework.IsLaststand()
    return exports.qbx_medical:IsLaststand()
end

function Framework.KillPlayer()
    exports.qbx_medical:KillPlayer()
end
