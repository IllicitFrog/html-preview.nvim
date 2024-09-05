-- Title:        Neo_WebPreview
-- Description:  A small plugin for live web development preview
-- Last Change:  August 21/2023
-- Maintainer:   Example User <https://github.com/example-user>
--
vim.api.nvim_buf_create_user_command(0, "NeowebPreviewStart", function()
  require("neoweb_preview").run()
end, {})

vim.api.nvim_buf_create_user_command(0, "NeowebPreviewStop", function()
	require("neoweb_preview").stop()
end, {})
