"
" Load vimrc files
"
for vimrc in ['plugins', 'configs', 'mappings', 'functions']
  exec 'source ~/.vim/vimrc/' . vimrc . '.vimrc'
endfor

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"       Taken from the following author's .vimrc
"
"       Maintainer: Amir Salihefendic - @amix3k
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

colorscheme onedark

" Use spaces instead of tabs
set expandtab
set shiftwidth=2
set tabstop=2

" Turn backup off, since most stuff is in SVN, git etc. anyway...
set nobackup
set nowb
set noswapfile

" Be smart when using tabs ;)
set smarttab

" Sets how many lines of history VIM has to remember
set history=500

" Set 7 lines to the cursor - when moving vertically using j/k
set so=7

" Turn on the Wild menu
set wildmenu

" Always show current position
set ruler

" Height of the command bar
set cmdheight=1

" A buffer becomes hidden when it is abandoned
set hid

" Set to auto read when a file is changed from the outside
set autoread
au FocusGained,BufEnter * silent! checktime

" Indentions
set ai "Auto indent
set si "Smart indent
set wrap "Wrap lines

" Prevent the cursor from going to next line when at eol
set whichwrap=

" Ignore case when searching
set ignorecase

" When searching try to be smart about cases
set smartcase

" Highlihht search results
set hlsearch

" Makes search act like search in modern browsers
set incsearch

" Don't redraw while executing macros (good performance config)
set lazyredraw

" For regular expressions turn magic on
set magic

" Show matching brackets when text indicator is over them
set showmatch

" How many tenths of a second to blink when matching brackets
set mat=2

" No annoying sound on errors
set noerrorbells
set novisualbell
set t_vb=
set tm=500

" Add a bit extra margin to the left
set foldcolumn=0

" Set utf8 as standard encoding and en_US as the standard language
set encoding=utf8

" Use Unix as the standard file type
set ffs=unix,dos,mac

" Linebreak on 500 characters
set lbr
set tw=500

" Always show the status line
set laststatus=1

" set occurence count on search
set shortmess-=S
set number

" Cursor shapes
" Insert mode cursor = line
" Normal mode cursor = block
let &t_SI = "\e[6 q"
let &t_EI = "\e[2 q"

" Return to last edit position when opening files (You want this!)
au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif

" Enable filetype plugins
filetype plugin on
filetype indent on

syntax on

