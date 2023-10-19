local highlights = require "ibl.highlights"
local hooks = require "ibl.hooks"
local autocmds = require "ibl.autocmds"
local inlay_hints = require "ibl.inlay_hints"
local indent = require "ibl.indent"
local vt = require "ibl.virt_text"
local scp = require "ibl.scope"
local conf = require "ibl.config"
local utils = require "ibl.utils"

local namespace = vim.api.nvim_create_namespace "indent_blankline"

local M = {}

---@package
M.initialized = false

---@type table<number, { scope: TSNode?, left_offset: number, top_offset: number, tick: number }>
local global_buffer_state = {}

---@param bufnr number
local clear_buffer = function(bufnr)
    vt.clear_buffer(bufnr)
    inlay_hints.clear_buffer(bufnr)
    for _, fn in pairs(hooks.get(bufnr, hooks.type.CLEAR)) do
        fn(bufnr)
    end
end

---@param config ibl.config.full
local setup = function(config)
    M.initialized = true

    if not config.enabled then
        for bufnr, _ in pairs(global_buffer_state) do
            clear_buffer(bufnr)
        end
        global_buffer_state = {}
        inlay_hints.clear()
        return
    end

    inlay_hints.setup()
    highlights.setup()
    autocmds.setup()
    M.refresh_all()
end

--- Initializes and configures indent-blankline.
---
--- Optionally, the first parameter can be a configuration table.
--- All values that are not passed in the table are set to the default value.
--- List values get merged with the default list value.
---
--- `setup` is idempotent, meaning you can call it multiple times, and each call will reset indent-blankline.
--- If you want to only update the current configuration, use `update()`.
---@param config ibl.config?
M.setup = function(config)
    setup(conf.set_config(config))
end

--- Updates the indent-blankline configuration
---
--- The first parameter is a configuration table.
--- All values that are not passed in the table are kept as they are.
--- List values get merged with the current list value.
---@param config ibl.config
M.update = function(config)
    setup(conf.update_config(config))
end

--- Overwrites the indent-blankline configuration
---
--- The first parameter is a configuration table.
--- All values that are not passed in the table are kept as they are.
--- All values that are passed overwrite existing and default values.
---@param config ibl.config
M.overwrite = function(config)
    setup(conf.overwrite_config(config))
end

--- Configures indent-blankline for one buffer
---
--- All values that are not passed are cleared, and will fall back to the global config
---@param bufnr number
---@param config ibl.config
M.setup_buffer = function(bufnr, config)
    assert(M.initialized, "Tried to setup buffer without doing global setup")
    bufnr = utils.get_bufnr(bufnr)
    local c = conf.set_buffer_config(bufnr, config)

    if c.enabled then
        M.refresh(bufnr)
    else
        clear_buffer(bufnr)
    end
end

--- Refreshes indent-blankline in all buffers
M.refresh_all = function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        vim.api.nvim_win_call(win, function()
            M.refresh(vim.api.nvim_win_get_buf(win) --[[@as number]])
        end)
    end
end

local debounced_refresh = setmetatable({
    timers = {},
    queued_buffers = {},
}, {
    ---@param bufnr number
    __call = function(self, bufnr)
        bufnr = utils.get_bufnr(bufnr)
        local uv = vim.uv or vim.loop
        if not self.timers[bufnr] then
            self.timers[bufnr] = uv.new_timer()
        end
        if uv.timer_get_due_in(self.timers[bufnr]) <= 50 then
            M.refresh(bufnr)

            local config = conf.get_config(bufnr)
            self.timers[bufnr]:start(config.debounce, 0, function()
                if self.queued_buffers[bufnr] then
                    self.queued_buffers[bufnr] = nil
                    vim.schedule_wrap(M.refresh)(bufnr)
                end
            end)
        else
            self.queued_buffers[bufnr] = true
        end
    end,
})

--- Refreshes indent-blankline in one buffer, debounced
---
---@param bufnr number
M.debounced_refresh = function(bufnr)
    if vim.api.nvim_get_current_buf() == bufnr and vim.api.nvim_get_option_value("scrollbind", { scope = "local" }) then
        for _, b in ipairs(vim.fn.tabpagebuflist()) do
            debounced_refresh(b)
        end
    else
        debounced_refresh(bufnr)
    end
end

--- Refreshes indent-blankline in one buffer
---
--- Only use this directly if you know what you are doing, consider `debounced_refresh` instead
---@param bufnr number
M.refresh = function(bufnr)
    assert(M.initialized, "Tried to refresh without doing setup")
    bufnr = utils.get_bufnr(bufnr)
    local is_current_buffer = vim.api.nvim_get_current_buf() == bufnr
    local config = conf.get_config(bufnr)

    if not config.enabled or not vim.api.nvim_buf_is_loaded(bufnr) or not utils.is_buffer_active(bufnr, config) then
        clear_buffer(bufnr)
        return
    end

    for _, fn in
        pairs(hooks.get(bufnr, hooks.type.ACTIVE) --[[ @as ibl.hooks.cb.active[] ]])
    do
        if not fn(bufnr) then
            clear_buffer(bufnr)
            return
        end
    end

    local left_offset, top_offset, win_end, win_height, cursor_row = utils.get_offset(bufnr)
    if top_offset > win_end then
        return
    end

    local offset = math.max(top_offset - 1 - config.viewport_buffer.min, 0)

    local scope_disabled = false
    for _, fn in
        pairs(hooks.get(bufnr, hooks.type.SCOPE_ACTIVE) --[[ @as ibl.hooks.cb.scope_active[] ]])
    do
        if not fn(bufnr) then
            scope_disabled = true
            break
        end
    end

    local scope
    if not scope_disabled and config.scope.enabled then
        scope = scp.get(bufnr, config)
        if scope and scope:start() >= 0 then
            offset = top_offset - math.min(top_offset - math.min(offset, scope:start()), config.viewport_buffer.max)
        end
    end

    local range = math.min(win_end + config.viewport_buffer.min, vim.api.nvim_buf_line_count(bufnr))
    local lines = vim.api.nvim_buf_get_lines(bufnr, offset, range, false)

    ---@type ibl.indent_options
    local indent_opts = {
        tabstop = vim.api.nvim_get_option_value("tabstop", { buf = bufnr }),
        vartabstop = vim.api.nvim_get_option_value("vartabstop", { buf = bufnr }),
        shiftwidth = vim.api.nvim_get_option_value("shiftwidth", { buf = bufnr }),
        smart_indent_cap = config.indent.smart_indent_cap,
    }
    local listchars = utils.get_listchars(bufnr)
    if listchars.tabstop_overwrite then
        indent_opts.tabstop = 2
        indent_opts.vartabstop = ""
    end

    local indent_state
    local empty_line_counter = 0

    local buffer_state = global_buffer_state[bufnr]
        or {
            scope = nil,
            left_offset = -1,
            top_offset = -1,
            tick = 0,
        }

    local same_scope = (scope and scope:id()) == (buffer_state.scope and buffer_state.scope:id())

    if not same_scope then
        inlay_hints.clear_buffer(bufnr)
    end

    global_buffer_state[bufnr] = {
        left_offset = left_offset,
        top_offset = top_offset,
        scope = scope,
        tick = buffer_state.tick + 1,
    }

    local scope_col_start_single = -1
    local scope_row_start, scope_col_start, scope_row_end, scope_col_end = -1, -1, -1, -1
    local scope_index = -1
    if scope then
        scope_row_start, scope_col_start, scope_row_end, scope_col_end = scope:range()
        scope_row_start, scope_col_start, scope_row_end = scope_row_start + 1, scope_col_start + 1, scope_row_end + 1
    end
    local exact_scope_col_start = scope_col_start

    local cursor_row_stack_size = -1
    local current_indent_row_start = offset + 1
    local current_indent_row_end = range

    ---@type table<integer, boolean>
    local line_skipped = {}

    ---@type ibl.hooks.cb.skip_line[]
    local skip_line_hooks = hooks.get(bufnr, hooks.type.SKIP_LINE)
    for i, line in ipairs(lines) do
        local row = i + offset
        line_skipped[i] = false
        for _, fn in pairs(skip_line_hooks) do
            if fn(buffer_state.tick, bufnr, row - 1, line) then
                line_skipped[i] = true
                break
            end
        end
    end

    local get_indent_details = function(ws_tbl)
        local number_of_indents = 0
        local last_indent_col = -1
        if not ws_tbl then
            return number_of_indents, last_indent_col
        end
        local k = 0
        local has_seen_indent = false
        while k < #ws_tbl do
            if indent.is_indent(ws_tbl[#ws_tbl - k]) then
                if not has_seen_indent then
                    has_seen_indent = true
                    last_indent_col = #ws_tbl - k - 1
                end
                number_of_indents = number_of_indents + 1
            end
            k = k + 1
        end
        return number_of_indents, last_indent_col
    end

    ---@type number
    local cur_indent_stack_size = 0

    ---@type number
    local current_indent_col = -1

    ---@type ibl.indent.whitespace[]
    local next_whitespace_tbl = {}

    -- array of tables
    ---@type table<integer, ibl.indent.whitespace[]>
    local arr_whitespace_tbl = {}

    -- arrays of numbers
    ---@type table<integer, integer>
    local current_indent_stack = {} -- current indent stack of line nr
    ---@type table<integer, integer>
    local arr_whitespace_len = {}

    -- boolean arrays
    ---@type table<integer, boolean>
    local arr_blankline = {}
    ---@type table<integer, boolean>
    local arr_whitespace_only = {}

    -- in the first loop we calculate the things we need to setup the virtual text via extmarks
    for i, line in ipairs(lines) do
        local row = i + offset

        if line_skipped[i] then
            vt.clear_buffer(bufnr, row)
            goto continue
        end

        local whitespace = utils.get_whitespace(line)
        local foldclosed = vim.fn.foldclosed(row)

        if is_current_buffer and foldclosed == row then
            local foldtext = vim.fn.foldtextresult(row)
            local foldtext_whitespace = utils.get_whitespace(foldtext)
            if vim.fn.strdisplaywidth(foldtext_whitespace, 0) < vim.fn.strdisplaywidth(whitespace, 0) then
                vt.clear_buffer(bufnr, row)
                line_skipped[i] = true
                goto continue
            end
        end

        if is_current_buffer and foldclosed > -1 and foldclosed + win_height < row then
            vt.clear_buffer(bufnr, row)
            line_skipped[i] = true
            goto continue
        end

        ---@type ibl.indent.whitespace[]
        local whitespace_tbl

        local blankline = line:len() == 0
        arr_blankline[i] = blankline

        arr_whitespace_len[i] = #whitespace
        arr_whitespace_only[i] = not blankline and line == whitespace

        -- #### calculate indent ####
        if not blankline then
            whitespace_tbl, indent_state = indent.get(whitespace, indent_opts, indent_state)
        elseif empty_line_counter > 0 then
            empty_line_counter = empty_line_counter - 1
            whitespace_tbl = next_whitespace_tbl
        else
            if i == #lines then
                whitespace_tbl = {}
            else
                local j = i + 1
                while j < #lines and (lines[j]:len() == 0 or line_skipped[j]) do
                    if not line_skipped[j] then
                        empty_line_counter = empty_line_counter + 1
                    end
                    j = j + 1
                end

                local j_whitespace = utils.get_whitespace(lines[j])
                whitespace_tbl, indent_state = indent.get(j_whitespace, indent_opts, indent_state)

                if utils.has_end(lines[j]) then
                    local last_whitespace_tbl = arr_whitespace_tbl[i - 1] or {}
                    local trail = last_whitespace_tbl[indent_state.stack[#indent_state.stack] + 1]
                    local trail_whitespace = last_whitespace_tbl[indent_state.stack[#indent_state.stack]]
                    if trail then
                        table.insert(whitespace_tbl, trail)
                    elseif trail_whitespace then
                        if indent.is_space_indent(trail_whitespace) then
                            table.insert(whitespace_tbl, indent.whitespace.INDENT)
                        else
                            table.insert(whitespace_tbl, indent.whitespace.TAB_START)
                        end
                    end
                end
            end
            next_whitespace_tbl = whitespace_tbl
        end

        -- remove blankline trail
        if blankline and config.whitespace.remove_blankline_trail then
            while #whitespace_tbl > 0 do
                if indent.is_indent(whitespace_tbl[#whitespace_tbl]) then
                    break
                end
                table.remove(whitespace_tbl, #whitespace_tbl)
            end
        end

        if config.current_indent.enabled then
            local number_of_indents, last_indent_col = get_indent_details(whitespace_tbl)

            local prev_indent_stack_size = cur_indent_stack_size

            cur_indent_stack_size = number_of_indents

            if row <= cursor_row then
                if prev_indent_stack_size > cur_indent_stack_size then
                    -- we need to take into account that we might jump back more than
                    -- only one indent level at once
                    while prev_indent_stack_size > cur_indent_stack_size do
                        current_indent_stack[#current_indent_stack] = nil
                        prev_indent_stack_size = prev_indent_stack_size - 1
                    end
                elseif prev_indent_stack_size < cur_indent_stack_size then
                    current_indent_stack[#current_indent_stack + 1] = row
                end
            else
                -- row > cursor_row
                if cursor_row_stack_size >= 0 and cursor_row_stack_size > cur_indent_stack_size then
                    current_indent_row_end = row - 1
                    cursor_row_stack_size = -1
                end
            end
            if row == cursor_row then
                cursor_row_stack_size = cur_indent_stack_size
                current_indent_col = last_indent_col
                if current_indent_stack[#current_indent_stack] then
                    current_indent_row_start = current_indent_stack[#current_indent_stack]
                end
            end
        end

        -- Fix horizontal scroll
        local current_left_offset = left_offset
        while #whitespace_tbl > 0 and current_left_offset > 0 do
            table.remove(whitespace_tbl, 1)
            current_left_offset = current_left_offset - 1
        end

        for _, fn in
            pairs(hooks.get(bufnr, hooks.type.WHITESPACE) --[[ @as ibl.hooks.cb.whitespace[] ]])
        do
            whitespace_tbl = fn(buffer_state.tick, bufnr, row - 1, whitespace_tbl)
        end

        -- this do block is purely to help stylua with the scope
        do
            arr_whitespace_tbl[i] = whitespace_tbl
        end

        ::continue::
    end

    -- set up the virtual text via extmarks
    for i, line in ipairs(lines) do
        if line_skipped[i] then
            goto continue1
        end

        local row = i + offset
        local whitespace_len = arr_whitespace_len[i]

        local blankline = arr_blankline[i]
        local whitespace_tbl = arr_whitespace_tbl[i]
        local whitespace_only = arr_whitespace_only[i]

        local scope_active = row >= scope_row_start and row <= scope_row_end
        if
            scope_active
            and scope_col_start_single > -1
            and (whitespace_tbl[scope_col_start_single + 1] or blankline)
            and not indent.is_indent(whitespace_tbl[scope_col_start_single + 1])
        then
            if indent.is_space_indent(whitespace_tbl[scope_col_start_single + 1]) then
                whitespace_tbl[scope_col_start_single + 1] = indent.whitespace.INDENT
            else
                whitespace_tbl[scope_col_start_single + 1] = indent.whitespace.TAB_START
            end
            local k = scope_col_start_single
            while not whitespace_tbl[k] and k >= 0 do
                whitespace_tbl[k] = indent.whitespace.SPACE
                k = k - 1
            end
        end

        -- #### make virtual text ####
        local scope_start = row == scope_row_start
        local scope_end = row == scope_row_end

        local current_indent_start = row == current_indent_row_start - 1
        local current_indent_end = row == current_indent_row_end + 1

        local current_indent_active = row >= current_indent_row_start
            and row <= current_indent_row_end
            and config.current_indent.enabled

        if scope_start and scope then
            scope_col_start = whitespace_len
            scope_col_start_single = #whitespace_tbl
            scope_index = #vim.tbl_filter(function(w)
                return indent.is_indent(w)
            end, whitespace_tbl) + 1
            for _, fn in
                pairs(hooks.get(bufnr, hooks.type.SCOPE_HIGHLIGHT) --[[ @as ibl.hooks.cb.scope_highlight[] ]])
            do
                scope_index = fn(buffer_state.tick, bufnr, scope, scope_index)
            end
        end

        local char_map = vt.get_char_map(config, listchars, whitespace_only, blankline)
        local virt_text, scope_hl, current_indent_hl = vt.get(
            config,
            char_map,
            whitespace_tbl,
            scope_active,
            scope_index,
            scope_end,
            scope_col_start_single,
            current_indent_active,
            current_indent_col
        )

        -- #### set virtual text ####
        vt.clear_buffer(bufnr, row)

        -- Show exact scope
        local scope_col_start_draw = whitespace_len
        local scope_show_end_cond = #whitespace_tbl > scope_col_start_single

        if config.scope.show_exact_scope then
            scope_col_start_draw = exact_scope_col_start - 1
            scope_show_end_cond = #whitespace_tbl >= scope_col_start_single
        end

        -- Scope start
        if config.scope.show_start and scope_start then
            vim.api.nvim_buf_set_extmark(bufnr, namespace, row - 1, scope_col_start_draw, {
                end_col = #line,
                hl_group = scope_hl.underline,
                priority = config.scope.priority,
                strict = false,
            })
            inlay_hints.set(bufnr, row - 1, whitespace_len, scope_hl.underline, scope_hl.underline)
        end

        -- Scope end
        if config.scope.show_end and scope_end and scope_show_end_cond then
            vim.api.nvim_buf_set_extmark(bufnr, namespace, row - 1, scope_col_start, {
                end_col = scope_col_end,
                hl_group = scope_hl.underline,
                priority = config.scope.priority,
                strict = false,
            })
            inlay_hints.set(bufnr, row - 1, whitespace_len, scope_hl.underline, scope_hl.underline)
        end

        -- current_indent start
        if config.current_indent.show_start and current_indent_start and current_indent_col >= 0 then
            vim.api.nvim_buf_set_extmark(bufnr, namespace, row - 1, current_indent_col, {
                end_col = #line,
                hl_group = current_indent_hl.underline,
                priority = config.current_indent.priority,
                strict = false,
            })
            inlay_hints.set(bufnr, row - 1, whitespace_len, current_indent_hl.underline, current_indent_hl.underline)
        end

        -- current_indent end
        if
            config.current_indent.show_end
            and current_indent_end
            and #whitespace_tbl >= current_indent_col
            and current_indent_col >= 0
        then
            vim.api.nvim_buf_set_extmark(bufnr, namespace, row - 1, current_indent_col, {
                end_col = #line,
                hl_group = current_indent_hl.underline,
                priority = config.current_indent.priority,
                strict = false,
            })
            inlay_hints.set(bufnr, row - 1, whitespace_len, current_indent_hl.underline, current_indent_hl.underline)
        end

        for _, fn in
            pairs(hooks.get(bufnr, hooks.type.VIRTUAL_TEXT) --[[ @as ibl.hooks.cb.virtual_text[] ]])
        do
            virt_text = fn(buffer_state.tick, bufnr, row - 1, virt_text)
        end

        -- Indent
        if #virt_text > 0 then
            vim.api.nvim_buf_set_extmark(bufnr, namespace, row - 1, 0, {
                virt_text = virt_text,
                virt_text_pos = "overlay",
                hl_mode = "combine",
                priority = config.indent.priority,
                strict = false,
            })
        end

        ::continue1::
    end
end

return M
