# Indent Blankline

This plugin adds indentation guides to empty lines.

It is recommended, but not required, to use it together with [Yggdroot/indentLine](https://github.com/Yggdroot/indentLine).

This plugin requires Neovim 0.4.0 or higher. It makes use of Neovim only
features so it will not work in Vim.

## Note

**If you are using Neomvim 0.5, you should use the `lua` branch.**  
It is much faster and has real-time update support.  
It will become the default once Neovim 0.5 is released.

## Details

indent-blankline uses the virtual text feature from Neovim to display
indentation guides on empty lines.\
Virtual text can currently only be added after the end of the line, so it is not
possible to use this to display indentation guides on lines with text.

The indentation level is generated like Neovim would generate normal
indentation.\
If `indentexpr` is empty, it uses `cindent()`.\
If `indentexpr` is set to `lisp`, it uses `lispindent()`.\
If `indentexpr` is set to anything else, it uses that function.

**The lines to indent and the level of indentation is computed asynchronously with
an embedded read-only instance of Neovim.**

This makes generation of indentation not affect normal editing. But it could be
resource intensive.\
indent-blankline needs to open buffers in read-only mode with autocommands, to
set up the correct `indentexpr`. In most cases this should not cause issues, but
if you have side effects defined for opening buffers, this might lead to undesired
execution of those.

A possible solution for this would be to check if Neovim has a UI attached
before running such side effects.

```vim
if len(nvim_list_uis())
    " your side effect code
endif
```

## IndentLine dependency

indent-blankline does not require the [indentLine](https://github.com/Yggdroot/indentLine)
Plugin. But it is recommended to use the two together.

Almost all settings from indentLine will work seamlessly with indent-blankline
as well without any setup.

## Settings

Please see `:help indent_blankline.txt`

## Screenshots

Screenshots are made together with indentLine

#### Default settings

![Screenshot](https://i.imgur.com/3gRG5qI.png)

#### With custom `listchars` and `g:indent_blankline_space_char`

![Screenshot](https://i.imgur.com/VxCThMu.png)
