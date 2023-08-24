" Title:        Neo_WebPreview
" Description:  A small plugin for live web development preview
" Last Change:  August 21/2023
" Maintainer:   Example User <https://github.com/example-user>

if exists("g:loaded_neowebpreview")
  finish
endif
let g:loaded_neowebpreview = 1

command! -nargs=0 NWP lua require("neo_webpreview").start()
command! -nargs=1 NWPBrowser lua require("neo_webpreview").set_browser()
command! -nargs=0 NWPStop lua require("neo_webpreview").stop()
command! -nargs=? NWPPreview lua require("neo_webpreview").preview()
