%%%%%%%%%%%%%%
% Attributes %
%%%%%%%%%%%%%%

-attr().

%%%%%%%%%%
% Tokens %
%%%%%%%%%%

f() ->
    SimpleAtom = case@case,
    SimpleVar = Var@case,
    ok.

%%%%%%%%%%
% Period %
%%%%%%%%%%

f() ->
    (
        .

f() ->
    (
        . % xx

% bad
f() ->
    A . B,
ok.
        ok.

f() ->
    ok.

%%%%%%%%%%%%
% Comments %
%%%%%%%%%%%%

% Comment
f() ->
    % Comment
    ok.
% Comment

%%%%%%%%%%%
% Strings %
%%%%%%%%%%%

% bad
f() ->
    x("foo
        bar")
        ,
        ok.

% bad
f() ->
    x("foo
        %        bar")
        ,
        ok.

%%%%%%%%%%%%%%%%%%%
% Basic functions %
%%%%%%%%%%%%%%%%%%%

f() ->
    ok.

%%%%%%%%%%%%%%%%%%%%%
% Actual parameters %
%%%%%%%%%%%%%%%%%%%%%

% bad
f() ->
    g(A,
        B,
        C).

%%%%%%%
% fun %
%%%%%%%

f() ->
    fun a/0,
    fun (A) ->
            A;
        (B) ->
            B
    end,
    ok.

%%%%%%%%%%%
% receive %
%%%%%%%%%%%

f() ->
    receive
        A ->
            A;
        B ->
            B
    end,
    receive
        X -> X
    after
        X -> X
    end,
    ok.

% bad
f() ->
    receive A -> A end,
    receive A -> A; B -> B end,
        receive A -> A; B -> B end,
            receive X -> X after X -> X end,
            receive A -> A; B -> B after X -> X end,
                ok.
%%%%%%%
% try %
%%%%%%%

f() ->
    try
        f()
    catch
        A ->
            B
    end,
    try
        f()
    catch
        A ->
            B
    after
        Timeout ->
            Timeout
    end.

f() ->
    try f()
    catch
        A -> B
    end,
    try f()
    catch
        A -> B
    after
        Timeout -> Timeout
    end.

f() ->
    try f() catch A -> B end,
    try f() catch A -> B after Timeout -> Timeout end,
    ok.

% bad
f() ->
    fun
        init/0,
        ok.

%%%%%%%%%%%
% Records %
%%%%%%%%%%%

% bad
f() ->
    A#rec.field,
    A#rec
    .field,
bad_indent.
