local M = {}

M.config = {
	port = 8090,
	browser = "xdg-open",
}

M.validate = function(user_config)
	if not user_config then
		return false
	end

	if type(user_config) ~= "table" then
		return false
	end

	if user_config.port ~= nil then
		if type(user_config.port) == "number" then
			M.config.port = user_config.port
		end
	end

	if M.config.browser ~= nil then
		if type(M.config.browser) == "string" then
			M.config.browser = user_config.browser
		end
	end
end

return M
