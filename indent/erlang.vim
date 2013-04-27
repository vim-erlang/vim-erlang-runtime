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
setlocal indentkeys+=0=end,0=of,0=catch,0=after,0=),0=],0=},0=>>

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

function! s:L2s(list)
    return ''.join([a:list])
endfunction

" ---------------- "
" Indtoken library "
" ---------------- "

" Indtokens are "indentation tokens".
"
" Types:
"
" indtoken = [token, col]
" token = string: see ErlangAnalyzeLine
" col = integer (the column of the first character of the token)

function! s:GetTokenFromIndtokens(indtokens)
    return a:indtokens[0]
endfunction

function! s:AddIndToken(indtokens, token, col)
    call add(a:indtokens, [a:token, a:col])
endfunction

" -------------------------- "
" ErlangAnalyzeLine function "
" -------------------------- "

" The function goes through the whole line, analyzes it and returns the
" indentation level.
"
" Types:
"
" line = string: the line to be examined
" string_continuation = bool
" atom_continuation = bool
" result = [indtoken]

function! s:ErlangAnalyzeLine(line, string_continuation, atom_continuation)

    let linelen = strlen(a:line) " The length of the line
    let i = 0 " The index of the current character in the line
    let indtokens = []

    if a:string_continuation
        let i = matchend(a:line, '^\%([^"\\]\|\\.\)*"', 0)
        if i == -1
            call s:Log("    Whole line is string continuation -> ignore")
            return []
        else
            call s:AddIndToken(indtokens, 'string_end', i)
        endif
    elseif a:atom_continuation
        let i = matchend(a:line, "^\\%([^'\\\\]\\|\\\\.\\)*'", 0)
        if i == -1
            call s:Log("    Whole line is quoted atom continuation -> ignore")
            return []
        else
            call s:AddIndToken(indtokens, 'quoted_atom_end', i)
        endif
    endif

    while 0 <= i && i < linelen

        " Blanks
        if a:line[i] =~# '\s'
            let next_i = matchend(a:line, '\s*', i + 1)

        " Comment
        elseif a:line[i] == '%'
            let next_i = linelen

        " String token: "..."
        elseif a:line[i] == '"'
            let next_i = matchend(a:line, '"\%([^"\\]\|\\.\)*"', i)
            if next_i == -1
                call s:AddIndToken(indtokens, 'string_start', i)
            else
                call s:AddIndToken(indtokens, 'string', i)
            endif

        " Quoted atom token: '...'
        elseif a:line[i] == "'"
            let next_i = matchend(a:line, "'\\%([^'\\\\]\\|\\\\.\\)*'", i)
            if next_i == -1
                call s:AddIndToken(indtokens, 'quoted_atom_start', i)
            else
                call s:AddIndToken(indtokens, 'quoted_atom', i)
            endif

        " Keyword or atom or variable token
        elseif a:line[i] =~# "[a-zA-Z_@]"
            let next_i = matchend(a:line, "[[:alnum:]_@]*", i + 1)
            call s:AddIndToken(indtokens, a:line[(i):(next_i - 1)], i)

        " Character token: $<char> (as in: $a)
        elseif a:line[i] == '$'
            call s:AddIndToken(indtokens, 'char', i)
            let next_i = i + 2

        " Dot token: .
        elseif a:line[i] == "."

            let next_i = i + 1
            " Dot token (end of clause): . (as in: f() -> ok.)
            if i + 1 == linelen || a:line[i + 1] =~# '[[:blank:]%]'
                call s:AddIndToken(indtokens, 'end_of_clause', i)
            else
                " Possibilities:
                " - Dot token in float: . (as in: 3.14)
                " - Dot token in record: . (as in: #myrec.myfield)
                call s:AddIndToken(indtokens, 'dot', i)
            endif

        " Two-character tokens: ->, <<, >>
        elseif i + 1 < linelen &&
             \ ((a:line[i] == '-' && a:line[i + 1] == '>') ||
             \  (a:line[i] == '<' && a:line[i + 1] == '<') ||
             \  (a:line[i] == '>' && a:line[i + 1] == '>'))
            call s:AddIndToken(indtokens, a:line[i : i + 1], i)
            let next_i = i + 2

        " Other character
        else
            call s:AddIndToken(indtokens, a:line[i], i)
            let next_i = i + 1
        endif

        let i = next_i
    endwhile

    return indtokens

endfunction

" ------------- "
" Stack library "
" ------------- "

function! s:Push(stack, token)
    call s:Log('    Stack Push: ' . a:token . ' -> ' . s:L2s(a:stack))
    call insert(a:stack, a:token)
endfunction

function! s:Pop(stack)
    let head = remove(a:stack, 0)
    call s:Log('    Stack Pop: ' . head . ' <- ' . s:L2s(a:stack))
    return head
endfunction

" TODO Remove - Currently not used
function! s:PushShift(stack, shift)
    if len(a:stack) > 0 && type(a:stack[0]) == type(0)
        call s:Log('    Shift on stack updated: ' . a:stack[0] . ' -> ' . a:stack[0] + a:shift)
        let a:stack[0] += a:shift
    else
        call s:Push(a:stack, a:shift)
    endif
endfunction

" TODO Remove - Currently not used
function! s:PopShift(stack)
    if len(a:stack) > 0 && type(a:stack[0]) == type(0)
        let head = remove(a:stack, 0)
        call s:Log('    Stack PopShift: ' . head . ' <- ' . s:L2s(a:stack))
        return head
    else
        call s:Log('    Stack PopShift: 0')
        return 0
    endif
endfunction

" TODO Use empty() instead - shift are currently not used
function! s:IsEmptyButShift(stack)
    return empty(a:stack) || type(a:stack[0]) == type(0)
endfunction

function! s:Get(list, i)
    if len(a:list) > a:i
        return a:list[a:i]
    else
        return ''
    endif
endfunction

" --------------------------------- "
" ErlangCalcIndent helper functions "
" --------------------------------- "

" Return whether the given line starts with a string continuation:
"
"     f () ->          % IsLineStringContinuation = false
"         "This is a   % IsLineStringContinuation = false
"         multiline    % IsLineStringContinuation = true
"         string".     % IsLineStringContinuation = true
function! s:IsLineStringContinuation(lnum)
    if has('syntax_items')
        return synIDattr(synID(a:lnum, 1, 0), 'name') =~# '^erlangString'
    else
        return 0
    endif
endfunction

function! s:IsLineAtomContinuation(lnum)
    if has('syntax_items')
        return synIDattr(synID(a:lnum, 1, 0), 'name') =~# '^erlangQuotedAtom'
    else
        return 0
    endif
endfunction

if !exists('g:erlang_unexpected_token_indent')
    let g:erlang_unexpected_token_indent = -1
endif

function! s:UnexpectedToken(token, stack)
    call s:Log('    Unexpected token ' . a:token . ', stack = ' . s:L2s(a:stack) . ' -> return')
    return g:erlang_unexpected_token_indent
endfunction

function! s:BeginElementFoundIfEmpty(stack, token, curr_col, abscol, sw)
    if empty(a:stack)
        if a:abscol == -1
            call s:Log('    "' . a:token . '" directly preceeds LTI -> return')
            return [1, a:curr_col + a:sw]
        else
            call s:Log('    "' . a:token . '" token (whose expression includes LTI) found -> return')
            return [1, a:abscol]
        endif
    else
        return [0, 0]
    endif
endfunction

function! s:BeginElementFound(stack, token, curr_col, abscol, end_token, sw)

    " Return 'return' if the stack is empty
    let [ret, res] = s:BeginElementFoundIfEmpty(a:stack, a:token, a:curr_col, a:abscol, a:sw)
    if ret | return [ret, res] | endif

    if a:stack[0] == a:end_token
        call s:Log('    "' . a:token . '" pops "' . a:end_token . '"')
        call s:Pop(a:stack)
        if !empty(a:stack) && a:stack[0] == 'align_to_begin_element'
            call s:Pop(a:stack)
            if empty(a:stack)
                return [1, a:curr_col]
            else
                return [1, s:UnexpectedToken(a:token, a:stack)]
            endif
        endif
        return [0, 0]
    else
        return [1, s:UnexpectedToken(a:token, a:stack)]
    endif
endfunction

function! s:CheckForFuncDefArrow(stack, token, abscol)
    if !empty(a:stack) && a:stack[0] == '->'
        call s:Log('    CheckForFuncDefArrow: "->" found in stack')
        call s:Pop(a:stack)
        if s:IsEmptyButShift(a:stack)
            call s:Log('    Stack is ["->"], so LTI is in function body -> return')
            return [1, a:abscol + &sw]
        elseif a:stack[0] == ';'
            call s:Pop(a:stack)
            if s:IsEmptyButShift(a:stack)
                call s:Log('    Stack is ["->", ";"], so LTI is in a function head -> return')
                return [0, a:abscol]
            else
                return [1, s:UnexpectedToken(a:token, a:stack)]
            endif
        else
            return [1, s:UnexpectedToken(a:token, a:stack)]
        endif
    else
        return [0, 0]
    endif
endfunction

function! s:NextToken(all_tokens, i)
    " If the current line has a next token, return that
    if len(a:all_tokens[0]) > a:i + 1
        return a:all_tokens[0][a:i + 1]

    " If the current line does not have any tokens after position `i` and
    " there are no other lines, return []
    elseif len(a:all_tokens) == 1
        return []

    " If the current line does not have any tokens after position `i`, return
    " the first token of the next line
    else
        return a:all_tokens[1][0]
    endif

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

function! s:ErlangCalcIndent(lnum, stack, indtokens)
    let res = s:ErlangCalcIndent2(a:lnum, a:stack, a:indtokens)
    call s:Log("ErlangCalcIndent returned: " . res)
    return res
endfunction

function! s:ErlangCalcIndent2(lnum, stack, indtokens)

    let lnum = a:lnum
    let abscol = -1
    let mode = 'normal'
    let stack = a:stack
    let semicolon_abscol = ''

    " TODO Remove - Currently not used
    let leave_abscol = 0

    if empty(a:indtokens)
        let all_tokens = []
    else
        let all_tokens = [a:indtokens]
    endif

    " Walk through the lines of the buffer backwards (starting from the
    " previous line) until we can decide how to indent the current line.
    while 1

        let lnum = prevnonblank(lnum)

        " Hit the start of the file
        if lnum == 0
            let [ret, res] = s:CheckForFuncDefArrow(stack, 'beginning_of_file', abscol)
            if ret | return res | endif

            return 0
        endif

        " Get the tokens from the currently analyzed line
        let line = getline(lnum)
        call s:Log('Analysing line ' . lnum . ': ' . line)
        let string_continuation = s:IsLineStringContinuation(lnum)
        let atom_continuation = s:IsLineAtomContinuation(lnum)
        let indtokens = s:ErlangAnalyzeLine(line, string_continuation, atom_continuation)
        call s:Log("  Tokens in the line:\n    - " . join(reverse(copy(indtokens)), "\n    - "))
        if len(indtokens) > 0
            call insert(all_tokens, indtokens)
        endif

        let i = len(indtokens) - 1

        while i >= 0

            " Prepare the analysis of the tokens
            let [token, curr_col] = indtokens[i]
            call s:Log('  Analyzing the following token: ' . s:L2s(indtokens[i]))
            let leave_abscol = 0

            if token == 'end_of_clause'
                let [ret, res] = s:CheckForFuncDefArrow(stack, token, abscol)
                if ret | return res | endif

                if abscol == -1
                    call s:Log('    End of clause directly preceeds LTI -> return')
                    return 0
                else
                    call s:Log('    End of clause (but not end of line) -> return')
                    return abscol
                endif

            elseif token == 'begin'
                let [ret, res] = s:BeginElementFound(stack, token, curr_col, abscol, 'end', &sw)
                if ret | return res | endif

            elseif token == 'case' || token == 'if' || token == 'try' || token == 'receive'

                " stack = []  =>  LTI is a condition
                " stack = ['->']  =>  LTI is a branch
                " stack = ['->', ';']  =>  LTI is a condition
                if empty(stack)
                    " pass
                elseif (token == 'case' && stack[0] == 'of') ||
                     \ (token == 'if') ||
                     \ (token == 'try' && (stack[0] == 'catch' || stack[0] == 'after')) ||
                     \ (token == 'receive')

                    if token == 'case' || token == 'try' ||
                     \ (token == 'receive' && stack[0] == 'after')
                        call s:Pop(stack)
                    endif

                    if empty(stack)
                        call s:Log('    LTI is in a condition; matching "case/if/try/receive" found')
                        let abscol = curr_col + &sw
                    elseif stack[0] == 'align_to_begin_element'
                        call s:Pop(stack)
                        let abscol = curr_col
                    elseif len(stack) > 1 && stack[0] == '->' && stack[1] == ';'
                        call s:Log('    LTI is in a condition; matching "case/if/try/receive" found')
                        call s:Pop(stack)
                        call s:Pop(stack)
                        let abscol = curr_col + &sw
                    elseif stack[0] == '->'
                        call s:Log('    LTI is in a branch; matching "case/if/try/receive" found')
                        call s:Pop(stack)
                        let abscol = curr_col + 2 * &sw
                    endif

                endif

                let [ret, res] = s:BeginElementFound(stack, token, curr_col, abscol, 'end', &sw)
                if ret | return res | endif

            elseif token == 'fun'
                let next_indtoken = s:NextToken(all_tokens, i)
                call s:Log('    Next indtoken = ' . s:L2s(next_indtoken))

                if !empty(next_indtoken) && s:GetTokenFromIndtokens(next_indtoken) == '('
                    " We have an anonymous function definition
                    " (e.g. "fun () -> ok end")

                    " stack = []  =>  LTI is a condition
                    " stack = ['->']  =>  LTI is a branch
                    " stack = ['->', ';']  =>  LTI is a condition
                    if empty(stack)
                        call s:Log('    LTI is in a condition; matching "fun" found')
                        let abscol = curr_col + &sw
                    elseif len(stack) > 1 && stack[0] == '->' && stack[1] == ';'
                        call s:Log('    LTI is in a condition; matching "fun" found')
                        call s:Pop(stack)
                        call s:Pop(stack)
                    elseif stack[0] == '->'
                        call s:Log('    LTI is in a branch; matching "fun" found')
                        call s:Pop(stack)
                        let abscol = curr_col + 2 * &sw
                    endif

                    let [ret, res] = s:BeginElementFound(stack, token, curr_col, abscol, 'end', &sw)
                    if ret | return res | endif
                else
                    " We have a function reference (e.g. "fun f/0")
                endif

            elseif token == '('
                let [ret, res] = s:BeginElementFound(stack, token, curr_col, abscol, ')', 2)
                if ret | return res | endif

            elseif token == '['
                let [ret, res] = s:BeginElementFound(stack, token, curr_col, abscol, ']', 1)
                if ret | return res | endif

            elseif token == '{'
                let [ret, res] = s:BeginElementFound(stack, token, curr_col, abscol, '}', 1)
                if ret | return res | endif

            elseif token == '<<'
                let [ret, res] = s:BeginElementFound(stack, token, curr_col, abscol, '>>', 2)
                if ret | return res | endif

            elseif index(['end', ')', ']', '}', '>>'], token) != -1
                call s:Push(stack, token)

            elseif token == ';'

                if empty(stack)
                    call s:Push(stack, ';')
                elseif stack[0] == 'end' || stack[0] == 'after' || stack[0] == ';' || stack[0] == '->'
                    " pass
                else
                    return s:UnexpectedToken(token, stack)
                endif

            elseif token == '->'

                if empty(stack) || stack[0] == ';' || stack[0] == 'end'
                    " stack = ['->']  ->  LTI is a condition
                    " stack = ['->', ';']  -> LTI is a branch
                    call s:Push(stack, '->')
                elseif stack[0] == '->' || stack[0] == 'after'
                    " pass
                else
                    return s:UnexpectedToken(token, stack)
                endif

            elseif token == 'when'

                " Pop all ';' from the top of the stack
                while !empty(stack) && stack[0] == ';'
                    call s:Pop(stack)
                endwhile

                if empty(stack)

                    if semicolon_abscol == ''
                        let semicolon_abscol = abscol
                    endif

                    let [ret, res] = s:BeginElementFoundIfEmpty(stack, token, curr_col, semicolon_abscol, &sw)
                    if ret | return res | endif
                elseif stack[0] == '->'
                    " pass
                else
                    return s:UnexpectedToken(token, stack)
                endif

            elseif token == 'of' || token == 'catch' || token == 'after'

                if empty(stack) || stack[0] == '->'
                    call s:Push(stack, token)
                elseif token == 'catch' || stack[0] == 'after'
                    " pass
                else
                    return s:UnexpectedToken(token, stack)
                endif

            else
                call s:Log('    Misc token, stack unchanged = ' . s:L2s(stack))

            endif

            if leave_abscol
                " pass
            elseif s:IsEmptyButShift(stack) || stack[0] == '->'
                let abscol = curr_col
                let semicolon_abscol = ''
                call s:Log('    Misc token when the stack is empty or has "->" -> setting abscol to ' . abscol)
            elseif stack[0] == ';'
                let semicolon_abscol = curr_col
                call s:Log('    Setting semicolon-abscol to ' . abscol)
            endif

            let i -= 1
            call s:Log('    Token processed. abscol=' . abscol)

        endwhile " iteration on tokens in a line

        call s:Log('  Line analyzed. abscol=' . abscol)

        if s:IsEmptyButShift(stack) && abscol != -1 && !string_continuation && !atom_continuation
            call s:Log('    Empty stack at the beginning of the line -> return')
            return abscol + s:PopShift(stack)
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

    if s:IsLineStringContinuation(v:lnum) || s:IsLineAtomContinuation(v:lnum)
        call s:Log('String or atom continuation found -> leaving indentation unchanged')
        return -1
    endif

    let ml = matchlist(currline, '^\s*\(\%(end\|of\|catch\|after\)\>\|[)\]}]\|>>\)')
    if empty(ml)
        call s:Log("  Line type = 'normal'")

        if currline =~# '^\s*('
            let indtokens = ['(']
        else
            let indtokens = []
        endif

        let new_col = s:ErlangCalcIndent(v:lnum - 1, [], indtokens)
        if currline =~# '^\s*when\>'
            let new_col += 2
        endif

    else
        call s:Log("  Line type = 'end'")
        let new_col = s:ErlangCalcIndent(v:lnum - 1, [ml[1], 'align_to_begin_element'], [])
    endif

    if new_col < -1
        call s:Log('WARNING: returning new_col == ' . new_col)
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

function! s:TestErlangAnalyzeLine()

    call s:AssertEqual(s:ErlangAnalyzeLine('', 0, 0), [])

endfunction

function! TestErlangIndent()
    call s:TestErlangAnalyzeLine()
    echo "Test finished."
endfunction

function! ErlangAnalyzeLine(line)
    echo "Line: " . a:line
    let indtokens = s:ErlangAnalyzeLine(a:line, 0, 0)
    echo "Tokens:"
    for it in indtokens
        echo it
    endfor
endfunction

function! ErlangAnalyzeCurrentLine()
    return ErlangAnalyzeLine(getline('.'))
endfunction
