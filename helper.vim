if &ft != 'erlang'
    throw 'This helper script should be called only on an Erlang file!'
endif

" ----------- "
" Indentation "
" ----------- "

" Automatic comments are not always helpful for test.erl
setlocal fo-=ro

" Automatic indentkeys are not always helpful for developing the indentation
" script
setlocal indentkeys-==after,=end,=catch,=),=],=}

" Reread indentation file
noremap <buffer> <F1> :call RereadIndent()<cr>

" Indent the whole buffer
noremap <buffer> <F2> :call ClearDebugLog()<cr>mkHmlggvG=`lzt`k:call PrintDebugLog()<cr>

" Indent the current line
noremap <buffer> <F3> :call ClearDebugLog()<cr>==:call PrintDebugLog()<cr>

function! RereadIndent()
    delfunction ErlangIndent
    unlet b:did_indent
    so indent/erlang.vim
endfunction

" --------- "
" Debugging "
" --------- "

let g:debug_log = ''

function! Log(line)
    let g:debug_log .= a:line . "\n"
endfunction

function! Log2(line)
    let g:debug_log .= a:line
endfunction

function! ClearDebugLog()
    let g:debug_log = ''
endfunction

function! PrintDebugLog()
    echo g:debug_log
endfunction
