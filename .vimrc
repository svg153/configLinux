" Used to avoid side effects with plugins
set nocompatible

" ~/.vimrc (configuration file for vim only)
" skeletons
function! SKEL_spec()
	0r /usr/share/vim/current/skeletons/skeleton.spec
	language time en_US
	let login = system('whoami')
	if v:shell_error
	   let login = 'unknown'
	else
	   let newline = stridx(login, "\n")
	   if newline != -1
		let login = strpart(login, 0, newline)
	   endif
	endif
	let hostname = system('hostname -f')
	if v:shell_error
	    let hostname = 'localhost'
	else
	    let newline = stridx(hostname, "\n")
	    if newline != -1
		let hostname = strpart(hostname, 0, newline)
	    endif
	endif
	exe "%s/specRPM_CREATION_DATE/" . strftime("%a\ %b\ %d\ %Y") . "/ge"
	exe "%s/specRPM_CREATION_AUTHOR_MAIL/" . login . "@" . hostname . "/ge"
	exe "%s/specRPM_CREATION_NAME/" . expand("%:t:r") . "/ge"
endfunction
autocmd BufNewFile	*.spec	call SKEL_spec()

:set hlsearch

let mapleader="\º"

" set UTF-8 encoding
set enc=utf-8
set fenc=utf-8
set termencoding=utf-8

" use indentation of previous line
set autoindent

" use intelligent indentation for C
set smartindent

" configure tabwidth and insert spaces instead of tabs
set tabstop=2        " tab width is 2 spaces
set shiftwidth=2     " indent also with 2 spaces
set expandtab        " expand tabs to spaces

" wrap lines at 120 chars. 80 is somewaht antiquated with nowadays displays.
set textwidth=120

" turn syntax highlighting on
set t_Co=256
set background=dark
execute pathogen#infect()
syntax on
filetype plugin indent on

" Add spaces after comment delimiters by default
let g:NERDSpaceDelims = 1

" Add your own custom formats or override the defaults
let g:NERDCustomDelimiters = { 'c': { 'left': '/**','right': '*/' } }

map <C-n> :NERDTreeToggle<CR>

" colorscheme wombat256
" turn line numbers on
set number
" highlight matching braces
set showmatch
" intelligent comments
set comments=sl:/*,mb:\ *,elx:\ */

" Close current window
map <leader>qq :q<CR>
" Close all windows without savings
map <leader>qa :qa!<CR>

" Movement through buffers
map <F5> :bp<CR>
map <F6> :w<CR>
map <F7> :bd<CR>
map <F8> :bn<CR>

:set splitright
" Movement through windows
map <C-m> :split
map <S-m> :vsplit
map <C-left> <C-w>h
map <C-down> <C-w>j
map <C-up> <C-w>k
map <C-right> <C-w>l

" Install DoxygenToolkit from http://www.vim.org/scripts/script.php?script_id=987
let g:DoxygenToolkit_authorName="John Doe <john@doe.com>"


" Enhanced keyboard mappings
"
" 
" create doxygen comment
map <F10> :Dox<CR>
" build using makeprg with <F7>
set makeprg=/tmp/make_script
map <F12> :make <Bar> copen<CR>
" build using makeprg with <S-F7>
map <S-F12> :make clean_all<CR>

" Save file
map <F4> :w<CR>

":set paste
set pastetoggle=<F2>

":syntax enable
":set background=light
":set t_Co=256
":let g:solarized_termcolors=256
":let g:solarized_termtrans=1
"":color default
":color solarized
" ~/.vimrc ends here

command W :execute ':silent w !sudo tee % > /dev/null' | :edit!

