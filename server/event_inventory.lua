-- ============================================================
-- EVENT INVENTORY SYSTEM
-- Handles saving, wiping, restoring, and giving custom loadouts.
-- Uses ox_inventory exports for QBox compatibility.
-- ============================================================

local INVENTORY_DIR = "data/event_inventories/"

-- Ensure the directory exists (create it via system command later or let FiveM handle it if possible, 
-- but we will just write to the root of the resource if subfolder fails, or create it)
-- To be safe, we'll prefix it if needed.
local function GetInventoryFilePath(citizenid)
    return INVENTORY_DIR .. citizenid .. ".json"
end

-- Start up check for directory
Citizen.CreateThread(function()
    local testPath = INVENTORY_DIR .. "test.json"
    SaveResourceFile(GetCurrentResourceName(), testPath, "{}", -1)
    Wait(100)
    local testRead = LoadResourceFile(GetCurrentResourceName(), testPath)
    if not testRead then
        DebugPrint("^1[EVENT INVENTORY] ERROR: Could not write to " .. INVENTORY_DIR .. "^7")
        DebugPrint("^1[EVENT INVENTORY] Make sure the 'data/event_inventories' folder exists in the resource!^7")
    end
end)

local function GetPlayerCitizenId(src)
    local Player = exports.qbx_core:GetPlayer(src)
    if Player then
        return Player.PlayerData.citizenid
    end
    return nil
end

function SavePlayerInventory(src)
    local cid = GetPlayerCitizenId(src)
    if not cid then return false end

    -- Get entire inventory via ox_inventory
    local inventory = exports.ox_inventory:GetInventory(src)
    if not inventory then return false end

    -- Extract just the items array
    local items = inventory.items or {}

    -- Save to JSON
    local data = {
        citizenid = cid,
        items = items
    }
    
    local jsonStr = json.encode(data, {indent = true})
    local filePath = GetInventoryFilePath(cid)
    
    -- BACKUP LOGIC: If a file already exists, don't just overwrite it. 
    -- Move it to a backup so we don't lose previous unrestored items.
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

function ClearPlayerInventory(src)
    -- ox_inventory 'ClearInventory' export completely wipes it
    exports.ox_inventory:ClearInventory(src)
    DebugPrint("Cleared inventory for player " .. src)
end

function RestorePlayerInventory(src)
    local cid = GetPlayerCitizenId(src)
    if not cid then return false end

    local filePath = GetInventoryFilePath(cid)
    local jsonStr = LoadResourceFile(GetCurrentResourceName(), filePath)
    
    if not jsonStr or jsonStr == "" then
        -- Try backup if main is missing
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

    -- 1. Wipe current event inventory (ensure it's clean before restoring)
    ClearPlayerInventory(src)

    -- 2. Add all items back
    local restoreCount = 0
    for _, item in pairs(data.items) do
        if item.name then
            exports.ox_inventory:AddItem(src, item.name, item.count or item.amount or 1, item.metadata, item.slot)
            restoreCount = restoreCount + 1
        end
    end

    DebugPrint("Restored " .. restoreCount .. " items for " .. cid)

    -- 3. Delete the backup file ONLY if we actually processed it
    -- Overwrite with empty first to be sure
    SaveResourceFile(GetCurrentResourceName(), filePath, "", -1)
    
    -- Attempt OS remove (resource must have access, usually standard for local files)
    local fullPath = GetResourcePath(GetCurrentResourceName()) .. "/" .. filePath
    os.remove(fullPath)

    return true
end

function GiveLevelLoadout(src, level)
    local cfg = Config.Levels[level]
    if not cfg or not cfg.loadout then return end

    local loadout = cfg.loadout

    -- Give Weapons with Ammo included in metadata
    if loadout.weapons then
        for _, wep in ipairs(loadout.weapons) do
            exports.ox_inventory:AddItem(src, wep.name, 1, {ammo = wep.ammo or 0})
        end
    end

    -- Give Items
    if loadout.items then
        for _, item in ipairs(loadout.items) do
            exports.ox_inventory:AddItem(src, item.name, item.amount or 1)
        end
    end

    DebugPrint("Given Level " .. level .. " loadout to player " .. src)
end

function HandleKillReward(src, level)
    local cfg = Config.Levels[level]
    if not cfg or not cfg.loadout or type(cfg.loadout.killRewards) ~= 'table' then return end

    local rewards = cfg.loadout.killRewards
    
    for _, reward in ipairs(rewards) do
        if reward.name and reward.amount then
            exports.ox_inventory:AddItem(src, reward.name, reward.amount)
            DebugPrint("Rewarded " .. reward.amount .. "x " .. reward.name .. " to player " .. src)
        end
    end
end
