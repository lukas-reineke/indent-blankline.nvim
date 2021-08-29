local ts_status, ts_query = pcall(require, "nvim-treesitter.query")
local ts_status, ts_indent = pcall(require, "nvim-treesitter.indent")
local utils = require "indent_blankline/utils"
local M = {}

local char_highlight = "IndentBlanklineChar"
local space_char_highlight = "IndentBlanklineSpaceChar"
local space_char_blankline_highlight = "IndentBlanklineSpaceCharBlankline"
local context_highlight = "IndentBlanklineContextChar"

M.init = function()
    vim.g.indent_blankline_namespace = vim.api.nvim_create_namespace("indent_blankline")

    utils.reset_highlights()

    require("indent_blankline.commands").refresh(true)
end

M.setup = function(options)
    if options == nil then
        options = {}
    end

    local o = utils.first_not_nil

    vim.g.indent_blankline_char = o(options.char, vim.g.indent_blankline_char, vim.g.indentLine_char, "│")
    vim.g.indent_blankline_char_list =
        o(options.char_list, vim.g.indent_blankline_char_list, vim.g.indentLine_char_list, {})
    vim.g.indent_blankline_char_highlight_list =
        o(options.char_highlight_list, vim.g.indent_blankline_char_highlight_list, {})
    vim.g.indent_blankline_space_char =
        o(options.space_char, vim.g.indent_blankline_space_char, vim.opt.listchars:get().lead, vim.opt.listchars:get().space, " ")
    vim.g.indent_blankline_space_char_highlight_list =
        o(options.space_char_highlight_list, vim.g.indent_blankline_space_char_highlight_list, {})
    vim.g.indent_blankline_space_char_blankline =
        o(options.space_char_blankline, vim.g.indent_blankline_space_char_blankline, vim.g.indent_blankline_space_char)
    vim.g.indent_blankline_space_char_blankline =
        o(
        options.space_char_blankline,
        vim.g.indent_blankline_space_char_blankline,
        vim.g.indent_blankline_space_char_highlight_list
    )
    vim.g.indent_blankline_space_char_blankline_highlight_list =
        o(
        options.space_char_blankline_highlight_list,
        vim.g.indent_blankline_space_char_blankline_highlight_list,
        vim.g.indent_blankline_space_char_highlight_list
    )
    vim.g.indent_blankline_indent_level = o(options.indent_level, vim.g.indent_blankline_indent_level, 20)
    vim.g.indent_blankline_enabled = o(options.enabled, vim.g.indent_blankline_enabled, true)
    vim.g.indent_blankline_filetype =
        o(options.filetype, vim.g.indent_blankline_filetype, vim.g.indentLine_fileType, {})
    vim.g.indent_blankline_filetype_exclude =
        o(options.filetype_exclude, vim.g.indent_blankline_filetype_exclude, vim.g.indentLine_fileTypeExclude, {})
    vim.g.indent_blankline_bufname_exclude =
        o(options.bufname_exclude, vim.g.indent_blankline_bufname_exclude, vim.g.indentLine_bufNameExclude, {})
    vim.g.indent_blankline_buftype_exclude =
        o(options.buftype_exclude, vim.g.indent_blankline_buftype_exclude, vim.g.indentLine_bufTypeExclude, {})
    vim.g.indent_blankline_viewport_buffer = o(options.viewport_buffer, vim.g.indent_blankline_viewport_buffer, 10)
    vim.g.indent_blankline_use_treesitter = o(options.use_treesitter, vim.g.indent_blankline_use_treesitter, false)
    vim.g.indent_blankline_show_first_indent_level =
        o(options.show_first_indent_level, vim.g.indent_blankline_show_first_indent_level, true)
    vim.g.indent_blankline_show_trailing_blankline_indent =
        o(options.show_trailing_blankline_indent, vim.g.indent_blankline_show_trailing_blankline_indent, true)
    vim.g.indent_blankline_show_end_of_line =
        o(options.show_end_of_line, vim.g.indent_blankline_show_end_of_line, false)
    vim.g.indent_blankline_show_foldtext = o(options.show_foldtext, vim.g.indent_blankline_show_foldtext, true)
    vim.g.indent_blankline_show_current_context =
        o(options.show_current_context, vim.g.indent_blankline_show_current_context, false)
    vim.g.indent_blankline_context_highlight_list =
        o(options.context_highlight_list, vim.g.indent_blankline_context_highlight_list, {})
    vim.g.indent_blankline_context_patterns =
        o(options.context_patterns, vim.g.indent_blankline_context_patterns, {"class", "function", "method"})
    vim.g.indent_blankline_strict_tabs = o(options.strict_tabs, vim.g.indent_blankline_strict_tabs, false)

    vim.g.indent_blankline_disable_warning_message =
        o(options.disable_warning_message, vim.g.indent_blankline_disable_warning_message, false)
    vim.g.indent_blankline_debug = o(options.debug, vim.g.indent_blankline_debug, false)

    if vim.g.indent_blankline_show_current_context then
        vim.cmd [[
            augroup IndentBlanklineContextAutogroup
                autocmd!
                autocmd CursorMoved * IndentBlanklineRefresh
            augroup END
        ]]
    end

    vim.g.__indent_blankline_setup_completed = true
end

local refresh = function()
    local v = utils.get_variable
    local bufnr = vim.api.nvim_get_current_buf()

    if
        not utils.is_indent_blankline_enabled(
            vim.b.indent_blankline_enabled,
            vim.g.indent_blankline_enabled,
            vim.bo.filetype,
            v("indent_blankline_filetype"),
            v("indent_blankline_filetype_exclude"),
            vim.bo.buftype,
            v("indent_blankline_buftype_exclude"),
            v("indent_blankline_bufname_exclude"),
            vim.fn["bufname"]("")
        )
     then
        if vim.b.__indent_blankline_active then
            vim.schedule_wrap(utils.clear_buf_indent)(bufnr)
        end
        vim.b.__indent_blankline_active = false
        return
    else
        vim.b.__indent_blankline_active = true
    end

    local offset = math.max(vim.fn.line("w0") - 1 - v("indent_blankline_viewport_buffer"), 0)
    local left_offset = vim.fn.winsaveview().leftcol
    local range =
        math.min(vim.fn.line("w$") + v("indent_blankline_viewport_buffer"), vim.api.nvim_buf_line_count(bufnr))
    local lines = vim.api.nvim_buf_get_lines(bufnr, offset, range, false)
    local char = v("indent_blankline_char")
    local char_list = v("indent_blankline_char_list")
    local char_highlight_list = v("indent_blankline_char_highlight_list")
    local space_char_highlight_list = v("indent_blankline_space_char_highlight_list")
    local space_char_blankline_highlight_list = v("indent_blankline_space_char_blankline_highlight_list")
    local space_char = v("indent_blankline_space_char")
    local space_char_blankline = v("indent_blankline_space_char_blankline")
    local max_indent_level = v("indent_blankline_indent_level")
    local expandtab = vim.bo.expandtab
    local use_ts_indent = v("indent_blankline_use_treesitter") and ts_status and ts_query.has_indents(vim.bo.filetype)
    local first_indent = v("indent_blankline_show_first_indent_level")
    local trail_indent = v("indent_blankline_show_trailing_blankline_indent")
    local end_of_line = v("indent_blankline_show_end_of_line")
    local end_of_line_char = vim.opt.listchars:get().eol or ""
    local strict_tabs = v("indent_blankline_strict_tabs")
    local foldtext = v("indent_blankline_show_foldtext")

    local tabs = vim.bo.shiftwidth == 0 or not expandtab
    local space = utils._if(tabs, vim.bo.tabstop, vim.bo.shiftwidth)

    local context_highlight_list = v("indent_blankline_context_highlight_list")
    local context_status, context_start, context_end = false, 0, 0
    if v("indent_blankline_show_current_context") then
        context_status, context_start, context_end = utils.get_current_context(v("indent_blankline_context_patterns"))
    end


    local get_virtual_substring = function(blankline, number, base_string)
        -- gets first few characters and returns substring plus reduced original string
        local ret_string = ""
        local mod_string = ""
        if blankline then
            ret_string = string.rep(" ", number)
            mod_string = string.gsub(base_string, "^.", "", number)
        else
            for _=1,number do
                -- get substring of given length, then remove that substring from original
                ret_string = string.sub(base_string,1,number)
                mod_string = string.gsub(base_string, ret_string, "",1)
            end
        end
        -- return both the substring and the modified original
        return ret_string, mod_string
    end

    local get_virtual_text = function(blankline, context_active, context_indent, virtual_string, indent)
        local virtual_text = {}
        local current_left_offset = left_offset

        for i = 1, math.min(math.max(indent, 0), max_indent_level) do
            local space_count = space
            local context = context_active and context_indent == i
            if i ~= 1 or first_indent then
                space_count = space_count - 1
                if current_left_offset > 0 then
                    current_left_offset = current_left_offset - 1
                else

                    table.insert(
                        virtual_text,
                        {
                            utils._if(
                                i == 1 and blankline and end_of_line and #end_of_line_char > 0,
                                end_of_line_char,
                                utils._if(
                                    #char_list > 0,
                                    utils.get_from_list(char_list, i - utils._if(not first_indent, 1, 0)),
                                    char
                                )
                            ),
                            utils._if(
                                context,
                                utils._if(
                                    #context_highlight_list > 0,
                                    utils.get_from_list(context_highlight_list, i),
                                    context_highlight
                                ),
                                utils._if(
                                    #char_highlight_list > 0,
                                    utils.get_from_list(char_highlight_list, i),
                                    char_highlight
                                )
                            )
                        }
                    )
                    -- We set the first char with a special one above, replacing the first of virt_string
                    virtual_string = string.gsub(virtual_string, "^.", "")
                end
            end

            if current_left_offset > 0 then
                local current_space_count = space_count
                space_count = space_count - current_left_offset
                current_left_offset = current_left_offset - current_space_count
            end
            local indent_string = ""
            if space_count > 0 then
                indent_string, virtual_string = get_virtual_substring(blankline, space_count, virtual_string)
                table.insert(
                    virtual_text,
                    {
                        indent_string,
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
        end

        if (blankline  and trail_indent) and (first_indent or #virtual_text > 0) and current_left_offset < 1 then
            local index = math.ceil(#virtual_text / 2) + 1
            table.insert(
                virtual_text,
                {
                    utils._if(
                        #char_list > 0,
                        utils.get_from_list(char_list, index - utils._if(not first_indent, 1, 0)),
                        char
                    ),
                    utils._if(
                        context_active and context_indent == index,
                        utils._if(
                            #context_highlight_list > 0,
                            utils.get_from_list(context_highlight_list, index),
                            context_highlight
                        ),
                        utils._if(
                            #char_highlight_list > 0,
                            utils.get_from_list(char_highlight_list, index),
                            char_highlight
                        )
                    )
                }
            )
        end

        return virtual_text
    end

    local context_indent
    -- keep track of virtual strings for blank lines
    local prev_virt_string = ""
    for i,line in pairs(lines) do
        if foldtext and vim.fn.foldclosed(i + offset) > 0 then
            utils.clear_line_indent(bufnr, i + offset)
        else
            local async
            async =
                vim.loop.new_async(
                function()
                    local blankline = utils._if(line == "", true, false)
                    local context_active = false
                    if context_status then
                        context_active = offset + i > context_start and offset + i <= context_end
                    end

                    local tab_width="nil"
                    local tab = "t"
                    local virtual_string = ""

                    if blankline then
                        virtual_string = prev_virt_string
                    else
                        local whitespace = string.match(line, '^%s+')
                        if whitespace then
                            for n = 0, #whitespace-1 do
                                -- sub() uses 1 based index, but we need 0 based index for the loop
                                -- to acurately determine the necessary width of potential tabs
                                local test_char = string.sub(whitespace, n+1, n+1)
                                if test_char == "\t" then
                                    tab_width = space - virtual_string:len() % space
                                    if tab_width > 1 then
                                        -- replace whitespace chars with something with a fixed length
                                        tab = "t"..string.rep("a", tab_width - 2).."b"
                                    end
                                    virtual_string = virtual_string..tab
                                else
                                    virtual_string = virtual_string.."s"
                                end
                            end
                        end
                        prev_virt_string = virtual_string
                    end

                    local indent = math.floor( string.len(virtual_string) / space )

                    if offset + i == context_start then
                        context_indent = (indent or 0) + 1
                    end

                    -- shortcut if there aren't any indents
                    if not indent or indent == 0 then
                        vim.schedule_wrap(utils.clear_line_indent)(bufnr, i + offset)
                        return async:close()
                    end

                    local virtual_text = get_virtual_text(blankline, context_active, context_indent, virtual_string, indent)
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
                                {virt_text = virtual_text, virt_text_pos = "overlay", hl_mode = "combine"}
                            )
                        end
                    )()
                    return async:close()
                end
            )

            async:send()
        end
    end
end

M.refresh = function()
    xpcall(refresh, utils.error_handler)
end

return M
