local utils = require "ibl.utils"

local has_virtual_lines = vim.fn.has "nvim-0.11" == 1

local M = {}

---@type function?
local handler = nil

---@type integer?
local augroup = nil

--- Cached original leading space widths per buffer -> row -> virtual_lines_ns -> extmark_id -> widths[]
---@type table<number, table<number, table<number, table<number, number[]>>>>
local buffer_state = {}

---@type table<number, table<number, boolean>>
local current_line_buffers = {}

---@type table<number, boolean>
local pending_buffers = {}

---@type table<number, boolean>
local pending_current_line_buffers = {}

local uv = vim.uv or vim.loop
local virtual_lines_timer = uv.new_timer()
local current_line_timer = uv.new_timer()

---@return integer[]
local get_virt_lines_namespaces = function()
    local namespaces = {}
    if vim.diagnostic and vim.diagnostic.get_namespaces then
        for _, ns in pairs(vim.diagnostic.get_namespaces()) do
            if ns.user_data and ns.user_data.virt_lines_ns then
                table.insert(namespaces, ns.user_data.virt_lines_ns)
            end
        end
    end
    return namespaces
end

---@param hl string|string[]|number|nil
---@return boolean
local is_ibl_hl = function(hl)
    if type(hl) == "string" then
        return vim.startswith(hl, "@ibl.")
    end
    if type(hl) ~= "table" then
        return false
    end
    for _, group in ipairs(hl) do
        if type(group) == "string" and vim.startswith(group, "@ibl.") then
            return true
        end
    end
    return false
end

---@param hl string|string[]|number|nil
---@return boolean
local is_empty_hl = function(hl)
    return hl == nil or hl == "" or hl == 0
end

---@param virt_text ibl.virtual_text
---@param underline_hl string?
---@return ibl.virtual_text
local strip_underline = function(virt_text, underline_hl)
    local result = {}
    for _, chunk in ipairs(virt_text) do
        local hl = chunk[2]
        if type(hl) == "table" then
            local filtered = {}
            for _, group in ipairs(hl) do
                if group ~= underline_hl and not vim.startswith(group, "@ibl.scope.underline.") then
                    table.insert(filtered, group)
                end
            end
            table.insert(result, { chunk[1], filtered })
        elseif hl == underline_hl or (type(hl) == "string" and vim.startswith(hl, "@ibl.scope.underline.")) then
            table.insert(result, { chunk[1], "" })
        else
            table.insert(result, { chunk[1], hl })
        end
    end
    return result
end

---@param vline { [1]: string, [2]: string|string[]|number }[]
---@param prefix_chunks ibl.virtual_text
---@param cached_width number?
---@return { [1]: string, [2]: string|string[]|number }[], number, boolean
local rewrite_vline = function(vline, prefix_chunks, cached_width)
    local ibl_count = 0
    local ibl_width = 0
    for i, chunk in ipairs(vline) do
        if is_ibl_hl(chunk[2]) then
            ibl_count = i
            ibl_width = ibl_width + vim.fn.strwidth(chunk[1])
        else
            break
        end
    end

    if ibl_count == 0 and #prefix_chunks == 0 then
        return vline, 0, false
    end

    local avail = 0
    local consume_until = 0
    local next_chunk = vline[ibl_count + 1]
    local next_is_spaces = next_chunk ~= nil and is_empty_hl(next_chunk[2]) and next_chunk[1]:match "^ +$" ~= nil

    if ibl_count == 0 then
        if next_is_spaces then
            avail = #next_chunk[1]
            consume_until = 1
        end
    else
        if cached_width then
            avail = cached_width
            consume_until = ibl_count
            if avail > ibl_width and next_is_spaces then
                consume_until = ibl_count + 1
            end
        elseif next_is_spaces then
            avail = ibl_width + #next_chunk[1]
            consume_until = ibl_count + 1
        else
            avail = ibl_width
            consume_until = ibl_count
        end
    end

    if avail == 0 then
        return vline, 0, false
    end

    local new_vline = {}
    if #prefix_chunks == 0 then
        table.insert(new_vline, { string.rep(" ", avail), "" })
    else
        local used = 0
        for _, chunk in ipairs(prefix_chunks) do
            local width = vim.fn.strwidth(chunk[1])
            if used + width <= avail then
                table.insert(new_vline, chunk)
                used = used + width
            else
                break
            end
        end
        if avail > used then
            table.insert(new_vline, { string.rep(" ", avail - used), "" })
        end
    end

    for i = consume_until + 1, #vline do
        table.insert(new_vline, vline[i])
    end

    return new_vline, avail, true
end

---@param bufnr number
---@param row number
---@return table<number, table[]>?
local get_row_marks = function(bufnr, row)
    local namespaces = get_virt_lines_namespaces()
    if #namespaces == 0 then
        return nil
    end

    local row_marks
    for _, vl_ns in ipairs(namespaces) do
        local marks = vim.api.nvim_buf_get_extmarks(bufnr, vl_ns, { row, 0 }, { row, -1 }, {
            details = true,
            hl_name = true,
            type = "virt_lines",
        })
        if marks and #marks > 0 then
            if not row_marks then
                row_marks = {}
            end
            row_marks[vl_ns] = marks
        end
    end
    return row_marks
end

---@param bufnr number
local schedule_refresh = function(bufnr)
    if not virtual_lines_timer then
        return
    end
    pending_buffers[bufnr] = true
    virtual_lines_timer:start(
        0,
        0,
        vim.schedule_wrap(function()
            local bufs = pending_buffers
            pending_buffers = {}
            local ibl = require "ibl"
            if not ibl.initialized then
                return
            end
            for b, _ in pairs(bufs) do
                if vim.api.nvim_buf_is_valid(b) and vim.api.nvim_buf_is_loaded(b) then
                    ibl.debounced_refresh(b)
                end
            end
        end)
    )
end

---@param bufnr number
local schedule_current_line_refresh = function(bufnr)
    if not current_line_timer then
        return
    end
    pending_current_line_buffers[bufnr] = true
    current_line_timer:start(
        0,
        0,
        vim.schedule_wrap(function()
            local bufs = pending_current_line_buffers
            pending_current_line_buffers = {}
            local ibl = require "ibl"
            if not ibl.initialized then
                return
            end
            for b, _ in pairs(bufs) do
                if vim.api.nvim_buf_is_valid(b) and vim.api.nvim_buf_is_loaded(b) then
                    ibl.refresh(b)
                end
            end
        end)
    )
end

M.setup = function()
    if not has_virtual_lines or not vim.diagnostic or not vim.diagnostic.handlers then
        return
    end

    local vl_handler = vim.diagnostic.handlers.virtual_lines
    if not handler and vl_handler and vl_handler.show then
        handler = vl_handler.show

        vl_handler.show = function(namespace, bufnr, diagnostics, opts)
            if handler then
                handler(namespace, bufnr, diagnostics, opts)
            end

            local resolved_bufnr = utils.get_bufnr(bufnr)
            local is_current_line = opts
                and type(opts.virtual_lines) == "table"
                and opts.virtual_lines.current_line == true
            if is_current_line then
                if not current_line_buffers[resolved_bufnr] then
                    current_line_buffers[resolved_bufnr] = {}
                end
                current_line_buffers[resolved_bufnr][namespace] = true
            elseif current_line_buffers[resolved_bufnr] then
                current_line_buffers[resolved_bufnr][namespace] = nil
                if not next(current_line_buffers[resolved_bufnr]) then
                    current_line_buffers[resolved_bufnr] = nil
                end
            end

            schedule_refresh(resolved_bufnr)
        end
    end

    if not augroup then
        augroup = vim.api.nvim_create_augroup("IndentBlanklineVirtualLines", {})
        vim.api.nvim_create_autocmd("CursorMoved", {
            group = augroup,
            pattern = "*",
            callback = function(opts)
                if current_line_buffers[opts.buf] and next(current_line_buffers[opts.buf]) then
                    schedule_current_line_refresh(opts.buf)
                end
            end,
        })
    end
end

M.clear = function()
    if handler and vim.diagnostic and vim.diagnostic.handlers and vim.diagnostic.handlers.virtual_lines then
        vim.diagnostic.handlers.virtual_lines.show = handler
        handler = nil
    end
    if augroup then
        pcall(vim.api.nvim_del_augroup_by_id, augroup)
        augroup = nil
    end
    for bufnr, _ in pairs(buffer_state) do
        M.clear_buffer(bufnr)
    end
    current_line_buffers = {}
    pending_buffers = {}
    pending_current_line_buffers = {}
end

---@param bufnr number
M.clear_buffer = function(bufnr)
    if vim.api.nvim_buf_is_loaded(bufnr) then
        for row, _ in pairs(buffer_state[bufnr] or {}) do
            M.set(bufnr, row, {}, nil, nil)
        end
    end

    buffer_state[bufnr] = nil
end

--- Forgets a buffer without touching its extmarks
---
--- Used for buffers that are gone, where restoring the virtual lines is pointless
---@param bufnr number
M.clear_buffer_state = function(bufnr)
    buffer_state[bufnr] = nil
    current_line_buffers[bufnr] = nil
    pending_buffers[bufnr] = nil
    pending_current_line_buffers[bufnr] = nil
end

---@param bufnr number
---@param start_row number
---@param end_row number
---@return table<number, table<number, table[]>>?
M.get_buffer_marks = function(bufnr, start_row, end_row)
    if not has_virtual_lines or not vim.api.nvim_buf_is_loaded(bufnr) then
        return nil
    end

    local namespaces = get_virt_lines_namespaces()
    if #namespaces == 0 then
        return nil
    end

    local result
    for _, vl_ns in ipairs(namespaces) do
        local marks = vim.api.nvim_buf_get_extmarks(bufnr, vl_ns, { start_row, 0 }, { end_row, -1 }, {
            details = true,
            hl_name = true,
            type = "virt_lines",
        })
        for _, mark in ipairs(marks or {}) do
            local row = mark[2]
            if not result then
                result = {}
            end
            if not result[row] then
                result[row] = {}
            end
            if not result[row][vl_ns] then
                result[row][vl_ns] = {}
            end
            table.insert(result[row][vl_ns], mark)
        end
    end

    return result
end

---@param bufnr number
---@param row number
---@param virt_text ibl.virtual_text
---@param underline_hl string?
---@param row_marks table<number, table[]>?
M.set = function(bufnr, row, virt_text, underline_hl, row_marks)
    if not has_virtual_lines or not vim.api.nvim_buf_is_loaded(bufnr) then
        return
    end

    row_marks = row_marks or get_row_marks(bufnr, row)
    if not row_marks then
        return
    end

    local prefix_chunks = #virt_text > 0 and strip_underline(virt_text, underline_hl) or {}

    for vl_ns, marks in pairs(row_marks) do
        for _, mark in ipairs(marks) do
            local mark_id, mark_row, mark_col, mark_opt = unpack(mark)
            if mark_opt and mark_opt.virt_lines then
                local cached_widths = buffer_state[bufnr]
                    and buffer_state[bufnr][row]
                    and buffer_state[bufnr][row][vl_ns]
                    and buffer_state[bufnr][row][vl_ns][mark_id]
                local new_widths = {}
                local new_virt_lines = {}
                local changed = false

                for idx, vline in ipairs(mark_opt.virt_lines) do
                    local cached_width = cached_widths and cached_widths[idx]
                    local new_vline, avail, line_changed = rewrite_vline(vline, prefix_chunks, cached_width)
                    new_widths[idx] = avail
                    new_virt_lines[idx] = new_vline
                    if line_changed then
                        changed = true
                    end
                end

                if changed then
                    if #prefix_chunks > 0 then
                        if not buffer_state[bufnr] then
                            buffer_state[bufnr] = {}
                        end
                        if not buffer_state[bufnr][row] then
                            buffer_state[bufnr][row] = {}
                        end
                        if not buffer_state[bufnr][row][vl_ns] then
                            buffer_state[bufnr][row][vl_ns] = {}
                        end
                        buffer_state[bufnr][row][vl_ns][mark_id] = new_widths
                    end

                    mark_opt.ns_id = nil
                    mark_opt.id = mark_id
                    mark_opt.virt_lines = new_virt_lines
                    pcall(vim.api.nvim_buf_set_extmark, bufnr, vl_ns, mark_row, mark_col, mark_opt)
                end
            end
        end
    end
end

return M
