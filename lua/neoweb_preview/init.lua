local pegasus = require("pegasus")
local files = require("plugins.static")
local config = require("config")
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
					location = vim.fn.getcwd(),
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

	local file_name = vim.api.nvim_buf_get_name(0):gsub(cwd, "")
	vim.fn.jobstart(config.config.browser .. " http://0.0.0.0:" .. config.config.port .. "/" .. file_name)
end

M.stop = function()
	M.kill = true
  M.server = nil
end

return M
