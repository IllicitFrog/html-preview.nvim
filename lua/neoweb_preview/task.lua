return [===[
      print=function(msg)end
      local pegasus = require("pegasus")
      local mimetypes = require("mimetypes")

      local Static = {}
      Static.__index = Static

      function Static:new(options)
        options = options or {}
        local plugin = {}

        local location = options.location or ""
        if location:sub(1, 2) ~= "./" and location:sub(1, 1) ~= "/" then
          -- make sure it's a relative path, forcefully!
          location = "./" .. location
        end
        if location:sub(-1, -1) == "/" then
          location = location:sub(1, -2)
        end
        plugin.location = location -- this is now a relative path, without trailing slash

        local default = options.default or "index.html"
        if default ~= "" then
          if default:sub(1, 1) ~= "/" then
            default = "/" .. default
          end
        end
        plugin.default = default -- this is now a filename prefixed with a slash, or ""

        setmetatable(plugin, Static)
        return plugin
      end

      function Static:newRequestResponse(request, response)
        local stop = false

        local method = request:method()
        if method ~= "GET" and method ~= "HEAD" then
          return stop -- we only handle GET requests
        end

        local path = request:path()
        if path == "/" then
          if self.default ~= "" then
            response:redirect(self.default)
            stop = true
          end
          return stop -- no default set, so nothing to serve
        end

        local filename = self.location .. path

        if filename:match("[^.]+$") ~= "html" then
          stop = not not response:writeFile(filename, mimetypes.guess(filename) or "text/html")
        else

          local file, err = io.open(filename, 'rb')
          if not file then
            return nil, err
          end

          local value, err = file:read('*a')
          file:close()
          response:contentType("text/html")
          response:statusCode(200)
          stop = not not response:write(value .. [[<script src="https://livejs.com/live.js"></script>]])
        end

        return stop
      end

      local server = pegasus:new({
        port = {{port}},
        plugins = {
          Static:new({
            location = {{root}},
          }),
        },
      })

			server:start(function(request, response)

			end)
      ]===]
