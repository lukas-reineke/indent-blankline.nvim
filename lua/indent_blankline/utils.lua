local M = {}

M.error_handler = function(err)
    if vim.g.indent_blankline_debug then
        vim.cmd("echohl Error")
        vim.cmd('echomsg "' .. err .. '"')
        vim.cmd("echohl None")
    end
end

M.set_indent_blankline_enabled = function()
    vim.b.indent_blankline_enabled = true

    for i = 1, #vim.g.indent_blankline_filetype_exclude do
        if vim.g.indent_blankline_filetype_exclude[i] == vim.bo.filetype then
            vim.b.indent_blankline_enabled = false
        end
    end

    for i = 1, #vim.g.indent_blankline_buftype_exclude do
        if vim.g.indent_blankline_buftype_exclude[i] == vim.bo.buftype then
            vim.b.indent_blankline_enabled = false
        end
    end

    if #vim.g.indent_blankline_filetype > 0 then
        vim.b.indent_blankline_enabled = false
        for i = 1, #vim.g.indent_blankline_filetype do
            if vim.g.indent_blankline_filetype[i] == vim.bo.filetype then
                vim.b.indent_blankline_enabled = true
            end
        end
    end

    local bufname = vim.fn["bufname"]("")
    for i = 1, #vim.g.indent_blankline_bufname_exclude do
        if vim.fn["matchstr"](bufname, vim.g.indent_blankline_bufname_exclude[i]) == bufname then
            vim.b.indent_blankline_enabled = false
        end
    end

    if vim.b.indentLine_enabled == false then
        vim.b.indent_blankline_enabled = false
    end
end

M.clear_line_indent = function(buf, lnum)
    xpcall(vim.api.nvim_buf_clear_namespace, M.error_handler, buf, vim.g.indent_blankline_namespace, lnum - 1, lnum)
end

M.get_from_list = function(list, i)
    return list[((i - 1) % #list) + 1]
end

M._if = function(bool, a, b)
    if bool then
        return a
    else
        return b
    end
end

M.find_indent = function(line, shiftwidth, strict_tabs)
    local _, whitespace_count = line:find("^%s+")
    if not whitespace_count or whitespace_count == 0 then
        return 0, false
    end
    local whitespace_string = line:sub(1, whitespace_count)
    local _, spaces = whitespace_string:gsub(" ", "")
    local _, tabs = whitespace_string:gsub("	", "")
    if strict_tabs and tabs > 0 then
        return tabs, spaces > 0
    end
    local indent = tabs + (spaces / shiftwidth)
    return indent, spaces % shiftwidth ~= 0
end

M.get_current_context = function(type_patterns)
    local ts_utils = require "nvim-treesitter.ts_utils"
    local cursor_node = ts_utils.get_node_at_cursor()

    while cursor_node do
        local node_type = cursor_node:type()
        local found
        for _, rgx in ipairs(type_patterns) do
            if node_type:find(rgx) then
                found = true
            end
        end
        if found then
            break
        end
        cursor_node = cursor_node:parent()
    end

    if cursor_node then
        local node_start, _, node_end, _ = cursor_node:range()

        if node_start ~= node_end then
            return true, node_start, node_end
        end
    end

    return false
end

return M
