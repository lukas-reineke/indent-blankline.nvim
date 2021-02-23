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

return M
