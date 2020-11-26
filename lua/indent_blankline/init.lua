local ts_status, ts_query = pcall(require, "nvim-treesitter.query")
local ts_status, ts_indent = pcall(require, "nvim-treesitter.indent")
local utils = require "indent_blankline/utils"
local M = {}

M.setup = function()
    vim.g.indent_blankline_namespace = vim.api.nvim_create_namespace("indent_blankline")
end

local refresh = function()
    if vim.b.indent_blankline_enabled == nil then
        utils.set_indent_blankline_enabled()
    end

    if not vim.g.indent_blankline_enabled or not vim.b.indent_blankline_enabled then
        return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local offset = math.max(vim.fn.line("w0") - 1 - vim.g.indent_blankline_viewport_buffer, 0)
    local range =
        math.min(vim.fn.line("w$") + vim.g.indent_blankline_viewport_buffer, vim.api.nvim_buf_line_count(bufnr))
    local lines = vim.api.nvim_buf_get_lines(bufnr, offset, range, false)
    local char = vim.g.indent_blankline_char
    local char_list = vim.g.indent_blankline_char_list
    local char_highlight = vim.g.indent_blankline_char_highlight
    local char_highlight_list = vim.g.indent_blankline_char_highlight_list
    local space_char_highlight = vim.g.indent_blankline_space_char_highlight
    local space_char_highlight_list = vim.g.indent_blankline_space_char_highlight_list
    local space_char = vim.g.indent_blankline_space_char
    local max_indent_level = vim.g.indent_blankline_indent_level
    local extra_indent_level = vim.g.indent_blankline_extra_indent_level
    local expandtab = vim.bo.expandtab
    local has_ts_indent = vim.g.indent_blankline_use_treesitter and ts_status and ts_query.has_indents(vim.bo.filetype)

    local space
    if (vim.bo.shiftwidth == 0 or not expandtab) then
        space = vim.bo.tabstop
    else
        space = vim.bo.shiftwidth
    end

    if #char_list > 0 then
        char = nil
    end
    if #char_highlight_list > 0 then
        char_highlight = nil
    end
    if #space_char_highlight_list > 0 then
        space_char_highlight = nil
    end

    local get_virtual_text = function(indent)
        if expandtab then
            indent = indent / space
        end

        if extra_indent_level then
            indent = indent + extra_indent_level
        end

        local virtual_text = {}
        for i = 1, math.min(math.max(indent, 0), max_indent_level) do
            virtual_text[i * 2 - 1] = {
                space_char:rep(space - 1),
                space_char_highlight or utils.get_from_list(space_char_highlight_list, i)
            }
            virtual_text[i * 2] = {
                char or utils.get_from_list(char_list, i),
                char_highlight or utils.get_from_list(char_highlight_list, i)
            }
        end

        return virtual_text
    end

    local next_indent
    local empty_line_counter = 0
    for i = 1, #lines do
        local async
        async =
            vim.loop.new_async(
            function()
                if lines[i]:len() > 0 then
                    vim.schedule_wrap(utils.clear_line_indent)(bufnr, i + offset)
                    return async:close()
                end

                if has_ts_indent then
                    vim.schedule_wrap(
                        function()
                            local indent = ts_indent.get_indent(i + offset)
                            if not indent or indent == 0 then
                                utils.clear_line_indent(bufnr, i + offset)
                                return
                            end

                            local virtual_text = get_virtual_text(indent)
                            xpcall(
                                vim.api.nvim_buf_set_virtual_text,
                                utils.error_handler,
                                bufnr,
                                vim.g.indent_blankline_namespace,
                                i - 1 + offset,
                                virtual_text,
                                vim.empty_dict()
                            )
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
                        _, indent = lines[j]:find("^%s+")
                    end
                    next_indent = indent
                end

                if not indent or indent == 0 then
                    vim.schedule_wrap(utils.clear_line_indent)(bufnr, i + offset)
                    return async:close()
                end

                local virtual_text = get_virtual_text(indent)
                vim.schedule_wrap(
                    function()
                        xpcall(
                            vim.api.nvim_buf_set_virtual_text,
                            utils.error_handler,
                            bufnr,
                            vim.g.indent_blankline_namespace,
                            i - 1 + offset,
                            virtual_text,
                            vim.empty_dict()
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
    xpcall(refresh, utils.error_handler)
end

return M
