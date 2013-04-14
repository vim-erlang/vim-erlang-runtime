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

" ---------------- "
"  Logging library "
" ---------------- "

function! s:Log(s)
    if exists("*ErlangIndentLog")
        call ErlangIndentLog(a:s)
    endif
endfunction

" ---------------- "
" Indtoken library "
" ---------------- "

" Indtokens are "indentation tokens". They are similar to lexical tokens, but
" they:
" - include virtual tokens that just increase or descrease the indentation;
"   and
" - omit lexical tokens that are not useful for indentation calculations.
"
" Types:
"
" indtoken = [tokentype, absrel, col, level]
" tokentype = string: see ErlangAnalyzeLine
" absrel = 'abs' | 'rel' | 'special'
" col = integer
" level = integer
"
" Examples:
"
" - {+2, 0} = ['x', 'rel', 2, 0]
" - {-4, 0} = ['x', 'rel', -4, 0]
" - {1, 0} = ['x', 'abs', 1, 0]

function! s:SetLevelInIndtokens(indtokens, level)
    let a:indtokens[3] = a:level
endfunction

function! s:GetTokentypeFromIndtokens(indtokens)
    return a:indtokens[0]
endfunction

" Add a new token, except if the both the previous and current tokens are
" absolute tokens and neither change the indentation level
function! s:AddIndToken(indtokens, tokentype, absrel, col, level)
    if !(len(a:indtokens) > 0 &&
     \   a:indtokens[-1][1] == 'abs' &&
     \   a:indtokens[-1][3] == 0 &&
     \   a:absrel == 'abs' &&
     \   a:level == 0)
        call add(a:indtokens, [a:tokentype, a:absrel, a:col, a:level])
    endif
endfunction

function! s:AddIndToken2(indtokens, tokentype, absrel, col, level)
    call add(a:indtokens, [a:tokentype, a:absrel, a:col, a:level])
endfunction

" -------------------------- "
" ErlangAnalyzeLine function "
" -------------------------- "

" The function goes through the whole line, analyses it and returns the
" indentation level.
"
" Types:
"
" line = string: the line to be examined
" first_token_of_next_line = indtoken
" result = integer: the indentation level of the examined line

function! s:ErlangAnalyzeLine(line, first_token_of_next_line)

    let linelen = strlen(a:line) " The length of the line
    let i = 0 " The index of the current character in the line
    let indtokens = []

    while 0 <= i && i < linelen

        " Blanks
        if a:line[i] =~# '\s'
            let next_i = matchend(a:line, '\s*', i + 1)

        " Comment
        elseif a:line[i] == '%'
            let next_i = linelen

        " String token: "..."
        elseif a:line[i] == '"'
            call s:AddIndToken(indtokens, 'string', 'abs', i, 0)
            let next_i = matchend(a:line, '"\%([^"\\]\|\\.\)*"', i)

        " Atom token: '...'
        elseif a:line[i] == "'"
            call s:AddIndToken(indtokens, 'atom_quote', 'abs', i, 0)
            let next_i = matchend(a:line, "'[^']*'",i)

        " Keyword or atom token
        elseif a:line[i] =~# "[a-z]"
            let next_i = matchend(a:line, "[[:alnum:]_@]*", i + 1)
            let word = a:line[(i):(next_i - 1)]

            if word == 'fun'
                call s:AddIndToken(indtokens, 'fun', 'abs', i, 0)

            elseif word =~# '^\%(begin\|case\|if\|try\|receive\)$'
                call s:AddIndToken(indtokens, word, 'abs', i, 1)
                call s:AddIndToken(indtokens, word, 'rel', &sw, 0)

            elseif word =~# '^\%(after\|of\|catch\)$'
                call s:AddIndToken(indtokens, word, 'rel', -&sw, 0)
                call s:AddIndToken(indtokens, word, 'abs', i, 0)
                call s:AddIndToken(indtokens, word, 'rel', &sw, 0)

            elseif word == 'end'
                call s:AddIndToken(indtokens, 'end', 'abs', i, -1)

            " Plain atom or function name
            else
                call s:AddIndToken(indtokens, 'atom_plain', 'abs', i, 0)
            endif

        " Variable token (as in: MyVariable)
        elseif a:line[i] =~# "[A-Z_]"
            call s:AddIndToken(indtokens, 'var', 'abs', i, 0)
            let next_i = matchend(a:line, "[[:alnum:]_@]*", i + 1)

        " Character token: $<char> (as in: $a)
        elseif a:line[i] == '$'
            call s:AddIndToken(indtokens, 'char', 'abs', i, 0)
            let next_i = i + 2

        " Dot token: .
        elseif a:line[i] == "."

            let next_i = i + 1
            " Dot token (end of clause): . (as in: f() -> ok.)
            if i + 1 == linelen || a:line[i + 1] =~# '[[:blank:]%]'
                call s:AddIndToken2(indtokens, 'end_of_clause', 'special', i, 0)
            else
                " Possibilities:
                " - Dot token in float: . (as in: 3.14)
                " - Dot token in record: . (as in: #myrec.myfield)
                call s:AddIndToken(indtokens, 'dot', 'abs', i, 0)
            endif

        " Arrow token: ->
        elseif a:line[i] == '-' && (i + 1 < linelen && a:line[i + 1] == '>')
            call s:AddIndToken(indtokens, 'arrow', 'abs', i, 0)
            call s:AddIndToken(indtokens, 'arrow', 'rel', &sw, 0)
            let next_i = i + 2

        " Semicolon token: ;
        elseif a:line[i] == ';' && a:line[(i):(linelen)] !~# '.*->.*'
            call s:AddIndToken(indtokens, ';', 'abs', i, 0)
            call s:AddIndToken(indtokens, ';', 'rel', -&sw, 0)
            let next_i = i + 1

        " Opening paren token: (
        elseif a:line[i] == '('

            " If the previous token was 'fun' and the current token is '(', then
            " we are at the definition of an anonymous function, so we should
            " increase the indent level. (If the current token is not '(',
            " then we just have a function reference like "fun f/0".)
            if len(indtokens) > 0 && s:GetTokentypeFromIndtokens(indtokens[-1]) == 'fun'
                call s:SetLevelInIndtokens(indtokens[-1], 1)
                call s:AddIndToken(indtokens, 'fun', 'rel', &sw, 0)
            endif

            call s:AddIndToken(indtokens, '(', 'abs', i, 1)
            call s:AddIndToken(indtokens, '(', 'rel', 2, 0)
            let next_i = i + 1
            let last_fun = 0

        " Closing paren token: )
        elseif a:line[i] == ')'
            call s:AddIndToken(indtokens, ')', 'rel', -2, 0)
            call s:AddIndToken(indtokens, ')', 'abs', i, -1)
            let next_i = i + 1

        " Opening bracket: {, [
        elseif a:line[i] =~# '[{[]'
            call s:AddIndToken(indtokens, 'open_bracket', 'abs', i, 1)
            call s:AddIndToken(indtokens, 'open_bracket', 'rel', &sw, 0)
            let next_i = i + 1
            let last_fun = 0

        " Closing bracket: }, ]
        elseif a:line[i] =~# '[}\]]'
            call s:AddIndToken(indtokens, 'close_bracket', 'abs', i, -1)
            let next_i = i + 1

        " Other character
        else
            call s:AddIndToken(indtokens, 'other', 'abs', i, 0)
            let next_i = i + 1
        endif

        let i = next_i
    endwhile

    if len(indtokens) != 0

        let last_token_type = s:GetTokentypeFromIndtokens(indtokens[-1])

        " If the last token of the current line is 'fun' and the first token
        " of the next line is '(', then we are at the definition of an
        " anonymous function, so we should increase the indent level. (If the
        " first token of the next line is not '(', then we just have a
        " function reference like "fun f/0".)
        if last_token_type == 'fun' &&
         \ len(a:first_token_of_next_line) > 0 &&
         \ s:GetTokentypeFromIndtokens(a:first_token_of_next_line) == '('
            call s:SetLevelInIndtokens(indtokens[-1], 1)
            call s:AddIndToken(indtokens, 'fun', 'rel', &sw, 0)
        endif
    endif

    return indtokens

endfunction

" ----------------- "
"  ErlangCalcIndent "
" ----------------- "

" Calculate the indentation of the given line.
"
" Types:
"
" lnum = integer: number of the line for which the indentation should be
"                 calculated
" level = integer: base level
" type = 'normal' | 'end'
"     // type == 'end' means that the matching begin/case/etc. should be found
"     // and the current line should be indented into the same column
" result = integer

function! s:ErlangCalcIndent(lnum, level, type)

    let lnum = a:lnum
    let level = a:level
    let abscol = -1
    let shift = 0
    let first_token_of_next_line = []

    " Walk through the lines of the buffer backwards (starting from the
    " previous line) until we can decide how to indent the current line.
    while 1

        let lnum = prevnonblank(lnum)

        " Hit the start of the file, use zero indent
        if lnum == 0
            return 0
        endif

        let line = getline(lnum)
        call s:Log('Analysing line ' . lnum . ': ' . line)

        let indtokens = s:ErlangAnalyzeLine(line, first_token_of_next_line)
        call s:Log("  Tokens in the line:\n    - " . join(indtokens, "\n    - "))
        if len(indtokens) > 0
            let first_token_of_next_line = indtokens[0]
        endif

        let i = len(indtokens) - 1

        while i >= 0
            let [token, absrel, curr_col, curr_level] = indtokens[i]
            call s:Log('  Analysing the following token: ' . join([indtokens[i]]))
            let level += curr_level
            call s:Log('  New level: ' . level)

            if token == 'end_of_clause'
                if abscol == -1
                    call s:Log('    End of clause at end of line, returning abscol 0')
                    return 0
                else
                    call s:Log('    End of clause (but not end of line), returning abscol ' . abscol)
                    return abscol
                endif
            endif

            if level > 0
                if abscol == -1
                    let abscol = curr_col + shift
                endif
                call s:Log('    Token with higher level reached, so returning abscol ' . abscol)
                call s:Log('    (curr_col=' . curr_col . ', shift=' . shift)
                return abscol

            elseif absrel == 'abs' && level == 0 && a:type == 'end'
                if abscol == -1
                    let abscol = curr_col + shift
                endif
                call s:Log('    Pair for "end" token found, returning abscol ' . abscol)
                call s:Log('    (curr_col=' . curr_col . ', shift=' . shift)
                return abscol

            elseif absrel == 'abs' && level == 0
                let abscol = curr_col + shift
                call s:Log('    Abs token on level 0: setting abscol to ' . abscol)
                "if token == 'arrow'
                "    let abscol = curr_col + shift
                "    call s:Log('    Abs "arrow" token on level 0: setting abscol to ' . abscol')
                "endif
                "else
                "    call s:Log('    Abs token on level 0: not sure wh')
                "    let shift = 0
                "    call s:Log('    Abs token on level 0: setting abscol to ' . abscol . ' and shift to 0')

            elseif absrel == 'rel' && level == 0
                let shift += curr_col
                call s:Log('    Rel token on level 0: setting shift to ' . shift)

            else
                call s:Log('    Level=' . level . ', doing nothing.')

            endif

            let i -= 1
            call s:Log('    Token analyzed. abscol=' . abscol . ', shift=' . shift)

        endwhile " iteration on tokens in a line

        call s:Log('  Line analyzed. abscol=' . abscol . ', shift=' . shift)

        if level == 0 && abscol != -1
            call s:Log('    Token with level 0 reached, so returning abscol ' . abscol)
            return abscol
        endif

        let lnum -= 1

    endwhile " iteration on lines

endfunction

" --------------------- "
" ErlangIndent function "
" --------------------- "

function! ErlangIndent()

    let currline = getline(v:lnum)
    call s:Log('Indenting line ' . v:lnum . ': ' . currline)

    if currline =~# '^\s*\%\(\%(end\|of\|catch\|after\)\>\|[)\]}]\)'
        call s:Log("  Line type = 'end'")
        let new_col = s:ErlangCalcIndent(v:lnum - 1, -1, 'end')
    else
        call s:Log("  Line type = 'normal'")
        let new_col = s:ErlangCalcIndent(v:lnum - 1, 0, 'normal')
    endif

    if new_col < 0
        throw "new_col < 0"
    endif

    return new_col

endfunction

" ---------- "
" Unit tests "
" ---------- "

function! s:AssertEqual(a, b)
    if type(a:a) == type(a:b) && a:a == a:b
        return 1
    else
        let t = ["Test failed: The following values are not equal:\n",
              \  a:a, "\n",
              \  a:b, "\n"]
        echo join(t, '')
        return 0
    endif
endfunction

function! s:TestAddIndToken()

    " Consecutive absolute, 0-level tokens should be skipped
    let indtokens = []
    call s:AddIndToken(indtokens, 'x', 'abs', 5, 0)
    call s:AssertEqual([['x', 'abs', 5, 0]], indtokens)
    call s:AddIndToken(indtokens, 'x', 'abs', 1, 0)
    call s:AssertEqual([['x', 'abs', 5, 0]], indtokens)
    call s:AddIndToken(indtokens, 'x', 'abs', 2, 1)
    call s:AssertEqual([['x', 'abs', 5, 0], ['x', 'abs', 2, 1]], indtokens)
    call s:AddIndToken(indtokens, 'x', 'abs', 3, 1)
    call s:AssertEqual([['x', 'abs', 5, 0], ['x', 'abs', 2, 1], ['x', 'abs', 3, 1]], indtokens)
    call s:AddIndToken(indtokens, 'x', 'abs', 4, 0)
    call s:AssertEqual([['x', 'abs', 5, 0], ['x', 'abs', 2, 1], ['x', 'abs', 3, 1], ['x', 'abs', 4, 0]], indtokens)

    " Other combinations should not be skipped
    let indtokens = []
    call s:AddIndToken(indtokens, 'x', 'rel', 5, 0)
    call s:AssertEqual([['x', 'rel', 5, 0]], indtokens)
    call s:AddIndToken(indtokens, 'x', 'rel', 6, 0)
    call s:AssertEqual([['x', 'rel', 5, 0], ['x', 'rel', 6, 0]], indtokens)
    call s:AddIndToken(indtokens, 'x', 'abs', 7, 0)
    call s:AssertEqual([['x', 'rel', 5, 0], ['x', 'rel', 6, 0], ['x', 'abs', 7, 0]], indtokens)
    call s:AddIndToken(indtokens, 'x', 'abs', 8, 0)
    call s:AssertEqual([['x', 'rel', 5, 0], ['x', 'rel', 6, 0], ['x', 'abs', 7, 0]], indtokens)
    call s:AddIndToken(indtokens, 'x', 'rel', 9, 0)
    call s:AssertEqual([['x', 'rel', 5, 0], ['x', 'rel', 6, 0], ['x', 'abs', 7, 0], ['x', 'rel', 9, 0]], indtokens)

    let indtokens = []
    call s:AddIndToken(indtokens, 'x', 'abs', 5, 1)
    call s:AssertEqual([['x', 'abs', 5, 1]], indtokens)
    call s:AddIndToken(indtokens, 'x', 'abs', 6, 1)
    call s:AssertEqual([['x', 'abs', 5, 1], ['x', 'abs', 6, 1]], indtokens)
    call s:AddIndToken(indtokens, 'x', 'abs', 0, -1)
    call s:AssertEqual([['x', 'abs', 5, 1], ['x', 'abs', 6, 1], ['x', 'abs', 0, -1]], indtokens)

endfunction

function! s:TestErlangAnalyzeLine()

    call s:AssertEqual(s:ErlangAnalyzeLine('', 0), [])

    call s:AssertEqual(s:ErlangAnalyzeLine('A, B', 0), [
                \ ['var', 'abs', 0, 0]])

    call s:AssertEqual(s:ErlangAnalyzeLine(' A, B', 0), [
                \ ['var', 'abs', 1, 0]])

    call s:AssertEqual(s:ErlangAnalyzeLine('begin X end', 0), [
                \ ['begin', 'abs', 0, 1], ['begin', 'rel', &sw, 0],
                \ ['var', 'abs', 6, 0],
                \ ['end', 'abs', 8, -1]])

    call s:AssertEqual(s:ErlangAnalyzeLine('A.', 0), [
                \ ['var', 'abs', 0, 0],
                \ ['end_of_clause', 'special', 1, 0]])

endfunction

function! TestErlangIndent()
    call s:TestAddIndToken()
    call s:TestErlangAnalyzeLine()
    echo "Test finished."
endfunction

function! ErlangAnalyzeLine(line)
    echo "Line: " . a:line
    let indtokens = s:ErlangAnalyzeLine(a:line, 0)
    echo "Tokens:"
    for it in indtokens
        echo it
    endfor
endfunction

function! ErlangAnalyzeCurrentLine()
    return ErlangAnalyzeLine(getline('.'))
endfunction
