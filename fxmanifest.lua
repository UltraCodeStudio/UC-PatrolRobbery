fx_version 'cerulean'
game 'gta5'

description 'Patrol Robbery Script for FiveM'
version '1.2'
author 'Ultra Code'

shared_scripts {
    'config.lua',
    '@ox_lib/init.lua',
}

client_scripts {
    'client/**.lua',
}

server_scripts {
    'server/**.lua'
}

dependencies {
    'ox_lib',
}

lua54 'yes'
use_experimental_fxv2_oal 'yes'


