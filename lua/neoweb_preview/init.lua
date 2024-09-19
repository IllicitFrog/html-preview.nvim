local server = require("neoweb_preview.server")
local config = require("neoweb_preview.config")

local M = {}

M.instances = {}

M.setup = function(user_config)
	local settings = config.validate(user_config)
  local count = 0

	vim.api.nvim_create_user_command("NeowebPreviewStart", function()
		local cwd = vim.fn.getcwd()
		if not M.instances[cwd] then
			M.instances[cwd] = server:new(cwd, settings.port + count)
      count = count + 1
		end
		if not M.instances[cwd]:isRunning() then
			M.instances[cwd]:start(settings.ip, settings.port, cwd)
		end
		--logic for starting from random buffer <---------------
		local file_name = vim.api.nvim_buf_get_name(0):gsub(cwd, "")
		vim.fn.jobstart(settings.browser .. " http://" .. settings.ip .. ":" .. M.instances[cwd].port .. file_name)
	end, {})

	vim.api.nvim_create_user_command("NeowebPreviewStop", function()
		local cwd = vim.fn.getcwd()
		if M.instances[cwd] then
			M.instances[cwd]:stop()
			M.instances[cwd] = nil
		end
	end, {})
end

M.websocket = {
	send = function(type, data)
		server.websocket.send(type, data)
	end,
}

return M
