local M = {}

---@param line string?
M.get_whitespace = function(line)
    if not line then
        return ""
    end
    return string.match(line, "^%s+") or ""
end

---@class ibl.listchars
---@field tabstop_overwrite boolean
---@field space_char string
---@field trail_char string?
---@field lead_char string?
---@field multispace_chars string[]?
---@field leadmultispace_chars string[]?
---@field tab_char_start string?
---@field tab_char_fill string
---@field tab_char_end string?

---@param bufnr number
---@return ibl.listchars
M.get_listchars = function(bufnr)
    local listchars
    local list = vim.opt.list:get()
    if list then
        listchars = vim.opt.listchars:get()
    end

    if bufnr ~= vim.api.nvim_get_current_buf() then
        local win_list = vim.fn.win_findbuf(bufnr)
        local win = win_list and win_list[1]
        if win then
            list = vim.api.nvim_get_option_value("list", { win = win })
            if list then
                local raw_value = vim.api.nvim_get_option_value("listchars", { win = win })
                listchars = {}
                for _, key_value_str in ipairs(vim.split(raw_value, ",")) do
                    local key, value = unpack(vim.split(key_value_str, ":"))
                    listchars[vim.trim(key)] = value
                end
            end
        end
    end

    if list then
        local tabstop_overwrite = false
        local tab_char
        local space_char = listchars.space or " "
        local multispace_chars
        local leadmultispace_chars
        if listchars.tab then
            tab_char = vim.fn.split(listchars.tab, "\\zs")
        else
            tabstop_overwrite = true
            tab_char = { "^", "I" }
        end
        if listchars.multispace then
            multispace_chars = vim.fn.split(listchars.multispace, "\\zs")
        end
        if listchars.leadmultispace then
            leadmultispace_chars = vim.fn.split(listchars.leadmultispace, "\\zs")
        end
        return {
            tabstop_overwrite = tabstop_overwrite,
            space_char = space_char,
            trail_char = listchars.trail,
            multispace_char = multispace_chars,
            leadmultispace_char = leadmultispace_chars,
            lead_char = listchars.lead,
            tab_char_start = tab_char[1] or space_char,
            tab_char_fill = tab_char[2] or space_char,
            tab_char_end = tab_char[3],
        }
    end
    return {
        tabstop_overwrite = false,
        space_char = " ",
        trail_char = nil,
        lead_char = nil,
        multispace_chars = nil,
        leadmultispace_chars = nil,
        tab_char_start = nil,
        tab_char_fill = " ",
        tab_char_end = nil,
    }
end

---@param bufnr number
M.get_filetypes = function(bufnr)
    return vim.split(
        vim.api.nvim_get_option_value("filetype", { buf = bufnr }),
        ".",
        { plain = true, trimempty = true }
    )
end

local has_end_reg = vim.regex "^\\s*\\(}\\|]\\|)\\|end\\)"
---@param line string
M.has_end = function(line)
    if has_end_reg and has_end_reg:match_str(line) ~= nil then
        return true
    end
    return false
end

---@param bufnr number
M.get_offset = function(bufnr)
    local win = 0
    local win_view
    local win_end
    if bufnr == vim.api.nvim_get_current_buf() then
        win_view = vim.fn.winsaveview()
        win_end = vim.fn.line "w$"
    else
        local win_list = vim.fn.win_findbuf(bufnr)
        if not win_list or not win_list[1] then
            return 0, 0, 0, 0
        end
        win = win_list[1]
        win_view = vim.api.nvim_win_call(win, vim.fn.winsaveview)
    end

    local win_height = vim.api.nvim_win_get_height(win)
    if not win_end then
        win_end = win_height + (win_view.topline or 0)
    end
    if win_view.lnum > win_end then
        win_view.topline = win_view.lnum
        win_end = win_view.lnum + win_height
    end

    return win_view.leftcol or 0, win_view.topline or 0, win_end, win_height
end

---@param bufnr number
---@param config ibl.config
M.is_buffer_active = function(bufnr, config)
    for _, filetype in ipairs(M.get_filetypes(bufnr)) do
        if vim.tbl_contains(config.exclude.filetypes, filetype) then
            return false
        end
    end

    local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
    if vim.tbl_contains(config.exclude.buftypes, buftype) then
        return false
    end

    return true
end

---@param bufnr number
---@return number
M.get_bufnr = function(bufnr)
    if not bufnr or bufnr == 0 then
        return vim.api.nvim_get_current_buf() --[[@as number]]
    end
    return bufnr
end

---@generic T: table
---@vararg T
---@return T
M.tbl_join = function(...)
    local result = {}
    for i, v in ipairs(vim.tbl_flatten { ... }) do
        result[i] = v
    end
    return result
end

---@generic T
---@param list T[]
---@param i number
---@return T
M.tbl_get_index = function(list, i)
    return list[((i - 1) % #list) + 1]
end

return M
