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
    local space_char_blankline_highlight = vim.g.indent_blankline_space_char_blankline_highlight
    local space_char_blankline_highlight_list = vim.g.indent_blankline_space_char_blankline_highlight_list
    local space_char = vim.g.indent_blankline_space_char
    local space_char_blankline = vim.g.indent_blankline_space_char_blankline
    local max_indent_level = vim.g.indent_blankline_indent_level
    local extra_indent_level = vim.g.indent_blankline_extra_indent_level
    local expandtab = vim.bo.expandtab
    local use_ts_indent = vim.g.indent_blankline_use_treesitter and ts_status and ts_query.has_indents(vim.bo.filetype)
    local first_indent = vim.g.indent_blankline_show_first_indent_level
    local trail_indent = vim.g.indent_blankline_show_trailing_blankline_indent

    local tabs = vim.bo.shiftwidth == 0 or not expandtab
    local space = utils._if(tabs, vim.bo.tabstop, vim.bo.shiftwidth)

    local get_virtual_text = function(indent, blankline)
        if not indent then
            indent = 0
        end
        local extra = indent % space ~= 0 and not tabs
        if expandtab then
            indent = indent / space
        end

        if extra_indent_level then
            indent = indent + extra_indent_level
        end

        local virtual_text = {}
        for i = 1, math.min(math.max(indent, 0), max_indent_level) do
            local space_count = space
            if i ~= 1 or first_indent then
                space_count = space_count - 1
                table.insert(
                    virtual_text,
                    {
                        utils._if(#char_list > 0, utils.get_from_list(char_list, i), char),
                        utils._if(#char_highlight_list > 0, utils.get_from_list(char_highlight_list, i), char_highlight)
                    }
                )
            end
            table.insert(
                virtual_text,
                {
                    utils._if(blankline, space_char_blankline, space_char):rep(space_count),
                    utils._if(
                        blankline,
                        utils._if(
                            #space_char_blankline_highlight_list > 0,
                            utils.get_from_list(space_char_blankline_highlight_list, i),
                            space_char_blankline_highlight
                        ),
                        utils._if(
                            #space_char_highlight_list > 0,
                            utils.get_from_list(space_char_highlight_list, i),
                            space_char_highlight
                        )
                    )
                }
            )
        end

        if (blankline and trail_indent) or extra then
            table.insert(
                virtual_text,
                {
                    utils._if(#char_list > 0, utils.get_from_list(char_list, #virtual_text), char),
                    utils._if(
                        #char_highlight_list > 0,
                        utils.get_from_list(char_highlight_list, #virtual_text),
                        char_highlight
                    )
                }
            )
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
                local blankline = lines[i]:len() == 0

                if blankline and use_ts_indent then
                    vim.schedule_wrap(
                        function()
                            local indent = ts_indent.get_indent(i + offset)
                            if not indent or indent == 0 then
                                utils.clear_line_indent(bufnr, i + offset)
                                return
                            end

                            local virtual_text = get_virtual_text(indent, blankline)
                            utils.clear_line_indent(bufnr, i + offset)
                            xpcall(
                                vim.api.nvim_buf_set_extmark,
                                utils.error_handler,
                                bufnr,
                                vim.g.indent_blankline_namespace,
                                i - 1 + offset,
                                0,
                                {virt_text = virtual_text, virt_text_pos = "overlay"}
                            )
                        end
                    )()
                    return async:close()
                end

                local indent
                if not blankline then
                    _, indent = lines[i]:find("^%s+")
                elseif empty_line_counter > 0 then
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

                local virtual_text = get_virtual_text(indent, blankline)
                vim.schedule_wrap(
                    function()
                        utils.clear_line_indent(bufnr, i + offset)
                        xpcall(
                            vim.api.nvim_buf_set_extmark,
                            utils.error_handler,
                            bufnr,
                            vim.g.indent_blankline_namespace,
                            i - 1 + offset,
                            0,
                            {virt_text = virtual_text, virt_text_pos = "overlay"}
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
