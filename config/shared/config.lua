-- config/shared/config.lua
-- Global settings, bucket configuration, and finale logic.

Config = Config or {}

Config.Framework = "qbox" -- 'qbox' or 'qbcore'
Config.EmoteSystem = "scully_emotemenu" -- "rpemotes-reborn", "scully_emotemenu"
Config.MainBucket = 100
Config.PersonalBucketStart = 5000
Config.MaxWinners = 3
Config.UseEventID = false 
Config.TeleportOnEventEnd = true
Config.TeleportOnEventEndCoords = vec4(-1845.03, -888.66, 0.78, 125.11)

Config.Admins = {
    "license:cfdbadb7a85f5336adbd44da4ba010b2071d4db1", -- Naagu
    "license:b415a202986a437907f327cff2cea1c0a9c9c99a", -- Ramu
}

Config.HUD = {
    Position = 'bottom-center' 
}

Config.VehicleRestrictedZones = {
    {
        coords = vector3(-1111.97, 4923.99, 218.43),
        radius = 120.0,
        carTeleportCoords = vector3(-1062.21, 5037.04, 177.90), 
        activeLevels = false
    }
}

Config.EventVehicles = {
    initialVehicle = "sultan",
    finalVehicle = "tunak",
    stagingCoords = vector4(1700.02, 3251.02, 40.35, 285.63),
    SpawnPoints = {
        vector4(1702.67, 3264.49, 41.15, 101.61),
        vector4(1704.43, 3256.71, 41.01, 104.68),
        vector4(1707.07, 3246.89, 41.01, 117.77)
    }
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

Config.Predators = {
    Model = "a_c_mtlion",
    Difficulty = {
        hard = {
            health = 800,        
            speedScale = 1.3,    
            attackDistance = 35.0,
            sprintDistance = 25.0
        }
    }
}

-- Cinematic Podium
Config.Podium = {
    Duration = 15000, 
    Prop = {
        model = `xs_prop_arena_podium_02a`,
        coords = vec4(-1803.63, -839.63, 6.28, 118.21), 
    },
    Phase2Duration = false, 
    MusicURL = "https://www.youtube.com/watch?v=iqLN1abVEOM&list=RDiqLN1abVEOM&start_radio=1", 
    LoopMusic = false, 
    StartCamera = {
        coords = vector3(-1814.17, -865.72, 9.93), 
        rot = vector3(-16.02, -0.00, -23.84)
    },
    EndCamera = {
        coords = vector3(-1807.78, -840.41, 7.95),
        rot = vector3(-8.26, -0.00, -85.51)
    },
    WinnerCoords = {
        vector4(-1803.63, -839.63, 6.28, 118.21),
        vector4(-1803.63, -839.63, 6.28, 118.21),
        vector4(-1803.63, -839.63, 6.28, 118.21)  
    },
    ParticipantCoords = { 
        CrowdStart = vector4(-1807.63, -843.63, 6.28, 118.21), 
        ItemsPerRow = 5,
        RowSpacing = 1.5,
        ColSpacing = 1.5
    },
    Phase1WinnerAnimations = {
        [1] = "champagnespray",        
        [2] = "dancesilly9",     
        [3] = "dancesilly9",    
    },
    Phase1CrowdAnimation = "clap", 
    Phase2Enabled = true,
    Phase2Camera = {
        coords = vector3(-1810.0, -841.0, 8.5),
        rot = vector3(-10.0, 0.0, -90.0)
    },
    Phase2DanceAnimations = {
        "dance", "dance2", "dance3", "dance4", "dance5", 
        "dance6", "dance7", "dance8", "dance9"
    }
}

Config.Debug = false
