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

" ---------------------- "
" Line tokenizer library "
" ---------------------- "

" Indtokens are "indentation tokens".

" Function:
"     s:CalcVCol
"
" Purpose:
"     Calculate the new virtual column after the given segment of a line.
"
" Types:
"     vcol = integer (the virtual column of the first character of the token)
"
" Example:
"     " index:    0 12 34567
"     " vcol:     0 45 89
"     s:CalcVCol("\t'\tx', b", 1, 4, 4)  -> 10

function! s:CalcVCol(line, first_index, last_index, vcol, tabstop)

    " We copy the relevent segment of the line, otherwise if the line were
    " e.g. `"\t", term` then the else branch below would consume the `", term`
    " part at once.
    let line = a:line[a:first_index : a:last_index]

    let i = 0
    let last_index = a:last_index - a:first_index
    let vcol = a:vcol

    while 0 <= i && i <= last_index

        if line[i] == "\t"
            " Example (when tabstop == 4):
            "
            " vcol + tab -> next_vcol
            " 0 + tab -> 4
            " 1 + tab -> 4
            " 2 + tab -> 4
            " 3 + tab -> 4
            " 4 + tab -> 8
            "
            " next_i - i == the number of tabs
            let next_i = matchend(line, '\t*', i + 1)
            let vcol = (vcol / a:tabstop + (next_i - i)) * a:tabstop
            call s:Log('new vcol after tab: '. vcol)
        else
            let next_i = matchend(line, '[^\t]*', i + 1)
            let vcol += next_i - i
            call s:Log('new vcol after other: '. vcol)
        endif
        let i = next_i
    endwhile

    return vcol
endfunction

" Function:
"     s:GetTokensFromLine
"
" Purpose:
"     Go through the whole line and return the tokens in the line.
"
" Types:
"     line = string: the line to be examined
"     string_continuation = bool
"     atom_continuation = bool
"     result = [indtoken]
"     indtoken = [token, vcol]
"     token = string (examples: 'begin', '<variable>', '}')
"     vcol = integer (the virtual column of the first character of the token)

function! s:GetTokensFromLine(line, string_continuation, atom_continuation, tabstop)

    let linelen = strlen(a:line) " The length of the line
    let i = 0 " The index of the current character in the line
    let vcol = 0 " The virtual column of the current character
    let indtokens = []

    if a:string_continuation
        let i = matchend(a:line, '^\%([^"\\]\|\\.\)*"', 0)
        if i == -1
            call s:Log("    Whole line is string continuation -> ignore")
            return []
        else
            let vcol = s:CalcVCol(a:line, 0, i - 1, 0, a:tabstop)
            call add(indtokens, ['<string_end>', i])
        endif
    elseif a:atom_continuation
        let i = matchend(a:line, "^\\%([^'\\\\]\\|\\\\.\\)*'", 0)
        if i == -1
            call s:Log("    Whole line is quoted atom continuation -> ignore")
            return []
        else
            let vcol = s:CalcVCol(a:line, 0, i - 1, 0, a:tabstop)
            call add(indtokens, ['<quoted_atom_end>', i])
        endif
    endif

    while 0 <= i && i < linelen

        let next_vcol = ''

        " Spaces
        if a:line[i] == ' '
            let next_i = matchend(a:line, ' *', i + 1)

        " Tabs
        elseif a:line[i] == "\t"
            let next_i = matchend(a:line, '\t*', i + 1)

            " See example in s:CalcVCol
            let next_vcol = (vcol / a:tabstop + (next_i - i)) * a:tabstop

        " Comment
        elseif a:line[i] == '%'
            let next_i = linelen

        " String token: "..."
        elseif a:line[i] == '"'
            let next_i = matchend(a:line, '\%([^"\\]\|\\.\)*"', i + 1)
            if next_i == -1
                call add(indtokens, ['<string_start>', vcol])
            else
                let next_vcol = s:CalcVCol(a:line, i, next_i - 1, vcol, a:tabstop)
                call add(indtokens, ['<string>', vcol])
            endif

        " Quoted atom token: '...'
        elseif a:line[i] == "'"
            let next_i = matchend(a:line, "\\%([^'\\\\]\\|\\\\.\\)*'", i + 1)
            if next_i == -1
                call add(indtokens, ['<quoted_atom_start>', vcol])
            else
                let next_vcol = s:CalcVCol(a:line, i, next_i - 1, vcol, a:tabstop)
                call add(indtokens, ['<quoted_atom>', vcol])
            endif

        " Keyword or atom or variable token or number
        elseif a:line[i] =~# '[a-zA-Z_@0-9]'
            let next_i = matchend(a:line, '[[:alnum:]_@:]*\%(\s*#\s*[[:alnum:]_@:]*\)\=', i + 1)
            call add(indtokens, [a:line[(i):(next_i - 1)], vcol])

        " Character token: $<char> (as in: $a)
        elseif a:line[i] == '$'
            call add(indtokens, ['$.', vcol])
            let next_i = i + 2

        " Dot token: .
        elseif a:line[i] == '.'

            let next_i = i + 1
            " Dot token (end of clause): . (as in: f() -> ok.)
            if i + 1 == linelen || a:line[i + 1] =~# '[[:blank:]%]'
                call add(indtokens, ['<end_of_clause>', vcol])
            else
                " Possibilities:
                " - Dot token in float: . (as in: 3.14)
                " - Dot token in record: . (as in: #myrec.myfield)
                call add(indtokens, ['.', vcol])
            endif

        " Equal sign
        elseif a:line[i] == '='
            " This is handled separately so that "=<<" will be parsed as
            " ['=', '<<'] instead of ['=<', '<']. Although Erlang parses it
            " currently in the latter way, that may be fixed some day.
            call add(indtokens, [a:line[i], vcol])
            let next_i = i + 1

        " Three-character tokens
        elseif i + 1 < linelen &&
             \ index(['=:=', '=/='], a:line[i : i + 1]) != -1
            call add(indtokens, [a:line[i : i + 1], vcol])
            let next_i = i + 2

        " Two-character tokens
        elseif i + 1 < linelen &&
             \ index(['->', '<<', '>>', '||', '==', '/=', '=<', '>=', '++', '--', '::'], a:line[i : i + 1]) != -1
            call add(indtokens, [a:line[i : i + 1], vcol])
            let next_i = i + 2

        " Other character: , ; < > ( ) [ ] { } # + - * / : ? = !
        else
            call add(indtokens, [a:line[i], vcol])
            let next_i = i + 1

        endif

        if next_vcol == ''
            let vcol += next_i - i
        else
            let vcol = next_vcol
        endif

        let i = next_i

    endwhile

    return indtokens

endfunction

" ------------- "
" Stack library "
" ------------- "

function! s:Push(stack, token)
    call s:Log('    Stack Push: ' . a:token . ' into ' . s:L2s(a:stack))
    call insert(a:stack, a:token)
endfunction

function! s:Pop(stack)
    let head = remove(a:stack, 0)
    call s:Log('    Stack Pop: ' . head . ' from ' . s:L2s(a:stack))
    return head
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
    if !empty(a:stack) && a:stack[0] == 'when'
        call s:Log('    CheckForFuncDefArrow: "when" found in stack')
        call s:Pop(a:stack)
        if empty(a:stack)
            call s:Log('    Stack is ["when"], so LTI is in a guard -> return')
            return [1, a:abscol + &sw + 2]
        else
            return [1, s:UnexpectedToken(a:token, a:stack)]
        endif
    elseif !empty(a:stack) && a:stack[0] == '->'
        call s:Log('    CheckForFuncDefArrow: "->" found in stack')
        call s:Pop(a:stack)
        if empty(a:stack)
            call s:Log('    Stack is ["->"], so LTI is in function body -> return')
            return [1, a:abscol + &sw]
        elseif a:stack[0] == ';'
            call s:Pop(a:stack)
            if empty(a:stack)
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

" `lnum -> indtokens` dictionary
let s:all_tokens = {}

function! ClearErlangParseCache()
    let s:all_tokens = {}
endfunction

function! s:ParseStoreLine(lnum, direction)

    if a:direction == 'up'
        let lnum = prevnonblank(a:lnum)
    else " a:direction == 'down'
        let lnum = nextnonblank(a:lnum)
    endif

    " We hit the beginning or end of the file
    if lnum == 0
        let indtokens = []

    " The line has already been parsed
    elseif has_key(s:all_tokens, lnum)
        let indtokens = s:all_tokens[lnum]

    " The line should be parsed now
    else

        " Parse the line
        let line = getline(lnum)
        call s:Log('Tokenizing line ' . lnum . ': ' . line)
        let string_continuation = s:IsLineStringContinuation(lnum)
        let atom_continuation = s:IsLineAtomContinuation(lnum)
        let indtokens = s:GetTokensFromLine(line, string_continuation, atom_continuation, &tabstop)
        call s:Log("  Tokens in the line:\n    - " . join(indtokens, "\n    - "))
        let s:all_tokens[lnum] = indtokens

    endif

    return [lnum, indtokens]
endfunction

function! s:FindIndToken(lnum, dir)
    let lnum = a:lnum
    while 1
        let lnum += (a:dir == 'up' ? -1 : 1)
        let [lnum, indtokens] = s:ParseStoreLine(lnum, a:dir)
        if lnum == 0
            " We hit the beginning or end of the file
            return []
        elseif !empty(indtokens)
            return indtokens[a:dir == 'up' ? -1 : 0]
        endif
    endwhile
endfunction

function! s:PrevIndToken(lnum, i)
    call s:Log('    PrevIndToken called: lnum=' . a:lnum . ', i =' . a:i)

    " If the current line has a previous token, return that
    if a:i > 0
        return s:all_tokens[a:lnum][a:i - 1]
    else
        return s:FindIndToken(a:lnum, 'up')
    endif
endfunction

function! s:NextIndToken(lnum, i)
    call s:Log('    NextIndToken called: lnum=' . a:lnum . ', i =' . a:i)

    " If the current line has a next token, return that
    if len(s:all_tokens[a:lnum]) > a:i + 1
        return s:all_tokens[a:lnum][a:i + 1]
    else
        return s:FindIndToken(a:lnum, 'down')
    endif
endfunction

function! s:IsCatchStandalone(lnum, i)
    call s:Log('    IsCatchStandalone called: lnum=' . a:lnum . ', i=' . a:i)
    let prev_indtoken = s:PrevIndToken(a:lnum, a:i)

    " If we hit the beginning of the file, it is not a catch in a try block
    if prev_indtoken == []
        return 1
    endif

    let prev_token = prev_indtoken[0]

    if prev_token =~# '[A-Z_@0-9]'
        let is_standalone = 0
    elseif prev_token =~# '[a-z]'
        if index(['after', 'and', 'andalso', 'band', 'begin', 'bnot', 'bor',
         \        'bsl', 'bsr', 'bxor', 'case', 'catch', 'div', 'not', 'or',
         \        'orelse', 'rem', 'try', 'xor'], prev_token) != -1
            " If catch is after these keywords, it is standalone
            let is_standalone = 1
        else
            " If catch is after another keyword (e.g. 'end') or an atom, it is
            " part of try-catch.
            "
            " Keywords:
            " - may precede 'catch': end
            " - may not precede 'catch': fun if of receive when 
            " - unused: cond let query
            let is_standalone = 0
        endif
    elseif index([')', ']', '}', '<string>', '<string_end>', '<quoted_atom>',
         \        '<quoted_atom_end>', '$.'], prev_token) != -1
        let is_standalone = 0
    else
        "Including: -> == /= =< < >= > =:= =/= + - * / ++ -- :: < > ; ( [ { ? = ! .
        let is_standalone = 1
    endif

    call s:Log('   "catch" preceded by "' . prev_token  . '" -> catch ' .
       \       (is_standalone ? 'is standalone' : 'belongs to try-catch'))
    return is_standalone

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

    if empty(a:indtokens)
        let all_tokens = []
    else
        let all_tokens = [a:indtokens]
    endif

    " Walk through the lines of the buffer backwards (starting from the
    " previous line) until we can decide how to indent the current line.
    while 1

        let [lnum, indtokens] = s:ParseStoreLine(lnum, 'up')

        " Hit the start of the file
        if lnum == 0
            let [ret, res] = s:CheckForFuncDefArrow(stack, 'beginning_of_file', abscol)
            if ret | return res | endif

            return 0
        endif

        let i = len(indtokens) - 1
        let last_token_of_line = 1

        while i >= 0

            let [token, curr_col] = indtokens[i]
            call s:Log('  Analyzing the following token: ' . s:L2s(indtokens[i]))

            if token == '<end_of_clause>'
                let [ret, res] = s:CheckForFuncDefArrow(stack, token, abscol)
                if ret | return res | endif

                if abscol == -1
                    call s:Log('    End of clause directly preceeds LTI -> return')
                    return 0
                else
                    call s:Log('    End of clause (but not end of line) -> return')
                    return abscol
                endif

            elseif stack == ['prev_term_plus']
                if token =~# '[a-zA-Z_@]' ||
                 \ token == '<string>' || token == '<string_start>' ||
                 \ token == '<quoted_atom>' || token == '<quoted_atom_start>'
                    call s:Log('    previous token found: curr_col + plus = ' . curr_col . " + " . plus)
                    return curr_col + plus
                endif

            elseif token == 'begin'
                let [ret, res] = s:BeginElementFound(stack, token, curr_col, abscol, 'end', &sw)
                if ret | return res | endif

            " case EXPR of BRANCHES end
            " try EXPR catch BRANCHES end
            " try EXPR after BODY end
            " try EXPR catch BRANCHES after BODY end
            " try EXPR of BRANCHES catch BRANCHES end
            " try EXPR of BRANCHES after BODY end
            " try EXPR of BRANCHES catch BRANCHES after BODY end
            " receive BRANCHES end
            " receive BRANCHES after BRANCHES end

            " This branch is not Emacs-compatible
            elseif (token == 'of' || token == 'receive' || token == 'after' || token == 'if' ||
                 \  (token == 'catch' && !s:IsCatchStandalone(lnum, i))) &&
                 \ !last_token_of_line &&
                 \ (empty(stack)  || stack == ['when']|| stack == ['->'] || stack == ['->', ';'])

                " If we are after of/receive, but these are not the last
                " tokens of the line, we want to indent like this:
                "
                " % stack == []
                " receive Abscol,
                "         LTI
                "
                " % stack == ['->', ';']
                " receive Abscol ->
                "             B;
                "         LTI
                "
                " % stack == ['->']
                " receive Abscol ->
                "             LTI
                "
                " % stack == ['when']
                " receive Abscol when
                "             LTI

                " stack = []  =>  LTI is a condition
                " stack = ['->']  =>  LTI is a branch
                " stack = ['->', ';']  =>  LTI is a condition
                " stack = ['when']  =>  LTI is a guard
                if empty(stack) || stack == ['->', ';']
                    call s:Log('    LTI is in a condition after "of/receive/after/if/catch" -> return')
                    return abscol
                elseif stack == ['->']
                    call s:Log('    LTI is in a branch after "of/receive/after/if/catch" -> return')
                    return abscol + &sw
                elseif stack == ['when']
                    call s:Log('    LTI is in a guard after "of/receive/after/if/catch" -> return')
                    return abscol + &sw
                else
                    return s:UnexpectedToken(token, stack)
                endif

            elseif token == 'case' || token == 'if' || token == 'try' || token == 'receive'

                " stack = []  =>  LTI is a condition
                " stack = ['->']  =>  LTI is a branch
                " stack = ['->', ';']  =>  LTI is a condition
                " stack = ['when']  =>  LTI is in a guard
                if empty(stack)
                    " pass
                elseif (token == 'case' && stack[0] == 'of') ||
                     \ (token == 'if') ||
                     \ (token == 'try' && (stack[0] == 'of' ||
                     \                     stack[0] == 'catch' ||
                     \                     stack[0] == 'after')) ||
                     \ (token == 'receive')

                    " From the indentation point of view, the keyword
                    " (of/catch/after/end) before the LTI is what counts, so
                    " when we reached these tokens, and the stack already had
                    " a catch/after/end, we didn't modify it.
                    "
                    " This way when we reach case/try/receive (i.e. now),
                    " there is at most one of/catch/after/end token in the
                    " stack.
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
                    elseif stack[0] == 'when'
                        call s:Log('    LTI is in a guard; matching "case/if/try/receive" found')
                        call s:Pop(stack)
                        let abscol = curr_col + 2 * &sw + 2
                    endif

                endif

                let [ret, res] = s:BeginElementFound(stack, token, curr_col, abscol, 'end', &sw)
                if ret | return res | endif

            elseif token == 'fun'
                let next_indtoken = s:NextIndToken(lnum, i)
                call s:Log('    Next indtoken = ' . s:L2s(next_indtoken))

                if !empty(next_indtoken) && next_indtoken[0] == '('
                    " We have an anonymous function definition
                    " (e.g. "fun () -> ok end")

                    " stack = []  =>  LTI is a condition
                    " stack = ['->']  =>  LTI is a branch
                    " stack = ['->', ';']  =>  LTI is a condition
                    " stack = ['when']  =>  LTI is in a guard
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
                    elseif stack[0] == 'when'
                        call s:Log('    LTI is in a guard; matching "fun" found')
                        call s:Pop(stack)
                        let abscol = curr_col + 2 * &sw + 2
                    endif

                    let [ret, res] = s:BeginElementFound(stack, token, curr_col, abscol, 'end', &sw)
                    if ret | return res | endif
                else
                    " We have a function reference (e.g. "fun f/0")
                endif

            elseif token == '['
                " Emacs compatibility
                let [ret, res] = s:BeginElementFound(stack, token, curr_col, abscol, ']', 1)
                if ret | return res | endif

            elseif token == '<<'
                " Emacs compatibility
                let [ret, res] = s:BeginElementFound(stack, token, curr_col, abscol, '>>', 2)
                if ret | return res | endif

            elseif token == '(' || token == '{'

                let end_token = (token == '(' ? ')' :
                              \  token == '{' ? '}' : 'error')

                if empty(stack)
                    " We found the opening paren whose block contains the LTI.
                    let mode = 'inside'
                elseif stack[0] == end_token
                    call s:Log('    "' . token . '" pops "' . end_token . '"')
                    call s:Pop(stack)

                    if !empty(stack) && stack[0] == 'align_to_begin_element'
                        " We found the opening paren whose closing paren
                        " starts LTI
                        let mode = 'align_to_begin_element'
                    else
                        " We found the opening pair for a closing paren that
                        " was already in the stack.
                        let mode = 'outside'
                    endif
                else
                    return s:UnexpectedToken(token, stack)
                endif

                if mode == 'inside' || mode == 'align_to_begin_element'

                    if last_token_of_line && i != 0
                        " Examples:
                        "
                        " mode == 'inside':
                        "
                        "     my_func(
                        "       LTI
                        "
                        "     [Variable, {
                        "        LTI
                        "
                        " mode == 'align_to_begin_element':
                        "
                        "     my_func(
                        "       Params
                        "      ) % LTI
                        "
                        "     [Variable, {
                        "        Terms
                        "       } % LTI
                        let stack = ['prev_term_plus']
                        let plus = (mode == 'inside' ? 2 : 1)
                        call s:Log('    "' . token . '" token found at end of line -> find previous token')
                    elseif mode == 'align_to_begin_element'
                        " Examples:
                        "
                        " mode == 'align_to_begin_element' && !last_token_of_line
                        "
                        "     my_func(Abscol
                        "            ) % LTI
                        "
                        "     [Variable, {Abscol
                        "                } % LTI
                        "
                        " mode == 'align_to_begin_element' && i == 0
                        "
                        "     (
                        "       Abscol
                        "     ) % LTI
                        "
                        "     {
                        "       Abscol
                        "     } % LTI
                        "
                        call s:Log('    "' . token . '" token (whose closing token starts LTI) found -> return')
                        return curr_col
                    elseif abscol == -1
                        " Examples:
                        "
                        " mode == 'inside' && abscol == -1 && !last_token_of_line
                        "
                        "     my_func(
                        "             LTI
                        "     [Variable, {
                        "                 LTI
                        "
                        " mode == 'inside' && abscol == -1 && i == 0
                        "
                        "     (
                        "      LTI
                        "
                        "     {
                        "      LTI
                        call s:Log('    "' . token . '" token (which directly precedes LTI) found -> return')
                        return curr_col + 1
                    else
                        " Examples:
                        "
                        " mode == 'inside' && abscol != -1 && !last_token_of_line
                        "
                        "     my_func(Abscol,
                        "             LTI
                        "
                        "     [Variable, {Abscol,
                        "                 LTI
                        "
                        " mode == 'inside' && abscol != -1 && i == 0
                        "
                        "     (Abscol,
                        "      LTI
                        "
                        "     {Abscol,
                        "      LTI
                        call s:Log('    "' . token . '" token (whose block contains LTI) found -> return')
                        return abscol
                    endif
                endif

            elseif index(['end', ')', ']', '}', '>>'], token) != -1
                call s:Push(stack, token)

            elseif token == ';'

                if empty(stack)
                    call s:Push(stack, ';')
                elseif index([';', '->', 'when', 'end', 'after', 'catch'], stack[0]) != -1
                    " Pass:
                    "
                    " - If the stack top is another ';', then one ';' is
                    "   enough.
                    " - If the stack top is an '->' or a 'when', then we
                    "   should keep that, because they signify the type of the
                    "   LTI (branch, condition or guard).
                    " - From the indentation point of view, the keyword
                    "   (of/catch/after/end) before the LTI is what counts, so
                    "   if the stack already has a catch/after/end, we don't
                    "   modify it. This way when we reach case/try/receive,
                    "   there will be at most one of/catch/after/end token in
                    "   the stack.
                else
                    return s:UnexpectedToken(token, stack)
                endif

            elseif token == '->'

                if empty(stack) && !last_token_of_line
                    call s:Log('    LTI is in expression after arrow -> return')
                    return abscol
                elseif empty(stack) || stack[0] == ';' || stack[0] == 'end'
                    " stack = [';']  -> LTI is either a branch or in a guard
                    " stack = ['->']  ->  LTI is a condition
                    " stack = ['->', ';']  -> LTI is a branch
                    call s:Push(stack, '->')
                elseif index(['->', 'when', 'end', 'after', 'catch'], stack[0]) != -1
                    " Pass:
                    "
                    " - If the stack top is another '->', then one '->' is
                    "   enough.
                    " - If the stack top is a 'when', then we should keep
                    "   that, because this signifies that LTI is a in a guard.
                    " - From the indentation point of view, the keyword
                    "   (of/catch/after/end) before the LTI is what counts, so
                    "   if the stack already has a catch/after/end, we don't
                    "   modify it. This way when we reach case/try/receive,
                    "   there will be at most one of/catch/after/end token in
                    "   the stack.
                else
                    return s:UnexpectedToken(token, stack)
                endif

            elseif token == 'when'

                " Pop all ';' from the top of the stack
                while !empty(stack) && stack[0] == ';'
                    call s:Pop(stack)
                endwhile

                if empty(stack)
                    if semicolon_abscol != ''
                        let abscol = semicolon_abscol
                    endif
                    if !last_token_of_line
                        " when A,
                        "      LTI
                        let [ret, res] = s:BeginElementFoundIfEmpty(stack, token, curr_col, abscol, &sw)
                        if ret | return res | endif
                    else
                        " when
                        "     LTI
                        call s:Push(stack, token)
                    endif
                elseif index(['->', 'when', 'end', 'after', 'catch'], stack[0]) != -1
                    " Pass:
                    " - If the stack top is another 'when', then one 'when' is
                    "   enough.
                    " - If the stack top is an '->' or a 'when', then we
                    "   should keep that, because they signify the type of the
                    "   LTI (branch, condition or guard).
                    " - From the indentation point of view, the keyword
                    "   (of/catch/after/end) before the LTI is what counts, so
                    "   if the stack already has a catch/after/end, we don't
                    "   modify it. This way when we reach case/try/receive,
                    "   there will be at most one of/catch/after/end token in
                    "   the stack.
                else
                    return s:UnexpectedToken(token, stack)
                endif

            elseif token == 'of' || token == 'after' ||
                 \ (token == 'catch' && !s:IsCatchStandalone(lnum, i))

                if token == 'after'
                    " If LTI is between an 'after' and the corresponding
                    " 'end', then let's return
                    let [ret, res] = s:BeginElementFoundIfEmpty(stack, token, curr_col, abscol, &sw)
                    if ret | return res | endif
                endif

                if empty(stack) || stack[0] == '->' || stack[0] == 'when'
                    call s:Push(stack, token)
                elseif stack[0] == 'catch' || stack[0] == 'after' || stack[0] == 'end'
                    " Pass: From the indentation point of view, the keyword
                    " (of/catch/after/end) before the LTI is what counts, so
                    " if the stack already has a catch/after/end, we don't
                    " modify it. This way when we reach case/try/receive,
                    " there will be at most one of/catch/after/end token in
                    " the stack.
                else
                    return s:UnexpectedToken(token, stack)
                endif

            elseif token == '||' && empty(stack) && !last_token_of_line

                call s:Log('    LTI is in expression after "||" -> return')
                return abscol

            else
                call s:Log('    Misc token, stack unchanged = ' . s:L2s(stack))

            endif

            if empty(stack) || stack[0] == '->' || stack[0] == 'when'
                let abscol = curr_col
                let semicolon_abscol = ''
                call s:Log('    Misc token when the stack is empty or has "->" -> setting abscol to ' . abscol)
            elseif stack[0] == ';'
                let semicolon_abscol = curr_col
                call s:Log('    Setting semicolon-abscol to ' . abscol)
            endif

            let i -= 1
            call s:Log('    Token processed. abscol=' . abscol)

            let last_token_of_line = 0

        endwhile " iteration on tokens in a line

        call s:Log('  Line analyzed. abscol=' . abscol)

        if empty(stack) && abscol != -1 &&
         \ (!empty(indtokens) && indtokens[0][0] != '<string_end>' &&
         \                       indtokens[0][0] != '<quoted_atom_end>')
            call s:Log('    Empty stack at the beginning of the line -> return')
            return abscol
        endif

        let lnum -= 1

    endwhile " iteration on lines

endfunction

" --------------------- "
" ErlangIndent function "
" --------------------- "

function! ErlangIndent()

    if !exists('g:erlang_indent_external_cache_handling') ||
     \ g:erlang_indent_external_cache_handling == 0
        call ClearErlangParseCache()
    endif

    let currline = getline(v:lnum)
    call s:Log('Indenting line ' . v:lnum . ': ' . currline)

    if s:IsLineStringContinuation(v:lnum) || s:IsLineAtomContinuation(v:lnum)
        call s:Log('String or atom continuation found -> leaving indentation unchanged')
        return -1
    endif

    let ml = matchlist(currline, '^\s*\(\%(end\|of\|catch\|after\)\>\|[)\]}]\|>>\)')

    " If the line has a special beginning, but not a standalone catch
    if !empty(ml) && !(ml[1] == 'catch' && s:IsCatchStandalone(v:lnum, 0))
        call s:Log("  Line type = 'end'")
        let new_col = s:ErlangCalcIndent(v:lnum - 1, [ml[1], 'align_to_begin_element'], [])
    else
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
    endif

    if new_col < -1
        call s:Log('WARNING: returning new_col == ' . new_col)
        return g:erlang_unexpected_token_indent
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

function! s:TestGetTokensFromLine()

    call s:AssertEqual(s:GetTokensFromLine('', 0, 0, 4), [])

    " Tabs and spaces
    call s:AssertEqual(s:GetTokensFromLine("a  b", 0, 0, 4), [
       \ ['a', 0],
       \ ['b', 3]])

    call s:AssertEqual(s:GetTokensFromLine("\ta", 0, 0, 4), [
       \ ['a', 4]])

    call s:AssertEqual(s:GetTokensFromLine(" \t  a", 0, 0, 4), [
       \ ['a', 6]])

    call s:AssertEqual(s:GetTokensFromLine("a\tb\t\tc", 0, 0, 4), [
       \ ['a', 0],
       \ ['b', 4],
       \ ['c', 12]])

    call s:AssertEqual(s:GetTokensFromLine("\t\"a", 1, 0, 4), [
       \ ['<string_end>', 2],
       \ ['a', 5]])

    call s:AssertEqual(s:GetTokensFromLine("\t\"a\tb\"c", 0, 0, 4), [
       \ ['<string>', 4],
       \ ['c', 10]])

endfunction

function! TestErlangIndent()
    call s:TestGetTokensFromLine()
    echo "Test finished."
endfunction

function! ErlangShowTokensInLine(line)
    echo "Line: " . a:line
    let indtokens = s:GetTokensFromLine(a:line, 0, 0, &tabstop)
    echo "Tokens:"
    for it in indtokens
        echo it
    endfor
endfunction

function! ErlangShowTokensInCurrentLine()
    return ErlangShowTokensInLine(getline('.'))
endfunction
