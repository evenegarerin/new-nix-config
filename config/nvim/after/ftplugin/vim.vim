" NOTE: the target uses `set` here. Every one of these options is buffer- or
" window-local, so `set` also writes the global default and leaks the value to
" other buffers -- confirmed for keywordprg, which stayed `:help` everywhere
" after visiting a .vim file. `setlocal` throughout.

" Disable inserting comment leader after hitting o or O or <Enter>
setlocal formatoptions-=o
setlocal formatoptions-=r

" NOTE: the target sets `foldmethod=expr` here with utils#VimFolds /
" utils#MyFoldText. nvim-ufo (Stage 8) manages folding globally and sets
" foldmethod=manual itself, so the two fight over every .vim buffer -- and this
" config has several (autoload/, plugin/). Folding is left to ufo.

" Use :help command for keyword when pressing `K` in vim file,
" see `:h K` and https://stackoverflow.com/q/15867323/6064933
setlocal keywordprg=:help

nnoremap <buffer><silent> <F9> :source %<CR>
