local aspect_ratios = setmetatable({
	["full"] = { "100vw", "100vh" },
	["letter"] = { "calc(99vh * 1.33)", "99vh" },
	["mobile"] = { "calc(99vh * .75)", "99vh" },
}, {
	__index = function()
		return { "100vw", "100vh" }
	end,
})

local enclose = function(port, aspect)
	local ratio = aspect_ratios[aspect]
	local border = "none"

	if aspect ~= "full" then
		border = "2px solid white"
	end

	local iframe = [[
    <!DOCTYPE html>
    <html>
      <head>
        <title>Neoweb Preview</title>
      </head>
      <body style="margin: 0; padding: 0; overflow: hidden; background-color:black;">
      <div class="output">
      <iframe style="display: block; transform: translate(-50%, -50%); position: absolute; 
      top: 50%; left: 50%; border: ]] .. border .. [[; margin: auto; width:]] .. ratio[1] ..
      "; height:" .. ratio[2] .. [[;"></iframe>
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
