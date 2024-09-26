local iframe = require("neoweb_preview.http.iframe")

local STATUS_TEXT = {
	[200] = "OK",
	[404] = "Not Found",
	[405] = "Method Not Allowed",
	[500] = "Internal Server Error",
}

local mime_types = {
	["html"] = "text/html",
	["css"] = "text/css",
	["js"] = "application/javascript",
	["png"] = "image/png",
	["jpg"] = "image/jpeg",
	["jpeg"] = "image/jpeg",
	["gif"] = "image/gif",
}

local toHex = function(dec)
	local charset = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f" }
	local tmp = {}

	repeat
		table.insert(tmp, 1, charset[dec % 16 + 1])
		dec = math.floor(dec / 16)
	until dec == 0

	return table.concat(tmp)
end

local error_body = function(statusCode)
	local body = [[
  <!DOCTYPE html>
  <html>
    <head>
      <title> {{TITLE}}  </title>
    </head>
    <body style="background-color: black; color: white">
      <img style="display: block; margin-left: auto; margin-right: auto; width: 25%;" src="neoweb/error.png" />
      <h1 style="text-align: center"> {{MESSAGE}} {{TITLE}} </h1>
      <p style="text-align: center"> "Something went wrong!!" </p>
    </body>
  </html>
  ]]

	body = string.gsub(body, "{{TITLE}}", tostring(statusCode) or "Unknown")
	body = string.gsub(body, "{{MESSAGE}}", STATUS_TEXT[statusCode] or "Unknown")
	return body
end

local status_line = function(statusCode)
	return "HTTP/1.1 " .. tostring(statusCode) .. " " .. STATUS_TEXT[statusCode] .. "\r\n"
end

local load_file = function(filename)
	local file = io.open(filename, "rb")
	if not file then
		return 404, nil
	end
	local value, err = file:read("*a")
	file:close()
	return 200, value
end

local Response = {

	body = nil,
	mime = "",
	keepAlive = false,
	statusCode = 0,
	header = "",
	assets = "",

	add_header = function(self, key, value)
		self.header = self.header .. key .. ": " .. value .. "\r\n"
	end,

	create = function(self, req, cwd, port, assets, aspect)
		self.mime = mime_types[req.file:match("[^.]+$")] or "text/html"
		self.keepAlive = req.headers["Connection"] == "keep-alive"
		self.assets = assets

		if req.version ~= "HTTP/1.1" then
			self.statusCode = 505
		elseif req.method ~= "GET" and req.method ~= "HEAD" then
			self.statusCode = 405
		elseif req.file == "/neoweb.html" then
			self.statusCode = 200
			self.body = iframe(port, aspect)
		else
			if req.file:sub(1, 7) == "/neoweb" or req.file == "/favicon.ico" then
				self.statusCode, self.body = load_file(assets .. req.file)
			else
				self.statusCode, self.body = load_file(cwd .. req.file)
			end
		end

		if self.statusCode ~= 200 then
			if self.mime:sub(1, 5) == "image" then
				self.statusCode, self.body = load_file(assets .. "neoweb/image404.png")
			else
				self.body = error_body(self.statusCode)
			end
		end
		return self:create_header(), toHex(#self.body) .. "\r\n" .. self.body .. "\r\n"
	end,

	create_header = function(self)
		self:add_header("Content-Type", self.mime)
		self:add_header("Server", "Neoweb_Preview")
		self:add_header("Date", os.date("!%a, %d %b %Y %H:%M:%S GMT", os.time()))
		if self.keepAlive then
			self:add_header("Connection", "keep-alive")
			self:add_header("Transfer-Encoding", "chunked")
		else
			self:add_header("Connection", "close")
			self:add_header("Content-Length", #self.body)
		end
		return status_line(self.statusCode) .. self.header .. "\r\n"
	end,
}

return Response
