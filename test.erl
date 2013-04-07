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

%%%%%%%%%%%%%
% begin-end %
%%%%%%%%%%%%%

f() ->
    begin A, % [{BeginCol, 1}, {ACol, 0}]
            B % [{BCol, 0}]
    end, % [{EndCol, -1}]
    begin % [{BeginCol, 1}]
            A, % [{ACol, 0}]
            B % [{BCol, 0}]
    end, % [{EndCol, -1}]
    begin A, % [{BeginCol, 1}, {ACol, 0}]
            begin B % [{BeginCol, 1}, {BCol, 0}]
            end, % [{EndCol, -1}]
            C % [{CCol, 0}]
    end, % [{EndCol, -1}]
    begin
            A,
            begin % [{BeginCol, 1}]
                    B % [{BCol, 0}]
            end, % [{EndCol, -1}]
            C, D, % [{CCol, 0}, {DCol, 0}]
            E
    end,
    begin
            A, % [{BCol, 0}]
            B, begin % [{BCol, 0}, {BeginCol, 1}]
                    C % [{CCol, 0}]
            end, % [{EndCol, -1}]
            D
    end,
    ok.

f() ->

    % [{BeginCol, 1}, {ACol, 0}, {EndCol, 1}]
    % We don't need BCol
    begin A, B end,

    % [{BeginCol, 1}, {ACol, 0}, {BeginCol, 1}, {BCol, 0}, {EndCol, 1}, {CCol, 0}, {EndCol, 1}]
    begin A, begin B end, C end,
    ok.

%%%%%%%%
% case %
%%%%%%%%

f() ->
    case A of A -> case B of B -> B end end,
    ok.

f() ->
    case A of
        A ->
            case B of
                B -> B
            end
    end,
    ok.

f() ->
    f(case X of
            A -> A
        end),
    ok.

f() ->
    ffffff(case X of
            A -> fffffff(case X of
                        B -> B
                    end)
        end),
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
    % No BCol
    g(A, B, % [{FCol, 0}, {'OpenParCol', 1}, {ACol, 0}]
        C, % [{CCol, 0}]
        D),
    ok.


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

% receive -- with linebreaks
f() ->

    % receive with 0 branch
    receive end, % not valid Erlang, but why not behave nicely

% receive with 1 branch
receive
        A -> A
    end,

    receive
        A ->
            A
    end,

    % receive with 2 branches
    receive
        A -> A;
        B -> B
    end,

    receive
        A ->
            A;
        B ->
            B
    end,

    ok.

% receive + after -- with linebreaks
f() ->

    % receive with 0 branch
    receive
    after
        T -> T
    end,

    % receive with 1 branch
    receive
        A -> A
    after
        T -> T
    end,

    receive
        A ->
            A
    after
        T ->
            T
    end,

    % receive with 2 branches
    receive
        A -> A;
        B -> B
    after
        T -> T
    end,

    receive
        A ->
            A;
        B ->
            B
    after
        T -> T
    end,

    ok.

% receive -- one-liners
% bad
f() ->
    receive A -> A end,
    receive A -> A; B -> B end,

        % half-liners
        receive A -> A end, receive A -> A end,
        receive A -> A; B -> B end, receive A -> A; B -> B end,
                ok.

% receive + after -- one-liners
% bad
f() ->

    receive after T -> T end,
    receive A -> A after T -> T end,
    receive A -> A; B -> B after T -> T end, 

        % half-liners
        receive after T -> T end, receive after T -> T end,
        receive A -> A after T -> T end, receive A -> A after T -> T end,
        receive A -> A; B -> B after T -> T end, receive A -> A; B -> B after T -> T end, 
                ok.

% tricky scenarios which may catch some heuristics
f() ->
    receive
        A ->
            "receive"
    after
        T -> T
    end.

f() ->
    ok, receive
    after
        T -> T
    end.

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
