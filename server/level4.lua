-- ============================================================
-- LEVEL 4 — UNDERWATER CHEST SHUFFLE
-- Server tracks which chest holds the token. Reshuffles on find.
-- ============================================================

local L4 = {
    activeChest = 0 -- Index of the chest that holds token 4
}

-- Shuffle: pick a random chest index
local function ShuffleChest()
    local count = #Config.Levels[4].chestLocations
    local newIndex = math.random(1, count)
    -- Avoid same chest twice in a row
    if newIndex == L4.activeChest and count > 1 then
        newIndex = (newIndex % count) + 1
    end
    L4.activeChest = newIndex
    DebugPrint("^5[L4-CHEST] Token shuffled to chest " .. L4.activeChest .. " / " .. count .. "^7")
end

-- On Level 4 unlock, shuffle the first time
AddEventHandler('ng_event:server:UnlockLevel', function(level)
    if level == 4 then
        ShuffleChest()
    end
end)

-- Player attempts to loot a chest
RegisterNetEvent("ng_event:server:LootChest4", function(chestIndex)
    local src = source
    if not ValidatePlayer(src) then return end
    if EventState.players[src].pendingLevel == 4 then
        ConfirmLevelEntry(src)
    end
    
    if EventState.players[src].confirmedLevel ~= 4 then return end
    if EventState.players[src].tokens[4] then return end -- Already has token

    if type(chestIndex) ~= "number" then return end

    if chestIndex == L4.activeChest then
        -- CORRECT CHEST — grant token
        EventState.players[src].tokens[4] = true
        local safeSpawn = Config.Levels[4].spawnCoords
        UpdateLevel(src, 5, safeSpawn)

        TriggerClientEvent("ng_event:client:ShowNotification", src, {
            title = "Event",
            description = "Correct chest! Token 4 acquired. Follow GPS to Level 5.",
            type = "success"
        })
        TriggerClientEvent("ng_event:client:HideLevel4Blip", src)
        TriggerClientEvent("ng_event:client:ShowLevel5Blip", src)

        DebugPrint("^2[L4-CHEST] Player " .. src .. " found the correct chest (" .. chestIndex .. "). Token granted.^7")

        -- Reshuffle for the next player
        ShuffleChest()
    else
        -- WRONG CHEST
        TriggerClientEvent("ng_event:client:ShowNotification", src, {
            title = "Event",
            description = "Empty chest! The token is hidden elsewhere...",
            type = "error"
        })
        DebugPrint("^3[L4-CHEST] Player " .. src .. " opened chest " .. chestIndex .. " (wrong, active is " .. L4.activeChest .. ")^7")
    end
end)
