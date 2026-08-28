fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'liveafk_admin'
author 'Acardia RP V2'
description 'Tablette administration Acardia RP V2'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
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
    'oxmysql',
    'qbx_core',
}
