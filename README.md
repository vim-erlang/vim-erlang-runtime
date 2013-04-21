This is an improved version of the Erlang indentation shipped with Vim 7.3.

It can be tested in the following way:

- Copy `syntax/erlang.vim` into `~/syntax`. If you skip this, the only
  difference will be that multiline strings will not always be recognized.
- Open `test.erl` in vim from this directory. (`test.erl` should always show the
  Erlang code is indented by the script – not how it should be.)
- Source `helper.vim` (`:source helper.vim`)
- Press F1 to load the new indentation (`indent/erlang.vim`).
- Press F2 to run the unit tests.
- Press F3 to reindent the current line. Press shift-F3 to print a log.
- Press F4 to reindent the current buffer. Press shift-F4 to print a log.
- Press F5 to show the tokens of the current line.
