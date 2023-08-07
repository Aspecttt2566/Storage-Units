fx_version "cerulean"
author "Aspect"
games {"gta5"}

client_scripts {
    '@amity_framework/client/lib/cl_rpc.lua',
    'server/*.lua',
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    '@amity_framework/server/lib/sv_rpc.lua',
    'server/*.lua',
}

shared_scripts {
    'config.lua'
}