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
---@param scope_active boolean
---@param scope_index number
---@param scope_start boolean
---@param scope_end boolean
---@param scope_col_start_single number
---@return ibl.virtual_text, ibl.highlight
M.get = function(
    config,
    char_map,
    whitespace_tbl,
    scope_active,
    scope_index,
    scope_start,
    scope_end,
    scope_col_start_single
)
    local scope_hl = utils.tbl_get_index(highlights.scope, scope_index)
    local indent_index = 1
    local virt_text = {}
    local scope_edge = (config.scope.show_start and scope_start and not config.scope.show_exact_scope)
        or (config.scope.show_end and scope_end)

    for i, ws in ipairs(whitespace_tbl) do
        local whitespace_hl = utils.tbl_get_index(highlights.whitespace, indent_index - 1).char
        local indent_hl
        local underline_hl
        local sa = scope_active
        local char = get_char(char_map[ws], indent_index)

        if indent.is_indent(ws) then
            whitespace_hl = utils.tbl_get_index(highlights.whitespace, indent_index).char
            if vim.fn.strdisplaywidth(char) == 0 then
                char = char_map[whitespace.SPACE] --[[@as string]]
                sa = false
            else
                indent_hl = utils.tbl_get_index(highlights.indent, indent_index).char
            end
            indent_index = indent_index + 1
        end

        if sa and scope_edge and i - 1 > scope_col_start_single then
            scope_hl = utils.tbl_get_index(highlights.scope, scope_index)
            underline_hl = scope_hl.underline
        end

        if sa and i - 1 == scope_col_start_single then
            if not scope_start then
                indent_hl = scope_hl.char

                if config.scope.char then
                    local scope_char = get_char(config.scope.char, scope_index)
                    if vim.fn.strdisplaywidth(scope_char) == 1 then
                        char = scope_char
                    end
                end
            end

            if scope_edge then
                underline_hl = scope_hl.underline
            end
        end

        table.insert(virt_text, {
            char,
            utils.tbl_filter(function(v)
                return v ~= nil
            end, { whitespace_hl, indent_hl, underline_hl }),
        })
    end

    return virt_text, scope_hl
end

return M
