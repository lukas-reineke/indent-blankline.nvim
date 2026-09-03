assert = require "luassert"
local ibl = require "ibl"
local conf = require "ibl.config"

local uv = vim.uv or vim.loop

---@return number
local count_timers = function()
    local count = 0
    uv.walk(function(handle)
        if handle:get_type() == "timer" and not handle:is_closing() then
            count = count + 1
        end
    end)
    return count
end

describe("clear_buffer_state", function()
    local bufnr

    before_each(function()
        ibl.setup { debounce = 10 }
        bufnr = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "    foo" })
    end)

    after_each(function()
        if vim.api.nvim_buf_is_valid(bufnr) then
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end
    end)

    it("releases the buffer config", function()
        conf.set_buffer_config(bufnr, { enabled = false })

        ibl.clear_buffer_state(bufnr)

        assert.are.equal(conf.get_config(bufnr).enabled, conf.default_config.enabled)
    end)

    it("closes a pending debounce timer", function()
        local timers = count_timers()
        ibl.debounced_refresh(bufnr)
        assert.are.equal(timers + 1, count_timers())

        ibl.clear_buffer_state(bufnr)

        assert.are.equal(timers, count_timers())
    end)

    it("is called when a buffer is wiped out", function()
        conf.set_buffer_config(bufnr, { enabled = false })
        local timers = count_timers()
        ibl.debounced_refresh(bufnr)
        assert.are.equal(timers + 1, count_timers())

        vim.api.nvim_buf_delete(bufnr, { force = true })

        assert.are.equal(timers, count_timers())
        assert.are.equal(conf.get_config(bufnr).enabled, conf.default_config.enabled)
    end)
end)

describe("debounced_refresh", function()
    local bufnr

    before_each(function()
        ibl.setup { debounce = 10 }
        bufnr = vim.api.nvim_create_buf(false, true)
        vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "    foo" })
    end)

    after_each(function()
        if vim.api.nvim_buf_is_valid(bufnr) then
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end
    end)

    it("closes the debounce timer once it fired", function()
        local timers = count_timers()

        ibl.debounced_refresh(bufnr)
        assert.are.equal(timers + 1, count_timers())

        vim.wait(1000, function()
            return count_timers() == timers
        end)

        assert.are.equal(timers, count_timers())
    end)

    it("debounces refreshes of the same buffer", function()
        local timers = count_timers()

        for _ = 1, 10 do
            ibl.debounced_refresh(bufnr)
        end

        assert.are.equal(timers + 1, count_timers())
    end)
end)
