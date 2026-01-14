fx_version 'adamant'

game 'gta5'
author 'Skull Network Italia'
description 'A beautiful and simple NUI progress bar for ESX'
version '1.0.0'
lua53 'yes'

client_scripts { 'Progress.lua' }
shared_script '@es_extended/imports.lua'
ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/js/*.js',
    'nui/css/*.css',
}
