local highlights = require "ibl.highlights"
local utils = require "ibl.utils"
local indent = require "ibl.indent"
local whitespace = indent.whitespace
local M = {}

---@alias ibl.virtual_text { [1]: string, [2]: string|string[] }[]
---@alias ibl.char_map { [ibl.indent.whitespace]: string|string[] }

---@param input string|string[]
---@param index number
---@return string
local get_char = function(input, index)
    if type(input) == "string" then
        return input
    end
    return utils.tbl_get_index(input, index)
end

---@param config ibl.config
---@param listchars ibl.listchars
---@param whitespace_only boolean
---@param blankline boolean
---@return ibl.char_map
M.get_char_map = function(config, listchars, whitespace_only, blankline)
    return {
        [whitespace.TAB_START] = config.indent.tab_char or listchars.tab_char_start or config.indent.char,
        [whitespace.TAB_START_SINGLE] = config.indent.tab_char
            or listchars.tab_char_end
            or listchars.tab_char_start
            or config.indent.char,
        [whitespace.TAB_FILL] = (blankline and " ") or listchars.tab_char_fill,
        [whitespace.TAB_END] = (blankline and " ") or listchars.tab_char_end or listchars.tab_char_fill,
        [whitespace.SPACE] = (blankline and " ")
            or (whitespace_only and (listchars.trail_char or listchars.multispace_chars or listchars.space_char))
            or listchars.leadmultispace_chars
            or listchars.lead_char
            or listchars.multispace_chars
            or listchars.space_char,
        [whitespace.INDENT] = config.indent.char,
    }
end

---@param bufnr number
---@param row number?
M.clear_buffer = function(bufnr, row)
    local namespace = vim.api.nvim_create_namespace "indent_blankline"
    local line_start = 0
    local line_end = -1
    if row then
        line_start = row - 1
        line_end = row
    end
    pcall(vim.api.nvim_buf_clear_namespace, bufnr, namespace, line_start, line_end)
end

---@param config ibl.config
---@param char_map ibl.char_map
---@param whitespace_tbl ibl.indent.whitespace[]
---@param is_current_indent_active boolean
---@param current_indent_index number
---@param is_current_indent_end boolean
---@param current_indent_col_start_single number
---@param is_scope_active boolean
---@param scope_index number
---@param is_scope_end boolean
---@param scope_col_start_single number
---@return ibl.virtual_text, ibl.highlight, ibl.highlight
M.get = function(
    config,
    char_map,
    whitespace_tbl,
    is_current_indent_active,
    current_indent_index,
    is_current_indent_end,
    current_indent_col_start_single,
    is_scope_active,
    scope_index,
    is_scope_end,
    scope_col_start_single
)
    local scope_hl = utils.tbl_get_index(highlights.scope, scope_index)
    local current_indent_hl = utils.tbl_get_index(highlights.current_indent, current_indent_index)
    local indent_index = 1
    local virt_text = {}
    for i, ws in ipairs(whitespace_tbl) do
        local whitespace_hl = utils.tbl_get_index(highlights.whitespace, indent_index - 1).char
        local indent_hl
        local underline_hl
        local sa = is_scope_active
        local cia = is_current_indent_active
        local indent_char = get_char(char_map[ws], indent_index)
        local char = indent_char

        if indent.is_indent(ws) then
            whitespace_hl = utils.tbl_get_index(highlights.whitespace, indent_index).char
            if vim.fn.strdisplaywidth(char) == 0 then
                char = char_map[whitespace.SPACE] --[[@as string]]
                sa = false
                cia = false
            else
                indent_hl = utils.tbl_get_index(highlights.indent, indent_index).char
            end
            indent_index = indent_index + 1
        end

        local set_current_indent = function()
            if
                config.current_indent.show_end
                and cia
                and is_current_indent_end
                and i - 1 > current_indent_col_start_single
            then
                current_indent_hl = utils.tbl_get_index(highlights.current_indent, current_indent_index)
                underline_hl = current_indent_hl.underline
            end

            if cia and i - 1 == current_indent_col_start_single then
                indent_hl = current_indent_hl.char

                if config.current_indent.char then
                    local current_indent_char = get_char(config.current_indent.char, current_indent_index)
                    if vim.fn.strdisplaywidth(current_indent_char) == 1 then
                        char = current_indent_char
                    else
                        char = indent_char
                    end
                else
                    char = indent_char
                end

                if config.current_indent.show_end and is_current_indent_end then
                    underline_hl = current_indent_hl.underline
                end
            end
        end

        local set_scope = function()
            if config.scope.show_end and sa and is_scope_end and i - 1 > scope_col_start_single then
                scope_hl = utils.tbl_get_index(highlights.scope, scope_index)
                underline_hl = scope_hl.underline
            end

            if sa and i - 1 == scope_col_start_single then
                indent_hl = scope_hl.char

                if config.scope.char then
                    local scope_char = get_char(config.scope.char, scope_index)
                    if vim.fn.strdisplaywidth(scope_char) == 1 then
                        char = scope_char
                    else
                        char = indent_char
                    end
                else
                    char = indent_char
                end

                if config.scope.show_end and is_scope_end then
                    underline_hl = scope_hl.underline
                end
            end
        end

        if config.scope.priority >= config.current_indent.priority then
            set_current_indent()
            set_scope()
        else
            set_scope()
            set_current_indent()
        end

        table.insert(virt_text, {
            char,
            vim.tbl_filter(function(v)
                return v ~= nil
            end, { whitespace_hl, indent_hl, underline_hl }),
        })
    end

    return virt_text, scope_hl, current_indent_hl
end

return M
