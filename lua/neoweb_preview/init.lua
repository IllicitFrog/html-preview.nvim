local config = require("neoweb_preview.config")
local llthreads2 = require("llthreads2")
local task = require("neoweb_preview.task")

local M = {}

llthreads2.set_logger(function(msg) end)
local running = false

M.setup = function(user_config)
	config.validate(user_config)
	vim.api.nvim_create_user_command("NeowebPreviewStart", function()
		require("neoweb_preview").run()
	end, {})

	vim.api.nvim_create_user_command("NeowebPreviewStop", function()
		require("neoweb_preview").stop()
	end, {})
end

M.run = function()
	if not running then
		running = true
		local edit = task:gsub("{{port}}", config.config.port):gsub("{{root}}", '"' .. vim.fn.getcwd() .. '"')
		local thread = llthreads2.new(edit)
		thread:start(true, true)
	end

	local cwd = vim.fn.getcwd()
	local file_name = vim.api.nvim_buf_get_name(0):gsub(cwd, "")
	vim.fn.jobstart(config.config.browser .. " http://0.0.0.0:" .. config.config.port .. "/" .. file_name)
end

return M
