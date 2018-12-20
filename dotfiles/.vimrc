" $URL$
" $Date$
" $Revision$

" Copyright (c) 2004 by Jon R. Roma

filetype on             " turn on file type detection

if &t_Co >= 8
  syntax on             " enable syntax highlighting
else
  syntax off            " disable syntax highlighting when non-GUI, non-color
endif

set cmdheight=2         " set 2-line command line
set cpoptions+=u        " enable vi-compatable undo
set cpoptions-=u        " disable vi-compatable undo
set formatoptions-=cro  " disable annoying auto-formatting
set hlsearch            " turn on search pattern highlighting
set laststatus=2        " always a status line
set mousehide           " hide mouse while typing

set autoindent
set magic
"set nomesg
"set optimize
"set redraw
set report=2
set ruler
set shellcmdflag=-ic
set terse
set wrapscan

map <F1>    :set list<CR>
map <F2>    :set nolist<CR>
map <F3>    :set number<CR>
map <F4>    :set nonumber<CR>
map <F12>   :nohls<CR>

"if &background == "dark"
"
"else
"
"endif

highlight   Normal        guibg=Gray88
highlight   Comment       gui=NONE      guifg=Gray60
"highlight  Constant      gui=NONE      guibg=Gray92
highlight   Cursor        guifg=NONE    guibg=Red3
highlight   ErrorMsg      guibg=Red3
highlight   Identifier    gui=NONE      guifg=#008b8b
highlight   NonText       guibg=Gray80
"highlight  Special       gui=NONE      guibg=Gray92
highlight   StatusLine    guifg=Green3  guibg=White
"highlight  StatusLineNC  guifg=#e0c8a0 guibg=Gray60
highlight   StatusLineNC  guifg=Gray72  guibg=Gray42
highlight   User1         guifg=Red     guibg=White

if &t_Co >= 16
  highlight Comment       ctermfg=8 
  highlight SpecialKey    ctermfg=14      ctermbg=8   " newline characters, etc.
  highlight Search        ctermfg=0       ctermbg=11

endif

if ! exists("g:loaded_matchparen")    " don't highlight matching parentheses
  let g:loaded_matchparen = 1
endif

if has("autocmd")

  autocmd BufEnter    *   let &titlestring = "Vim " . expand("%:P")

  " function to register tab stops for this/these file type(s)

  function! RegisterFileTypeTabs(ts, ...)

    " should validate that a:ts is numeric

    let i = 1
    while i <= a:0
      execute "let type = a:" . i
      execute 'let g:retab_' . type . ' = "' . a:ts . '"'
      let i = i + 1
    endwhile

  endfunction

  " function to convert blank spaces to tabs when reading file

  function! RetabRead()
    if ! exists("&filetype") || ! exists("g:retab_" . &filetype)
      let l:ts = 8                    " set default tab stop
      execute "set tabstop="    . l:ts
      execute "set shiftwidth=" . l:ts
      return
    endif

    execute "let l:ts = g:retab_" . &filetype

  " if exists("&filetype") && exists("g:retab_" . &filetype)
  "   execute "let l:ts = g:retab_" . &filetype
  " else
  " let l:ts = 8    " set default tab stop
  " endif

    execute "set tabstop="    . l:ts
    execute "set shiftwidth=" . l:ts

    if &modifiable
      set noexpandtab
      retab!
    endif
  endfunction

  " function to convert tabs to blank spaces before writing file

  function! RetabPreWrite()
    if ! exists("&filetype") || ! exists("g:retab_" . &filetype)
      return
    endif

    set expandtab
    retab
  endfunction

  function! RetabPostWrite()
    if ! exists("&filetype") || ! exists("g:retab_" . &filetype)
      return
    endif

    set noexpandtab
    retab!
    endfunction

  "   assume that *.cgi files use perl syntax; ought to read to be certain
  "   *.gs files are Trainz gamescript (close enough to pretend to be Java)

  augroup filetypedetect

  autocmd BufRead,BufNewFile    *.cgi   set filetype=perl
  autocmd BufRead,BufNewFile    *.fcgi  set filetype=perl
  autocmd BufRead,BufNewFile    *.gs    set filetype=java

  autocmd BufRead,BufNewFile    *.in
    \ if getline(1) =~ '@PERL@' |
    \ set filetype=perl |
    \ elseif getline(1) =~ '@PYTHON@' |
    \ set filetype=python |
    \ endif

  autocmd BufRead,BufNewFile    * setlocal  formatoptions-=cro
  augroup END

  augroup Tab     " start autocmd group

  autocmd!
  autocmd BufRead,BufNewFile,FileReadPost *   call RetabRead()
  autocmd BufWritePre,FileWritePre        *   call RetabPreWrite()
  autocmd BufWritePost,FileWritePost      *   call RetabPostWrite()

  augroup END     " end autocmd group

  call RegisterFileTypeTabs(4, "css", "dtd")
  call RegisterFileTypeTabs(4, "html", "htmldjango")
  call RegisterFileTypeTabs(4, "java")
  call RegisterFileTypeTabs(3, "javascript")
  call RegisterFileTypeTabs(4, "perl", "xs")
  call RegisterFileTypeTabs(4, "python")
  call RegisterFileTypeTabs(4, "spec")
  call RegisterFileTypeTabs(8, "sql")
  call RegisterFileTypeTabs(4, "svg", "wsdl", "xhtml", "xml")
  call RegisterFileTypeTabs(2, "vim")
  call RegisterFileTypeTabs(4, "ksh", "zsh")

endif " has("autocmd")
