fx_version 'adamant'

lua53 'yes'
game 'gta5'
version '1.0.0'
author 'Skull Network Italia'
description 'A beautiful and simple NUI notification system for ESX'

shared_script '@es_extended/imports.lua'

client_scripts { 'Config.lua', 'Notify.lua'}

ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/js/*.js',
    'nui/css/*.css',
}
