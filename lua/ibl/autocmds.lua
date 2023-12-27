local highlights = require "ibl.highlights"
local M = {}

M.setup = function()
    local group = vim.api.nvim_create_augroup("IndentBlankline", {})
    local ibl = require "ibl"
    local buffer_leftcol = {}

    vim.api.nvim_create_autocmd("VimEnter", {
        group = group,
        pattern = "*",
        callback = ibl.refresh_all,
    })
    vim.api.nvim_create_autocmd({
        "CursorMoved",
        "CursorMovedI",
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
            ibl.debounced_refresh(opts.buf)
        end,
    })
    vim.api.nvim_create_autocmd("OptionSet", {
        group = group,
        pattern = "list,listchars,shiftwidth,tabstop,vartabstop,breakindent,breakindentopt",
        callback = function(opts)
            ibl.debounced_refresh(opts.buf)
        end,
    })
    vim.api.nvim_create_autocmd("WinScrolled", {
        group = group,
        pattern = "*",
        callback = function(opts)
            local win_view = vim.fn.winsaveview() or { leftcol = 0 }

            if buffer_leftcol[opts.buf] ~= win_view.leftcol then
                buffer_leftcol[opts.buf] = win_view.leftcol
                -- Refresh immediately for horizontal scrolling
                ibl.refresh(opts.buf)
            else
                ibl.debounced_refresh(opts.buf)
            end
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
