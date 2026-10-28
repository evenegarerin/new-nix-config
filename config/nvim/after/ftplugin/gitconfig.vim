" NOTE: the target uses `set` here. Every one of these options is buffer- or
" window-local, so `set` also writes the global default and leaks the value to
" other buffers -- confirmed for keywordprg, which stayed `:help` everywhere
" after visiting a .vim file. `setlocal` throughout.
setlocal commentstring=#\ %s
