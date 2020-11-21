# Erlang runtime files for Vim

This repository contains the indentation, syntax and ftplugin scripts which are
shipped with Vim for the Erlang programming language.

## Installation

### Installing manually

1.  Clone this repository:

    ```
    $ mkdir -p ~/.vim/bundle
    $ cd ~/.vim/bundle
    $ git clone https://github.com/vim-erlang/vim-erlang-runtime
    ```

2.  Add the repository path to `runtimepath` in your `.vimrc`:

    ```
    :set runtimepath^=~/.vim/bundle/vim-erlang-runtime/
    ```

### Installing manually, alternative method

1.  Copy `syntax/erlang.vim` into `~/.vim/syntax/`.

2.  Copy `indent/erlang.vim` into `~/.vim/indent/`.

3.  Copy `ftplugin/erlang.vim` into `~/.vim/ftplugin/`.

### Installing using vim-plug

1.  Install vim-plug using the [instructions][vim-plug].

2.  Add vim-erlang-runtime to your plugin list in `.vimrc` by inserting the
    following lines:

    ```
    '' Erlang Runtime
    Plug 'vim-erlang/vim-erlang-runtime'
    ```

    between

    ```
    call plug#begin('~/.vim/plugged')
    ```

    and

    ```
    call plug#end()
    ```

3.  Run `:PlugInstall`.

[vim-plug]:https://github.com/junegunn/vim-plug

## Development and testing the indentation script

This section is relevant only if you want to be involved in the development of
the indentation script.

The indentation script can be tested in the following way:

1.  Copy `syntax/erlang.vim` into `~/syntax`.

2.  Change to the `test` directory and open `test/test_indent.erl`.

    Note: `test_indent.erl` always shows how the Erlang code is indented by the
    script – not how it should be.

3.  Source `helper.vim` (`:source helper.vim`)

4.  Press F1 to load the new indentation (`indent/erlang.vim`).

5.  Press F3 to reindent the current line. Press shift-F3 to print a log.

6.  Press F4 to reindent the current buffer.

7.  Press F5 to show the tokens of the current line.

Note: When the indentation scripts detects a syntax error in test mode (i.e.
when it was loaded with `F1` from `helper.vim`), it indents the line to column
40 instead of leaving it as it is. This behavior is useful for testing.

## Tip: indentation from the command line

The following snippet re-indents all `src/*.?rl` files using the indentation
shipped with Vim:

```bash
vim -ENn -u NONE \
    -c 'filetype plugin indent on' \
    -c 'set expandtab shiftwidth=4' \
    -c 'args src/*.?rl' \
    -c 'argdo silent execute "normal gg=G" | update' \
    -c q
```

Notes:

- This can be for example added to a Makefile as a "re-indent rule".
- You can use the `expandtab`, `shiftwidth` and `tabstop` options to customize
  how to use space and tab characters. The command above uses only spaces, and
  one level of indentation is 4 spaces.
- If you would like to use a different version of the indentation script from
  that one shipped in Vim (e.g. because you have Vim 7.3), then also add the
  following as the first command parameter:

  ```bash
  -c ':set runtimepath^=~/.vim/bundle/vim-erlang-runtime/'
  ```

## Running vader tests

The tests for the `include` and `define` options in `test_include_search.vader`
are run using the [vader](https://github.com/junegunn/vader.vim) Vim plugin.

A common pattern to use for test cases is to do

```vim
Given:
  text to test

Do:
  daw

Expect:
  to text
```

The text that should be tested is placed in the `Given` block. A normal command
is placed in the `Do` block and the expected output in the `Expect` block. The
cursor is by default on the first column in the first line, and doing `daw`
should therefore delete around the first word.

The simplest way to run a vader test file is to open the test file in Vim and
run `:Vader`. To run it from the command line, do `vim '+Vader!*' && echo
Success || echo Failure`. If the environment variable `VADER_OUTPUT_FILE` is
set, the results are written to this file.

To test the code with only the wanted plugins loaded and without a vimrc, a
similar command as for testing indentation can be run from the command line. The
command below does the following:

- Starts Vim with nocompatible set and without sourcing any vimrc.
- Puts the current folder first in the runtimepath, such that the ftplugin,
  indent etc. in the current folder are sourced first. Then the regular runtime
  path is added and finally the path to where vader is installed is added (this
  will be different depending on which plugin manager you use, the path below is
  where vim-plug puts it).
- Sources the vader plugin file so that the `Vader` command can be used.
- Enables using filetype specific settings and indentation.
- Runs all vader test files found in the current directory and then exits Vim.
- Echoes `Success` if all test cases pass, else `Failure`.

```bash
vim -N -u NONE \
    -c 'set runtimepath=.,$VIMRUNTIME,~/.vim/plugged/vader.vim' \
    -c 'runtime plugin/vader.vim' \
    -c 'filetype plugin indent on' \
    -c 'Vader!*' \
    && echo Success || echo Failure
```

For more details, see the [vader](https://github.com/junegunn/vader.vim)
repository.
