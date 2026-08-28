fx_version 'cerulean'
game 'gta5'

description 'qbx_scoreboard'
repository 'https://github.com/Qbox-project/qbx_scoreboard'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

client_script 'client/*.lua'
server_script 'server/*.lua'

ui_page 'html/ui.html'

files {
    'html/*',
    'config/client.lua',
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'
