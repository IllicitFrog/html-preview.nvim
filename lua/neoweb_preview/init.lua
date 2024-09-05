local pegasus = require("pegasus")
local files = require("neoweb_preview.plugins.static")
local config = require("neoweb_preview.config")
local async = require("plenary.async")

local M = {}

M.server = nil
M.kill = false
M.config = {}

M.setup = function(user_config)
	M.config = config.validate(user_config)
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

  local cwd = vim.fn.getcwd()
	local file_name = vim.api.nvim_buf_get_name(0):gsub(cwd, "")
	vim.fn.jobstart(M.config.browser .. " http://0.0.0.0:" .. M.config.port .. "/" .. file_name)
end

M.stop = function()
	M.kill = true
  M.server = nil
end

return M
