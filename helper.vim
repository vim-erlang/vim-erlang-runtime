" ----------- "
" Indentation "
" ----------- "

" Reread indentation file
noremap <buffer> <F1> :call RereadIndent()<cr>

" Indent the whole buffer
noremap <buffer> <F2> :call ClearDebugLog()<cr>mkHmlggvG=`lzt`k:call PrintDebugLog()<cr>

" Indent the current line
noremap <buffer> <F3> :call ClearDebugLog()<cr>==:call PrintDebugLog()<cr>

function! RereadIndent()
    delfunction ErlangIndent
    unlet b:did_indent
    setlocal fo-=ro
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
