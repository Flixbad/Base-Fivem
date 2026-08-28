fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'acardia_autotransport'
author 'Acardia'
description 'Job Auto Import Export - transport vehicules et motos'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/fr.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/jobaccess.lua',
    'server/society.lua',
    'server/stash.lua',
    'server/garage.lua',
    'server/stats.lua',
    'server/missions.lua',
    'server/orders.lua',
    'server/thefts.lua',
    'server/boss.lua',
    'server/main.lua',
}

client_scripts {
    '@qbx_core/modules/playerdata.lua',
    'client/jobaccess.lua',
    'client/main.lua',
    'client/garage.lua',
    'client/missions.lua',
    'client/tablet.lua',
    'client/police.lua',
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
