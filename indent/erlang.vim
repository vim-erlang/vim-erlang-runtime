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
function! s:ErlangAnalyzeLine(line)
    let linelen = strlen(a:line) " The length of the line
    let i = 0 " The index of the current character in the line
    let ind = 0 " How much should be the difference between the indentation of
                " the current line and the indentation of the next line?
                " e.g. +1: the indentation of the next line should be equal to
                " the indentation of the current line plus one shiftwidth
    let last_fun = 0 " The last token was a 'fun'

    " The last analyzed token. Possibilities:
    " - 'receive': used by the line containing 'after' in case of a
    "   receive-after structure with no branches.
    " - 'end_of_clause': used to indent the line after the end of a clause
    "   (marked by a period) to column 1.
    let last_token = 'none'

    " Partial function head where the guard is missing
    if a:line =~# "\\(^\\l[[:alnum:]_]*\\)\\|\\(^'[^']\\+'\\)(" &&
     \ a:line !~# '->'
        return ['rel', 2, '']
    endif

    " The missing guard from the split function head
    if a:line =~# '^\s*when\s\+.*->'
        return ['rel', -1, '']
    endif

    while 0 <= i && i < linelen
        " m: the next value of the i

        let prev_token = last_token
        let last_token = ''

        " Blanks
        if a:line[i] =~# '\s'
            let m = matchend(a:line, '\s*', i + 1)
            let last_token = prev_token

        " Comment
        elseif a:line[i] == '%'
            let m = linelen
            let last_token = prev_token

        " String token: "..."
        elseif a:line[i] == '"'
            let m = matchend(a:line, '"\%([^"\\]\|\\.\)*"', i)

        " Atom token: '...'
        elseif a:line[i] == "'"
            let m = matchend(a:line, "'[^']*'",i)

        " Keyword or atom token
        elseif a:line[i] =~# "[a-z]"
            let m = matchend(a:line, "[[:alnum:]_@]*", i + 1)
            if last_fun
                let ind -= 1
                let last_fun = 0
            elseif a:line[(i):(m - 1)] =~# '^\%(case\|if\|try\)$'
                let ind += 1
            elseif a:line[(i):(m - 1)] =~# '^receive$'
                let ind += 1
                let last_token = 'receive'
            elseif a:line[(i):(m-1)] =~# '^begin$'
                let ind = ind + 2
            elseif a:line[(i):(m - 1)] =~# '^end$'
                let ind = ind - 2
            elseif a:line[(i):(m - 1)] =~# '^after$'
                if prev_token == 'receive'
                    let ind = ind + 0
                else
                    let ind -= 1
                endif
            elseif a:line[(i):(m - 1)] =~# '^fun$'
                let ind += 1
                let last_fun = 1
            endif

        " Variable token
        elseif a:line[i] =~# "[A-Z_]"
            let m = matchend(a:line, "[[:alnum:]_@]*", i + 1)

        " Character token: $<char> (as in: $a)
        elseif a:line[i] == '$'
            let m = i + 2

        " Period token: .
        elseif a:line[i] == "."
            
            let m = i + 1

            " Period token (end of clause): . (as in: f() -> ok.)
            if i + 1 == linelen || a:line[i + 1] =~# '[[:blank:]%]'
                let last_token = 'end_of_clause'
                let ind = 0
            endif

            " Other possibilities:
            " - Period token in float: . (as in: 3.14)
            " - Period token in record: . (as in: #myrec.myfield)

        " Arrow token: ->
        elseif a:line[i] == '-' && (i + 1 < linelen && a:line[i + 1] == '>')
            let m = i + 2
            let ind += 1

        " Semicolon token: ;
        elseif a:line[i] == ';' && a:line[(i):(linelen)] !~# '.*->.*'
            let m = i + 1
            let ind -= 1

        " Hash mark token: #
        elseif a:line[i] == '#'
            let m = i + 1

        " Opening paren token: (, {, [
        elseif a:line[i] =~# '[({[]'
            let m = i + 1
            let ind += 1
            let last_fun = 0

        " Closing paren token: ), }, ]
        elseif a:line[i] =~# '[)}\]]'
            let m = i + 1
            let ind -= 1

        " Other character
        else
            let m = i + 1
        endif

        let i = m
    endwhile

    if last_token == 'end_of_clause'
        return ['abs', 0, 'end_of_clause']
    else
        return ['rel', ind, last_token]
    endif
endfunction

function! s:AnalyzePrevNonBlankNonComment(lnum)
    let lnum = a:lnum
    while 1
        let lnum = prevnonblank(lnum)
        if 0 == lnum
            return [0, 'abs', 0, 'beginning_of_file']
        endif
        let line = getline(lnum)
        let [absrel, ind_after, last_token] = s:ErlangAnalyzeLine(line)
        if last_token != 'none'
            return [lnum, absrel, ind_after, last_token]
        endif
        let lnum -= 1
    endwhile
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

    let [absrel, ind_after, last_token] = s:ErlangAnalyzeLine(prevline)
    if absrel == 'abs'
        return ind_after
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
        let [plnum, absrel, ind_after, last_token] =
          \ s:AnalyzePrevNonBlankNonComment(v:lnum - 1)
       if last_token == 'receive'
            " If we have a 'receive-after' structure without a branch, and the
            " 'receive' is not in the same line as the 'after'
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
