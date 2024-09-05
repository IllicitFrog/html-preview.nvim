local M = {}

M.config = {
	port = 8090,
	browser = "xdg-open",
}

M.validate = function(user_config)
	if not user_config then
		return M.config
	end

	if type(user_config) ~= "table" then
		return M.config
	end

	if user_config.port ~= nil then
		if type(user_config.port) == "number" then
			M.config.port = user_config.port
		end
	end

	if user_config.browser ~= nil then
		if type(M.config.browser) == "string" then
			M.config.browser = user_config.browser
		end
	end

  return M.config
end

return M
