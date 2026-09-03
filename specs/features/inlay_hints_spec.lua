assert = require "luassert"
local inlay_hints = require "ibl.inlay_hints"

---@param fn function
---@return number
local count_rows = function(fn)
    local rows = 0
    local get_extmarks = vim.api.nvim_buf_get_extmarks
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.api.nvim_buf_get_extmarks = function(...)
        rows = rows + 1
        return get_extmarks(...)
    end

    local ok, err = pcall(fn)

    vim.api.nvim_buf_get_extmarks = get_extmarks
    assert(ok, err)

    return rows
end

describe("inlay_hints", function()
    local bufnr

    before_each(function()
        bufnr = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "    foo", "    bar", "    baz" })
    end)

    after_each(function()
        inlay_hints.clear_buffer(bufnr)
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end)

    it("remembers every row only once", function()
        for _ = 1, 50 do
            inlay_hints.set(bufnr, 0, 0, "Error", "Error")
        end

        assert.are.equal(
            1,
            count_rows(function()
                inlay_hints.clear_buffer(bufnr)
            end)
        )
    end)

    it("remembers all rows that are set", function()
        inlay_hints.set(bufnr, 0, 0, "Error", "Error")
        inlay_hints.set(bufnr, 1, 0, "Error", "Error")
        inlay_hints.set(bufnr, 2, 0, "Error", "Error")

        assert.are.equal(
            3,
            count_rows(function()
                inlay_hints.clear_buffer(bufnr)
            end)
        )
    end)

    it("forgets a buffer without touching its extmarks", function()
        inlay_hints.set(bufnr, 0, 0, "Error", "Error")

        inlay_hints.clear_buffer_state(bufnr)

        assert.are.equal(
            0,
            count_rows(function()
                inlay_hints.clear_buffer(bufnr)
            end)
        )
    end)
end)
