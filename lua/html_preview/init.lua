local server = require("html_preview.server")
local vim = vim

local instances = {}
local page = {}
local stylebuf = {}
local scriptbuf = {}

vim.api.nvim_create_user_command("HTPreview", function(opts)
	local browser = ""

	local OS = vim.loop.os_uname().sysname
	if OS == "Darwin" then
		browser = "open"
	elseif OS == "Windows_NT" then
		browser = "start"
	else
		browser = "xdg-open"
	end

	local ext = vim.fn.expand("%:e")
	if ext ~= "html" and ext ~= "htm" then
		print("File is not html")
	else
		local bufnr = vim.api.nvim_get_current_buf()
		local cwd = vim.fn.getcwd()
		local css_files = {}
		local js_files = {}

		stylebuf[cwd] = {}
		scriptbuf[cwd] = {}

		if instances[cwd] then
			if instances[cwd]:running() then
				print("Server already running")
				return
			else
				instances[cwd] = nil
			end
		end
		instances[cwd] = server:new()
		instances[cwd]:start(cwd, OS, opts.fargs[1])

		--logic for starting from random buffer <---------------
		if instances[cwd].websock_client == nil then
			vim.fn.jobstart(browser .. " http://127.0.0.1:" .. instances[cwd]:getPort() .. "/neoweb.html")
		end

		do
			page[cwd] = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))

			for lines in page[cwd]:gmatch("%a+%.css") do
				table.insert(css_files, lines)
			end

			for lines in page[cwd]:gmatch("%a+%.js") do
				table.insert(js_files, lines)
			end

			local timer = vim.uv.new_timer()
			timer:start(500, 5, function()
				if instances[cwd].websock_client then
					instances[cwd]:ws_send("UPDA" .. page[cwd])
					timer:stop()
				end
			end)
		end

		local send = function()
			local sendpage = page[cwd]
			for key, styledata in pairs(stylebuf[cwd]) do
				sendpage = string.gsub(sendpage, "<link (.-)" .. key .. "(.-)>", styledata)
			end
			for key, scriptdata in pairs(scriptbuf[cwd]) do
				sendpage = string.gsub(sendpage, "<script (.-)" .. key .. "(.-)</script>", scriptdata)
			end

			instances[cwd]:ws_send("UPDA" .. sendpage)
		end

		vim.api.nvim_create_augroup("Neoweb-" .. cwd, { clear = true })

		vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
			group = "Neoweb-" .. cwd,
			buffer = bufnr,
			callback = function()
				page[cwd] = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
				send()
			end,
		})

		vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
			group = "Neoweb-" .. cwd,
			pattern = js_files,
			callback = function()
				scriptbuf[cwd][vim.fn.expand("%:t")] = "<script>"
					.. table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), 0, -1, false))
					.. " </script>"
				send()
			end,
		})

		vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
			group = "Neoweb-" .. cwd,
			pattern = css_files,
			callback = function()
				stylebuf[cwd][vim.fn.expand("%:t")] = "<style> "
					.. table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), 0, -1, false))
					.. " </style>"
				send()
			end,
		})

		vim.api.nvim_create_autocmd({ "BufDelete", "BufUnload", "BufWipeout" }, {
			group = "Neoweb-" .. cwd,
			buffer = bufnr,
			callback = function()
				instances[cwd]:ws_send("STOP")
			end,
		})
	end
end, { nargs = "?" })

-- nually Stop Server
vim.api.nvim_create_user_command("HTPreviewStop", function()
	local cwd = vim.fn.getcwd()
	if instances[cwd] then
		instances[cwd]:ws_send("STOP")
	else
		print("No server running")
	end
end, {})
