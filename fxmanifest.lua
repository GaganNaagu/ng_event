fx_version 'cerulean'
game 'gta5'

description 'Extreme Multi-Level Event for QBox (Modular)'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config/shared/config.lua',
    'config/shared/levels.lua',
    'core/shared/compatibility.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    
    'framework/qbox/server.lua',

    'core/server/state_manager.lua',
    'core/server/transition_manager.lua',
    'core/server/player_manager.lua',
    'core/server/level_manager.lua',
    'core/server/event_manager.lua',

    'modules/**/server.lua',
    'levels/**/server.lua'
}

client_scripts {
    'framework/qbox/client.lua',
    'target/ox_target/client.lua',

    'core/client/level_manager.lua',

    'modules/**/client.lua',
    'modules/**/nui.lua',
    'levels/**/client.lua'
}

ui_page 'ui/dist/index.html'

files {
    'ui/dist/**/*'
}

dependencies {
    'qbx_core',
    'ox_lib',
    'ox_target'
}
