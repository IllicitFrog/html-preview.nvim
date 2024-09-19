local uv = vim.uv
local websocket = require("neoweb_preview.websocket")
local request = require("neoweb_preview.http.request")
local response = require("neoweb_preview.http.response")

local Server = {
	server = uv.new_tcp(),
	cwd = "",
	is_active = false,
  ip = "127.0.0.1",
  port = 8090,
	websock_clients = {},

	get_cwd = function(self)
		return self.cwd
	end,

	isRunning = function(self)
		return self.is_active
	end,

	new = function(self, cwd, port)
		local instance = {}
		setmetatable(instance, {__index = self})
		self.__index = self
    instance.cwd = cwd
		return instance
	end,

	start = function(self, bufnr)
		-- options.enabled_buffers[bufnr] = vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
		self.is_active = true

		self.server:bind(self.ip, self.port)
		self.server:listen(128, function(err)
			if err then
				print("Error listening:", err)
				return
			end
			local client = uv.new_tcp()
			self.server:accept(client)

			client:read_start(function(error, chunk)
				if error then
					print("Error reading:", error)
					client:shutdown()
					client:close()
				end
				if chunk then
					if self.websock_clients[client] then
						if websocket.is_close(chunk) then
							client:shutdown()
							client:close()
							self.websock_clients[client] = nil
						end
					else
						local req = request:new(chunk)
						if req.headers["Upgrade"] == "websocket" then
							client:write(websocket.handshake(req.headers["Sec-WebSocket-Key"]))
							client:write("0\r\n\r\n")
							self.websock_clients[client] = true
							client:keepalive(true, 0)
						else
							local headers, body = response:new(req, self.cwd)
							client:keepalive(true, 90)
							client:write(headers)
							client:write(body)
							client:write("0\r\n\r\n")
						end
					end
				end
			end)
		end)
	end,

	stop = function(self)
		self.is_active = false
		self.server:close()
	end,

	ws_send = function(self, data)
		for _, client in pairs(self.websock_clients) do
			local encode = websocket.encode(data)
			client:write(encode)
		end
	end,
}

return Server
