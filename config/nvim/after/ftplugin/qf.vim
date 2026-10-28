" Set quickfix window height, see also https://github.com/lervag/vimtex/issues/1127
function! AdjustWindowHeight(minheight, maxheight)
  execute max([a:minheight, min([line('$'), a:maxheight])]) . 'wincmd _'
endfunction

call AdjustWindowHeight(5, 15)

" Stage 1 remaps global `q` to a reminder; restore it buffer-locally here, the
" same way the target's after/ftplugin/man.lua does for man pages.
nnoremap <buffer><silent> q <cmd>quit<CR>
