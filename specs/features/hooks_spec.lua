assert = require "luassert"
local hooks = require "ibl.hooks"

describe("hooks", function()
    before_each(function()
        hooks.clear_all()
    end)

    it("registers a new hook", function()
        local hook_id = hooks.register(hooks.type.ACTIVE, function()
            return true
        end)

        assert.is.equal(type(hook_id), "string")
    end)

    it("does not allow invalid types", function()
        local ok, _ = pcall(hooks.register, "invalid", function()
            return true
        end)
        assert.is.False(ok)
    end)

    it("does not allow nil types", function()
        local ok, _ = pcall(hooks.register, nil, function()
            return true
        end)
        assert.is.False(ok)
    end)

    it("does not allow invalid function", function()
        local ok, _ = pcall(hooks.register, hooks.type.ACTIVE, nil)
        assert.is.False(ok)
    end)

    it("registers hooks globally by default", function()
        hooks.register(hooks.type.ACTIVE, function()
            return true
        end)

        assert.equal(#hooks.get(9999, hooks.type.ACTIVE), 1)
    end)

    it("registers hooks to buffer when bufnr ~= nil", function()
        hooks.register(hooks.type.ACTIVE, function()
            return true
        end, { bufnr = 1 })

        assert.equal(#hooks.get(1, hooks.type.ACTIVE), 1)
        assert.equal(#hooks.get(9999, hooks.type.ACTIVE), 0)
    end)

    it("registers hooks to the current buffer when bufnr == 0", function()
        local bufnr = vim.api.nvim_get_current_buf()
        hooks.register(hooks.type.ACTIVE, function()
            return true
        end, { bufnr = 0 })

        assert.equal(#hooks.get(bufnr, hooks.type.ACTIVE), 1)
    end)
end)

describe("default hooks", function()
    describe("skip_preproc_lines", function()
        local skip_preproc_lines = hooks.builtin.skip_preproc_lines

        it("does not match 'foo'", function()
            assert.is.False(skip_preproc_lines(0, 0, 0, "foo"))
        end)

        it("does match '#if'", function()
            assert.is.True(skip_preproc_lines(0, 0, 0, "#if"))
        end)

        it("does match with trailing whitespace", function()
            assert.is.False(skip_preproc_lines(0, 0, 0, " #if"))
        end)

        it("does match '#if something'", function()
            assert.is.True(skip_preproc_lines(0, 0, 0, "#if something"))
        end)
    end)
end)
