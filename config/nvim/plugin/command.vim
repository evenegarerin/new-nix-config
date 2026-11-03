" Capture output from a command to register @m, to paste, press "mp
command! -nargs=1 -complete=command Redir call utils#CaptureCommandOutput(<q-args>)

command! -bar -bang -nargs=* -complete=file Edit call utils#MultiEdit([<f-args>])
call utils#Cabbrev('edit', 'Edit')

call utils#Cabbrev('man', 'Man')

" show current date and time in human readable format
command! -nargs=? Datetime echo utils#iso_time(<q-args>)

" Convert Markdown file to PDF
command! ToPDF call s:md_to_pdf()

" Hand a finished PDF to the platform's viewer. Detached, so closing nvim does
" not take the viewer with it.
function! s:open_pdf(pdf_path) abort
  if g:is_linux
    let l:viewer = ['zathura', a:pdf_path]
  elseif g:is_mac
    let l:viewer = ['open', a:pdf_path]
  elseif g:is_win
    let l:viewer = ['cmd.exe', '/c', 'start', '', a:pdf_path]
  else
    return
  endif

  if executable(l:viewer[0]) != 1
    echomsg printf('ToPDF: wrote %s (%s not found, not opening)', a:pdf_path, l:viewer[0])
    return
  endif

  call jobstart(l:viewer, {'detach': v:true})
endfunction

" xelatex writes the reason it gave up -- a missing .sty, a bad macro -- to
" stderr. The old version discarded it and left no trace that anything failed.
function! s:on_pandoc_exit(pdf_path, errors, code) abort
  if a:code == 0
    echomsg printf('ToPDF: wrote %s', fnamemodify(a:pdf_path, ':t'))
    call s:open_pdf(a:pdf_path)
    return
  endif

  let l:lines = filter(copy(a:errors), '!empty(trim(v:val))')

  echohl ErrorMsg
  echomsg printf('ToPDF: pandoc exited with %d', a:code)
  for l:line in l:lines[:19]
    echomsg l:line
  endfor
  echohl None

  if len(l:lines) > 20
    echomsg printf('ToPDF: %d more line(s) suppressed, see :messages', len(l:lines) - 20)
  endif
endfunction

function! s:md_to_pdf() abort
  " check if pandoc is installed
  if executable('pandoc') != 1
    echoerr "pandoc not found"
    return
  endif

  let l:md_path = expand("%:p")

  if empty(l:md_path)
    echoerr 'ToPDF: buffer is not backed by a file'
    return
  endif

  let l:pdf_path = fnamemodify(l:md_path, ":r") .. ".pdf"

  let l:header_path = stdpath('config') . '/resources/head.tex'

  " List form rather than a shell string: no quoting needed, so paths with
  " spaces survive.
  let l:cmd = [
        \ 'pandoc',
        \ '--pdf-engine=xelatex',
        \ '--highlight-style=zenburn',
        \ '--table-of-content',
        \ '--include-in-header=' . l:header_path,
        \ '-V', 'fontsize=10pt',
        \ '-V', 'colorlinks',
        \ '-V', 'toccolor=NavyBlue',
        \ '-V', 'linkcolor=red',
        \ '-V', 'urlcolor=teal',
        \ '-V', 'filecolor=magenta',
        \ '-s', l:md_path,
        \ '-o', l:pdf_path,
        \ ]

  " Lists are references, so what on_stderr appends here is what on_exit sees.
  let l:errors = []

  let l:id = jobstart(l:cmd, {
        \ 'stderr_buffered': v:true,
        \ 'on_stderr': {_, data, __ -> extend(l:errors, data)},
        \ 'on_exit': {_, code, __ -> s:on_pandoc_exit(l:pdf_path, l:errors, code)},
        \ })

  if l:id <= 0
    echoerr "Error running command"
    return
  endif

  echomsg printf('ToPDF: building %s ...', fnamemodify(l:pdf_path, ':t'))
endfunction
