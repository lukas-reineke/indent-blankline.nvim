local conf = require "ibl.config"
local hooks = require "ibl.hooks"

---@class ibl.highlight
---@field char string
---@field underline string?

local M = {
    ---@type ibl.highlight[]
    indent = {},
    ---@type ibl.highlight[]
    whitespace = {},
    ---@type ibl.highlight[]
    scope = {},
    ---@type ibl.highlight[]
    current_indent = {},
}

local get = function(name)
    return vim.api.nvim_get_hl(0, { name = name })
end

local not_set = function(hl)
    return not hl or vim.tbl_count(hl) == 0
end

local setup_builtin_hl_groups = function()
    local whitespace_hl = get "Whitespace"
    local line_nr_hl = get "LineNr"
    local cursor_line_nr_hl = get "CursorLineNr"
    local ibl_indent_hl_name = "IblIndent"
    local ibl_whitespace_hl_name = "IblWhitespace"
    local ibl_scope_hl_name = "IblScope"
    local ibl_current_indent_hl_name = "IblCurrentIndent"

    if not_set(get(ibl_indent_hl_name)) then
        vim.api.nvim_set_hl(0, ibl_indent_hl_name, whitespace_hl)
    end
    if not_set(get(ibl_whitespace_hl_name)) then
        vim.api.nvim_set_hl(0, ibl_whitespace_hl_name, whitespace_hl)
    end
    if not_set(get(ibl_scope_hl_name)) then
        vim.api.nvim_set_hl(0, ibl_scope_hl_name, line_nr_hl)
    end
    if not_set(get(ibl_current_indent_hl_name)) then
        vim.api.nvim_set_hl(0, ibl_current_indent_hl_name, cursor_line_nr_hl)
    end
end

M.setup = function()
    local config = conf.get_config(-1)

    for _, fn in
        pairs(hooks.get(-1, hooks.type.HIGHLIGHT_SETUP) --[[ @as ibl.hooks.cb.highlight_setup[] ]])
    do
        fn()
    end

    setup_builtin_hl_groups()

    local indent_highlights = config.indent.highlight
    if type(indent_highlights) == "string" then
        indent_highlights = { indent_highlights }
    end
    M.indent = {}
    for i, name in ipairs(indent_highlights) do
        local hl = get(name)
        if not_set(hl) then
            error(string.format("No highlight group '%s' found", name))
        end
        hl.nocombine = true
        M.indent[i] = { char = string.format("@ibl.indent.char.%d", i) }
        vim.api.nvim_set_hl(0, M.indent[i].char, hl)
    end

    local whitespace_highlights = config.whitespace.highlight
    if type(whitespace_highlights) == "string" then
        whitespace_highlights = { whitespace_highlights }
    end
    M.whitespace = {}
    for i, name in ipairs(whitespace_highlights) do
        local hl = get(name)
        if not_set(hl) then
            error(string.format("No highlight group '%s' found", name))
        end
        hl.nocombine = true
        M.whitespace[i] = { char = string.format("@ibl.whitespace.char.%d", i) }
        vim.api.nvim_set_hl(0, M.whitespace[i].char, hl)
    end

    local scope_highlights = config.scope.highlight
    if type(scope_highlights) == "string" then
        scope_highlights = { scope_highlights }
    end
    M.scope = {}
    for i, scope_name in ipairs(scope_highlights) do
        local char_hl = get(scope_name)
        if not_set(char_hl) then
            error(string.format("No highlight group '%s' found", scope_name))
        end
        char_hl.nocombine = true
        M.scope[i] = {
            char = string.format("@ibl.scope.char.%d", i),
            underline = string.format("@ibl.scope.underline.%d", i),
        }
        vim.api.nvim_set_hl(0, M.scope[i].char, char_hl)
        vim.api.nvim_set_hl(0, M.scope[i].underline, { sp = char_hl.fg, underline = true })
    end

    local current_indent_highlights = config.current_indent.highlight
    if type(current_indent_highlights) == "string" then
        current_indent_highlights = { current_indent_highlights }
    end
    M.current_indent = {}
    for i, current_indent_name in ipairs(current_indent_highlights) do
        local char_hl = get(current_indent_name)
        if not_set(char_hl) then
            error(string.format("No highlight group '%s' found", current_indent_name))
        end
        char_hl.nocombine = true
        M.current_indent[i] = {
            char = string.format("@ibl.current_indent.char.%d", i),
            underline = string.format("@ibl.current_indent.underline.%d", i),
        }
        vim.api.nvim_set_hl(0, M.current_indent[i].char, char_hl)
        vim.api.nvim_set_hl(0, M.current_indent[i].underline, { sp = char_hl.fg, underline = true })
    end
end

return M
