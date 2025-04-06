fx_version 'cerulean'
game 'gta5'
lua54 'yes' 

author 'Flash_Dev'
description 'Sistema di auto gratuita per nuovi giocatori con salvataggio nel garage'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua', -- Assicurati che sia installato
    'server/logs.lua',
    'server/main.lua'
}

dependencies {
    'ox_lib',
    'oxmysql'
}
