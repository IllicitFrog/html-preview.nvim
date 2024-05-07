" Title:        Neo_WebPreview
" Description:  A small plugin for live web development preview
" Last Change:  August 21/2023
" Maintainer:   Example User <https://github.com/example-user>

if exists("g:loaded_neowebpreview")
  finish
endif
let g:loaded_neowebpreview = 1

function! s:init() abort
  augroup neo_webpreview
    autocmd!
    autocmd BufEnter *.{html, htm, json} call lua require("neo_webpreview")
  augroup END
endfunction

call s:init()
