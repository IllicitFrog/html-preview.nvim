local aspect_ratios = setmetatable({
	["full"] = { "100vw", "100vh" },
	["letter"] = { "100vw", "calc(100vw * .75)" },
	["mobile"] = { "calc(100vh * .75)", "100vh" },
}, {
	__index = function()
		return { "100vw", "100vh" }
	end,
})

local enclose = function(port, aspect)
  local ratio = aspect_ratios["mobile"]
	local iframe = [[
    <!DOCTYPE html>
    <html>
      <head>
        <title>Neoweb Preview</title>
      </head>
      <body style="margin: 0; padding: 0; background-color: black">
      <div class="output">
      <iframe style="display: block; border: none; margin: auto; width:]] ..ratio[1] .. "; height:" .. ratio[2] .. [[;"></iframe>
      </div>
      </body>
      <script>
        const socket = new WebSocket("ws://127.0.0.1:]] .. port .. [[");
        socket.onopen = () => {
          console.log("Connected");
        };
        socket.onclose = () => {
          console.log("Disconnected");
        };
        socket.onmessage = (event) => {
          var instruction = event.data.substring(0, 4);
          if (instruction == "UPDA") {
            document.querySelector(".output > iframe").contentWindow.document.open();
            document.querySelector(".output > iframe").contentWindow.document.write(event.data.substring(4));
            document.querySelector(".output > iframe").contentWindow.document.close();
          } else if (instruction == "STOP") {
            window.close();
          }
        }
        socket.onerror = () => {
          window.close();
        };

      </script>
      </html>
  ]]
	return iframe
end

return enclose
