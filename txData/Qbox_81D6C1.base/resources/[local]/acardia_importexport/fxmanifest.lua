fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'acardia_importexport'
author 'Acardia'
description 'Job Acardia Export - import/export societe'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/fr.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/society.lua',
    'server/stash.lua',
    'server/garage.lua',
    'server/boss.lua',
    'server/main.lua',
}

client_scripts {
    'client/main.lua',
    'client/garage.lua',
    'client/tablet.lua',
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'oxmysql',
    'qbx_core',
}