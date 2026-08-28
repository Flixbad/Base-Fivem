fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'acardia_discord'
author 'Acardia RP V2'
description 'Discord Rich Presence Acardia RP V2'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}

client_scripts {
    'client/main.lua',
}

dependencies {
    'ox_lib',
    'qbx_core',
}
