fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'liveafk_loadingscreen'
author 'Acardia RP V2'
description 'Loading screen cinematic Acardia RP V2'
version '1.0.0'

loadscreen 'html/index.html'
loadscreen_cursor 'yes'
loadscreen_manual_shutdown 'yes'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'assets/banner.png',
    'assets/Arcadia.mp3',
}

client_script 'client.lua'
