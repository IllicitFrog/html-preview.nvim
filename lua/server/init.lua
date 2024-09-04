local pegasus = require("pegasus")
local files = require("server.plugins.static")
local config = require("server.config")
local async = require("plenary.async")

local M = {}

M.server = nil
M.kill = false

M.setup = function(user_config)
	config.validate(user_config)
end

M.run = function()
	if M.server ~= nil then
		M.server = pegasus:new({
			port = config.config.port,
			plugins = {
				files:new({
					location = "/opt/sam",
				}),
			},
		})
		async.run(M.server:start(function(request, response)
			print("Do Server Stuff")
      if M.kill then
        return true
      end
		end))
	end
end

M.stop = function()
  M.kill = true
end

return M
