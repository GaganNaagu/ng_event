-- target/ox_target/client.lua
-- Wrapper for ox_target (CLIENT)

Target = {}

function Target.AddZone(data)
    return exports.ox_target:addSphereZone(data)
end

function Target.RemoveZone(id)
    exports.ox_target:removeZone(id)
end

function Target.AddEntity(ent, options)
    return exports.ox_target:addLocalEntity(ent, options)
end

function Target.RemoveEntity(ent)
    exports.ox_target:removeLocalEntity(ent)
end
