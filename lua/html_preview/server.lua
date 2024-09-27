local uv = vim.uv
local websocket = require("html_preview.websocket")
local request = require("html_preview.http.request")
local response = require("html_preview.http.response")
local localhost = "127.0.0.1"

local Server = {
	server = uv.new_tcp(),
	is_active = false,
	port = 0,
	websock_client = nil,
	cwd = "",
	assets = "",
	aspect = "full",

	running = function(self)
		return self.is_active
	end,

	getPort = function(self)
		return self.port
	end,

	new = function(self)
		return setmetatable({}, { __index = self })
	end,

	start = function(self, cwd, OS, aspect)
		self.cwd = cwd
		self.is_active = true
		if aspect ~= nil then
			self.aspect = aspect
		end

		self.server = uv.new_tcp()

		if OS == "Windows_NT" then
			self.assets = string.match(debug.getinfo(2, "S").source:sub(2), "(.*[/\\])") .. "http\\"
		else
			self.assets = string.match(debug.getinfo(2, "S").source:sub(2), "(.*/)") .. "http/"
		end

		self.server:bind(localhost, self.port)
		if self.port == 0 then
			self.port = self.server:getsockname().port
		end

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
							print("HTML Preview closed")
							self.server:close_reset()
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
							print("HTML Preview open")
							client:keepalive(true, 0)
						else
							--HTTP file Request
							local headers, body = response:create(req, self.cwd, self.port, self.assets, self.aspect)
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
