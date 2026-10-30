" Disable inserting comment leader after hitting o or O or <Enter>
setlocal formatoptions-=o
setlocal formatoptions-=r

" Use :help command for keyword when pressing `K` in vim file,
" see `:h K` and https://stackoverflow.com/q/15867323/6064933
setlocal keywordprg=:help

nnoremap <buffer><silent> <F9> :source %<CR>
