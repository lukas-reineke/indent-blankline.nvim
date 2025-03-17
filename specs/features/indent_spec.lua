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
        local whitespace_tbl, _ = indent.get("", opts, false)

        assert.are.same({}, whitespace_tbl)
    end)

    it("normal space indentation", function()
        local whitespace_tbl, _ = indent.get("  ", opts, false, { cap = false, stack = { 0 } })

        assert.are.same({ INDENT, SPACE }, whitespace_tbl)
    end)

    it("normal tab", function()
        local whitespace_tbl, _ = indent.get("	", opts, false, { cap = false, stack = { 0 } })

        assert.are.same({ TAB_START, TAB_FILL, TAB_FILL, TAB_END }, whitespace_tbl)
    end)

    it("single width tab", function()
        opts.tabstop = 1
        local whitespace_tbl, _ = indent.get("	", opts, false, { cap = false, stack = { 0 } })

        assert.are.same({ TAB_START_SINGLE }, whitespace_tbl)
    end)

    it("double width tab", function()
        opts.tabstop = 2
        local whitespace_tbl, _ = indent.get("	", opts, false, { cap = false, stack = { 0 } })

        assert.are.same({ TAB_START, TAB_END }, whitespace_tbl)
    end)

    it("vartabstop", function()
        opts.vartabstop = "1,3"
        local whitespace_tbl, _ = indent.get("			", opts, false, { cap = false, stack = { 0 } })

        assert.are.same(
            { TAB_START_SINGLE, TAB_START, TAB_FILL, TAB_END, TAB_START, TAB_FILL, TAB_END },
            whitespace_tbl
        )
    end)

    it("vartabstop with mixed indentation", function()
        opts.vartabstop = "2,8"
        local whitespace_tbl, _ = indent.get("  	", opts, false, { cap = false, stack = { 0 } })

        assert.are.same(
            { INDENT, SPACE, TAB_START, TAB_FILL, TAB_FILL, TAB_FILL, TAB_FILL, TAB_FILL, TAB_FILL, TAB_END },
            whitespace_tbl
        )
    end)

    it("vartabstop with mixed indentation and stack", function()
        opts.vartabstop = "2,8"
        local whitespace_tbl, _ = indent.get("  	", opts, false, { cap = false, stack = { 1 } })

        assert.are.same(
            { INDENT, INDENT, TAB_START, TAB_FILL, TAB_FILL, TAB_FILL, TAB_FILL, TAB_FILL, TAB_FILL, TAB_END },
            whitespace_tbl
        )
    end)

    it("mix of tabs and spaces", function()
        local whitespace_tbl, _ = indent.get("  	 	", opts, false, { cap = false, stack = { 0 } })

        assert.are.same({ INDENT, SPACE, TAB_START, TAB_END, SPACE, TAB_START, TAB_FILL, TAB_END }, whitespace_tbl)
    end)

    it("mix of tabs and spaces with vartabstop", function()
        opts.vartabstop = "1,3"
        local whitespace_tbl, _ = indent.get("	 	 ", opts, false, { cap = false, stack = { 0 } })

        assert.are.same({ TAB_START_SINGLE, SPACE, TAB_START, TAB_END, SPACE }, whitespace_tbl)
    end)

    it("caps after first indent after last item in stack", function()
        local whitespace_tbl, _ = indent.get("        ", opts, false, { cap = false, stack = { 0, 4 } })

        assert.are.same({ INDENT, SPACE, INDENT, SPACE, INDENT, SPACE, SPACE, SPACE }, whitespace_tbl)
    end)

    it("caps after first indent of first item in stack when cap is true", function()
        local whitespace_tbl, _ = indent.get("        ", opts, false, { cap = true, stack = { 0, 4 } })

        assert.are.same({ INDENT, SPACE, SPACE, SPACE, INDENT, SPACE, SPACE, SPACE }, whitespace_tbl)
    end)

    it("doesn't cap with smart_indent_cap off", function()
        opts.smart_indent_cap = false
        local whitespace_tbl, _ = indent.get("        ", opts, false, { cap = false, stack = { 0, 4 } })

        assert.are.same({ INDENT, SPACE, INDENT, SPACE, INDENT, SPACE, INDENT, SPACE }, whitespace_tbl)
    end)
end)
