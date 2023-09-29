# Indent Blankline

This plugin adds indentation guides to Neovim.
It uses Neovim's virtual text feature and **no conceal**

To start using indent-blankline, call the `ibl.setup()` function.

This plugin requires the latest stable version of Neovim.

## Install

Use your favourite plugin manager to install.

For [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{ "lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {} }
```

For [pckr.nvim](https://github.com/lewis6991/pckr.nvim):

```lua
use "lukas-reineke/indent-blankline.nvim"
```

## Setup

To initialize and configure indent-blankline, run the `setup` function.

```lua
require("ibl").setup()
```

Optionally, you can pass a configuration table to the setup function. For all
available options, take a look at `:help ibl.config`.

## Screenshots

### Simple

```lua
require("ibl").setup()
```

<img width="900" src="https://github.com/lukas-reineke/indent-blankline.nvim/assets/12900252/69ca7bb2-e294-4437-818b-8b47e63244b3" alt="Screenshot" />

### Scope

Scope requires treesitter to be set up.

```lua
require("ibl").setup()
```

<img width="900" src="https://github.com/lukas-reineke/indent-blankline.nvim/assets/12900252/a9d2426f-56a4-44bd-8bb5-2a3c5f5ca384" alt="Screenshot" />

The scope is _not_ the current indentation level! Instead, it is the
indentation level where variables or functions are accessible, as in [Wikipedia Scope (Computer Science)](<https://en.wikipedia.org/wiki/Scope_(computer_science)>). This depends
on the language you are writing. For more information, see `:help ibl.config.scope`.

The start and end of scope uses underline, so to achieve the best result you
might need to tweak the underline position. In Kitty terminal for example you
can do that with [modify_font](https://sw.kovidgoyal.net/kitty/conf/#opt-kitty.modify_font)

### Mixed indentation

```lua
require("ibl").setup()
```

<img width="900" src="https://github.com/lukas-reineke/indent-blankline.nvim/assets/12900252/64a1a3c6-74e6-4183-901d-ad94c1edc59c" alt="Screenshot" />

### Multiple indent colors

```lua
local highlight = {
    "RainbowRed",
    "RainbowYellow",
    "RainbowBlue",
    "RainbowOrange",
    "RainbowGreen",
    "RainbowViolet",
    "RainbowCyan",
}

local hooks = require "ibl.hooks"
-- create the highlight groups in the highlight setup hook, so they are reset
-- every time the colorscheme changes
hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
    vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
    vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
    vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
    vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
    vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
    vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
    vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
end)

require("ibl").setup { indent = { highlight = highlight } }
```

<img width="900" src="https://github.com/lukas-reineke/indent-blankline.nvim/assets/12900252/78fd962a-67fa-4ddf-8924-780256dfd118" alt="Screenshot" />

### Background color indentation guides

```lua
local highlight = {
    "CursorColumn",
    "Whitespace",
}
require("ibl").setup {
    indent = { highlight = highlight, char = "" },
    whitespace = {
        highlight = highlight,
        remove_blankline_trail = false,
    },
    scope = { enabled = false },
}
```

<img width="900" src="https://github.com/lukas-reineke/indent-blankline.nvim/assets/12900252/35d70992-4482-4577-b1e1-28fda23b2b2d" alt="Screenshot" />

### rainbow-delimiters.nvim integration

[rainbow-delimiters.nvim](https://gitlab.com/HiPhish/rainbow-delimiters.nvim)

```lua
local highlight = {
    "RainbowRed",
    "RainbowYellow",
    "RainbowBlue",
    "RainbowOrange",
    "RainbowGreen",
    "RainbowViolet",
    "RainbowCyan",
}
local hooks = require "ibl.hooks"
-- create the highlight groups in the highlight setup hook, so they are reset
-- every time the colorscheme changes
hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
    vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#E06C75" })
    vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#E5C07B" })
    vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#61AFEF" })
    vim.api.nvim_set_hl(0, "RainbowOrange", { fg = "#D19A66" })
    vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#98C379" })
    vim.api.nvim_set_hl(0, "RainbowViolet", { fg = "#C678DD" })
    vim.api.nvim_set_hl(0, "RainbowCyan", { fg = "#56B6C2" })
end)

vim.g.rainbow_delimiters = { highlight = highlight }
require("ibl").setup { scope = { highlight = highlight } }

hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
```

<img width="900" src="https://github.com/lukas-reineke/indent-blankline.nvim/assets/12900252/67707d8e-57d3-411c-8418-77908d8babd9" alt="Screenshot" />
