if &ft != 'erlang'
    throw 'This helper script should be called only on an Erlang file!'
endif

" ----------- "
" Indentation "
" ----------- "

" Automatic comments are not always helpful for test.erl
setlocal debug=msg,throw

" Automatic indentkeys are not always helpful for developing the indentation
" script
setlocal indentkeys-==after,=end,=catch,=),=],=}

" Reread indentation file
noremap <buffer> <F1> :call RereadIndent()<cr>

function! RereadIndent()
    if exists("*ErlangIndent")
        delfunction ErlangIndent
    endif
    unlet b:did_indent
    so indent/erlang.vim
endfunction

" Unit tests
noremap <buffer> <F2> :call TestErlangIndent()<cr>

" Indent the current line
noremap <buffer> <F3> :call IndentCurrentLinePerf()<cr>
noremap <buffer> <s-F3> :call IndentCurrentLineLog()<cr>

function! IndentCurrentLineLog()
    let g:hcs1 = exists("*ErlangIndentLog")
    call DefineErlangLog()
    let g:hcs2 = exists("*ErlangIndentLog")
    call ClearDebugLog()
    normal ==
    call PrintDebugLog()
endfunction

function! IndentCurrentLinePerf()
    call DeleteErlangLog()
    let start = reltime()
    normal ==
    echo "Execution time: " . reltimestr(reltime(start))
endfunction


" Indent the whole buffer
noremap <buffer> <F4> :call IndentCurrentBufferPerf()<cr>
noremap <buffer> <s-F4> :call IndentCurrentBufferLog()<cr>

function! IndentCurrentBufferLog()
    call DefineErlangLog()
    call ClearDebugLog()
    normal mkHmlggvG=`lzt`k
    call PrintDebugLog()
endfunction

function! IndentCurrentBufferPerf()
    call DeleteErlangLog()
    let start = reltime()
    normal mkHmlggvG=`lzt`k
    echo "Execution time: " . reltimestr(reltime(start))
endfunction

" Show tokens in current line
noremap <buffer> <F5> :call ErlangAnalyzeCurrentLine()<cr>

" --------- "
" Debugging "
" --------- "

let g:debug_log = ''

function! ClearDebugLog()
    let g:debug_log = ''
endfunction

function! PrintDebugLog()
    echo g:debug_log
endfunction

function! DefineErlangLog()
    function! ErlangIndentLog(line)
        let g:debug_log .= a:line . "\n"
    endfunction
endfunction

function! DeleteErlangLog()
    if exists("*ErlangIndentLog")
        delfunction ErlangIndentLog
    endif
endfunction
