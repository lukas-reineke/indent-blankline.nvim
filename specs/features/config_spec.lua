assert = require "luassert"
local conf = require "ibl.config"

describe("set_config", function()
    before_each(function()
        conf.set_config()
    end)

    it("fills in values with the default config", function()
        local config = conf.set_config()

        assert.are.same(config, conf.default_config)
    end)

    it("uses the passed config", function()
        local config = conf.set_config { enabled = false }

        assert.are_not.equal(config.enabled, conf.default_config.enabled)
    end)

    it("validates the passed config", function()
        ---@diagnostic disable-next-line
        local ok = pcall(conf.set_config, { enabled = "string" })

        assert.are.equal(ok, false)
    end)

    it("does not allow extra keys", function()
        ---@diagnostic disable-next-line
        local ok = pcall(conf.set_config, { this_does_not_exist = "string" })

        assert.are.equal(ok, false)
    end)

    it("resets the config every time", function()
        conf.set_config { enabled = false }
        local config = conf.set_config { debounce = 100 }

        assert.are.equal(config.enabled, true)
        assert.are.equal(config.debounce, 100)
    end)

    it("merges passed in lists", function()
        local config = conf.set_config { exclude = { buftypes = { "foo" } } }

        assert.are.equal(vim.tbl_contains(config.exclude.buftypes, "foo"), true)
        assert.are.equal(vim.tbl_contains(config.exclude.buftypes, "terminal"), true)
    end)

    it("merges node_type", function()
        local config = conf.set_config {
            scope = {
                exclude = {
                    node_type = {
                        foo = { "a", "b" },
                        lua = { "c" },
                    },
                },
            },
        }

        assert.are.equal(vim.tbl_contains(config.scope.exclude.node_type.foo, "a"), true)
        assert.are.equal(vim.tbl_contains(config.scope.exclude.node_type.foo, "b"), true)
        assert.are.equal(vim.tbl_contains(config.scope.exclude.node_type.lua, "c"), true)
        assert.are.equal(vim.tbl_contains(config.scope.exclude.node_type.lua, "chunk"), true)
    end)
end)

describe("update_config", function()
    before_each(function()
        conf.set_config()
    end)

    it("updates the existing config", function()
        conf.set_config { enabled = false }
        local config = conf.update_config { debounce = 100 }

        assert.are.equal(config.enabled, false)
        assert.are.equal(config.debounce, 100)
    end)
end)

describe("overwrite_config", function()
    before_each(function()
        conf.set_config()
    end)

    it("overwrites passed in lists", function()
        local config = conf.overwrite_config { exclude = { buftypes = { "foo" } } }

        assert.are.equal(vim.tbl_contains(config.exclude.buftypes, "foo"), true)
        assert.are.equal(vim.tbl_contains(config.exclude.buftypes, "terminal"), false)
    end)
end)

describe("set_buffer_config", function()
    local bufnr = 99
    before_each(function()
        conf.set_config()
        conf.clear_buffer_config(bufnr)
    end)

    it("uses the passed config", function()
        local config = conf.set_buffer_config(bufnr, { enabled = false })

        assert.are_not.equal(config.enabled, conf.default_config.enabled)
    end)

    it("uses uses the current global config as the default", function()
        conf.set_config { debounce = 100 }
        local config = conf.set_buffer_config(bufnr, { enabled = false })

        assert.are.equal(config.debounce, 100)
        assert.are.equal(config.enabled, false)
    end)

    it("validates the passed config", function()
        ---@diagnostic disable-next-line
        local ok = pcall(conf.set_buffer_config, bufnr, { enabled = "string" })

        assert.are.equal(ok, false)
    end)

    it("resets the config every time", function()
        conf.set_buffer_config(bufnr, { enabled = false })
        local config = conf.set_buffer_config(bufnr, { debounce = 100 })

        assert.are.equal(config.enabled, true)
        assert.are.equal(config.debounce, 100)
    end)
end)

describe("get_config", function()
    local bufnr = 99

    before_each(function()
        conf.set_config()
        conf.clear_buffer_config(bufnr)
    end)

    it("gets the global config by default", function()
        local config = conf.get_config(bufnr)

        assert.are.same(config, conf.default_config)
    end)

    it("gets the buffer config if available", function()
        conf.set_buffer_config(bufnr, { enabled = false })
        local config = conf.get_config(bufnr)

        assert.are.equal(config.enabled, false)
    end)

    it(
        "falls back to the global config if a value is not in the buffer config, even if it changed after the buffer config was set",
        function()
            conf.set_buffer_config(bufnr, { enabled = false })
            conf.set_config { debounce = 100 }
            local config = conf.get_config(bufnr)

            assert.are.equal(config.enabled, false)
            assert.are.equal(config.debounce, 100)
        end
    )
end)
