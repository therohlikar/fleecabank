fx_version 'bodacious'
game 'gta5'

export "openBank"

server_export "doesAccountExist"
server_export "getMainAccountByOwner"
server_export "getAccountsByOwner"
server_export "getAccountByNumber"
server_export "isBankAccountOwner"
server_export "create"
server_export "delete"
server_export "checkFunds"
server_export "removeFunds"
server_export "addFunds"
server_export "transferFunds"
server_export "updateAccountData"
server_export "openPaymentMethod"

client_scripts {
	"config.lua",
	"@warmenu/warmenu.lua",
	"client/main.lua"
}

server_scripts {
	'@mysql-async/lib/MySQL.lua',
	"config.lua",
	"server/main.lua"
}

ui_page "html/ui.html"

files {
	"html/*",
	"html/ui.html",
	"html/css/*",
	"html/js/*",
	"html/img/*",
	"html/fonts/*"
}
