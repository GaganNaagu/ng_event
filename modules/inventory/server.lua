-- modules/inventory/server.lua
-- Handles saving, wiping, restoring, and giving custom loadouts.

InventoryManager = {}

local INVENTORY_DIR = "data/event_inventories/"

Citizen.CreateThread(function()
    local testPath = INVENTORY_DIR .. "test.json"
    SaveResourceFile(GetCurrentResourceName(), testPath, "{}", -1)
    Wait(100)
    local testRead = LoadResourceFile(GetCurrentResourceName(), testPath)
    if not testRead then
        DebugPrint("^1[EVENT INVENTORY] ERROR: Could not write to " .. INVENTORY_DIR .. "^7")
    end
end)

local function GetInventoryFilePath(citizenid)
    return INVENTORY_DIR .. citizenid .. ".json"
end

function InventoryManager.SavePlayerInventory(src)
    local cid = Framework.GetPlayerCitizenId(src)
    if not cid then return false end

    local inventory = Framework.GetInventory(src)
    if not inventory then return false end

    local items = inventory.items or {}

    local data = {
        citizenid = cid,
        items = items
    }
    
    local jsonStr = json.encode(data, {indent = true})
    local filePath = GetInventoryFilePath(cid)
    
    local existing = LoadResourceFile(GetCurrentResourceName(), filePath)
    if existing and existing ~= "" then
        local backupPath = INVENTORY_DIR .. cid .. "_backup.json"
        SaveResourceFile(GetCurrentResourceName(), backupPath, existing, -1)
        DebugPrint("Existing inventory found for " .. cid .. ", moved to backup.")
    end

    local success = SaveResourceFile(GetCurrentResourceName(), filePath, jsonStr, -1)
    
    if success then
        DebugPrint("Saved inventory for " .. cid)
        return true
    else
        DebugPrint("^1[EVENT INVENTORY] Failed to save inventory to " .. filePath .. "^7")
        return false
    end
end

function InventoryManager.ClearPlayerInventory(src)
    Framework.ClearInventory(src)
    DebugPrint("Cleared inventory for player " .. src)
end

function InventoryManager.RestorePlayerInventory(src)
    local cid = Framework.GetPlayerCitizenId(src)
    if not cid then return false end

    local filePath = GetInventoryFilePath(cid)
    local jsonStr = LoadResourceFile(GetCurrentResourceName(), filePath)
    
    if not jsonStr or jsonStr == "" then
        local backupPath = INVENTORY_DIR .. cid .. "_backup.json"
        jsonStr = LoadResourceFile(GetCurrentResourceName(), backupPath)
        if jsonStr and jsonStr ~= "" then
            filePath = backupPath
            DebugPrint("Restoring from backup for " .. cid)
        else
            return false 
        end
    end

    local data = json.decode(jsonStr)
    if not data or not data.items then
        DebugPrint("^1[EVENT INVENTORY] Corrupt or invalid JSON backup for " .. cid .. "^7")
        return false
    end

    InventoryManager.ClearPlayerInventory(src)

    local restoreCount = 0
    for _, item in pairs(data.items) do
        if item.name then
            Framework.AddItem(src, item.name, item.count or item.amount or 1, item.metadata, item.slot)
            restoreCount = restoreCount + 1
        end
    end

    DebugPrint("Restored " .. restoreCount .. " items for " .. cid)

    SaveResourceFile(GetCurrentResourceName(), filePath, "", -1)
    
    local fullPath = GetResourcePath(GetCurrentResourceName()) .. "/" .. filePath
    os.remove(fullPath)

    return true
end

function InventoryManager.GiveLevelLoadout(src, level)
    local cfg = Config.Levels[level]
    if not cfg or not cfg.loadout then return end

    local loadout = cfg.loadout

    if loadout.weapons then
        for _, wep in ipairs(loadout.weapons) do
            Framework.AddItem(src, wep.name, 1, {ammo = wep.ammo or 0})
        end
    end

    if loadout.items then
        for _, item in ipairs(loadout.items) do
            Framework.AddItem(src, item.name, item.amount or 1)
        end
    end

    DebugPrint("Given Level " .. level .. " loadout to player " .. src)
end

function InventoryManager.HandleKillReward(src, level)
    local cfg = Config.Levels[level]
    if not cfg or not cfg.loadout or type(cfg.loadout.killRewards) ~= 'table' then return end

    local rewards = cfg.loadout.killRewards
    
    for _, reward in ipairs(rewards) do
        if reward.name and reward.amount then
            Framework.AddItem(src, reward.name, reward.amount)
            DebugPrint("Rewarded " .. reward.amount .. "x " .. reward.name .. " to player " .. src)
        end
    end
end
