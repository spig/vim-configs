" File: spig.vim
" Author: Steve Spigarelli
" Version: 1.0
" Last Modified: Feb 21, 2011
"
" Overview
" --------
" Just a test to add some things I like in VIM
"
" Installation
" ------------
" 1. Copy the spig.vim plugin to the $HOME/.vim/plugin directory. Refer to
"    the following Vim help topics for more information about Vim plugins:
"
"       :help add-plugin
"       :help add-global-plugin
"       :help runtimepath
"
" 2. Restart Vim.
"
" Usage
" -----
"
" ****************** Do not modify after this line ************************
if exists('loaded_spig') || &cp
    finish
endif
let loaded_spig=1

function! <SID>:AutoFuzzyFind()
  "let s:xqyFilename = matchstr(getline(line(".")), '/\zs[a-zA-Z0-9_\-]\+\.xqy')
  let s:xqyFilename = matchstr(getline(line(".")), '/\zs\f\+\.xqy')
"  echo matchstr(getline(line(".")), '/\zs[a-zA-Z0-9_\-]\+\.xqy')
  "execute 'FuzzyFinderTextMate ' . s:xqyFilename

  let s:xqyFilename = substitute(s:xqyFilename, '/^\//', '', '')

  if filereadable(s:xqyFilename)
    execute 'e ' . fnameescape(s:xqyFilename)
  else
    execute 'normal ^'
    execute "normal \/\.xqy\<CR>"
    execute 'normal gf'
  endif
  
  "call FuzzyFinderTextMateLauncher(xqyFilename, 0)
"  call g:FuzzyFinderMode.TextMate.launch(xqyFilename, 0)
  "command! -bang -narg=? -complete=file   FuzzyFinderTextMate   call FuzzyFinderTextMateLauncher(<q-args>, len(<q-bang>))
endfunction

"nmap <silent> <C-g>x :call <SID>:AutoFuzzyFind()<cr>
map <leader>gf :call <SID>:AutoFuzzyFind()<cr>
