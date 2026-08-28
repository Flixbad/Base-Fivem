fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'acardia_bank'
author 'Acardia RP V2'
description 'Banque Acardia - comptes, cartes, tablette, ATM'
version '1.0.0'

ui_page 'html/index.html'

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

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

server_exports {
    'verifyCardPayment',
    'debitPrimaryAccount',
}

dependencies {
    'ox_lib',
    'ox_target',
    'ox_inventory',
    'oxmysql',
    'qbx_core',
}
