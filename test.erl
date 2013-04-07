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

f() ->
    (
        .% xx

f() ->
    A . B, % not valid Erlang, but why not behave nicely
    ok.

% bad
ok.
        f() ->
            ok.

f() ->
    A = #a{},

    %A#a . f1, % syntax error
    A#a .f1,   % valid Erlang

    %A#a.      % syntax error
    %f1,

    A#a
    .f1,   % valid Erlang

    _ = 1.2,   % valid Erlang
    %_ = 1 .2,  % syntax error
    %_ = 1 . 2, % syntax error
    %_ = 1. 2,  % syntax error

    _ = " .
    ", % valid Erlang

    _ = ' .
    ', % valid Erlang

    ok.

f() -> 1. f() -> 2. f() ->
    3.

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

f() ->
    A#rec.field,
    A#rec
    .field,
    ok.
