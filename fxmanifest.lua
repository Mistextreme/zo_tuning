


fx_version "bodacious"
game "gta5"
lua54 "yes"

author "ZO Tuning"
description "ZO Tuning System for vRP"
version "1.0.0"

ui_page "nui/index.html"

client_scripts {
	"@vrp/lib/utils.lua",

	"cfg/*",

	"script/client/antilag.lua",
	"script/client/utils.lua",
	"script/client/sync.lua",
	"script/client/client.lua",
}

server_scripts {
	"@vrp/lib/utils.lua",

	"cfg/*",
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

