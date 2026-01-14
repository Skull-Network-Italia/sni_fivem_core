fx_version 'adamant'

game 'gta5'
author 'Skull Network Italia'
description 'A beautiful and simple Persistent Notification system for ESX.'
version '1.0.0'
lua53 'yes'

client_scripts { 'TextUI.lua' }
shared_script '@es_extended/imports.lua'
ui_page 'nui/index.html'

files {
    'nui/index.html',
    'nui/js/*.js',
    'nui/css/*.css'
}
