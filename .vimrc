set nocompatible

call plug#begin('~/.vim/plugged')
"	Plug 'majutsushi/tagbar'
	Plug 'garyburd/go-explorer'
	"Plug 'Shougo/neocomplete.vim'
	Plug 'Valloric/YouCompleteMe'
	Plug 'fatih/vim-go', { 'tag': '*' }
	" Plug 'AndrewRadev/splitjoin.vim'
	Plug 'SirVer/ultisnips', { 'tag': '*' }
	Plug 'fatih/molokai'
	Plug 'ctrlpvim/ctrlp.vim'
	" Plug 'mileszs/ack.vim'
	Plug 'scrooloose/nerdtree'
	" Plug 'vim-ctrlspace/vim-ctrlspace'
	Plug 'tpope/vim-fugitive'
	" Plug 'vim-syntastic/syntastic'
	Plug 'neomake/neomake'
	Plug 'bling/vim-airline'
	Plug 'vim-airline/vim-airline-themes'
	Plug 'tpope/vim-commentary'
	Plug 'mhinz/vim-grepper'
	Plug 'airblade/vim-gitgutter'
call plug#end()

" Color schema {{{
let g:rehash256 = 1
let g:molokai_original = 1
colorscheme molokai
" }}}

let mapleader = ","
let maplocalleader = ",,"

nnoremap : ;
nnoremap ; :

nnoremap <silent> <leader>ev :e $MYVIMRC<cr>
nnoremap <silent> <leader>sv :source $MYVIMRC<cr>

set showmode       " always show what mode we're currently editing in
set relativenumber
set number
set cursorline
set autowrite
set wrap
set ruler

set ttyfast
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
nnoremap <silent> <leader>/ :nohlsearch<CR>
set ignorecase    " ignore case when searching
set smartcase     " ignore case if search pattern is all lowercase, case-sensitive otherwise
set gdefault      " replace in all file
set showmatch     " set show matching parenthesis
set hlsearch      " highlight search terms
set incsearch     " show search matches as you type
" nnoremap <tab> %
" vnoremap <tab> %
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


let g:airline#extensions#tabline#enabled = 1
let g:airline_theme             = 'molokai'
let g:airline_powerline_fonts = 1
let g:airline_inactive_collapse=0
" let g:airline_section_y=''


let g:airline#extensions#virtualenv#enabled = 1
"let g:airline_exclude_preview = 1
"let g:airline_left_sep=''
"let g:airline_right_sep=''
"let g:airline_section_z=''
"let g:airline#extensions#tabline#left_sep = ' '
"let g:airline#extensions#tabline#left_alt_sep = '|'

set laststatus=2
set statusline=%02n:%m\ %f\ -\ Filetype:%Y
set statusline+=\ %#goStatuslineColor#
set statusline+=%{go#statusline#Show()}
set statusline+=%*
set statusline+=%=%l/%L\ %P
set cmdheight=2

" Arrows disable {{{
inoremap jj <esc>
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

"noremap j gj
"noremap k gk


" noremap <C-n> :cnext<CR>
" noremap <C-m> :cprevious<CR>
" nnoremap <leader>a :cclose<CR>

" nnoremap <c-u> viwU<esc>
" inoremap <c-u> <esc>viwui
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

nnoremap <silent> <C-n> :NERDTreeToggle<CR>
nnoremap <silent> <F4> :NERDTreeFind<CR>

nnoremap <leader>' viW<esc>a'<esc>hBi'<esc>lel
nnoremap <leader>" viW<esc>a"<esc>hBi"<esc>lel
vnoremap <leader>" <esc>`<i"<esc>`>la"<esc>
vnoremap <leader>' <esc>`<i'<esc>`>la'<esc>

" Use ,d (or ,dd or ,dj or 20,dd) to delete a line without adding it to the
" yanked stack (also, in visual mode)
nnoremap <silent> <leader>d "_d
vnoremap <silent> <leader>d "_d
nnoremap <silent> <leader>x "_x
vnoremap <silent> <leader>x "_x

iabbrev @@ stammru@gmail.com

if executable('ag')
	" let g:ackprg = 'ag --vimgrep'
" Use ag over grep
	set grepprg=ag\ --nogroup\ --nocolor

	" Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
	let g:ctrlp_user_command = 'ag %s --skip-vcs-ignores -l --nocolor -g ""'

	" ag is fast enough that CtrlP doesn't need to cache
	let g:ctrlp_use_caching = 0
endif

nnoremap <NUL> :CtrlPBuffer<cr>
nnoremap <space><space> <c-^>

" let g:ctrlp_cmd = 'CtrlPMixed'
let g:ctrlp_extensions = ['tag']
let g:ctrlp_working_path_mode = 'ra'
let g:ctrlp_buftag_types = {'go': '--languages=Go -R --exclude=vendor .'}
" let g:ctrlp_reuse_window = 'NERD_tree_2'
let g:ctrlp_prompt_mappings = {
    \ 'AcceptSelection("e")': ['<cr>', '<c-y>', '<2-LeftMouse>'],
    \ 'CreateNewFile()':      []
    \ }
" Set this to 1 to show only MRU files in the current working directory: >
let g:ctrlp_mruf_relative = 1
let g:ctrlp_open_single_match   = ['related', 'tags']
let g:ctrlp_by_filename = 1

let g:grepper = {
  \ 'tools': ['ag', 'rg'],
  \ 'ag': {
  \   'grepprg': 'ag -U --vimgrep --nogroup --nocolor',
  \ }}

" cnoreabbrev Ack Ack!
" nnoremap <leader>a :Ack!
" nnoremap <leader>a :Ack!
"nnoremap <leader>fw :Ack! "\b<cword>\b"<CR>
" nnoremap <leader>fnt :Ack! "\b<cword>\b" --ignore="*_test.go"<CR>

nnoremap <silent> <leader>f :set operatorfunc=<SID>AckOperator<cr>g@
vnoremap <silent> <leader>f :<c-u>call <SID>AckOperator(visualmode())<cr>

function! s:AckOperator(type)
	let saved_unnamed_register = @@
	if a:type ==# 'v'
		normal! `<v`>y
	elseif a:type ==# 'char'
		normal! `[v`]y
	else
		return
	endif

	execute "Grepper -nojump -tool ag -open -query " . shellescape("\\b" . @@ . "\\b")
	copen

	let @@ = saved_unnamed_register
endfunction

nnoremap <silent> <leader>cq :ccl<cr> " close quickfix
nnoremap <silent> <leader>oq :cope<cr> " open quickfix

"nnoremap <silent> <leader>cl :lcl<cr> " close locationlist
"nnoremap <silent> <leader>ol :lope<cr> " open locationlist

au FocusLost * :wa

let g:go_fmt_command = "goimports"
"let g:go_highlight_types = 1
" let g:go_highlight_fields = 1
"let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
"  let g:go_highlight_operators = 1
let g:go_metalinter_autosave = 0
" let g:go_auto_type_info = 1
" let g:go_auto_sameids = 1
" let g:go_list_type = "quickfix"
let g:go_list_type = "locationlist"
" let g:go_metalinter_autosave_enabled = ['vet', 'golint', 'errcheck']
let g:go_metalinter_autosave_enabled = ['vet', 'golint']
let g:go_gocode_unimported_packages = 1
let g:go_echo_command_info = 0
let g:go_info_mode = 'guru'
" Go file settings ---------------------- {{{
augroup filetype_go
	autocmd BufNewFile,BufRead *.go setlocal nolist noexpandtab tabstop=2 shiftwidth=2 foldmethod=syntax foldlevel=99
	autocmd BufWritePost,BufNewFile,BufRead *.go Neomake
	autocmd FileType go nmap <leader>b  <Plug>(go-build)
	autocmd FileType go nmap <leader>r  <Plug>(go-run)
	autocmd FileType go nmap <leader>t  <Plug>(go-test)
	autocmd FileType go nmap <leader>c  <Plug>(go-coverage-toggle)
	autocmd FileType go nmap <leader>im  <Plug>(go-imports)
	autocmd FileType go nmap <leader>l  <Plug>(go-metalinter)
	autocmd FileType go nmap <Leader>i <Plug>(go-info)
	" autocmd FileType go nmap <leader>b :<C-u>call <SID>build_go_files()<CR>
	autocmd FileType go nnoremap <silent> <Leader>mb :execute "make build"<CR>
augroup END
" }}}

" Vimscript file settings ---------------------- {{{
augroup filetype_vim
	autocmd!
	autocmd FileType vim setlocal foldmethod=marker
augroup END
" }}}

au BufNewFile,BufRead glide.lock set filetype=yaml

let g:acp_enableAtStartup = 1
"let g:neocomplete#enable_at_startup = 1
"let g:neocomplete#enable_auto_select = 1
set completeopt-=preview
let g:ycm_min_num_of_chars_for_completion = 1
"" Recommended key-mappings.
"" <CR>: close popup and save indent.
"inoremap <silent> <CR> <C-r>=<SID>my_cr_function()<CR>
"function! s:my_cr_function()
"    return neocomplete#close_popup() . "\<CR>"
"endfunction
"" <TAB>: completion.
"inoremap <expr><TAB>  pumvisible() ? "\<C-n>" : "\<TAB>"

" run :GoBuild or :GoTestCompile based on the go file
function! s:build_go_files()
	let l:file = expand('%')
	if l:file =~# '^\f\+_test\.go$'
		call go#cmd#Test(0, 1)
	elseif l:file =~# '^\f\+\.go$'
		call go#cmd#Build(0)
	endif
endfunction

let g:neomake_open_list = 0
let g:neomake_go_checkers = ['go', 'golint', 'errcheck']
let g:neomake_make_maker = {
	\ 'exe': 'make',
	\ 'args': ['build'],
	\ 'errorformat': '%f:%l:%c: %m',
	\ }
let g:neomake_build_maker = { 'exe': 'make', 'args': ['lint'], 'errorformat': '[%tRROR]\ %f:[%l]\ %m,%-G%.%#' }

hi NeomakeErrorSign ctermfg=red

" let g:ycm_key_list_select_completion = ['<c-n>']
" let g:ycm_key_list_previous_completion = ['<c-p>']
let g:UltiSnipsExpandTrigger="<c-e>"
" let g:UltiSnipsJumpForwardTrigger="<c-b>"
" let g:UltiSnipsJumpBackwardTrigger="<c-z>"

" syntastic {{{
" set statusline+=%#warningmsg#
" set statusline+=%{SyntasticStatuslineFlag()}
" set statusline+=%*
"
" let g:syntastic_always_populate_loc_list = 1
" let g:syntastic_auto_loc_list = 0
" let g:syntastic_check_on_open = 1
" let g:syntastic_check_on_wq = 0
"
" let g:syntastic_go_checkers = ['go', 'golint', 'errcheck']
" }}}


