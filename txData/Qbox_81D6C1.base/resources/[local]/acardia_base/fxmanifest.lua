fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'acardia_base'
author 'Acardia RP V2'
description 'Minimap carree + HUD stats Acardia'
version '1.2.0'

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

client_scripts {
    'client/radar.lua',
    'client/wanted.lua',
    'client/minimap.lua',
    'client/hud.lua',
    'client/death.lua',
}
