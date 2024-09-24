local uv = vim.uv
local websocket = require("neoweb_preview.websocket")
local request = require("neoweb_preview.http.request")
local response = require("neoweb_preview.http.response")
local localhost = "127.0.0.1"

local Server = {
	server = uv.new_tcp(),
	is_active = false,
	port = 0,
	websock_client = nil,
	cwd = nil,

	running = function(self)
		return self.is_active
	end,

	getPort = function(self)
		return self.port
	end,

	new = function(self)
		return setmetatable({}, { __index = self })
	end,

	start = function(self, cwd)
		self.cwd = cwd
		self.is_active = true

		self.server:bind(localhost, self.port)
		self.port = self.server:getsockname().port

		--Begin listening
		self.server:listen(12, function(err)
			if err then
				print("Error listening:", err)
				return
			end

			local client = uv.new_tcp()
			self.server:accept(client)

			-- TCP Connection Read Loop
			client:read_start(function(error, chunk)
				if error then
					print("Error reading:", error)
					client:shutdown()
					client:close()
				end
				if chunk then
					--Websocket closed from browser side
					if self.websock_client == client then
						if websocket.is_close(chunk) then
							print("Neoweb closed")
							self.server:shutdown()
							self.websock_client = nil
							self.is_active = false
              vim.schedule(function()
                vim.api.nvim_del_augroup_by_name("Neoweb-" .. cwd)
              end)
						end
					else
						--HTTP request handling
						local req = request:new(chunk)
						--Is a websocket Upgrade Request
						if req.headers["Upgrade"] == "websocket" then
							local res = websocket.handshake(req.headers["Sec-WebSocket-Key"])
							client:write(res)
							self.websock_client = client
							print("Neoweb open")
							client:keepalive(true, 0)
						else
							--HTTP file Request
							local headers, body = response:new(req, self.cwd, self.port)
							client:write(headers)
							client:write(body)
							client:write("0\r\n\r\n")
						end
					end
				end
			end)
		end)
	end,

	ws_send = function(self, data)
		local encode = websocket.frame(data)
		self.websock_client:write(encode)
	end,
}

Server.__index = Server

return Server
