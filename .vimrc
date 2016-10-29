set nocompatible

call plug#begin('~/.vim/plugged')
"	Plug 'majutsushi/tagbar'
	Plug 'garyburd/go-explorer'
	Plug 'Shougo/neocomplete.vim'
	Plug 'fatih/vim-go', { 'tag': '*' }
	Plug 'AndrewRadev/splitjoin.vim'
	Plug 'SirVer/ultisnips'
	Plug 'fatih/molokai'
	Plug 'ctrlpvim/ctrlp.vim'
	Plug 'mileszs/ack.vim'
	Plug 'scrooloose/nerdtree'
	Plug 'vim-ctrlspace/vim-ctrlspace'
call plug#end()

" Color schema {{{
let g:rehash256 = 1
let g:molokai_original = 1
colorscheme molokai
" }}}

let mapleader = ","
let maplocalleader = ",,"

nnoremap ; :
nnoremap : <nop>

nnoremap <silent> <leader>ev :e $MYVIMRC<cr>
nnoremap <silent> <leader>sv :source $MYVIMRC<cr>

set showmode       " always show what mode we're currently editing in
set relativenumber
set number 
set cursorline
set autowrite
set wrap

set hidden
set tabstop=2
set smarttab      " insert tabs on the start of a line according to shiftwidth, not tabstop
set backspace=indent,eol,start " allow backspacing over everything in insert mode
set autoindent    " always set autoindenting on
set copyindent    " copy the previous indentation on autoindenting
set shiftwidth=2  " number of spaces to use for autoindenting
set shiftround    " use multiple of shiftwidth when indenting with '<' and '>'
set scrolloff=4   " keep 4 lines off the edges of the screen when scrolling
set virtualedit=all             " allow the cursor to go in to "invalid" places

nnoremap / /\v
vnoremap / /\v
set ignorecase    " ignore case when searching
set smartcase     " ignore case if search pattern is all lowercase, case-sensitive otherwise
set gdefault      " replace in all file
set showmatch     " set show matching parenthesis
set hlsearch      " highlight search terms
set incsearch     " show search matches as you type
nnoremap <silent> <leader>/ :nohlsearch<CR>
nnoremap <tab> %
vnoremap <tab> %
" set clipboard=unnamed           " normal OS clipboard interaction
" Keep search matches in the middle of the window and pulse the line when
" moving
" to them.
" nnoremap n n:call PulseCursorLine()<cr>
" nnoremap N N:call PulseCursorLine()<cr>


set autoread                    " automatically reload files changed outside of Vim


set history=1000         " remember more commands and search history
set undolevels=1000      " use many muchos levels of undo
set undofile
set undodir=~/.vim/.undo
set nobackup
set noswapfile
 
set wildmenu                    " make tab completion for files/buffers act like bash
set wildmode=list:full          " show a list when pressing tab and complete

set wildignore=*.swp,*.bak,*.pyc,*.class
set title                " change the terminal's title
set visualbell           " don't beep
set noerrorbells         " don't beep
set showcmd

set list
set listchars=tab:▸\ ,trail:·,extends:#,nbsp:·,eol:¬

set pastetoggle=<F2>

set laststatus=2
set statusline=%02n:%m\ %f\ -\ Filetype:%Y%=%l/%L\ %P
set cmdheight=2

" Arrows disable {{{
inoremap jk <esc>
inoremap <esc> <nop>
noremap <Up> <nop>
noremap <Left> <nop>
noremap <Right> <nop>
noremap <Down> <nop>
inoremap <Up> <nop>
inoremap <Left> <nop>
inoremap <Right> <nop>
inoremap <Down> <nop>
" }}}

" nnoremap j gj
" nnoremap k gk


" noremap <C-n> :cnext<CR>
" noremap <C-m> :cprevious<CR>
" nnoremap <leader>a :cclose<CR>

" nnoremap <c-u> viwU<esc>
" inoremap <c-u> <esc>viwui

nnoremap <Leader>l :ls<CR>
nnoremap <Leader>b :bp<CR>
nnoremap <Leader>f :bn<CR>
nnoremap <Leader>g :e#<CR>
nnoremap <Leader>1 :1b<CR>
nnoremap <Leader>2 :2b<CR>
nnoremap <Leader>3 :3b<CR>
nnoremap <Leader>4 :4b<CR>
nnoremap <Leader>5 :5b<CR>
nnoremap <Leader>6 :6b<CR>
nnoremap <Leader>7 :7b<CR>
nnoremap <Leader>8 :8b<CR>
nnoremap <Leader>9 :9b<CR>
nnoremap <Leader>0 :10b<CR>

nnoremap <C-n> :NERDTreeToggle<CR>

nnoremap <leader>' viW<esc>a'<esc>hBi'<esc>lel
nnoremap <leader>" viW<esc>a"<esc>hBi"<esc>lel
vnoremap <leader>" <esc>`<i"<esc>`>la"<esc>
vnoremap <leader>' <esc>`<i'<esc>`>la'<esc>

nnoremap <leader>uf ?\(^\\|\s\)func<cr>
nnoremap <leader>df /\(^\\|\s\)func<cr>

" Use ,d (or ,dd or ,dj or 20,dd) to delete a line without adding it to the
" yanked stack (also, in visual mode)
nnoremap <silent> <leader>d "_d
vnoremap <silent> <leader>d "_d
nnoremap <silent> <leader>x "_x
vnoremap <silent> <leader>x "_x
 
iabbrev @@ stammru@gmail.com

nnoremap <C-q> :call <SID>QuickfixToggle()<cr>

if executable('ag')
	let g:ackprg = 'ag --vimgrep'
" Use ag over grep
"   set grepprg=ag\ --nogroup\ --nocolor

   " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
   let g:ctrlp_user_command = 'ag %s -l --nocolor -g ""'

   " ag is fast enough that CtrlP doesn't need to cache
   let g:ctrlp_use_caching = 0
endif
nnoremap <leader>a :Ack! 
nnoremap <leader>cq :ccl<cr> " close quickfix
nnoremap <leader>oq :cope<cr> " open quickfix

au FocusLost * :wa

let g:go_fmt_command = "goimports"
let g:go_highlight_types = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
"  let g:go_highlight_operators = 1
let g:go_metalinter_autosave = 1
let g:go_auto_type_info = 1
let g:go_auto_sameids = 1
 
" Go file settings ---------------------- {{{
augroup filetype_go

  autocmd BufNewFile,BufRead *.go setlocal noexpandtab tabstop=2 shiftwidth=2
  autocmd BufWritePre *.go Fmt
  autocmd FileType go nmap <leader>r  <Plug>(go-run)
  autocmd FileType go nmap <leader>t  <Plug>(go-test)
  autocmd FileType go nmap <leader>c  <Plug>(go-coverage-toggle)
  autocmd FileType go nmap <leader>im  <Plug>(go-imports)
  autocmd FileType go nmap <leader>l  <Plug>(go-metalinter)
  autocmd FileType go nmap <Leader>i <Plug>(go-info)
  autocmd FileType go nmap <leader>b :<C-u>call <SID>build_go_files()<CR>
augroup END
" }}}

" Vimscript file settings ---------------------- {{{
augroup filetype_vim
  autocmd!
  autocmd FileType vim setlocal foldmethod=marker
augroup END
" }}}

" run :GoBuild or :GoTestCompile based on the go file
function! s:build_go_files()
  let l:file = expand('%')
  if l:file =~# '^\f\+_test\.go$'
    call go#cmd#Test(0, 1)
  elseif l:file =~# '^\f\+\.go$'
    call go#cmd#Build(0)
  endif
endfunction

