This is an improved version of the Erlang indentation shipped with Vim 7.3.

It can be tested in the following way:

- Open `test.erl` in vim from this directory. (`test.erl` should always show the
  Erlang code is indented by the script – not how it should be.)
- Source `helper.vim` (`:source helper.vim`)
- Press F1 to load the new indentation (`indent/erlang.vim`).
- Press F2 to reindent the current buffer.
