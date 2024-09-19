
local config = {
	ip = "127.0.0.1",
	port = 8090,
	browser = "",
}

local validate = function(user_config)
	if not user_config or type(user_config) ~= "table" then
		return config
	end

	if user_config.ip ~= nil and type(user_config.ip) == "string" then
		config.ip = user_config.ip
	end

	if user_config.port ~= nil and type(user_config.port) == "number" then
		config.port = user_config.port
	end

	if user_config.browser ~= nil and type(user_config.browser) == "string" then
		config.browser = user_config.browser
	else
		OS = vim.loop.os_uname().sysname
		if OS == "Darwin" then
			config.browser = "open"
		elseif OS == "Windows_NT" then
			config.browser = "start"
		else
			config.browser = "xdg-open"
		end
	end
end
