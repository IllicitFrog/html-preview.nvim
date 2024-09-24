local enclose = function(port)
	local iframe = [[
    <!DOCTYPE html>
    <html>
      <head>
        <title>Neoweb Preview</title>
      </head>
      <body style="margin: 0; padding: 0;">
      <div class="output">
      <iframe style="display: block; border: none; width: 100vw; height: 100vh;"></iframe>
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

      </script>
      </html>
  ]]
	return iframe
end

return enclose
