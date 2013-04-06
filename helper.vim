noremap <buffer> <F1> :call RereadIndent()<cr>
noremap <buffer> <F2> mkHmlggvG=`lzt`k

function! RereadIndent()
    delfunction ErlangIndent
    unlet b:did_indent
    setlocal fo-=ro
    so indent/erlang.vim
endfunction

