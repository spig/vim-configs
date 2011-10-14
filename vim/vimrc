
if has("gui_running")
  colorscheme solarized
  set background=dark
  "set transparency=10
  set guifont=Monaco:h12
  set guioptions=egmrLt
  set enc=utf-8
  set columns=170        " New windows will open being 150 columns wide
  set lines=50           " Start with 40 lines
else
  set background=light
endif

syntax on
filetype plugin on

let mapleader = ","

"set spell              " Enable on-the-fly spell checking
set vb t_vb=           " Don't do anything on 'bell' (no sound)
set lbr                " Break on words, not on characters, when a line wraps
set showcmd            " Show (partial) command in status line.
set showmatch          " Show matching brackets.
set ignorecase         " Do case insensitive matching
set smartcase          " Do smart case matching
set incsearch          " Incremental search
set hidden             " Hide buffers when they are abandoned
set autoindent         " Copy indent from current line when starting a new line
set cursorline         " Turn on highlighting of current line
set smartindent        " Do smart autoindenting when starting a new line
set number             " Turn on line numbering
set wildmenu           " Turns on the wildmenu which makes tab completion and file browsing much nicer
set tabstop=2          " Set the default size of tabs to be 2 which is fairly common in the Rails world
set shiftwidth=2       " Same as above, but for indenting
set expandtab          " Turn on soft tabs
set laststatus=2       " Always show the status line
set ruler              " Show the line number, column number, and relative position in the status line
set viminfo='100,f0    " Save marks for up to 100 files in .viminfo
"set hlsearch           " Highlighted searches

if has("autocmd")
  filetype indent on
endif

" Allow for moving between windows using <CTRL>+normal vim movement keys (h j k l)
map <C-H> <C-W>h
map <C-J> <C-W>j
map <C-K> <C-W>k
map <C-L> <C-W>l
" Allow for quicker management of windows
" close current split
map <C-C> <C-W>c

" swap splits
map <C-X> <C-W>x

" focus current split (close all other splits)
map <C-O> <C-W>o

" delete all buffers
map bda :bufdo bd<CR>


" Allow backspacing over everything in insert mode
" This seems to be something that only OS X needs
set backspace=indent,eol,start

" FuzzyFinder File
map <leader>t :FuzzyFinderTextMate<CR>
map <leader>r :ruby finder.rescan!<CR>
let g:fuzzy_ignore = 'db/migrate/initial_fixtures/**;db/migrate/other_files/**;db/frozen/**;metrics/**;coverage/**;vendor/**;tmp/**;plasma/**'
let g:fuzzy_matching_limit = 20 " only display 20 entries in pop up menu

" Open up the filesystem tree view
map <leader>d :execute 'NERDTreeToggle ' . getcwd()<CR>

" FuzzyFinder Buffer
map <leader>b :FuzzyFinderBuffer<CR>

map <leader>ae :A<CR>
map <leader>av :AV<CR>
map <leader>as :AS<CR>

map <leader>ev :e ~/.vimrc<CR>

let g:github_user = 'CHANGEME'
let g:github_token = 'CHANGEME'
let g:gist_clip_command = 'pbcopy'
map <leader>gs :'<,'>Gist -p<CR>
map <leader>gf :Gist -p<CR>


" Tell NERDCommenter to not display warnings about unkown file types
let NERDShutUp=1

iab dbg require 'ruby-debug'; Debugger.start; debugger; puts 'debug'

function! s:ToggleScratch()
  if expand('%') == g:ScratchBufferName
    quit
  else
    Sscratch
  endif
endfunction

map <leader>s :call <SID>ToggleScratch()<CR>

" http://blog.ant0ine.com/2007/03/ack_and_vim_integration.html
" :Ack foo app/ - search for 'foo' in the app directory
" <leader>f 
" use :cc, :cp, :cn to navigate to the results
set grepprg=ack
map <leader>f :Ack -a 

