fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'acardia_clothing'
author 'Acardia RP V2'
description 'Boutiques vetements Acardia - NUI premium'
version '1.0.0'

ui_page 'html/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/camera.lua',
    'client/thumbnails.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/thumbnails/**/*',
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'illenium-appearance',
    'qbx_core',
    'screencapture',
    'uz_AutoShot',
}
