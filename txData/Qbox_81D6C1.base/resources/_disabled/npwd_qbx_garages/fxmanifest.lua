fx_version 'cerulean'
game 'gta5'

description 'Qbox Garages app for NPWD'
version '1.1.0'
repository 'https://github.com/Qbox-Project/npwd_qbx_garages'

ox_lib 'locale'
shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua'
}

client_script 'client/client.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
}

ui_page 'web/dist/index.html'

files {
    'locales/*.json',
    'web/dist/index.html',
    'web/dist/**/*',
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'
provide 'npwd_qb_garage'