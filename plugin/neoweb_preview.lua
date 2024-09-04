-- Title:        Neo_WebPreview
-- Description:  A small plugin for live web development preview
-- Last Change:  August 21/2023
-- Maintainer:   Example User <https://github.com/example-user>

 local augroup = vim.api.nvim_create_augroup("neoweb_preview", { clear = true })

 vim.api.nvim_create_autocmd("BufEnter", {
   pattern = {"*.html"},
   group = augroup,
   callback = function()
     require("neoweb_preview")()
   end,
 })
