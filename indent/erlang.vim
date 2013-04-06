" Vim indent file
" Language:     Erlang
" Author:       Csaba Hoch <csaba.hoch@gmail.com>
" Contributors: Edwin Fine <efine145_nospam01 at usa dot net>
"               Pawel 'kTT' Salata <rockplayer.pl@gmail.com>
"               Ricardo Catalinas Jiménez <jimenezrick@gmail.com>
" License:      Vim license
" Version:      2011/09/06

" Only load this indent file when no other was loaded
if exists("b:did_indent")
    finish
else
    let b:did_indent = 1
endif

setlocal indentexpr=ErlangIndent()
setlocal indentkeys+==after,=end,=catch,=),=],=}

" Only define the functions once
if exists("*ErlangIndent")
    finish
endif

" The function goes through the whole line, analyses it and returns the
" indentation level.
"
" line: the line to be examined
" return: the indentation level of the examined line
function! s:ErlangIndentAfterLine(line)
    let linelen = strlen(a:line) " The length of the line
    let i = 0 " The index of the current character in the line
    let ind = 0 " How much should be the difference between the indentation of
                " the current line and the indentation of the next line?
                " e.g. +1: the indentation of the next line should be equal to
                " the indentation of the current line plus one shiftwidth
    let last_fun = 0 " The last token was a 'fun'
    let last_receive = 0 " The last token was a 'receive'; needed for 'after'
    let last_hash_sym = 0 " The last token was a '#'
    let last = ''

    " Ignore comments
    if a:line =~# '^\s*%'
        return 0
    endif

"    " Go to column 0 after a period
"    if a:line =~# '\.$'
"        return ['abs', 0]
"    endif

    " Partial function head where the guard is missing
    if a:line =~# "\\(^\\l[[:alnum:]_]*\\)\\|\\(^'[^']\\+'\\)(" &&
     \ a:line !~# '->'
        return 2
    endif

    " The missing guard from the split function head
    if a:line =~# '^\s*when\s\+.*->'
        return -1
    endif

    while 0 <= i && i < linelen
        " m: the next value of the i

        " String token: "..."
        if a:line[i] == '"'
            let m = matchend(a:line, '"\%([^"\\]\|\\.\)*"', i)
            let last_receive = 0

        " Atom token: '...'
        elseif a:line[i] == "'"
            let m = matchend(a:line, "'[^']*'",i)
            let last_receive = 0

        " Keyword or atom token
        elseif a:line[i] =~# "[a-z]"
            let m = matchend(a:line, "[[:alnum:]_]*", i + 1)
            if last_fun
                let ind -= 1
                let last_fun = 0
                let last_receive = 0
            elseif a:line[(i):(m - 1)] =~# '^\%(case\|if\|try\)$'
                let ind += 1
            elseif a:line[(i):(m - 1)] =~# '^receive$'
                let ind += 1
                let last_receive = 1
            elseif a:line[(i):(m-1)] =~# '^begin$'
                let ind = ind + 2
                let last_receive = 0
            elseif a:line[(i):(m - 1)] =~# '^end$'
                let ind = ind - 2
                let last_receive = 0
            elseif a:line[(i):(m - 1)] =~# '^after$'
                if last_receive == 0
                    let ind -= 1
                else
                    let ind = ind + 0
                endif
                let last_receive = 0
            elseif a:line[(i):(m - 1)] =~# '^fun$'
                let ind += 1
                let last_fun = 1
                let last_receive = 0
            endif

        " Variable token
        elseif a:line[i] =~# "[A-Z_]"
            let m = matchend(a:line, "[[:alnum:]_]*", i + 1)
            let last_receive = 0

        " Character token
        elseif a:line[i] == '$'
            let m = i + 2
            let last_receive = 0

        " Period token: .
        elseif a:line[i] == "." &&
             \ (i + 1 >= linelen || a:line[i + 1] !~# "[0-9]")
            let m = i + 1
            if last_hash_sym
                let last_hash_sym = 0
            else
                let last = 'period'
            endif
            let last_receive = 0

        " Arrow token: ->
        elseif a:line[i] == '-' && (i+1<linelen && a:line[i + 1] == '>')
            let m = i + 2
            let ind += 1
            let last_receive = 0

        " Semicolon token: ;
        elseif a:line[i] == ';' && a:line[(i):(linelen)] !~# '.*->.*'
            let m = i + 1
            let ind -= 1
            let last_receive = 0

        " Hash mark token: #
        elseif a:line[i] == '#'
            let m = i + 1
            let last_hash_sym = 1

        " Opening paren token: (, {, [
        elseif a:line[i] =~# '[({[]'
            let m = i + 1
            let ind += 1
            let last_fun = 0
            let last_receive = 0
            let last_hash_sym = 0

        " Closing paren token: ), }, ]
        elseif a:line[i] =~# '[)}\]]'
            let m = i + 1
            let ind -= 1
            let last_receive = 0

        " Other character
        else
            let m = i + 1
        endif

        let i = m
    endwhile

    if last == 'period'
        return ['abs', 0]
    else
        return ind
    endif
endfunction

function! s:FindPrevNonBlankNonComment(lnum)
    let lnum = prevnonblank(a:lnum)
    let line = getline(lnum)
    " Continue to search above if the current line begins with a '%'
    while line =~# '^\s*%.*$'
        let lnum = prevnonblank(lnum - 1)
        if 0 == lnum
            return 0
        endif
        let line = getline(lnum)
    endwhile
    return lnum
endfunction

" The function returns the indentation level of the line adjusted to a mutiple
" of 'shiftwidth' option.
"
" lnum: line number
" return: the indentation level of the line
function! s:GetLineIndent(lnum)
    return (indent(a:lnum) / &sw) * &sw
endfunction

function! ErlangIndent()
    " Find a non-blank line above the current line
    let lnum = prevnonblank(v:lnum - 1)

    " Hit the start of the file, use zero indent
    if lnum == 0
        return 0
    endif

    let prevline = getline(lnum)
    let currline = getline(v:lnum)

    let ind_after = s:ErlangIndentAfterLine(prevline)
    if type(ind_after) == type([])
        let [_abs, column] = ind_after
        return column
    elseif ind_after != 0
        let ind = s:GetLineIndent(lnum) + ind_after * &sw
    else
        let ind = indent(lnum) + ind_after * &sw
    endif

    " Special cases:
    if prevline =~# '^\s*\%(after\|end\)\>'
        let ind = ind + 2*&sw
    endif
    if currline =~# '^\s*end\>'
        let ind = ind - 2*&sw
    endif
    if currline =~# '^\s*after\>'
        let plnum = s:FindPrevNonBlankNonComment(v:lnum - 1)
        if getline(plnum) =~# '^[^%]*\<receive\>\s*\%(%.*\)\=$'
            " If the 'receive' is not in the same line as the 'after'
            let ind -= &sw
        else
            let ind -= 2 * &sw
        endif
    endif
    if prevline =~# '^\s*[)}\]]'
        let ind += &sw
    endif
    if currline =~# '^\s*[)}\]]'
        let ind -= &sw
    endif
    if prevline =~# '^\s*\%(catch\)\s*\%(%\|$\)'
        let ind += &sw
    endif
    if currline =~# '^\s*\%(catch\)\s*\%(%\|$\)'
        let ind -= &sw
    endif

    if ind < 0
        let ind = 0
    endif
    return ind
endfunction
