local server = require("neoweb_preview.server")

local M = {}

M.instances = {}
M.stylebuf = {}
M.page = ""

M.setup = function()
	local browser = nil

	OS = vim.loop.os_uname().sysname
	if OS == "Darwin" then
		browser = "open"
	elseif OS == "Windows_NT" then
		browser = "start"
	else
		browser = "xdg-open"
	end

	vim.api.nvim_create_user_command("NeowebPreviewStart", function()
		local ext = vim.fn.expand("%:e")
		if ext ~= "html" and ext ~= "htm" then
			print("File is not html")
		else
			local bufnr = vim.api.nvim_get_current_buf()
			local cwd = vim.fn.getcwd()
			local css_files = {}

			if not M.instances[cwd] then
				M.instances[cwd] = server:new()
			end
			if not M.instances[cwd]:running() then
				M.instances[cwd]:start(cwd)
			end

			--logic for starting from random buffer <---------------
			if M.instances[cwd].websock_client == nil then
				vim.fn.jobstart(browser .. " http://127.0.0.1:" .. M.instances[cwd]:getPort() .. "/neoweb.html")
			end

			do
				M.page = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))

				for lines in M.page:gmatch("%a+%.css") do
					table.insert(css_files, lines)
				end

				local timer = vim.uv.new_timer()
				timer:start(500, 5, function()
					if M.instances[cwd].websock_client then
						M.instances[cwd]:ws_send("UPDA" .. M.page)
						timer:stop()
					end
				end)
			end

			local send = function()
				local sendpage = M.page
				for key, styledata in pairs(M.stylebuf) do
					sendpage = string.gsub(sendpage, "<link(.-)" .. key .. "(.-)>", styledata)
				end
				M.instances[cwd]:ws_send("UPDA" .. sendpage)
			end

			vim.api.nvim_create_augroup("Neoweb-" .. cwd, { clear = true })

			vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
				group = "Neoweb-" .. cwd,
				buffer = bufnr,
				callback = function()
					M.page = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
					send()
				end,
			})

			vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
				group = "Neoweb-" .. cwd,
				pattern = css_files,
				callback = function()
					M.stylebuf[vim.fn.expand("%:t")] = "<style>"
						.. table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), 0, -1, false))
						.. "</style>"
					send()
				end,
			})

			vim.api.nvim_create_autocmd({ "BufDelete", "BufUnload", "BufWipeout", "BufWrite" }, {
				group = "Neoweb-" .. cwd,
				pattern = css_files,
				callback = function()
					M.stylebuf[vim.fn.expand("%:t")] = nil
				end,
			})

			vim.api.nvim_create_autocmd({ "BufDelete", "BufUnload", "BufWipeout", "BufUnload" }, {
				group = "Neoweb-" .. cwd,
				buffer = bufnr,
				callback = function()
					M.instances[cwd]:ws_send("STOP")
				end,
			})
		end
	end, {})

	-- Manually Stop Server
	vim.api.nvim_create_user_command("NeowebPreviewStop", function()
		local cwd = vim.fn.getcwd()
		if M.instances[cwd] then
			M.instances[cwd]:ws_send("STOP")
		else
			print("No server running")
		end
	end, {})
end

return M
