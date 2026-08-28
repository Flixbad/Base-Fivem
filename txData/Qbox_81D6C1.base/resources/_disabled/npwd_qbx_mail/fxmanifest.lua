fx_version 'cerulean'
game 'gta5'

description 'Qbox Mail app for NPWD'
version '1.0.0'
repository 'https://github.com/Qbox-project/npwd_qbx_mail'

client_script 'client/client.lua'

shared_script '@ox_lib/init.lua'

server_script {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua',
}

ui_page 'web/dist/index.html'

files {
    'web/dist/**/*',
    'locales/*.json'
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'
provide 'npwd_qb_mail'