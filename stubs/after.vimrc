" Colorscheme
syntax enable
set background=dark
colorscheme solarized

" restore_view.vim configs
set viewoptions=cursor,folds,slash,unix
" let g:skipview_files = ['*\.vim']

if !exists('g:airline_symbols')
  let g:airline_symbols = {}
endif

" restore_view.vim configs
set viewoptions=cursor,folds,slash,unix
" let g:skipview_files = ['*\.vim']

" air-line
let g:airline_powerline_fonts = 1

if !exists('g:airline_symbols')
    let g:airline_symbols = {}
endif

" unicode symbols
let g:airline_left_sep = '»'
let g:airline_left_sep = '▶'
let g:airline_right_sep = '«'
let g:airline_right_sep = '◀'
let g:airline_symbols.linenr = '␊'
let g:airline_symbols.linenr = '␤'
let g:airline_symbols.linenr = '¶'
let g:airline_symbols.branch = '⎇'
let g:airline_symbols.paste = 'ρ'
let g:airline_symbols.paste = 'Þ'
let g:airline_symbols.paste = '∥'
let g:airline_symbols.whitespace = 'Ξ'

" airline symbols
let g:airline_left_sep = ''
let g:airline_left_alt_sep = ''
let g:airline_right_sep = ''
let g:airline_right_alt_sep = ''
let g:airline_symbols.branch = ''
let g:airline_symbols.readonly = ''
let g:airline_symbols.linenr = ''

" Map arrow keys
nmap <Left> <Left>
nmap <Right> <Right>
nmap <Up> <Up>
nmap <Down> <Down>

if &term == "xterm-ipad"
  nnoremap <Tab> <Esc>
  vnoremap <Tab> <Esc>gV
  onoremap <Tab> <Esc>
  inoremap <Tab> <Esc>\`^
  inoremap <Leader><Tab> <Tab>
endif
