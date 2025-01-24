local client = require("@client/")
local server = require("@server/")

return table.freeze {
    client = client,
    server = server.server,
    step_server = server.step,
}