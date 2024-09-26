<h1 align="center">HTML Preview</h1>

> Requires Neovim 0.9.0 or greater

> Still in early development expect ISSUES.

### A simple HTML preview plugin for neovim.

Was created for a simple web interface I was making and got tired of refreshing, orginally wrote in C++
but required to many build dependencies and issues cross platform.

It by no means is polished but I intend to maintain it.

Features:

- Built using Neovim native Luv api no external dependencies
- Supports live HTML, CSS, and JS
- Multiple live projects at once
- Works with neovim 0.9.0 or greater
- I really dislike making README's

### Installation

Lazy:

```lua

"IllicitFrog/html_preview.nvim",
ft = "html",
config = function()
    require("html_preview").setup()
end,

```

Packer:

```lua
use {
    "IllicitFrog/html_preview.nvim",
    config = function()
        require("html_preview").setup()
    end
}
```

## Usage

No configuration required simply run

`:HtmlPreview`

Can be exited by either closing the preview window or by

`:HtmlPreviewStop`

For different aspect ratio's use

`:HtmlPreview mobile` or `:HtmlPreview letter`

### Credit

The websockets were heavily "inspired" by LuaWebsockets

https://github.com/lipp/lua-websockets
