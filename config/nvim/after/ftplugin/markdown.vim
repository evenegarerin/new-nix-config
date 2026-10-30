setlocal concealcursor=c
setlocal synmaxcol=3000  " For long Chinese paragraphs

setlocal wrap

" vim-markdownfootnotes' own ftplugin runs before this file and claims
" <Leader>f and <Leader>r buffer-locally whenever nothing has taken them yet --
" with `mapleader = ' '` that is <Space>f and <Space>r. In normal mode it
" hijacks the leader: <Space>f inserts a footnote as soon as the second key
" misses 'timeoutlen' (200ms, options.lua), and <Space>r runs :q on the window.
" Insert mode is worse still: no longer mapping starts with <Space>f there, so
" there is no timeout to ride out and any word beginning with `f` after a space
" -- "for", "from", "a fair bit" -- splits the window and swallows the rest of
" the sentence into a footnote definition.
" The <Plug> mappings stay, so :call markdownfootnotes#VimFootnotes() and any
" deliberate binding still work.
if exists(':FootnoteNumber')
  silent! nunmap <buffer> <Leader>f
  silent! nunmap <buffer> <Leader>r
  silent! iunmap <buffer> <Leader>f
  silent! iunmap <buffer> <Leader>r
endif
