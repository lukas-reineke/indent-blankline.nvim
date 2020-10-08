local co = coroutine

local M = {}

vim.g.indent_blankline_namespace = vim.api.nvim_create_namespace('indent_blankline')

local function error_handler(err)
    if vim.g.indent_blankline_debug then
        vim.api.nvim_command('echohl Error')
        vim.api.nvim_command('echom "' .. err .. '"')
        vim.api.nvim_command('echohl None')
    end
end

local set_indent_blankline_enabled = function()
    vim.b.indent_blankline_enabled = true

    for i=1, #vim.g.indent_blankline_filetype_exclude do
        if vim.g.indent_blankline_filetype_exclude[i] == vim.bo.filetype then
            vim.b.indent_blankline_enabled = false
        end
    end

    for i=1, #vim.g.indent_blankline_buftype_exclude do
        if vim.g.indent_blankline_buftype_exclude[i] == vim.bo.buftype then
            vim.b.indent_blankline_enabled = false
        end
    end

    if #vim.g.indent_blankline_filetype > 0 then
        for i=1, #vim.g.indent_blankline_filetype do
            if vim.g.indent_blankline_filetype[i] == vim.bo.filetype then
                vim.b.indent_blankline_enabled = true
            end
        end
        vim.b.indent_blankline_enabled = false
    end

    local bufname = vim.fn['bufname']('')
    for i=1, #vim.g.indent_blankline_bufname_exclude do
        if vim.fn['matchstr'](bufname, vim.g.indent_blankline_bufname_exclude[i]) == bufname then
            vim.b.indent_blankline_enabled = false
        end
    end

    if vim.b.indentLine_enabled == false then
        vim.b.indent_blankline_enabled = false
    end
end

local clear_line_indent = function(buf, lnum)
    xpcall(function()
        vim.api.nvim_buf_clear_namespace(
            buf,
            vim.g.indent_blankline_namespace,
            lnum - 1,
            lnum
        )
    end, error_handler)
end

local refresh = function()
    if vim.b.indent_blankline_enabled == nil then
        set_indent_blankline_enabled()
    end

    if not vim.g.indent_blankline_enabled or not vim.b.indent_blankline_enabled then
        return
    end

    local buf = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local cache = {}
    local space
    local char = vim.g.indent_blankline_char
    local max_indent_level = vim.g.indent_blankline_indent_level
    local char_list = vim.g.indent_blankline_char_list
    local space_char = vim.g.indent_blankline_space_char
    local extra_indent_level = vim.g.indent_blankline_extra_indent_level
    local expandtab = vim.bo.expandtab

    if (vim.bo.shiftwidth == 0 or not expandtab) then
        space = vim.bo.tabstop
    else
        space = vim.bo.shiftwidth
    end

    for i = 1, #lines do
        local async
        async = vim.loop.new_async(function()
            if lines[i]:len() > 0 then
                vim.schedule_wrap(
                    function()
                        clear_line_indent(buf, i)
                    end
                )()
                return async:close()
            end

            local _, indent

            local j = i
            while(lines[j]:len() == 0 and j < #lines) do
                if cache[j] then
                    indent = cache[j]
                else
                    j = j + 1
                    _, indent = lines[j]:find('^%s+')
                    cache[j] = indent
                end
            end

            if not indent then
                vim.schedule_wrap(
                    function()
                        clear_line_indent(buf, i)
                    end
                )()
                return async:close()
            end

            local v_text = {}

            local indent_level = indent

            if (expandtab) then
                indent_level = indent_level / space
            end

            if extra_indent_level then
                indent_level = indent_level + extra_indent_level
            end

            for i = 1, math.min(math.max(indent_level, 0), max_indent_level) do
                local c

                if #char_list > 0 then
                    c = char_list[((i - 1) % #char_list) + 1]
                else
                    c = char
                end

                v_text[i * 2 - 1] = {space_char:rep(space - 1), 'Conceal'}
                v_text[i * 2] = {c, 'Whitespace'}
            end

            vim.schedule_wrap(
                function()
                    xpcall(function()
                        vim.api.nvim_buf_set_virtual_text(
                            buf,
                            vim.g.indent_blankline_namespace,
                            i - 1,
                            v_text,
                            vim.empty_dict()
                        )
                    end, error_handler)
                end
            )()
            return async:close()
        end)

        async:send()
    end
end

M.refresh = function()
    xpcall(refresh, error_handler)
end

return M
