fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'liveafk_pausemenu'
author 'Acardia RP V2'
description 'Pause menu cinematic Acardia RP V2'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    'server/main.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
}

dependencies {
    'ox_lib',
    'qbx_core',
}
