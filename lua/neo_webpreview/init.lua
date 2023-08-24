local M = {}
-- local jit = require("jit")
-- if jit then
--   local os = string.lower(jit.os)

M.job = nil
M.browser = nil

M.start = function()
	if M.job then
		return vim.notify(
			"Neo_WebPreview Server already running, view at http://localhost:8089" .. ", or :NWPPreview",
			vim.log.levels.INFO
		)
	end
	if vim.fn.executable("nwp") == 0 then
		--setup to build executable here
		return vim.notify("Neo_WebPreview executable not found!", vim.log.levels.ERROR)
	end

	local cmd = { "nwp", "--rootdir", vim.fn.getcwd(), "--index", vim.fn.expand("%:.") }
	M.job = vim.fn.jobstart(table.concat(cmd, " "), {
		stdout_buffered = true,
		on_stderr = function(_, data)
			if data then
				vim.notify(data, vim.log.levels.ERROR)
			end
		end,
	})
	vim.notify("Neoweb Preview started", vim.log.levels.INFO)
  M.preview()
end

M.preview = function(browse)
	if browse then
		M.browser = browse
	end
	if M.browser == nil then
		if vim.fn.executable("xdg-open") then
			M.browser = "xdg-open"
		else
			return vim.notify("Unable to detect default browser", vim.log.levels.ERROR)
		end
	end
	vim.fn.jobstart(M.browser .. " localhost:8090/" .. vim.fn.expand("%:."), {
		stdout_buffered = true,
		on_stderr = function(_, data)
			if data then
				vim.notify(data, vim.log.levels.ERROR)
			end
		end,
	})
	return vim.notify(vim.fn.expand("%:.") .. " opened in browser", vim.log.levels.INFO)
end

M.stop = function()
	if M.job then
		vim.fn.jobstop(M.job)
		M.job = nil
		return vim.notify("Neoweb preview stopped", vim.loglevels.INFO)
	else
		return vim.notify("No instance of Neo_WebPreview", vim.log.levels.INFO)
	end
end

return M
