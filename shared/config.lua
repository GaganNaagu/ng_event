Config = {}

Config.Core = "qbx_core"
Config.EmoteSystem = "scully_emotemenu" -- "rpemotes-reborn", "scully_emotemenu"
Config.MainBucket = 100
Config.PersonalBucketStart = 5000
Config.MaxWinners = 3
Config.UseEventID = false -- If false, /joinevent doesn't require an ID
Config.TeleportOnEventEnd = true
Config.TeleportOnEventEndCoords = vec4(-1845.03, -888.66, 0.78, 125.11)

Config.Admins = {
    "license:cfdbadb7a85f5336adbd44da4ba010b2071d4db1", -- Naagu
    "license:b415a202986a437907f327cff2cea1c0a9c9c99a", -- Ramu
}

Config.HUD = {
    -- Options: 'top-center', 'top-left', 'top-right', 'bottom-center', 'bottom-left', 'bottom-right', 'center-left', 'center-right'
    Position = 'bottom-center' 
}

Config.VehicleRestrictedZones = {
    {
        coords = vector3(-1111.97, 4923.99, 218.43),
        radius = 120.0,
        carTeleportCoords = vector3(-1062.21, 5037.04, 177.90), -- Near respawn
        activeLevels = false
    }
}

Config.EventVehicles = {
    initialVehicle = "sultan",
    finalVehicle = "tunak",
    stagingCoords = vector4(1700.02, 3251.02, 40.35, 285.63) -- Level 1 start area
}

Config.Audio = {
    Notification = {
        Url = "https://r2.fivemanage.com/e9vwtcVXA2juCcfr9Tr6C/notification.mp3",
        Volume = 0.4
    },
    Kill = {
        Url = "https://r2.fivemanage.com/e9vwtcVXA2juCcfr9Tr6C/kill_effect.mp3",
        Volume = 0.5
    }
}

Config.Levels = {
    [1] = {
        name = "Trial of Shock",
        panels = { -- Example Coordinates, replace with real ones
            vector3(2834.208496, 1550.248169, 25.025684),
            vector3(2840.082275, 1548.677002, 25.025377),
            vector3(2844.210449, 1564.564087, 25.008060),
            vector3(2838.239502, 1566.101318, 25.072763),
            vector3(2851.599365, 1556.376099, 24.995022),
            vector3(2857.546875, 1554.803589, 24.995016),
            vector3(2853.373779, 1538.345337, 24.980684),
            vector3(2847.435059, 1539.925293, 24.981073),
            vector3(2831.046631, 1488.959473, 25.154938),
            vector3(2825.205566, 1490.513184, 25.012070),
            vector3(2811.788574, 1500.886963, 24.996784),
            vector3(2817.750732, 1499.291992, 25.080402),
            vector3(2829.318359, 1506.978027, 25.084751),
            vector3(2835.216309, 1505.418457, 24.872791),
            vector3(2821.926758, 1515.166748, 24.958242),
            vector3(2815.908691, 1516.716187, 25.114975)

        },
        correctPanelsCount = 2,
        spawnLocs = {
            vector4(1702.67, 3264.49, 41.15, 101.61),
            vector4(1704.43, 3256.71, 41.01, 104.68),
            vector4(1707.07, 3246.89, 41.01, 117.77)
        },
        respawnLocs = {
            vector4(2678.53, 1720.01, 24.50, 180.71),
            vector4(2683.16, 1720.73, 24.51, 186.50),
            vector4(2688.39, 1720.86, 24.57, 178.81),
            vector4(2696.99, 1722.06, 24.49, 159.48)
        },
        hangarCoords = vector3(-1396.570312, -3268.592285, 14.410460) -- Airport hangar area
    },
    [2] = {
        name = "The Blood Arena",
        description = "PVP IS ENABLED!",
        killsRequired = 15,
        loadout = {
            weapons = {
                {name = "weapon_heavypistol", ammo = 60}
            },
            items = {
                {name = "bandage", amount = 5}
            },
            killRewards = {
                {name = "ammo-45", amount = 15}
            }
        },
        spawnLocs = {
            vector4(-1296.51, -3035.59, -48.49, 66.33),
            vector4(-1292.07, -3022.72, -48.49, 24.19),
            vector4(-1295.00, -3010.39, -44.09, 31.66),
            vector4(-1294.87, -3028.67, -44.09, 21.19),
            vector4(-1233.35, -3025.32, -48.49, 214.09),
            vector4(-1235.53, -3009.80, -42.89, 158.14),
            vector4(-1235.30, -3003.33, -42.89, 87.27),
            vector4(-1233.35, -2981.89, -41.27, 142.69),
            vector4(-1313.52, -2996.18, -48.49, 318.43)
        }
    },
    [3] = {
        name = "Treasure Hunt",
        description = "Find the Lion's Treasure!",
        treasureBoxCoords = vector3(-1169.940430, 4927.075195, 223.370789),
        treasurePropHash = `treasure`,
        redZoneCenter = vector3(-1111.97, 4923.99, 218.43),
        redZoneRadius = 100.0, -- Radius where zombies are hostile
        maxPredators = 15,      -- Global cap for synchronized lions
        waveSpawnDelay = 10000, -- Cooldown in ms before spawning a new wave of lions
        minigame = {
            difficulty = {'easy', 'medium', 'hard'},
            keys = {'w', 'a', 's', 'd'}
        },
        difficulty = "hard",
        loadout = {
            weapons = {
                {name = "weapon_pumpshotgun", ammo = 60}
            },
            items = {
                {name = "bandage", amount = 5}
            }
        },
        respawnLocs = {
            vector4(-1008.22, 4970.42, 194.18, 137.30),
        },
        predatorSpawnCoords = {
            vector4(-1070.10, 4920.80, 213.04, 204.63),
            vector4(-1060.90, 4899.46, 212.08, 10.79),
            vector4(-1087.85, 4900.28, 214.33, 334.09),
            vector4(-1078.96, 4913.72, 213.81, 182.35),
            vector4(-1085.53, 4922.02, 214.46, 139.96),
            vector4(-1101.26, 4904.59, 216.02, 217.88),
            vector4(-1109.61, 4913.76, 217.10, 327.37),
            vector4(-1098.67, 4928.98, 216.42, 179.22),
            vector4(-1119.67, 4916.42, 218.07, 342.21),
            vector4(-1122.35, 4935.89, 218.89, 188.57),
            vector4(-1051.93, 4924.07, 210.06, 206.37),
            vector4(-1079.10, 4876.86, 216.97, 15.22),
            vector4(-1130.26, 4932.97, 219.63, 144.56),
            vector4(-1141.72, 4917.79, 219.99, 34.08),
            vector4(-1151.92, 4932.24, 221.42, 155.69),
            vector4(-1158.60, 4915.61, 221.24, 335.18),
            vector4(-1176.34, 4920.26, 222.79, 257.60),
            vector4(-1175.36, 4931.27, 223.28, 295.27),
            vector4(-1166.00, 4930.65, 223.36, 192.79),
            vector4(-1168.28, 4923.51, 222.83, 287.19),
        }
    },
    [4] = {
        name = "Abyssal Descent",
        description = "Search the seabed!",
        treasurePropHash = `treasure`,
        chestLocations = {
            vector3(-945.312439, 6619.166504, -31.374226),
            vector3(-985.986633, 6596.853027, -27.458435),
            vector3(-1007.010010, 6572.993164, -7.519017),
            vector3(-954.447144, 6569.436035, -10.308558),
            vector3(-902.018799, 6605.320312, -34.063797)
        },
        spawnCoords = vector4(-959.97, 6211.68, 3.56, 340.99) -- Surface coord before diving
    },
    [5] = {
        name = "The Last Stand",
        description = "Eliminate the targets!",
        killsRequired = 15,
        maxNpcs = 20,
        npcRespawnCooldown = 5000, -- 5 seconds
        npcHash = `s_m_y_blackops_03`,
        npcWeapon = "WEAPON_SMG",
        entryCoords = vector4(2475.255615, -384.147095, 94.500282, 270.67),
        -- Arena coords (where player is teleported inside the personal bucket)
        arenaCoords = vector4(2154.87, 2921.0, -81.26, 270.67),
        -- Where player is put back on failure
        exitCoords = vector4(2547.51, -380.31, 92.52, 348.19),
        loadout = {
            weapons = {
                {name = "weapon_heavypistol", ammo = 120}
            },
            items = {
                {name = "bandage", amount = 10},
                {name = "painkillers", amount = 5},
                {name = "armour", amount = 3}
            },
            killRewards = {
                {name = "ammo-45", amount = 60},
                {name = "bandage", amount = 5},
                {name = "painkillers", amount = 2},
            }
        },
        npcSpawnCoords = {
            vector4(2152.48, 2907.44, -84.80, 70.76),
            vector4(2143.41, 2910.91, -84.80, 183.89),
            vector4(2142.94, 2914.21, -84.80, 359.91),
            vector4(2143.25, 2919.64, -84.80, 183.37),
            vector4(2143.36, 2923.01, -84.80, 354.28)
        }
    },
    [6] = {
        name = "Final Escape",
        description = "Reach the extraction point!",
        finishEntityType = 'ped', -- 'ped' or 'prop'
        finishEntityModel = `a_m_m_skater_01`, 
        finishMarkers = {
            vector4(4961.97, -4824.59, 4.89, 4.22),
        },
        blipCoords = vector4(1450.45, -2589.63, 48.64, 160.58),
        -- If winnerCoords is set, players teleport here upon finishing. If nil, they do not teleport.
        -- winnerCoords = vector4(100.0, 100.0, 100.0, 0.0),
        winnerBucket = 1
    }
}

Config.Predators = {
    Model = "a_c_mtlion",
    Difficulty = {
        hard = {
            health = 800,        -- Significantly increased to prevent one-shotting
            speedScale = 1.3,    -- Faster than human but natural
            attackDistance = 35.0,
            sprintDistance = 25.0
        }
    }
}

-- Cinematic Podium
Config.Podium = {
    Duration = 15000, -- How long Phase 1 (Winner Podium) lasts
    Prop = {
        model = `xs_prop_arena_podium_02a`,
        coords = vec4(-1803.63, -839.63, 6.28, 118.21), -- Example coords, user can adjust
    },
    Phase2Duration = false, -- If false, fetches duration from video. If number, uses that fixed ms.
    MusicURL = "https://www.youtube.com/watch?v=iqLN1abVEOM&list=RDiqLN1abVEOM&start_radio=1", -- Victory Theme
    LoopMusic = false, -- Whether the music should loop
    StartCamera = {
        coords = vector3(-1814.17, -865.72, 9.93), 
        rot = vector3(-16.02, -0.00, -23.84)
    },
    EndCamera = {
        coords = vector3(-1807.78, -840.41, 7.95),
        rot = vector3(-8.26, -0.00, -85.51)
    },
    WinnerCoords = {
        vector4(-1803.63, -839.63, 6.28, 118.21), -- 1st Place
        vector4(-1803.63, -839.63, 6.28, 118.21), -- 2nd Place
        vector4(-1803.63, -839.63, 6.28, 118.21)  -- 3rd Place
    },
    ParticipantCoords = { -- Where the crowd stands
        vector4(-1803.63, -839.63, 6.28, 118.21),
        vector4(-1803.63, -839.63, 6.28, 118.21),
        vector4(-1803.63, -839.63, 6.28, 118.21),
        vector4(-1803.63, -839.63, 6.28, 118.21),
    },
    Grid = {
        MaxPerRow = 15,
        SpacingX = 1.3,
    },
    -- Phase 1: Winners Podium Animations
    Phase1WinnerAnimations = {
        [1] = "champagnespray",        -- 1st Place
        [2] = "dancesilly9",     -- 2nd Place
        [3] = "dancesilly9",    -- 3rd Place
    },
    Phase1CrowdAnimation = "clap", -- Everyone else claps

    -- Phase 2: Cinematic Grid Animations (Random Pool)
    Phase2AnimationPool = {
        "dance", "dance2", "dance3", "dance4", "dance5", 
        "dance6", "dance7", "dance8", "dance9"
    }
}

Config.Debug = false

function DebugPrint(...)
    if Config.Debug then
        local args = {...}
        local msg = ""
        for i, v in ipairs(args) do
            msg = msg .. tostring(v) .. (i < #args and " | " or "")
        end
        print("^3[NG_EVENT DEBUG] ^7" .. msg)
    end
end
