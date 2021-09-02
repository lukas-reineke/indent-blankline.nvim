local M = {}

M.memo =
    setmetatable(
    {
        put = function(cache, params, result)
            local node = cache
            for i = 1, #params do
                local param = vim.inspect(params[i])
                node.children = node.children or {}
                node.children[param] = node.children[param] or {}
                node = node.children[param]
            end
            node.result = result
        end,
        get = function(cache, params)
            local node = cache
            for i = 1, #params do
                local param = vim.inspect(params[i])
                node = node.children and node.children[param]
                if not node then
                    return nil
                end
            end
            return node.result
        end
    },
    {
        __call = function(memo, func)
            local cache = {}

            return function(...)
                local params = {...}
                local result = memo.get(cache, params)
                if not result then
                    result = {func(...)}
                    memo.put(cache, params, result)
                end
                return unpack(result)
            end
        end
    }
)

M.error_handler = function(err)
    if vim.g.indent_blankline_debug then
        vim.cmd("echohl Error")
        vim.cmd('echomsg "' .. err .. '"')
        vim.cmd("echohl None")
    end
end

M.is_indent_blankline_enabled =
    M.memo(
    function(
        b_enabled,
        g_enabled,
        respect_list,
        opt_list,
        filetype,
        filetype_include,
        filetype_exclude,
        buftype,
        buftype_exclude,
        bufname_exclude,
        bufname)
        if b_enabled ~= nil then
            return b_enabled
        end
        if g_enabled ~= true then
            return false
        end
        if respect_list and not opt_list then
            return false
        end

        for _, ft in ipairs(filetype_exclude) do
            if ft == filetype then
                return false
            end
        end

        for _, bt in ipairs(buftype_exclude) do
            if bt == buftype then
                return false
            end
        end

        for _, bn in ipairs(bufname_exclude) do
            if vim.fn["matchstr"](bufname, bn) == bufname then
                return false
            end
        end

        if #filetype_include > 0 then
            for _, ft in ipairs(filetype_include) do
                if ft == filetype then
                    return true
                end
            end
            return false
        end

        return true
    end
)

M.clear_line_indent = function(buf, lnum)
    xpcall(vim.api.nvim_buf_clear_namespace, M.error_handler, buf, vim.g.indent_blankline_namespace, lnum - 1, lnum)
end

M.clear_buf_indent = function(buf)
    xpcall(vim.api.nvim_buf_clear_namespace, M.error_handler, buf, vim.g.indent_blankline_namespace, 0, -1)
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

M.find_indent = function(line, shiftwidth, strict_tabs, blankline, list_chars)
    local indent = 0
    local spaces = 0
    local tab_width
    local virtual_string = {}

    -- get leading whitespace of line and convert it to fixed-width string in table form
    local whitespace = string.match(line, "^%s+")
    if whitespace then
        for ch in whitespace:gmatch(".") do
            if ch == "\t" then
                if strict_tabs and indent == 0 and spaces ~= 0 then
                    return 0, false, {}
                end
                indent = indent + math.floor(spaces / shiftwidth) + 1
                spaces = 0
                -- replace dynamic-width tab with fixed-width string (ta..ab)
                tab_width = shiftwidth - table.maxn(virtual_string) % shiftwidth
                -- check if tab_char_end is set, see :help listchars
                if list_chars["tab_char_end"] then
                    if tab_width == 1 then
                        table.insert(virtual_string, list_chars["tab_char_end"])
                    else
                        table.insert(virtual_string, list_chars["tab_char_start"])
                        for _ = 1, (tab_width - 2) do
                            table.insert(virtual_string, list_chars["tab_char_fill"])
                        end
                        table.insert(virtual_string, list_chars["tab_char_end"])
                    end
                else
                    table.insert(virtual_string, list_chars["tab_char_start"])
                    for _ = 1, (tab_width - 1) do
                        table.insert(virtual_string, list_chars["tab_char_fill"])
                    end
                end
            else
                if strict_tabs and indent ~= 0 then
                    -- return early when no more tabs are found
                    return indent, true, virtual_string
                end
                if whitespace == line then
                    -- if the entire line is only whitespace use trail_char instead of lead_char
                    table.insert(virtual_string, list_chars["trail_char"])
                else
                    table.insert(virtual_string, list_chars["lead_char"])
                end
                spaces = spaces + 1
            end
        end
    end
    indent = indent + math.floor(spaces / shiftwidth)
    -- return indent level; bool whether there are extra chars or not; and whitespace table
    return indent, table.maxn(virtual_string) % shiftwidth ~= 0, M._if(blankline, {}, virtual_string)
end

M.get_current_context = function(type_patterns)
    local ts_utils = require "nvim-treesitter.ts_utils"
    local cursor_node = ts_utils.get_node_at_cursor()

    while cursor_node do
        local node_type = cursor_node:type()
        for _, rgx in ipairs(type_patterns) do
            if node_type:find(rgx) then
                local node_start, _, node_end, _ = cursor_node:range()
                if node_start ~= node_end then
                    return true, node_start + 1, node_end + 1
                end
                node_start, node_end = nil, nil
            end
        end
        cursor_node = cursor_node:parent()
    end

    return false
end

M.reset_highlights = function()
    local whitespace_highlight = vim.fn.synIDtrans(vim.fn.hlID("Whitespace"))
    local label_highlight = vim.fn.synIDtrans(vim.fn.hlID("Label"))

    local whitespace_fg = {
        vim.fn.synIDattr(whitespace_highlight, "fg", "gui"),
        vim.fn.synIDattr(whitespace_highlight, "fg", "cterm")
    }
    local label_fg = {
        vim.fn.synIDattr(label_highlight, "fg", "gui"),
        vim.fn.synIDattr(label_highlight, "fg", "cterm")
    }

    for highlight_name, highlight in pairs(
        {
            IndentBlanklineChar = whitespace_fg,
            IndentBlanklineSpaceChar = whitespace_fg,
            IndentBlanklineSpaceCharBlankline = whitespace_fg,
            IndentBlanklineContextChar = label_fg
        }
    ) do
        local current_highlight = vim.fn.synIDtrans(vim.fn.hlID(highlight_name))
        if vim.fn.synIDattr(current_highlight, "fg") == "" and vim.fn.synIDattr(current_highlight, "bg") == "" then
            vim.cmd(
                string.format(
                    "highlight %s guifg=%s ctermfg=%s gui=nocombine cterm=nocombine",
                    highlight_name,
                    M._if(highlight[1] == "", "NONE", highlight[1]),
                    M._if(highlight[2] == "", "NONE", highlight[2])
                )
            )
        end
    end
end

M.first_not_nil = function(...)
    for _, value in pairs({...}) do
        return value
    end
end

M.get_variable = function(key)
    if vim.b[key] ~= nil then
        return vim.b[key]
    end
    if vim.t[key] ~= nil then
        return vim.t[key]
    end
    return vim.g[key]
end

return M
