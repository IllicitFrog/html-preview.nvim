local function setup()
	local server = {}
	local browser = nil
	local cwd = nil
	local name = nil
	local port = 8090
	local neoweb = require("libneoweb_preview")
	vim.api.nvim_create_user_command("NeoWebPreview", function(opt_port)
		if cwd ~= vim.fn.getcwd() then
			cwd = vim.fn.getcwd()
			if server then
				server:setDocRoot(cwd)
			end
		end

		if name ~= vim.api.nvim_buf_get_name(0):sub(cwd, "") then
			name = vim.api.nvim_buf_get_name(0):sub(cwd, "")
			if server then
				server:setIndex(name)
			end
		end

		if not server then
			port = opt_port or 8090
			server = neoweb(cwd, port, name)
		end

		if not browser then
			browser = "xdg-open"
		end

		io.popen(browser .. " http://localhost:" .. port, "r")
		vim.notify("Neoweb Preview started", vim.log.levels.INFO)
	end, { nargs = 1 })

	vim.api.nvim_create_user_command(0, "NeoWebMustache", function(json)
		if server then
			if not json then
				json = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_buf_line_count(0), false)
			end
			server:loadMustasche(json)
		end
	end, { nargs = 1 })

	vim.api.nvim_create_user_command(0, "NeoWebPreviewToggleLive", function()
		if server then
			server:liveJS()
		end
	end, { nargs = 0 })

	vim.api.nvim_create_user_command(0, "NeoWebPreviewStop", function()
		if server then
			server:stop()
			return vim.notify("Neoweb preview stopped", vim.loglevels.INFO)
		else
			return vim.notify("No instance of Neo_WebPreview", vim.log.levels.INFO)
		end
	end, { nargs = 0 })
end
