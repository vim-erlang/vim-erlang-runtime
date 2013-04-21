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

%%%%%%%%%
% Terms %
%%%%%%%%%

f() ->
    f(
     ),
    {A},
    {A, B},

    {A,
     B},

    {{A,
      B},
     C,
     D},
    {[A,
      B]},
    {{A,
      {{B,
        C},
       D
      }}},
    [A
    ],

    {[A,B
     ]},

    {[A,B
     ]
    },
    ok.

f() ->
    f(
     ),
    {
     A
    },
    {
     A,
     B
    },

    {
     {
      A,
      B
     },
     C,
     D
    },
    {
     [
      A,
      B
     ]
    },
    {{
      A,
      {
       {
        B,
        C
       },
       D
      }}},
    [
     A
    ],

    {[
      A,B
     ]},

    {
     [
      A
      ,
      B
     ]
    },
    ok.

f() ->
    1
    ,
    2
    .

f() ->
    function_call),
                                        ok. % syntax error in prev.line

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
    % Not valid Erlang; the indent script thinks 'B' is the start of a new
    % clause, so it indents 'ok' below 'B'.
    A . B,
        ok.

% Not valid Erlang, but why not behave nicely
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

f() -> 1. f() ->
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

f() ->
    x("foo
      bar((("), % string continuation lines like this one are level changed
    x("foo
      bar((("),
    x("foo
      bar\\"),
    f("foo
      bar
      spam"),
    "foo
       bar",
    ok,
    "foo
      bar
      spam",

    "foo
      bar
      spam begin
      end",

    ok,
    "foo
      bar", [a,
             b],
    [a,
     b]),
                                        ok. % syntax error in the prev.line

f() ->
    x("foo
      %        bar")
    ,
    ok.

%%%%%%%%%%%%%
% begin-end %
%%%%%%%%%%%%%

f() ->
    begin A,
          B
    end,
    begin
        A,
        B
    end,
    begin A,
          begin B
          end,
          C
    end,
    begin
        A,
        begin
            B
        end,
        C, D,
        E
    end,
    begin
        A,
        B, begin
               C
           end,
        D
    end,
    ok.

f() ->
    begin A, B end,
    begin A, begin B end, C end,
    ok.

%%%%%%%%
% case %
%%%%%%%%

f() ->
    case X,
         Y of
        A ->
            A
    end,

    case X of
        A ->
            A
    end,

    case
        X
    of
        A ->
            A
    end,

    case
        X
    of
        A ->
            A
    end,

    case X of
        A ->
            A;
        B ->
            B
    end,

    case X of
        A
        ->
            A
    end,

    ok.

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

% case and when

f() ->
    case A of
        B when B > 0 ->
            ok;
        B
          when
              B > 0 ->
            ok;

        B
          when
              B > 0;
              B < 0
              ->
            ok
    end,
    ok.


%%%%%%%%%%%%%%%%%%%
% Basic functions %
%%%%%%%%%%%%%%%%%%%

f() ->
    ok.

f
(
)
->
    ok.

%%%%%%%%%%%%%%%%%%%%%
% Actual parameters %
%%%%%%%%%%%%%%%%%%%%%

% bad
f() ->
    g(A, B,
      C,
      D),
    ok.

% bad
f() ->
    long_function(
                   A, B,
                   C,
                   D),
    ok.

%%%%%%%%%%%%%%%%%%%%%
% Formal parameters %
%%%%%%%%%%%%%%%%%%%%%

% One expression after "when"
f(A) when A == 0 ->
    ok.

f(A)
  when A == 0
       ->
    ok.

f(A)
  when
      A == 0
      ->
    ok.

% Two expressions after "when"
f(A) when A == 0; B == 0 ->
    ok.

f(A)
  when A == 0;
       B == 0
       ->
    ok.

f(A)
  when
      A == 0;
      B == 0
      ->
    ok.

%%%%%%%
% fun %
%%%%%%%

% fun - without linebreaks
f() ->
    fun a/0,
    fun (A) -> A end,
    fun (A) -> A; (B) -> B end,
    ok.

% fun - with some linebreaks
f() ->
    fun a/0,
    fun (A) -> A
    end,
    fun (A) -> A;
        (B) -> B
    end,
    ok.

% fun - with more linebreaks
f() ->
    fun a/0,
    fun (A) ->
            A
    end,
    fun (A) ->
            A;
        (B) ->
            B
    end,
    ok.

% fun - with some linebreaks with less space
f() ->
    fun a/0,
    fun(A) -> A
    end,
    fun(A) -> A;
       (B) -> B
    end,
    ok.

% fun - with more linebreaks with less space
f() ->
    fun a/0,
    fun(A) ->
            A
    end,
    fun(A) ->
            A;
       (B) ->
            B
    end,
    ok.

% fun - with extra linebreaks
f() ->

    fun
    a/0,

    fun
    a
    /
    0,

    fun
        (A) ->
            A
    end,

    fun
        (A) ->
            A;
        (B) ->
            B
    end,
    ok.

% fun - without linebreaks + when
f() ->
    fun a/0,
    fun (A) when A > 0 -> A end,
    fun (A) when A > 0 -> A; (B) when B > 0 -> B end,
    ok.

% fun - with some linebreaks + when
f() ->
    fun a/0,
    fun (A) when A > 0 -> A
    end,
    fun (A) when A > 0 -> A;
        (B) when B > 0 -> B
    end,
    ok.

% fun - with more linebreaks + when
f() ->
    fun a/0,
    fun (A) when A > 0 ->
            A
    end,
    fun  (A) when A > 0 ->
            A;
         (B) when B > 0 ->
            B
    end,
    ok.

% fun - with some linebreaks with less space + when
f() ->
    fun a/0,
    fun(A) when A > 0 -> A
    end,
    fun(A) when A > 0 -> A;
       (B) when B > 0 -> B
    end,
    ok.

% fun - with more linebreaks with less space + when
f() ->
    fun a/0,
    fun(A) when A > 0 ->
            A
    end,
    fun(A) when A > 0 ->
            A;
       (B) when B > 0 ->
            B
    end,
    ok.

% fun - with extra linebreaks + when
f() ->

    fun
    a/0,

    fun
    a
    /
    0,

    fun
        (A) when A > 0 ->
            A
    end,

    fun
        (A) when A > 0 ->
            A;
        (B) when B > 0 ->
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

%%%%%%%%%%%
% Records %
%%%%%%%%%%%

f() ->
    A#rec.field,
    A#rec
    .field,
    ok.

%%%%%%%%%%%%
% Issue #1 %
%%%%%%%%%%%%

rand_pprint_slice() ->
    F = fun pprint/3,
    Rand = fun() ->
                   Bytes = crypto:rand_bytes(random:uniform(?MAX_BIN_SIZE)),
                   Pos = random:uniform(byte_size(Bytes)),
                   Len = random:uniform(byte_size(Bytes)),
                   {Bytes, Pos, Len}
           end,
    Tests = [ Rand() || _ <- lists:seq(1, ?RUNS) ],
    Title = fun(Size, Slice) ->
                    iolist_to_binary(io_lib:format("Random pprint w/ slice: (~p) ~p", [Size, Slice]))
            end,
    [ { Title(byte_size(Bytes), {Pos, Len}), fun() -> ?assertEqual(ok, F(Bytes, {Pos, Len}, [])) end }
      || { Bytes, Pos, Len } <- Tests ].

rand_pprint_opts() ->
    F = fun pprint/2,
    CustomPrinter = fun(B) when is_list(B) -> works end,
    OptsMap = [
               %% Option                          %% Predicate
               { {return,  binary},               fun erlang:is_binary/1  },
               { {return,  iolist},               fun erlang:is_list/1    },

               { {printer, CustomPrinter},        fun(works) -> true; (_) -> false end  },
               { {invalid, option},               fun({'EXIT', {badarg, _}}) -> true; (O) -> O end }
              ],
    Range = lengthOptsMap,
    Rand = fun() ->
                   Input = crypto:rand_bytes(random:uniform(?MAX_BIN_SIZE)),
                   {Opt, Predicate} = lists:nth(random:uniform(Range), OptsMap),
                   {Input, Opt, Predicate}
           end,
    Tests = [ Rand() || _ <- lists:seq(1, ?RUNS) ],
    Title = fun(Opt) ->
                    iolist_to_binary([ "Random pprint w/ opt: ", io_lib:format("~p", [Opt]) ]) end,
    [ { Title(Opt), fun() -> ?assertEqual(true, Pred( catch( F(I, [Opt]) ) )) end }
      || {I, Opt, Pred} <- Tests ].
