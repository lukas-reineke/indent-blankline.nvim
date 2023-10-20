assert = require "luassert"
local indent = require "ibl.indent"
local TAB_START = indent.whitespace.TAB_START
local TAB_START_SINGLE = indent.whitespace.TAB_START_SINGLE
local TAB_FILL = indent.whitespace.TAB_FILL
local TAB_END = indent.whitespace.TAB_END
local SPACE = indent.whitespace.SPACE
local INDENT = indent.whitespace.INDENT

describe("indent", function()
    local opts
    before_each(function()
        opts = {
            tabstop = 4,
            vartabstop = "",
            shiftwidth = 2,
            smart_indent_cap = true,
        }
    end)

    it("no whitespace", function()
        local whitespace_tbl, _ = indent.get("", opts, nil, 1)

        assert.are.same(whitespace_tbl, {})
    end)

    it("normal space indentation", function()
        local whitespace_tbl, _ = indent.get("  ", opts, { cap = false, stack = { { indent = 0, row = 1 } } }, 2)

        assert.are.same(whitespace_tbl, { INDENT, SPACE })
    end)

    it("normal tab", function()
        local whitespace_tbl, _ = indent.get("	", opts, { cap = false, stack = { { indent = 0, row = 1 } } }, 2)

        assert.are.same(whitespace_tbl, { TAB_START, TAB_FILL, TAB_FILL, TAB_END })
    end)

    it("single width tab", function()
        opts.tabstop = 1
        local whitespace_tbl, _ = indent.get("	", opts, { cap = false, stack = { { indent = 0, row = 1 } } }, 2)

        assert.are.same(whitespace_tbl, { TAB_START_SINGLE })
    end)

    it("double width tab", function()
        opts.tabstop = 2
        local whitespace_tbl, _ = indent.get("	", opts, { cap = false, stack = { { indent = 0, row = 1 } } }, 2)

        assert.are.same(whitespace_tbl, { TAB_START, TAB_END })
    end)

    it("vartabstop", function()
        opts.vartabstop = "1,3"
        local whitespace_tbl, _ = indent.get("			", opts, { cap = false, stack = { { indent = 0, row = 1 } } }, 2)

        assert.are.same(
            whitespace_tbl,
            { TAB_START_SINGLE, TAB_START, TAB_FILL, TAB_END, TAB_START, TAB_FILL, TAB_END }
        )
    end)

    it("mix of tabs and spaces", function()
        local whitespace_tbl, _ = indent.get("  	 	", opts, { cap = false, stack = { { indent = 0, row = 1 } } }, 2)

        assert.are.same(whitespace_tbl, { INDENT, SPACE, TAB_START, TAB_END, SPACE, TAB_START_SINGLE })
    end)

    it("mix of tabs and spaces with vartabstop", function()
        opts.vartabstop = "1,3"
        local whitespace_tbl, _ = indent.get("	 	 ", opts, { cap = false, stack = { { indent = 0, row = 1 } } }, 2)

        assert.are.same(whitespace_tbl, { TAB_START_SINGLE, SPACE, TAB_START, TAB_END, SPACE })
    end)

    it("caps after first indent after last item in stack", function()
        local whitespace_tbl, _ = indent.get(
            "        ",
            opts,
            { cap = false, stack = { { indent = 0, row = 1 }, { indent = 4, row = 2 } } },
            3
        )

        assert.are.same(whitespace_tbl, { INDENT, SPACE, INDENT, SPACE, INDENT, SPACE, SPACE, SPACE })
    end)

    it("caps after first indent of first item in stack when cap is true", function()
        local whitespace_tbl, _ = indent.get(
            "        ",
            opts,
            { cap = true, stack = { { indent = 0, row = 1 }, { indent = 4, row = 2 } } },
            2
        )

        assert.are.same(whitespace_tbl, { INDENT, SPACE, SPACE, SPACE, INDENT, SPACE, SPACE, SPACE })
    end)

    it("doesn't cap with smart_indent_cap off", function()
        opts.smart_indent_cap = false
        local whitespace_tbl, _ = indent.get(
            "        ",
            opts,
            { cap = false, stack = { { indent = 0, row = 1 }, { indent = 4, row = 2 } } },
            3
        )

        assert.are.same(whitespace_tbl, { INDENT, SPACE, INDENT, SPACE, INDENT, SPACE, INDENT, SPACE })
    end)
end)
