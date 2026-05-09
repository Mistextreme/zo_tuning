fx_version "bodacious"
game "gta5"
lua54 "yes"

author "ZO Tuning"
description "ZO Tuning System for ESX-Legacy"
version "2.0.0"

ui_page "nui/index.html"

shared_scripts {
    "@es_extended/imports.lua",
    "cfg/lang.lua",
    "cfg/config.lua",
}

client_scripts {
    "cfg/functions_client.lua",
    "script/client/antilag.lua",
    "script/client/utils.lua",
    "script/client/sync.lua",
    "script/client/client.lua",
}

server_scripts {
    "@oxmysql/lib/MySQL.lua",
    "cfg/functions_server.lua",
    "script/server/server.lua",
    "script/server/opServer.lua",
}

files {
    "nui/*",
    "nui/assets/imgs/*",

    "dlczosounds_sounds.dat54.rel",
    "dlc_zosounds/zosounds.awc",
}

data_file "AUDIO_WAVEPACK" "dlc_zosounds"
data_file "AUDIO_SOUNDDATA" "dlczosounds_sounds.dat"