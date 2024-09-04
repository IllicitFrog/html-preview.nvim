local addCmds = function()
	local async = require("plenary.async")
  local server = require("server")
	local browser = nil
	local cwd = nil
	local name = nil
	local port = 8090
	local webserver = nil

	local start = function()
		if webserver == nil then
      webserver = server:new({ port = port })
			async.run(webserver:run())
		else
			if cwd ~= vim.fn.getcwd() then
				cwd = vim.fn.getcwd()
				webserver:setDocRoot(cwd)
			end

			if name ~= vim.api.nvim_buf_get_name(0):gsub(cwd, "") then
				name = vim.api.nvim_buf_get_name(0):gsub(cwd, "")
				webserver:setIndex(name)
			end
		end

		if not browser then
			browser = "xdg-open"
		end

		vim.fn.jobstart(browser .. " http://0.0.0.0:" .. port)
	end

	local stop = function()
	end

	vim.api.nvim_buf_create_user_command(0, "NeowebPreviewStart", function()
		start()
		vim.api.nvim_create_autocmd("BufLeave", {
			pattern = { "*.html" },
			callback = function()
				if webserver then
					stop()
				end
			end,
		})
	end, {})

	vim.api.nvim_buf_create_user_command(0, "NeowebPreviewStop", function()
		stop()
	end, {})
end

return addCmds
