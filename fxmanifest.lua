fx_version "bodacious"
game "gta5"
lua54 "yes"

author "ZO Tuning"
description "ZO Tuning System for ESX Legacy"
version "1.0.0"

shared_scripts {
    "@es_extended/imports.lua",
    "@ox_lib/init.lua",
    "config.lua",
    "lang.lua"
}

client_scripts {
    "functions.lua",
    "utils.lua",
    "sync.lua",
    "antilag.lua",
    "client.lua"
}

server_scripts {
    "functions.lua",
    "utils.lua",
    "server.lua",
    "opServer.lua"
}

ui_page "nui/index.html"

files {
    "nui/index.html",
    "nui/**/*",
    "3rdpartylicenses.txt",
    "dlczosounds_sounds.dat54.rel",
    "dlc_zosounds/zosounds.awc"
}

data_file "AUDIO_WAVEPACK" "dlc_zosounds"
data_file "AUDIO_SOUNDDATA" "dlczosounds_sounds.dat"