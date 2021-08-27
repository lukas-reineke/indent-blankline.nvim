# Indent Blankline

This plugin adds indentation guides to all lines (including empty lines).

It uses Neovims virtual text feature and **no conceal**

This plugin requires Neovim 0.5 or higher. It makes use of Neovim only
features so it will not work in Vim.
There is a legacy version of the plugin that supports Neovim 0.4 under the
branch `version-1`

## Install

Use your favourite plugin manager to install.

#### Example with Packer

[wbthomason/packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
-- init.lua
require("packer").startup(
    function()
        use "lukas-reineke/indent-blankline.nvim"
    end
)
```

#### Example with Plug

[junegunn/vim-plug](https://github.com/junegunn/vim-plug)

```vim
" init.vim
call plug#begin('~/.vim/plugged')
Plug 'lukas-reineke/indent-blankline.nvim'
call plug#end()
```

## Setup

To configure indent-blankline, either run the setup function, or set variables manually.
The setup function has a single table as argument, keys of the table match the `:help indent-blankline-variables` without the `indent_blankline_` part.

```lua
require("indent_blankline").setup {
    char = "|",
    buftype_exclude = {"terminal"}
}
```

Please see `:help indent_blankline.txt`for more details and all possible values.

A lot of [Yggdroot/indentLine](https://github.com/Yggdroot/indentLine) options should work out of the box.

## Screenshots

All screenshots use [my custom onedark color scheme](https://github.com/lukas-reineke/onedark.nvim).

### Simple

```lua
vim.opt.listchars = {
    eol = "↴",
}

require("indent_blankline").setup {
    show_end_of_line = true,
}
```

<img width="900" src="https://i.imgur.com/3gRG5qI.png" alt="Screenshot" />

#### With custom `listchars` and `g:indent_blankline_space_char`

```lua
vim.opt.listchars = {
    space = "⋅",
    eol = "↴",
}

require("indent_blankline").setup {
    show_end_of_line = true,
    space_char_blankline = " ",
}
```

<img width="900" src="https://i.imgur.com/VxCThMu.png" alt="Screenshot" />

#### With custom `g:indent_blankline_char_highlight_list`

```lua
vim.opt.termguicolors = true
vim.cmd [[highlight IndentBlanklineIndent1 guifg=#E06C75 blend=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent2 guifg=#E5C07B blend=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent3 guifg=#98C379 blend=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent4 guifg=#56B6C2 blend=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent5 guifg=#61AFEF blend=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent6 guifg=#C678DD blend=nocombine]]

vim.opt.listchars = {
    space = "⋅",
    eol = "↴",
}

require("indent_blankline").setup {
    space_char_blankline = " ",
    char_highlight_list = {
        "IndentBlanklineIndent1",
        "IndentBlanklineIndent2",
        "IndentBlanklineIndent3",
        "IndentBlanklineIndent4",
        "IndentBlanklineIndent5",
        "IndentBlanklineIndent6",
    },
}
```

<img width="900" src="https://i.imgur.com/E3B0PUb.png" alt="Screenshot" />

#### With custom background highlight

```lua
vim.opt.termguicolors = true
vim.cmd [[highlight IndentBlanklineIndent1 guibg=#1f1f1f blend=nocombine]]
vim.cmd [[highlight IndentBlanklineIndent2 guibg=#1a1a1a blend=nocombine]]

require("indent_blankline").setup {
    char_highlight_list = {
        "IndentBlanklineIndent1",
        "IndentBlanklineIndent2",
    },
    show_trailing_blankline_indent = false,
}
```

<img width="900" src="https://i.imgur.com/DukMZGk.png" alt="Screenshot" />

#### With context indent highlighted by treesitter

```lua
vim.opt.listchars = {
    space = "⋅",
    eol = "↴",
}

require("indent_blankline").setup {
    space_char_blankline = " ",
    show_current_context = true,
}
```

<img width="900" src="https://i.imgur.com/mkyGPZZ.png" alt="Screenshot" />

## Thanks

Special thanks to [Yggdroot/indentLine](https://github.com/Yggdroot/indentLine)
