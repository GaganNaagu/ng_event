fx_version 'cerulean'
game 'gta5'

description 'Extreme Multi-Level Event for QBox'
version '1.0.0'

shared_scripts {
    -- '@qbx_core/modules/lib.lua',
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/wrapper.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/bucket_manager.lua',
    'server/event_inventory.lua',
    'server/event_vehicle.lua',
    'server/level_setup.lua',
    'server/state_sync.lua',
    'server/transition_controller.lua',
    'server/ui_handler.lua',
    'server/level1.lua',
    'server/level2.lua',
    'server/level3.lua',
    'server/level4.lua',
    'server/level5.lua',
    'server/level6.lua'
}

ui_page 'ui/dist/index.html'

files {
    'ui/dist/**/*'
}

client_scripts {
    -- '@qbx_core/modules/playerdata.lua',
    'client/main.lua',
    'client/event_vehicle.lua',
    'client/nui.lua',
    'client/state_listener.lua',
    'client/ui.lua',
    'client/vehicle_restrictor.lua',
    'client/zones.lua',
    'client/podium.lua',
    'client/levels/*.lua',
}

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_target'
}
