# Erlang indentation and syntax for Vim

This is an improved version of the Erlang indentation and syntax shipped with
Vim 7.3.

## Usage

- Copy `syntax/erlang.vim` into `~/syntax`.
- Copy `indent/erlang.vim` into `~/indent`.

## Development and testing

The indentation script can be tested in the following way:

- Copy `syntax/erlang.vim` into `~/syntax`.
- Open `test.erl` in Vim from this directory. (`test.erl` always shows how the
  Erlang code is indented by the script – not how it should be.)
- Source `helper.vim` (`:source helper.vim`)
- Press F1 to load the new indentation (`indent/erlang.vim`).
- Press F3 to reindent the current line. Press shift-F3 to print a log.
- Press F4 to reindent the current buffer.
- Press F5 to show the tokens of the current line.

*Note:*

- When the indentation scripts detects a syntax error in test mode (i.e. when it
  was loaded with `F1` from `helper.vim`), it indents the line to column 40
  instead of leaving it as it is. This behavior is useful for testing.
