-- core/shared/compatibility.lua
-- Temporary aliases to keep legacy code running during migration.

if Config == nil then Config = {} end
if not Config.Framework then Config.Framework = 'qbox' end

DebugPrint = DebugPrint or function(...)
    if Config.Debug then
        print("[ng_event] ", ...)
    end
end
