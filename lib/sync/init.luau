local client = require("@client/")
local server = require("@server/")
local patch = require("@patch/")

return table.freeze {
	client = client,
	is_none = patch.is_none,
	server = server.server,
	step_server = server.step,
}
