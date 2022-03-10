set background=dark

call plug#begin()

Plug 'scrooloose/nerdtree', { 'on': 'NERDTreeToggle' }
Plug 'morhetz/gruvbox'
Plug 'tpope/vim-sensible'
Plug 'skywind3000/asyncrun.vim'

call plug#end()

nmap <tab> :NERDTreeToggle<CR>

set number
colorscheme gruvbox

set nocompatible
set smartindent
set tabstop=4
set shiftwidth=4
set expandtab
set textwidth=120
syntax on
set showmatch
set ignorecase
set hlsearch
set incsearch

set wildmode=longest,list,full
set wildmenu

nmap <C-j> :bnext<CR>
nmap <C-k> :bprev<CR>

set backspace=indent,eol,start
filetype plugin on
filetype indent plugin on
set autoindent

autocmd FileType make set noexpandtab

set statusline=%f%=%{winnr()}

function! SwapWindows()
    let buf1 = winbufnr(v:count)
    let buf2 = winbufnr(winnr())
    exe "buffer" . buf1
    exe v:count . "wincmd w"
    exe "buffer" . buf2
endfunction


set hidden
nmap <C-w><C-s> :<c-u> call SwapWindows()<CR>

imap <C-a> <C-o>^
imap <C-e> <C-o>$

let mapleader="\\"

let g:asyncrun_open=1

" Insert line above
nmap [<SPACE> mlO<ESC>`l
" Insert line below
nmap ]<SPACE> mlo<ESC>`l 

" Preserve cursor position when joining
nmap J ml:join<CR>`l
