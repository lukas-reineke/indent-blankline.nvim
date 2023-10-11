local scope = require "ibl.scope"

local M = {}


---@enum ibl.indent.whitespace
M.whitespace = {
    TAB_START = 1,
    TAB_START_SINGLE = 2,
    TAB_FILL = 3,
    TAB_END = 4,
    SPACE = 5,
    INDENT = 6,
}

---@class ibl.indent_state
---@field cap boolean
---@field stack table<number, number>?

---@class ibl.indent_options
---@field smart_indent_cap boolean
---@field shiftwidth number
---@field tabstop number
---@field vartabstop string

--- Takes the whitespace of a line and returns a list of ibl.indent.whitespace
---
---@param whitespace string
---@param opts ibl.indent_options
---@param indent_state ibl.indent_state?
---@return ibl.indent.whitespace[], ibl.indent_state
M.get = function(whitespace, opts, indent_state)
    if not indent_state then
        indent_state = { cap = false, stack = {} }
    end
    local shiftwidth = opts.shiftwidth
    local tabstop = opts.tabstop
    local vartabstop = opts.vartabstop
    local spaces = 0
    local tabs = 0
    local extra = 0
    local indent_cap = indent_state.stack[#indent_state.stack] or 0
    if indent_state.cap then
        indent_cap = indent_state.stack[1] or 0
        indent_state.cap = false
    end
    local varts = vim.tbl_map(tonumber, vim.split(vartabstop, ",", { trimempty = true }))
    if shiftwidth == 0 then
        shiftwidth = tabstop
    end
    local whitespace_tbl = {}

    for ch in whitespace:gmatch "." do
        if ch == "\t" then
            local tab_width = tabstop - ((spaces + extra - tabstop) % tabstop)
            while #varts > 0 do
                tabstop = table.remove(varts, 1)
                if tabstop > spaces + extra then
                    tab_width = tabstop - spaces + extra
                    break
                end
            end
            tabs = tabs + tab_width

            if tab_width == 1 then
                table.insert(whitespace_tbl, M.whitespace.TAB_START_SINGLE)
            else
                table.insert(whitespace_tbl, M.whitespace.TAB_START)
            end

            for i = 2, tab_width do
                if i == tab_width then
                    table.insert(whitespace_tbl, M.whitespace.TAB_END)
                else
                    table.insert(whitespace_tbl, M.whitespace.TAB_FILL)
                end
            end
        else
            local mod = (spaces + tabs + extra) % shiftwidth
            if vim.tbl_contains(indent_state.stack, spaces + tabs) then
                table.insert(whitespace_tbl, M.whitespace.INDENT)
                extra = extra + mod
            elseif mod == 0 then
                if #whitespace_tbl < indent_cap or not opts.smart_indent_cap then
                    table.insert(whitespace_tbl, M.whitespace.INDENT)
                    extra = extra + mod
                else
                    indent_state.cap = true
                    table.insert(whitespace_tbl, M.whitespace.SPACE)
                end
            else
                table.insert(whitespace_tbl, M.whitespace.SPACE)
            end
            spaces = spaces + 1
        end
    end

    indent_state.stack = vim.tbl_filter(function(a)
        return a < spaces + tabs
    end, indent_state.stack)
    table.insert(indent_state.stack, spaces + tabs)

    return whitespace_tbl, indent_state
end

--- Returns true if the passed whitespace is an indent
---
---@param whitespace ibl.indent.whitespace
M.is_indent = function(whitespace)
    return vim.tbl_contains({ M.whitespace.INDENT, M.whitespace.TAB_START, M.whitespace.TAB_START_SINGLE }, whitespace)
end

--- Returns true if the passed whitespace belongs to space indent
---
---@param whitespace ibl.indent.whitespace
M.is_space_indent = function(whitespace)
    return vim.tbl_contains({ M.whitespace.INDENT, M.whitespace.SPACE }, whitespace)
end

---@param bufnr number
---@param config ibl.config.full
---@return TSNode?
M.get_current_block = function(bufnr, config)
    local lang_tree_ok, lang_tree = pcall(vim.treesitter.get_parser, bufnr)
    if not lang_tree_ok or not lang_tree then
        return nil
    end

    local win
    if bufnr ~= vim.api.nvim_get_current_buf() then
        local win_list = vim.fn.win_findbuf(bufnr)
        win = win_list and win_list[1]
        if not win then
            return nil
        end
    else
        win = 0
    end

    local range = scope.get_cursor_range(win)
    lang_tree = scope.language_for_range(lang_tree, range, config)
    if not lang_tree then
        return nil
    end

    -- get the current_node at the mouse
    local current_node = vim.treesitter.get_node()
    if current_node then
        local current_block = current_node:tree():root()
        local parent_block = current_node --[[@as TSNode|nil]]
        if current_block == parent_block then
            -- if we are in the root, don't show indents
            return nil
        end
        while parent_block do
            -- go up the tree until we are one step below the root
            if parent_block:parent() == current_block then
                current_block = parent_block
                break
            else
                parent_block = parent_block:parent()
            end
        end
        return current_block
    else
        -- if we can't get current_node, then don't show indents anywhere
        return nil
    end
end

return M
