local highlights = require "ibl.highlights"
local M = {}

M.setup = function()
    local group = vim.api.nvim_create_augroup("IndentBlankline", {})
    local ibl = require "ibl"

    vim.api.nvim_create_autocmd("VimEnter", {
        group = group,
        pattern = "*",
        callback = ibl.refresh_all,
    })
    vim.api.nvim_create_autocmd({
        "BufWinEnter",
        "CompleteChanged",
        "FileChangedShellPost",
        "FileType",
        "TextChanged",
        "TextChangedI",
    }, {
        group = group,
        pattern = "*",
        callback = function(opts)
            ibl.refresh(opts.buf)
        end,
    })
    vim.api.nvim_create_autocmd("OptionSet", {
        group = group,
        pattern = "list,listchars,shiftwidth,tabstop,vartabstop",
        callback = function(opts)
            ibl.refresh(opts.buf)
        end,
    })
    vim.api.nvim_create_autocmd("CursorMoved", {
        group = group,
        pattern = "*",
        callback = function(opts)
            ibl.debounced_refresh(opts.buf)
        end,
    })
    vim.api.nvim_create_autocmd("WinScrolled", {
        group = group,
        pattern = "*",
        callback = function(opts)
            ibl.debounced_refresh(opts.buf)
        end,
    })
    vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        pattern = "*",
        callback = function()
            highlights.setup()
            ibl.refresh_all()
        end,
    })
end

return M
