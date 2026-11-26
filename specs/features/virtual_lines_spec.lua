assert = require "luassert"

if vim.fn.has "nvim-0.11" == 0 then
    return
end

local ibl = require "ibl"
local virtual_lines = require "ibl.virtual_lines"

---@param bufnr number
---@param diag_ns number
---@return table[]
local get_virt_lines_extmarks = function(bufnr, diag_ns)
    local ns_info = vim.diagnostic.get_namespaces()[diag_ns]
    local vl_ns = ns_info and ns_info.user_data and ns_info.user_data.virt_lines_ns
    if not vl_ns then
        return {}
    end
    return vim.api.nvim_buf_get_extmarks(bufnr, vl_ns, 0, -1, {
        details = true,
        hl_name = true,
        type = "virt_lines",
    })
end

---@param hl string|string[]|nil
---@return boolean
local has_ibl_hl = function(hl)
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

describe("virtual_lines", function()
    local bufnr
    local diag_ns

    before_each(function()
        ibl.setup { debounce = 10 }
        bufnr = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_set_current_buf(bufnr)
        vim.bo[bufnr].buftype = ""
        vim.bo[bufnr].filetype = "lua"
        vim.bo[bufnr].shiftwidth = 4
        vim.bo[bufnr].tabstop = 4
        vim.bo[bufnr].expandtab = true
        diag_ns = vim.api.nvim_create_namespace "test_ibl_virtual_lines"
        vim.diagnostic.config { virtual_lines = true }
    end)

    after_each(function()
        vim.diagnostic.reset(diag_ns, bufnr)
        vim.diagnostic.config { virtual_lines = false }
        virtual_lines.clear_buffer(bufnr)
        if vim.api.nvim_buf_is_valid(bufnr) then
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end
    end)

    it("adds indent guides to diagnostic virtual_lines", function()
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
            "local function foo()",
            "    local x = 1",
            "        local y = 2",
            "end",
        })
        vim.diagnostic.set(diag_ns, bufnr, {
            { lnum = 2, col = 10, severity = vim.diagnostic.severity.ERROR, message = "some error" },
        })

        ibl.refresh(bufnr)

        local marks = get_virt_lines_extmarks(bufnr, diag_ns)
        assert.are.equal(1, #marks)

        local vline = marks[1][4].virt_lines[1]
        assert.are.equal("▎", vline[1][1])
        assert.is_true(has_ibl_hl(vline[1][2]))
        assert.are.equal("▎", vline[5][1])
        assert.is_true(has_ibl_hl(vline[5][2]))
        -- Remaining 2 spaces before col 10 and diagnostic message are preserved
        assert.are.equal("  ", vline[9][1])
        assert.are.equal("", vline[9][2])
        assert.are.equal("└──── ", vline[10][1])
        assert.are.equal("some error", vline[11][1])
    end)

    it("supports tab indentation", function()
        vim.bo[bufnr].expandtab = false
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
            "local function foo()",
            "\t\tlocal y = 2",
            "end",
        })
        vim.diagnostic.set(diag_ns, bufnr, {
            { lnum = 1, col = 4, severity = vim.diagnostic.severity.ERROR, message = "tab error" },
        })

        ibl.refresh(bufnr)

        local marks = get_virt_lines_extmarks(bufnr, diag_ns)
        assert.are.equal(1, #marks)

        local vline = marks[1][4].virt_lines[1]
        assert.are.equal("▎", vline[1][1])
        assert.is_true(has_ibl_hl(vline[1][2]))
        assert.are.equal("▎", vline[5][1])
        assert.is_true(has_ibl_hl(vline[5][2]))
        assert.are.equal("  ", vline[9][1])
        assert.are.equal("└──── ", vline[10][1])
        assert.are.equal("tab error", vline[11][1])
    end)

    it("does not overwrite diagnostic text when col is inside or before indentation", function()
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
            "        local y = 2",
        })
        vim.diagnostic.set(diag_ns, bufnr, {
            { lnum = 0, col = 2, severity = vim.diagnostic.severity.WARN, message = "early diag" },
        })

        ibl.refresh(bufnr)

        local marks = get_virt_lines_extmarks(bufnr, diag_ns)
        assert.are.equal(1, #marks)

        local vline = marks[1][4].virt_lines[1]
        assert.are.equal("▎", vline[1][1])
        assert.is_true(has_ibl_hl(vline[1][2]))
        assert.are.equal(" ", vline[2][1])
        assert.is_true(has_ibl_hl(vline[2][2]))
        assert.are.equal("└──── ", vline[3][1])
        assert.are.equal("early diag", vline[4][1])
    end)

    it("handles col 0 diagnostics without shifting connector", function()
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
            "    local x = 1",
        })
        vim.diagnostic.set(diag_ns, bufnr, {
            { lnum = 0, col = 0, severity = vim.diagnostic.severity.ERROR, message = "col0" },
        })

        ibl.refresh(bufnr)

        local marks = get_virt_lines_extmarks(bufnr, diag_ns)
        assert.are.equal(1, #marks)

        local vline = marks[1][4].virt_lines[1]
        assert.are.equal("", vline[1][1])
        assert.are.equal("└──── ", vline[2][1])
        assert.are.equal("col0", vline[3][1])
    end)

    it("handles multiline diagnostic messages and repeated refreshes idempotently", function()
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
            "        local y = 2",
        })
        vim.diagnostic.set(diag_ns, bufnr, {
            { lnum = 0, col = 8, severity = vim.diagnostic.severity.ERROR, message = "first\nsecond" },
        })

        ibl.refresh(bufnr)
        ibl.refresh(bufnr)

        local marks = get_virt_lines_extmarks(bufnr, diag_ns)
        assert.are.equal(1, #marks)
        local vlines = marks[1][4].virt_lines
        assert.are.equal(2, #vlines)

        assert.are.equal("▎", vlines[1][1][1])
        assert.are.equal("▎", vlines[1][5][1])
        assert.are.equal("└──── ", vlines[1][9][1])
        assert.are.equal("first", vlines[1][10][1])

        assert.are.equal("▎", vlines[2][1][1])
        assert.are.equal("▎", vlines[2][5][1])
        assert.are.equal("      ", vlines[2][9][1])
        assert.are.equal("second", vlines[2][10][1])
    end)

    it("does not apply scope underline highlights to virtual_lines", function()
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
            "        local y = 2",
        })
        vim.diagnostic.set(diag_ns, bufnr, {
            { lnum = 0, col = 8, severity = vim.diagnostic.severity.ERROR, message = "err" },
        })

        virtual_lines.set(bufnr, 0, {
            { "▎", { "@ibl.whitespace.char.1", "@ibl.indent.char.1", "@ibl.scope.underline.1" } },
            { " ", { "@ibl.whitespace.char.1", "@ibl.scope.underline.1" } },
        }, "@ibl.scope.underline.1")

        local marks = get_virt_lines_extmarks(bufnr, diag_ns)
        local vline = marks[1][4].virt_lines[1]
        assert.are.same({ "@ibl.whitespace.char.1", "@ibl.indent.char.1" }, vline[1][2])
        assert.are.equal("@ibl.whitespace.char.1", vline[2][2])
    end)

    it("restores virtual_lines on clear_buffer and updates automatically on DiagnosticChanged", function()
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
            "    local x = 1",
        })
        vim.diagnostic.set(diag_ns, bufnr, {
            { lnum = 0, col = 4, severity = vim.diagnostic.severity.ERROR, message = "auto" },
        })

        vim.wait(200, function()
            local marks = get_virt_lines_extmarks(bufnr, diag_ns)
            return #marks == 1 and has_ibl_hl(marks[1][4].virt_lines[1][1][2])
        end)

        local marks = get_virt_lines_extmarks(bufnr, diag_ns)
        assert.are.equal(1, #marks)
        assert.is_true(has_ibl_hl(marks[1][4].virt_lines[1][1][2]))

        virtual_lines.clear_buffer(bufnr)

        marks = get_virt_lines_extmarks(bufnr, diag_ns)
        assert.are.equal(1, #marks)
        assert.are.equal("    ", marks[1][4].virt_lines[1][1][1])
        assert.are.equal("", marks[1][4].virt_lines[1][1][2])
        assert.are.equal("└──── ", marks[1][4].virt_lines[1][2][1])
    end)

    it("forgets a buffer without touching its extmarks on clear_buffer_state", function()
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
            "    local x = 1",
        })
        vim.diagnostic.set(diag_ns, bufnr, {
            { lnum = 0, col = 4, severity = vim.diagnostic.severity.ERROR, message = "keep" },
        })
        ibl.refresh(bufnr)

        virtual_lines.clear_buffer_state(bufnr)
        virtual_lines.clear_buffer(bufnr)

        local marks = get_virt_lines_extmarks(bufnr, diag_ns)
        assert.are.equal(1, #marks)
        assert.is_true(has_ibl_hl(marks[1][4].virt_lines[1][1][2]))
    end)

    it("keeps indent guides aligned from col 0 when horizontally scrolled", function()
        local orig_wrap = vim.wo.wrap
        local orig_columns = vim.o.columns
        vim.wo.wrap = false
        vim.o.columns = 20
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
            "        local long_variable_name = 1234567890",
        })
        vim.diagnostic.set(diag_ns, bufnr, {
            { lnum = 0, col = 8, severity = vim.diagnostic.severity.ERROR, message = "scrolled" },
        })
        vim.api.nvim_win_set_cursor(0, { 1, 25 })
        vim.fn.winrestview { leftcol = 3 }

        ibl.refresh(bufnr)

        local marks = get_virt_lines_extmarks(bufnr, diag_ns)
        assert.are.equal(1, #marks)
        local vline = marks[1][4].virt_lines[1]
        assert.are.equal("▎", vline[1][1])
        assert.is_true(has_ibl_hl(vline[1][2]))
        assert.are.equal("▎", vline[5][1])
        assert.is_true(has_ibl_hl(vline[5][2]))
        assert.are.equal("└──── ", vline[9][1])

        vim.wo.wrap = orig_wrap
        vim.o.columns = orig_columns
    end)

    it("updates virtual_lines when moving cursor with current_line = true", function()
        vim.diagnostic.config { virtual_lines = { current_line = true } }
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {
            "    local a = 1",
            "        local b = 2",
        })
        vim.api.nvim_win_set_cursor(0, { 1, 0 })
        vim.diagnostic.set(diag_ns, bufnr, {
            { lnum = 1, col = 8, severity = vim.diagnostic.severity.ERROR, message = "line 2 err" },
        })

        vim.api.nvim_win_set_cursor(0, { 2, 0 })
        vim.api.nvim_exec_autocmds("CursorMoved", { buffer = bufnr })

        local ok = vim.wait(200, function()
            local marks = get_virt_lines_extmarks(bufnr, diag_ns)
            return #marks == 1 and has_ibl_hl(marks[1][4].virt_lines[1][1][2])
        end)
        assert.is_true(ok)

        local marks = get_virt_lines_extmarks(bufnr, diag_ns)
        local vline = marks[1][4].virt_lines[1]
        assert.are.equal("▎", vline[1][1])
        assert.are.equal("▎", vline[5][1])
        assert.are.equal("└──── ", vline[9][1])
    end)
end)
