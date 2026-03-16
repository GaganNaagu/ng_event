-- config/shared/levels.lua
-- Defines the ordered sequence and specific properties of each level.

Config = Config or {}

-- This allows dynamic, non-hardcoded flow through the event
Config.LevelOrder = {1, 2, 3, 4, 5, 6}

Config.Levels = {
    [1] = {
        name = "Trial of Shock",
        panels = { 
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
        hangarCoords = vector3(-1396.570312, -3268.592285, 14.410460) 
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
        redZoneRadius = 100.0, 
        maxPredators = 15,     
        waveSpawnDelay = 10000,
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
        spawnCoords = vector4(-959.97, 6211.68, 3.56, 340.99) 
    },
    [5] = {
        name = "The Last Stand",
        description = "Eliminate the targets!",
        killsRequired = 15,
        maxNpcs = 20,
        npcRespawnCooldown = 5000, 
        npcHash = `s_m_y_blackops_03`,
        npcWeapon = "WEAPON_SMG",
        entryCoords = vector4(2475.255615, -384.147095, 94.500282, 270.67),
        arenaCoords = vector4(2154.87, 2921.0, -81.26, 270.67),
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
        finishEntityType = 'ped', 
        finishEntityModel = `a_m_m_skater_01`, 
        finishMarkers = {
            vector4(4961.97, -4824.59, 4.89, 4.22),
        },
        blipCoords = vector4(1450.45, -2589.63, 48.64, 160.58),
        winnerBucket = 1
    }
}
