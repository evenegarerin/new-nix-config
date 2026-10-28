" NOTE: the target uses `set` here. Every one of these options is buffer- or
" window-local, so `set` also writes the global default and leaks the value to
" other buffers -- confirmed for keywordprg, which stayed `:help` everywhere
" after visiting a .vim file. `setlocal` throughout.

" Disable inserting comment leader after hitting o or O or <Enter>
setlocal formatoptions-=o
setlocal formatoptions-=r

" NOTE: the target sets `foldmethod=expr` here with utils#VimFolds /
" utils#MyFoldText. Those were held back while nvim-ufo owned folding globally;
" ufo has since been removed, so .vim buffers currently use vim's default
" (foldmethod=manual, i.e. no automatic folds). Both autoload functions still
" exist in autoload/utils.vim if you want the target's behaviour back:
"   setlocal foldmethod=expr
"   setlocal foldexpr=utils#VimFolds(v:lnum)
"   setlocal foldtext=utils#MyFoldText()

" Use :help command for keyword when pressing `K` in vim file,
" see `:h K` and https://stackoverflow.com/q/15867323/6064933
setlocal keywordprg=:help

nnoremap <buffer><silent> <F9> :source %<CR>
