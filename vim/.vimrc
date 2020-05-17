set nocompatible        " make vim load .vimrc correctly from any location
set backspace=indent,eol,start "  backspace in insert mode works like normal editor
syntax on               " syntax highlighting
filetype indent on      " activates indenting for files
set autoindent          " auto indenting
set number              " line numbers
" colorscheme desert      " colorscheme desert
set nobackup            " get rid of anoying ~file

filetype plugin indent on
set tabstop=4           " show existing tabs with 4 spaces width
set shiftwidth=4        " insert 4 spaces when indenting with '>'
set expandtab           " insert 4 spaces when indenting with tab

set relativenumber      " activate relative line numbers

inoremap jh <Esc>
