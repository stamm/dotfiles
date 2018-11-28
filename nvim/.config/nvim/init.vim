call plug#begin('~/.config/nvim/plugged/')
"	Plug 'majutsushi/tagbar'
	Plug 'ervandew/supertab'
	" Plug 'garyburd/go-explorer'
	"Plug 'Shougo/neocomplete.vim'
	if has('nvim')
		Plug 'autozimu/LanguageClient-neovim', {
    \ 'branch': 'next',
    \ 'do': 'bash install.sh',
    \ }
		Plug 'Shougo/deoplete.nvim', { 'tag': '*', 'do': ':UpdateRemotePlugins' }
		Plug 'zchee/deoplete-go', { 'do': 'make'}
	else
		Plug 'Valloric/YouCompleteMe'
	endif
	Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
	", { 'tag': '*' }
	" Plug 'AndrewRadev/splitjoin.vim'
	Plug 'SirVer/ultisnips', { 'tag': '*' }
	Plug 'fatih/molokai'
	Plug 'ctrlpvim/ctrlp.vim', { 'tag': '*' }
	Plug '/usr/local/opt/fzf'
	Plug 'junegunn/fzf.vim'
	" Plug 'mileszs/ack.vim'
	Plug 'scrooloose/nerdtree'
	" Plug 'vim-ctrlspace/vim-ctrlspace'
	Plug 'tpope/vim-fugitive'
	Plug 'w0rp/ale'
	Plug 'bling/vim-airline'
	Plug 'vim-airline/vim-airline-themes'
	Plug 'tpope/vim-commentary'
	Plug 'mhinz/vim-grepper'
	Plug 'airblade/vim-gitgutter'
	Plug 'MattesGroeger/vim-bookmarks'

	" if has('nvim')
	" 	Plug 'autozimu/LanguageClient-neovim', { 'do': ':UpdateRemotePlugins' }
	" endif
	" Plug 'tjdevries/nvim-langserver-shim'
	" Plug 'Shougo/echodoc.vim'
	" Plug 'christoomey/vim-tmux-navigator'
	"

	Plug 'vim-ruby/vim-ruby'
	Plug 'tpope/vim-bundler'
	Plug 'artur-shaik/vim-javacomplete2'
call plug#end()

" let g:python2_host_prog = '/usr/local/bin/python'
let g:python2_host_prog = '/usr/bin/python'
let g:python3_host_prog = '/usr/local/bin/python3'
" Skip the check of neovim module
let g:python3_host_skip_check = 1



if has('nvim')
	set mouse=""
else
	set nocompatible
	set ttyfast
	set autoindent    " always set autoindenting on
	set backspace=indent,eol,start " allow backspacing over everything in insert mode
	set history=1000         " remember more commands and search history
	set hlsearch      " highlight search terms
	set incsearch     " show search matches as you type
	set laststatus=2
	set listchars=tab:▸\ ,trail:·,extends:#,nbsp:·,eol:¬
	set smarttab      " insert tabs on the start of a line according to shiftwidth, not tabstop
	set wildmenu                    " make tab completion for files/buffers act like bash
endif
set undodir=~/.config/nvim/.undo

" Color schema {{{
let g:rehash256 = 1
" let g:molokai_original = 1
colorscheme molokai
" }}}

let mapleader = ","
let maplocalleader = ",,"

" nnoremap : ;
" nnoremap ; :

nnoremap <silent> <leader>ev :e $MYVIMRC<cr>
nnoremap <silent> <leader>sv :source $MYVIMRC<cr>

set showmode       " always show what mode we're currently editing in
set relativenumber
set number         " Show line numbers
set cursorline
set nocursorcolumn           " speed up syntax highlighting
set lazyredraw          " Wait to redraw
set autowrite       " Automatically save before :next, :make etc.
" set wrap
se wrap linebreak
se colorcolumn=120
set ruler
set exrc " enable autoload .vimrc in current project
set secure " Disable autocmd when autoload

set hidden
set tabstop=2
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
set clipboard=unnamed
" set clipboard^=unnamedplus

set autoread                    " automatically reload files changed outside of Vim


set undolevels=1000      " use many muchos levels of undo
set undofile
set nobackup             " Don't create annoying backup files
" set noswapfile           " Don't use swapfile
set dir=~/.config/nvim/.swapfiles//

set wildmode=list:full          " show a list when pressing tab and complete

set wildignore=*.swp,*.bak,*.pyc,*.class
set title                " change the terminal's title
set visualbell           " don't beep
set noerrorbells         " don't beep
set showcmd              " Show me what I'm typing
set splitright               " Split vertical windows right to the current windows
set splitbelow               " Split horizontal windows below to the current windows

set list

set pastetoggle=<F2>
set diffopt+=vertical    " Always use vertical diffs

set maxmempattern=100000


let g:airline#extensions#tabline#enabled = 0
let g:airline_theme             = 'molokai'
let g:airline_powerline_fonts = 1
let g:airline_inactive_collapse=1


let g:airline#extensions#virtualenv#enabled = 0

" let g:airline_section_x = '%#goStatuslineColor#%{go#statusline#Show()}%*'
let g:airline_section_y = '%{go#statusline#Show()}'
if !exists('g:airline_symbols')
	let g:airline_symbols = {}
endif
let g:airline_symbols.linenr = ''
let g:airline_symbols.maxlinenr = ''

set cmdheight=2

" Arrows disable {{{
inoremap jj <esc>
" inoremap <esc> <nop>
noremap <Up> <nop>
noremap <Left> <nop>
noremap <Right> <nop>
noremap <Down> <nop>
inoremap <Up> <nop>
inoremap <Left> <nop>
inoremap <Right> <nop>
inoremap <Down> <nop>
" }}}


nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
" Move line(s) of text using Alt+j/k
"set termencoding=latin1
nnoremap <silent> <A-j> :m+<CR>==
nnoremap <silent> <A-k> :m-2<CR>==
inoremap <silent> <A-j> <Esc>:m+<CR>==gi
inoremap <silent> <A-k> <Esc>:m-2<CR>==gi
vnoremap <silent> <A-j> :m'>+<CR>gv=gv
vnoremap <silent> <A-k> :m-2<CR>gv=gv

nnoremap <leader>w :wa<CR>

" let g:tmux_navigator_no_mappings = 1

" nnoremap <silent> <C-h> :TmuxNavigateLeft<cr>
" nnoremap <silent> <C-j> :TmuxNavigateDown<cr>
" nnoremap <silent> <C-k> :TmuxNavigateUp<cr>
" nnoremap <silent> <C-l> :TmuxNavigateRight<cr>
" nnoremap <silent> {Previous-Mapping} :TmuxNavigatePrevious<cr>

nnoremap <silent> <C-n> :NERDTreeToggle<CR>
nnoremap <silent> <C-s> :NERDTreeFind<CR>
let NERDTreeShowHidden=1
let NERDTreeMapJumpNextSibling = ''
let NERDTreeMapJumpPrevSibling = ''
let NERDTreeAutoDeleteBuffer = 1
let NERDTreeIgnore=['\.git$[[dir]]', '\.idea$[[dir]]', '\.DS_Store$']
let NERDTreeMinimalUI=1

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
xnoremap <leader>p "_dP

iabbrev @@ stammru@gmail.com

if executable('ag')
" Use ag over grep
	set grepprg=ag\ --vimgrep

	" Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
	let g:ctrlp_user_command = 'ag %s --skip-vcs-ignores -l --nocolor -g ""'
endif

" if executable('rg')
" 	set grepprg=rg\ --color=never

" 	let g:ctrlp_user_command = 'rg %s --no-ignore-vcs --files --color=never -g ""'
" endif

if has('nvim')
	nnoremap <silent> <C-Space> :CtrlPBuffer<cr>
else
	nnoremap <silent> <NUL> :CtrlPBuffer<cr>
endif
nnoremap <space><space> <c-^>

let g:ctrlp_cmd = 'CtrlPMixed'
" let g:ctrlp_cmd = 'CtrlPMRU'
let g:ctrlp_working_path_mode = 'ra'
let g:ctrlp_extensions = ['tag']
let g:ctrlp_buftag_types = {'go': '--languages=Go -R --exclude=vendor --exclude=static .'}
" let g:ctrlp_buftag_types = {'go' : '--language-force=go --golang-types=ftv'}
" let g:ctrlp_reuse_window = 'NERD_tree_2'
let g:ctrlp_prompt_mappings = {
	\ 'AcceptSelection("e")': ['<cr>', '<c-y>', '<2-LeftMouse>'],
	\ 'CreateNewFile()':      []
	\ }
" Set this to 1 to show only MRU files in the current working directory: >
let g:ctrlp_mruf_relative = 1
let g:ctrlp_open_single_match = ['related', 'tags']
" let g:ctrlp_by_filename = 1
let g:ctrlp_use_caching = 1
let g:ctrlp_clear_cache_on_exit = 0
let g:ctrlp_mruf_max=450    " number of recent/y opened files
let g:ctrlp_max_files=0     " do not limit the number of searchable files


let g:grepper = {
	\ 'tools': ['ag', 'rg'],
	\ 'rg': {
	\ 'grepprg': 'rg --no-ignore-vcs --no-heading --color=never --line-number --column --sort-files',
	\ },
	\ 'ag': {
	\   'grepprg': 'ag -U --vimgrep --nogroup --nocolor',
	\ }}
" let g:grepper.prompt = 0

nnoremap <silent> <leader>f :set operatorfunc=<SID>AckOperator<Enter>g@
vnoremap <silent> <leader>f :<c-u>call <SID>AckOperator(visualmode())<Enter>

nnoremap <leader>f* :Grepper -cword -noprompt<Enter>
nnoremap <leader>fnv* :Grepper -cword -noprompt -grepprg ag -U --vimgrep --nogroup --nocolor --ignore './vendor/'<Enter>
nnoremap <leader>fnvt* :Grepper -cword -noprompt -grepprg ag -U --vimgrep --nogroup --nocolor --ignore './vendor/' --ignore '*_test.go'<Enter>

nnoremap <silent> <leader>ff :Grepper<Enter>
nnoremap <silent> <leader>ft :Grepper -grepprg ag -U --vimgrep --nogroup --nocolor -G '*_test.go'<Enter>
nnoremap <silent> <leader>fnt :Grepper -grepprg ag -U --vimgrep --nogroup --nocolor --ignore '*_test.go'<Enter>
nnoremap <silent> <leader>fnv :Grepper -grepprg ag -U --vimgrep --nogroup --nocolor --ignore './vendor/'<Enter>
nnoremap <silent> <leader>fnvt :Grepper -grepprg ag -U --vimgrep --nogroup --nocolor --ignore './vendor/' --ignore '*_test.go'<Enter>

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
	" execute "Grepper -nojump -tool rg -open -query " . shellescape(@@)
	copen

	let @@ = saved_unnamed_register
endfunction

nnoremap <silent> <leader>cq :ccl<cr> " close quickfix
nnoremap <silent> <leader>oq :cope<cr> " open quickfix

nnoremap <silent> <leader>cl :lcl<cr> " close locationlist
nnoremap <silent> <leader>ol :lope<cr> " open locationlist

au FocusLost * :wa

let g:go_fmt_command = "goimports"
" let g:go_fmt_options = " -local=godep.lzd.co"
let g:go_highlight_types = 1
" let g:go_highlight_fields = 1
"let g:go_highlight_functions = 1
let g:go_highlight_methods = 1
let g:go_highlight_operators = 1
let g:go_metalinter_autosave = 0
" let g:go_auto_type_info = 1
" let g:go_auto_sameids = 1
" let g:go_list_type = "quickfix"
let g:go_list_type = "locationlist"
let g:go_gocode_unimported_packages = 1
let g:go_echo_command_info = 0
let g:go_info_mode = 'gocode'
let g:go_def_mode = 'godef'
" Go file settings ---------------------- {{{
augroup filetype_go
	au!
	autocmd BufNewFile,BufRead *.go setlocal noexpandtab tabstop=2 shiftwidth=2 foldmethod=syntax foldlevel=99
	autocmd BufNewFile,BufRead *.go setfiletype go
	" autocmd FileType go nmap <leader>gb  <Plug>(go-build)
	" autocmd FileType go nmap <leader>gr  <Plug>(go-run)
	autocmd FileType go nmap <leader>gt  <Plug>(go-test)
	autocmd FileType go nmap <leader>gc  <Plug>(go-coverage-toggle)
	" autocmd FileType go nmap <leader>gim  <Plug>(go-imports)
	" autocmd FileType go nmap <leader>gl  <Plug>(go-metalinter)
	autocmd FileType go nmap <Leader>gi <Plug>(go-info)
	" autocmd FileType go nmap <leader>b :<C-u>call <SID>build_go_files()<CR>
	autocmd FileType go nnoremap <silent> <Leader>mb :execute "make build"<CR>
	autocmd Filetype go command! -bang A call go#alternate#Switch(<bang>0, 'edit')

	autocmd BufNewFile,BufRead glide.lock set filetype=yaml
	autocmd BufEnter glide.yaml command! -bang A edit glide.lock
	autocmd BufEnter glide.lock command! -bang A edit glide.yaml
	autocmd BufEnter Gopkg.toml command! -bang A edit Gopkg.lock
	autocmd BufEnter Gopkg.lock command! -bang A edit Gopkg.toml

	autocmd BufNewFile,BufRead _helpers.tpl setlocal expandtab tabstop=2 shiftwidth=2 foldmethod=syntax foldlevel=99
augroup END
" }}}

" Vimscript file settings ---------------------- {{{
augroup filetype_vim
	au!
	autocmd FileType vim setlocal foldmethod=marker
augroup END
" }}}


set completeopt-=preview
set completeopt+=noinsert
" deoplete.nvim recommend
set completeopt+=noselect
if has('nvim')
	let g:deoplete#enable_at_startup = 1
	let g:deoplete#auto_complete_start_length = 2
	let g:deoplete#ignore_sources = {}
	let g:deoplete#ignore_sources._ = ['buffer', 'member', 'tag', 'file', 'neosnippet']
	let g:deoplete#sources#go#sort_class = ['package', 'func', 'type', 'var', 'const']
	let g:deoplete#sources#go#align_class = 1
	let g:deoplete#sources#go#package_dot = 1
	" call deoplete#enable_logging('DEBUG', '/tmp/deoplete.log')
	" let g:deoplete#sources#go#gocode_binary = $GOPATH.'/bin/gocode_old'

	" Use partial fuzzy matches like YouCompleteMe
	call deoplete#custom#source('_', 'matchers', ['matcher_fuzzy'])
	call deoplete#custom#source('_', 'converters', ['converter_remove_paren'])
	call deoplete#custom#source('_', 'disabled_syntaxes', ['Comment', 'String'])
else
	let g:ycm_min_num_of_chars_for_completion = 1
endif

" run :GoBuild or :GoTestCompile based on the go file
function! s:build_go_files()
	let l:file = expand('%')
	if l:file =~# '^\f\+_test\.go$'
		call go#cmd#Test(0, 1)
	elseif l:file =~# '^\f\+\.go$'
		call go#cmd#Build(0)
	endif
endfunction

" Ale {{{
" let g:ale_set_highlights = 0
let g:airline#extensions#ale#enabled = 1
" }}}

" UltiSnips {{{
let g:UltiSnipsExpandTrigger = "<c-e>"
let g:UltiSnipsJumpForwardTrigger = "<tab>"
let g:UltiSnipsJumpBackwardTrigger = "<s-tab>"
let g:UltiSnipsUsePythonVersion = 3

" if has('nvim')
" 	let g:UltiSnipsExpandTrigger="<tab>"
" 	function! g:UltiSnips_Complete()
" 		call UltiSnips#ExpandSnippet()
" 		if g:ulti_expand_res == 0
" 			if pumvisible()
" 				return "\<C-n>"
" 			else
" 				call UltiSnips#JumpForwards()
" 				if g:ulti_jump_forwards_res == 0
" 					return "\<TAB>"
" 				endif
" 			endif
" 		endif
" 		return ""
" 	endfunction

" 	function! g:UltiSnips_Reverse()
" 		call UltiSnips#JumpBackwards()
" 		if g:ulti_jump_backwards_res == 0
" 			return "\<C-P>"
" 		endif

" 		return ""
" 	endfunction

" 	if !exists("g:UltiSnipsJumpForwardTrigger")
" 		let g:UltiSnipsJumpForwardTrigger = "<tab>"
" 	endif

" 	if !exists("g:UltiSnipsJumpBackwardTrigger")
" 		let g:UltiSnipsJumpBackwardTrigger="<s-tab>"
" 	endif


" 	au InsertEnter * exec "inoremap <silent> " . g:UltiSnipsExpandTrigger . " <C-R>=g:UltiSnips_Complete()<cr>"
" 	au InsertEnter * exec "inoremap <silent> " . g:UltiSnipsJumpBackwardTrigger . " <C-R>=g:UltiSnips_Reverse()<cr>"
" else
" 	let g:UltiSnipsExpandTrigger="<c-e>"
" 	let g:UltiSnipsJumpForwardTrigger="<c-b>"
" 	let g:UltiSnipsJumpBackwardTrigger="<c-z>"
" endif
" }}}

" bookmarks {{{
" let g:bookmark_save_per_working_dir = 1
let g:bookmark_auto_close = 0
let g:bookmark_no_default_key_mappings = 1
nmap <Leader>mm <Plug>BookmarkToggle
nmap <Leader>ma <Plug>BookmarkShowAll
" }}}


" Ruby {{{
augroup filetype_ruby
	au!
	autocmd BufNewFile,BufRead *.rb,*.pp,Gemfile,Guardfile,Rakefile,rspec setlocal expandtab tabstop=2 shiftwidth=2 foldmethod=syntax foldlevel=99
	autocmd BufNewFile,BufRead *rb,*.pp,Gemfile,Guardfile,Rakefile,rspec setfiletype ruby
augroup END
" }}}


" Java {{{
augroup filetype_java
	au!
	autocmd FileType java setlocal omnifunc=javacomplete#Complete
augroup END
" }}}
"
" Show trailing whitespace and spaces before a tab:
highlight ExtraWhitespace ctermbg=red guibg=red
autocmd Syntax * syn match ExtraWhitespace /\s\+$\| \+\ze\\t/
