local conf = require "ibl.config"

---@class ibl.scope_hl
---@field char string
---@field start string
---@field end_ string
---@field corner string
---@field inlay_hint string

---@alias ibl.whitespace_hl string
local M = {
    ---@type string[]
    indent = {},
    ---@type ibl.whitespace_hl[]
    whitespace = {},
    ---@type table<ibl.whitespace_hl, ibl.scope_hl[]>
    scope = {},
}

M.setup = function()
    local config = conf.get_config(-1)

    local get = function(name)
        return vim.api.nvim_get_hl(0, { name = name })
    end
    local not_set = function(hl)
        return not hl or vim.tbl_count(hl) == 0
    end

    local indent_highlights = config.indent.highlight

    if type(indent_highlights) == "string" then
        indent_highlights = { indent_highlights }
    end

    M.indent = {}
    for i, name in ipairs(indent_highlights) do
        local hl = get(name)
        if not_set(hl) then
            error(string.format("No highlight group '%s' found", name))
        end
        hl.nocombine = true
        M.indent[i] = string.format("@indent.char.%d", i)
        vim.api.nvim_set_hl(0, M.indent[i], hl)
    end

    local whitespace_highlights = config.whitespace.highlight

    if type(whitespace_highlights) == "string" then
        whitespace_highlights = { whitespace_highlights }
    end

    local scope_highlights = config.scope.highlight

    if type(scope_highlights) == "string" then
        scope_highlights = { scope_highlights }
    end

    M.whitespace = {}
    M.scope = {}
    for i, name in ipairs(whitespace_highlights) do
        local hl = get(name)
        if not_set(hl) then
            error(string.format("No highlight group '%s' found", name))
        end
        hl.nocombine = true
        M.whitespace[i] = string.format("@indent.whitespace.%d", i)
        vim.api.nvim_set_hl(0, M.whitespace[i], hl)

        for j, scope_name in ipairs(scope_highlights) do
            local char_hl = get(scope_name)
            if not_set(char_hl) then
                error(string.format("No highlight group '%s' found", scope_name))
            end
            char_hl.nocombine = true
            char_hl.bg = hl.bg

            local start_hl = { sp = char_hl.fg, underline = true }
            local end_hl = { fg = hl.fg, bg = hl.bg, sp = char_hl.fg, underline = true }
            local corner_hl = { fg = char_hl.fg, bg = hl.bg, sp = char_hl.fg, underline = true }
            local inlay_hint_hl = get "LspInlayHint"
            inlay_hint_hl.underline = true
            inlay_hint_hl.sp = start_hl.sp

            if not M.scope[M.whitespace[i]] then
                M.scope[M.whitespace[i]] = {}
            end
            M.scope[M.whitespace[i]][j] = {
                char = string.format("@indent.scope.char.%d.%d", i, j),
                start = string.format("@indent.scope.start.%d.%d", i, j),
                end_ = string.format("@indent.scope.end.%d.%d", i, j),
                corner = string.format("@indent.scope.corner.%d.%d", i, j),
                inlay_hint = string.format("@indent.scope.inlay_hint.%d.%d", i, j),
            }
            vim.api.nvim_set_hl(0, M.scope[M.whitespace[i]][j].char, char_hl)
            vim.api.nvim_set_hl(0, M.scope[M.whitespace[i]][j].start, start_hl)
            vim.api.nvim_set_hl(0, M.scope[M.whitespace[i]][j].end_, end_hl)
            vim.api.nvim_set_hl(0, M.scope[M.whitespace[i]][j].corner, corner_hl)
            vim.api.nvim_set_hl(0, M.scope[M.whitespace[i]][j].inlay_hint, inlay_hint_hl)
        end
    end
end

return M
