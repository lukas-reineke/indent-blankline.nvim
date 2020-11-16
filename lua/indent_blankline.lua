local M = {}

vim.g.indent_blankline_namespace = vim.api.nvim_create_namespace("indent_blankline")

local function error_handler(err)
    if vim.g.indent_blankline_debug then
        vim.api.nvim_command("echohl Error")
        vim.api.nvim_command('echom "' .. err .. '"')
        vim.api.nvim_command("echohl None")
    end
end

local set_indent_blankline_enabled = function()
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

local clear_line_indent = function(buf, lnum)
    xpcall(
        function()
            vim.api.nvim_buf_clear_namespace(buf, vim.g.indent_blankline_namespace, lnum - 1, lnum)
        end,
        error_handler
    )
end

local refresh = function()
    if vim.b.indent_blankline_enabled == nil then
        set_indent_blankline_enabled()
    end

    if not vim.g.indent_blankline_enabled or not vim.b.indent_blankline_enabled then
        return
    end

    local buf = vim.api.nvim_get_current_buf()
    local offset = math.max(vim.fn.line("w0") - 1 - vim.g.indent_blankline_viewport_buffer, 0)
    local range = math.min(vim.fn.line("w$") + vim.g.indent_blankline_viewport_buffer, vim.api.nvim_buf_line_count(buf))
    local lines = vim.api.nvim_buf_get_lines(buf, offset, range, false)
    local space
    local char = vim.g.indent_blankline_char
    local max_indent_level = vim.g.indent_blankline_indent_level
    local char_list = vim.g.indent_blankline_char_list
    local space_char = vim.g.indent_blankline_space_char
    local extra_indent_level = vim.g.indent_blankline_extra_indent_level
    local expandtab = vim.bo.expandtab
    local empty_line_counter = 0
    local next_indent

    if (vim.bo.shiftwidth == 0 or not expandtab) then
        space = vim.bo.tabstop
    else
        space = vim.bo.shiftwidth
    end

    for i = 1, #lines do
        local async
        async =
            vim.loop.new_async(
            function()
                if lines[i]:len() > 0 then
                    vim.schedule_wrap(
                        function()
                            clear_line_indent(buf, i + offset)
                        end
                    )()
                    return async:close()
                end

                local indent
                if empty_line_counter > 0 then
                    empty_line_counter = empty_line_counter - 1
                    indent = next_indent
                else
                    if i == #lines then
                        indent = 0
                    else
                        local j = i + 1
                        while (j < #lines and lines[j]:len() == 0) do
                            j = j + 1
                            empty_line_counter = empty_line_counter + 1
                        end
                        local _
                        _, indent = lines[j]:find("^%s+")
                    end
                    next_indent = indent
                end

                if not indent or indent == 0 then
                    vim.schedule_wrap(
                        function()
                            clear_line_indent(buf, i + offset)
                        end
                    )()
                    return async:close()
                end

                if (expandtab) then
                    indent = indent / space
                end

                if extra_indent_level then
                    indent = indent + extra_indent_level
                end

                local v_text = {}
                for j = 1, math.min(math.max(indent, 0), max_indent_level) do
                    local c

                    if #char_list > 0 then
                        c = char_list[((j - 1) % #char_list) + 1]
                    else
                        c = char
                    end

                    v_text[j * 2 - 1] = {space_char:rep(space - 1), "Conceal"}
                    v_text[j * 2] = {c, "Whitespace"}
                end

                vim.schedule_wrap(
                    function()
                        xpcall(
                            function()
                                vim.api.nvim_buf_set_virtual_text(
                                    buf,
                                    vim.g.indent_blankline_namespace,
                                    i - 1 + offset,
                                    v_text,
                                    vim.empty_dict()
                                )
                            end,
                            error_handler
                        )
                    end
                )()
                return async:close()
            end
        )

        async:send()
    end
end

M.refresh = function()
    xpcall(refresh, error_handler)
end

return M
