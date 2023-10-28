local inlayhint_namespace = vim.api.nvim_create_namespace "vim_lsp_inlayhint"

local M = {}

---@type function?
local handler = nil

---@type table<number, number[]>
local buffer_state = {}

---@param bufnr number
---@param row number
---@param col number
---@param hl string|string[]
---@param hl_empty string
local set_extmark = function(bufnr, row, col, hl, hl_empty)
    if not vim.api.nvim_buf_is_loaded(bufnr) then
        return
    end
    local inlayhint_extmarks = vim.api.nvim_buf_get_extmarks(
        bufnr,
        inlayhint_namespace,
        { row, col },
        { row, -1 },
        { details = true, hl_name = false, type = "virt_text" }
    )

    vim.api.nvim_buf_clear_namespace(bufnr, inlayhint_namespace, row, row + 1)
    for _, inlay in ipairs(inlayhint_extmarks or {}) do
        local _, inlay_row, inlay_col, inlay_opt = unpack(inlay)
        for _, virt_text in ipairs(inlay_opt.virt_text) do
            if vim.trim(virt_text[1]) == "" then
                virt_text[2] = hl_empty
            else
                virt_text[2] = hl
            end
        end
        inlay_opt.ns_id = nil
        pcall(vim.api.nvim_buf_set_extmark, bufnr, inlayhint_namespace, inlay_row, inlay_col, inlay_opt)
    end
end

M.setup = function()
    if not handler then
        handler = vim.lsp.handlers["textDocument/inlayHint"]

        vim.lsp.handlers["textDocument/inlayHint"] = function(err, result, ctx, conf)
            if handler then
                handler(err, result, ctx, conf)
            end
            require("ibl").debounced_refresh(ctx.bufnr)
        end
    end
end

M.clear = function()
    if handler then
        vim.lsp.handlers["textDocument/inlayHint"] = handler
        handler = nil
    end
    for bufnr, _ in pairs(buffer_state) do
        M.clear_buffer(bufnr)
    end
end

---@param bufnr number
M.clear_buffer = function(bufnr)
    for _, row in ipairs(buffer_state[bufnr] or {}) do
        pcall(set_extmark, bufnr, row, 0, "LspInlayHint", "")
    end

    buffer_state[bufnr] = nil
end

---@param bufnr number
---@param row number
---@param col number
---@param hl string
---@param hl_empty string
M.set = function(bufnr, row, col, hl, hl_empty)
    if not buffer_state[bufnr] then
        buffer_state[bufnr] = {}
    end
    table.insert(buffer_state[bufnr], row)

    set_extmark(bufnr, row, col, { "LspInlayHint", hl }, hl_empty)
end

return M
