fx_version 'adamant'

game 'gta5'
description 'Saves/loads character appearances for ESX Legacy.'
version '1.0.0'
lua53 'yes'

client_scripts {
	'@es_extended/locale.lua',
	'locales/*.lua',
	'config.lua',
	'client/main.lua'
}
