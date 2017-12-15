let g:deoplete#enable_at_startup = 1
" let g:completor_gocode_binary = "/home/dmitry/go/bin/gocode" " is necessary
" let g:deoplete#sources#go#gocode_binary = "/home/dmitry/go/bin/gocode" " is necessary

call plug#begin('~/.vim/plugged')

Plug 'fatih/vim-go' " Amazing combination of features.

" Plug 'godoctor/godoctor.vim' " Some refactoring tools

if !has('nvim')
 Plug 'maralla/completor.vim' " or whichever you use
 Plug 'Shougo/vimproc.vim', {'do' : 'make'} " need for sebdah/vim-delve
 Plug 'Shougo/vimshell.vim' " need for sebdah/vim-delve
endif
if has('nvim')
 Plug 'Shougo/deoplete.nvim'
 " Plug 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' } " if not work command above, see CheckHealth
 Plug 'zchee/deoplete-go', { 'do': 'make'}
" Plug 'zchee/deoplete-go', {'build': {'unix': 'make'}} " if not work command above, see CheckHealth
" Plug 'jodosha/vim-godebug' " Debugger integration via delve, but not worked input dlv command
endif

Plug 'sebdah/vim-delve' "Debugger integration via delve

" All of your Plugs must be added before the following line
call plug#end()
