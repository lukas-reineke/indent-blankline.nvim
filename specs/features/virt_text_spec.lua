assert = require "luassert"
local conf = require "ibl.config"
local indent = require "ibl.indent"
local whitespace = indent.whitespace
local highlights = require "ibl.highlights"
local vt = require "ibl.virt_text"

local TAB_START = whitespace.TAB_START
local TAB_START_SINGLE = whitespace.TAB_START_SINGLE
local TAB_FILL = whitespace.TAB_FILL
local TAB_END = whitespace.TAB_END
local SPACE = whitespace.SPACE
local INDENT = whitespace.INDENT

describe("get_char_map", function()
    before_each(function()
        conf.set_config()
    end)

    it("makes a basic char map", function()
        local config = conf.set_config { indent = { char = "i" } }
        local listchars = {
            tabstop_overwrite = false,
            space_char = " ",
            trail_char = nil,
            lead_char = nil,
            multispace_chars = nil,
            leadmultispace_chars = nil,
            tab_char_start = ">",
            tab_char_fill = " ",
            tab_char_end = nil,
        }
        local whitespace_only = false
        local blankline = false
        local char_map = vt.get_char_map(config, listchars, whitespace_only, blankline)

        assert.are.same(char_map, {
            [TAB_START] = ">",
            [TAB_START_SINGLE] = ">",
            [TAB_FILL] = " ",
            [TAB_END] = " ",
            [SPACE] = " ",
            [INDENT] = "i",
        })
    end)

    it("uses tab_char for tabs", function()
        local config = conf.set_config { indent = { char = "i", tab_char = "t" } }
        local listchars = {
            tabstop_overwrite = false,
            space_char = " ",
            trail_char = nil,
            lead_char = nil,
            multispace_chars = nil,
            leadmultispace_chars = nil,
            tab_char_start = nil,
            tab_char_fill = " ",
            tab_char_end = nil,
        }
        local whitespace_only = false
        local blankline = false
        local char_map = vt.get_char_map(config, listchars, whitespace_only, blankline)

        assert.are.same(char_map, {
            [TAB_START] = "t",
            [TAB_START_SINGLE] = "t",
            [TAB_FILL] = " ",
            [TAB_END] = " ",
            [SPACE] = " ",
            [INDENT] = "i",
        })
    end)

    it("uses char for tabs if everything else is nil", function()
        local config = conf.set_config { indent = { char = "i" } }
        local listchars = {
            tabstop_overwrite = false,
            space_char = " ",
            trail_char = nil,
            lead_char = nil,
            multispace_chars = nil,
            leadmultispace_chars = nil,
            tab_char_start = nil,
            tab_char_fill = " ",
            tab_char_end = nil,
        }
        local whitespace_only = false
        local blankline = false
        local char_map = vt.get_char_map(config, listchars, whitespace_only, blankline)

        assert.are.same(char_map, {
            [TAB_START] = "i",
            [TAB_START_SINGLE] = "i",
            [TAB_FILL] = " ",
            [TAB_END] = " ",
            [SPACE] = " ",
            [INDENT] = "i",
        })
    end)

    it("parses basic listchars", function()
        local config = conf.set_config { indent = { char = "i" } }
        local listchars = {
            tabstop_overwrite = false,
            space_char = " ",
            trail_char = "w",
            lead_char = "a",
            multispace_chars = nil,
            leadmultispace_chars = nil,
            tab_char_start = "b",
            tab_char_fill = "c",
            tab_char_end = "d",
        }
        local whitespace_only = false
        local blankline = false
        local char_map = vt.get_char_map(config, listchars, whitespace_only, blankline)

        assert.are.same(char_map, {
            [TAB_START] = "b",
            [TAB_START_SINGLE] = "d",
            [TAB_FILL] = "c",
            [TAB_END] = "d",
            [SPACE] = "a",
            [INDENT] = "i",
        })
    end)

    it("parses uses multispace listchars", function()
        local config = conf.set_config { indent = { char = "i" } }
        local listchars = {
            tabstop_overwrite = false,
            space_char = " ",
            trail_char = "w",
            lead_char = nil,
            multispace_chars = { "x", "y" },
            leadmultispace_chars = nil,
            tab_char_start = "b",
            tab_char_fill = "c",
            tab_char_end = "d",
        }
        local whitespace_only = false
        local blankline = false
        local char_map = vt.get_char_map(config, listchars, whitespace_only, blankline)

        assert.are.same(char_map, {
            [TAB_START] = "b",
            [TAB_START_SINGLE] = "d",
            [TAB_FILL] = "c",
            [TAB_END] = "d",
            [SPACE] = { "x", "y" },
            [INDENT] = "i",
        })
    end)

    it("uses lead over multispace listchars", function()
        local config = conf.set_config { indent = { char = "i" } }
        local listchars = {
            tabstop_overwrite = false,
            space_char = " ",
            trail_char = "w",
            lead_char = "a",
            multispace_chars = { "x", "y" },
            leadmultispace_chars = nil,
            tab_char_start = "b",
            tab_char_fill = "c",
            tab_char_end = "d",
        }
        local whitespace_only = false
        local blankline = false
        local char_map = vt.get_char_map(config, listchars, whitespace_only, blankline)

        assert.are.same(char_map, {
            [TAB_START] = "b",
            [TAB_START_SINGLE] = "d",
            [TAB_FILL] = "c",
            [TAB_END] = "d",
            [SPACE] = "a",
            [INDENT] = "i",
        })
    end)

    it("uses leadmultispace over lead listchars", function()
        local config = conf.set_config { indent = { char = "i" } }
        local listchars = {
            tabstop_overwrite = false,
            space_char = " ",
            trail_char = "w",
            lead_char = "a",
            multispace_chars = { "x", "y" },
            leadmultispace_chars = { "o", "i" },
            tab_char_start = "b",
            tab_char_fill = "c",
            tab_char_end = "d",
        }
        local whitespace_only = false
        local blankline = false
        local char_map = vt.get_char_map(config, listchars, whitespace_only, blankline)

        assert.are.same(char_map, {
            [TAB_START] = "b",
            [TAB_START_SINGLE] = "d",
            [TAB_FILL] = "c",
            [TAB_END] = "d",
            [SPACE] = { "o", "i" },
            [INDENT] = "i",
        })
    end)

    it("uses trail listchars on whitspace only lines", function()
        local config = conf.set_config { indent = { char = "i" } }
        local listchars = {
            tabstop_overwrite = false,
            space_char = " ",
            trail_char = "w",
            lead_char = "a",
            multispace_chars = { "x", "y" },
            leadmultispace_chars = { "o", "i" },
            tab_char_start = "b",
            tab_char_fill = "c",
            tab_char_end = "d",
        }
        local whitespace_only = true
        local blankline = false
        local char_map = vt.get_char_map(config, listchars, whitespace_only, blankline)

        assert.are.same(char_map, {
            [TAB_START] = "b",
            [TAB_START_SINGLE] = "d",
            [TAB_FILL] = "c",
            [TAB_END] = "d",
            [SPACE] = "w",
            [INDENT] = "i",
        })
    end)

    it("uses spaces on blanklines", function()
        local config = conf.set_config { indent = { char = "i" } }
        local listchars = {
            tabstop_overwrite = false,
            space_char = "s",
            trail_char = "w",
            lead_char = "a",
            multispace_chars = { "x", "y" },
            leadmultispace_chars = { "o", "i" },
            tab_char_start = "b",
            tab_char_fill = "c",
            tab_char_end = "d",
        }
        local whitespace_only = false
        local blankline = true
        local char_map = vt.get_char_map(config, listchars, whitespace_only, blankline)

        assert.are.same(char_map, {
            [TAB_START] = "b",
            [TAB_START_SINGLE] = "d",
            [TAB_FILL] = " ",
            [TAB_END] = " ",
            [SPACE] = " ",
            [INDENT] = "i",
        })
    end)
end)

describe("virt_text", function()
    before_each(function()
        conf.set_config()
    end)

    it("handles empty whitespace table", function()
        local config = conf.set_config()
        highlights.setup()
        local char_map = {
            [TAB_START] = "a",
            [TAB_START_SINGLE] = "b",
            [TAB_FILL] = "c",
            [TAB_END] = "d",
            [SPACE] = "e",
            [INDENT] = "f",
        }
        local whitespace_tbl = {}
        local scope_active = false
        local scope_index = -1
        local scope_start = false
        local scope_end = false
        local scope_col_start_single = 0

        local virt_text = vt.get(
            config,
            char_map,
            whitespace_tbl,
            scope_active,
            scope_index,
            scope_start,
            scope_end,
            scope_col_start_single
        )

        assert.are.same(virt_text, {})
    end)

    it("handles simple indentation", function()
        local config = conf.set_config()
        highlights.setup()
        local char_map = {
            [TAB_START] = "a",
            [TAB_START_SINGLE] = "b",
            [TAB_FILL] = "c",
            [TAB_END] = "d",
            [SPACE] = "e",
            [INDENT] = "f",
        }
        local whitespace_tbl = { INDENT, SPACE, INDENT, SPACE }
        local scope_active = false
        local scope_index = -1
        local scope_start = false
        local scope_end = false
        local scope_col_start_single = 0

        local virt_text = vt.get(
            config,
            char_map,
            whitespace_tbl,
            scope_active,
            scope_index,
            scope_start,
            scope_end,
            scope_col_start_single
        )

        assert.are.same(virt_text, {
            { "f", { "@ibl.whitespace.char.1", "@ibl.indent.char.1" } },
            { "e", { "@ibl.whitespace.char.1" } },
            { "f", { "@ibl.whitespace.char.1", "@ibl.indent.char.1" } },
            { "e", { "@ibl.whitespace.char.1" } },
        })
    end)

    it("handles a list of indent chars", function()
        local config = conf.set_config()
        highlights.setup()
        local char_map = {
            [TAB_START] = "o",
            [TAB_START_SINGLE] = "b",
            [TAB_FILL] = "c",
            [TAB_END] = "d",
            [SPACE] = "e",
            [INDENT] = { "a", "b", "c" },
        }
        local whitespace_tbl = { INDENT, SPACE, INDENT, SPACE, INDENT, SPACE }
        local scope_active = false
        local scope_index = -1
        local scope_start = false
        local scope_end = false
        local scope_col_start_single = 0

        local virt_text = vt.get(
            config,
            char_map,
            whitespace_tbl,
            scope_active,
            scope_index,
            scope_start,
            scope_end,
            scope_col_start_single
        )

        assert.are.same(virt_text, {
            { "a", { "@ibl.whitespace.char.1", "@ibl.indent.char.1" } },
            { "e", { "@ibl.whitespace.char.1" } },
            { "b", { "@ibl.whitespace.char.1", "@ibl.indent.char.1" } },
            { "e", { "@ibl.whitespace.char.1" } },
            { "c", { "@ibl.whitespace.char.1", "@ibl.indent.char.1" } },
            { "e", { "@ibl.whitespace.char.1" } },
        })
    end)

    it("handles a list of tab chars", function()
        local config = conf.set_config()
        highlights.setup()
        local char_map = {
            [TAB_START] = { "a", "b", "c" },
            [TAB_START_SINGLE] = "o",
            [TAB_FILL] = "c",
            [TAB_END] = "d",
            [SPACE] = "e",
            [INDENT] = "f",
        }
        local whitespace_tbl = { TAB_START, TAB_END, TAB_START, TAB_END, TAB_START, TAB_END }
        local scope_active = false
        local scope_index = -1
        local scope_start = false
        local scope_end = false
        local scope_col_start_single = 0

        local virt_text = vt.get(
            config,
            char_map,
            whitespace_tbl,
            scope_active,
            scope_index,
            scope_start,
            scope_end,
            scope_col_start_single
        )

        assert.are.same(virt_text, {
            { "a", { "@ibl.whitespace.char.1", "@ibl.indent.char.1" } },
            { "d", { "@ibl.whitespace.char.1" } },
            { "b", { "@ibl.whitespace.char.1", "@ibl.indent.char.1" } },
            { "d", { "@ibl.whitespace.char.1" } },
            { "c", { "@ibl.whitespace.char.1", "@ibl.indent.char.1" } },
            { "d", { "@ibl.whitespace.char.1" } },
        })
    end)

    it("handles indent with no display width", function()
        local config = conf.set_config()
        highlights.setup()
        local char_map = {
            [TAB_START] = "a",
            [TAB_START_SINGLE] = "b",
            [TAB_FILL] = "c",
            [TAB_END] = "d",
            [SPACE] = "e",
            [INDENT] = "",
        }
        local whitespace_tbl = { INDENT, SPACE, INDENT, SPACE }
        local scope_active = false
        local scope_index = -1
        local scope_start = false
        local scope_end = false
        local scope_col_start_single = 0

        local virt_text = vt.get(
            config,
            char_map,
            whitespace_tbl,
            scope_active,
            scope_index,
            scope_start,
            scope_end,
            scope_col_start_single
        )

        assert.are.same(virt_text, {
            { "e", { "@ibl.whitespace.char.1" } },
            { "e", { "@ibl.whitespace.char.1" } },
            { "e", { "@ibl.whitespace.char.1" } },
            { "e", { "@ibl.whitespace.char.1" } },
        })
    end)

    it("handles scope", function()
        local config = conf.set_config()
        highlights.setup()
        local char_map = {
            [TAB_START] = "a",
            [TAB_START_SINGLE] = "b",
            [TAB_FILL] = "c",
            [TAB_END] = "d",
            [SPACE] = "e",
            [INDENT] = "f",
        }
        local whitespace_tbl = { INDENT, SPACE, INDENT, SPACE }
        local scope_active = true
        local scope_index = 1
        local scope_start = false
        local scope_end = false
        local scope_col_start_single = 2

        local virt_text = vt.get(
            config,
            char_map,
            whitespace_tbl,
            scope_active,
            scope_index,
            scope_start,
            scope_end,
            scope_col_start_single
        )

        assert.are.same(virt_text, {
            { "f", { "@ibl.whitespace.char.1", "@ibl.indent.char.1" } },
            { "e", { "@ibl.whitespace.char.1" } },
            { "f", { "@ibl.whitespace.char.1", "@ibl.scope.char.1" } },
            { "e", { "@ibl.whitespace.char.1" } },
        })
    end)

    it("handles tabs", function()
        local config = conf.set_config()
        highlights.setup()
        local char_map = {
            [TAB_START] = "a",
            [TAB_START_SINGLE] = "b",
            [TAB_FILL] = "c",
            [TAB_END] = "d",
            [SPACE] = "e",
            [INDENT] = "f",
        }
        local whitespace_tbl = { TAB_START, TAB_FILL, TAB_FILL, TAB_END, TAB_START_SINGLE }
        local scope_active = false
        local scope_index = -1
        local scope_start = false
        local scope_end = false
        local scope_col_start_single = 0

        local virt_text = vt.get(
            config,
            char_map,
            whitespace_tbl,
            scope_active,
            scope_index,
            scope_start,
            scope_end,
            scope_col_start_single
        )

        assert.are.same(virt_text, {
            { "a", { "@ibl.whitespace.char.1", "@ibl.indent.char.1" } },
            { "c", { "@ibl.whitespace.char.1" } },
            { "c", { "@ibl.whitespace.char.1" } },
            { "d", { "@ibl.whitespace.char.1" } },
            { "b", { "@ibl.whitespace.char.1", "@ibl.indent.char.1" } },
        })
    end)

    it("handles multiple highlight groups", function()
        local config = conf.set_config {
            whitespace = { highlight = { "Error", "Function", "Label" } },
            indent = { highlight = { "Error", "Function", "Label" } },
        }
        highlights.setup()
        local char_map = {
            [TAB_START] = "a",
            [TAB_START_SINGLE] = "b",
            [TAB_FILL] = "c",
            [TAB_END] = "d",
            [SPACE] = "e",
            [INDENT] = "f",
        }
        local whitespace_tbl = { INDENT, SPACE, INDENT, SPACE, INDENT, SPACE }
        local scope_active = false
        local scope_index = -1
        local scope_start = false
        local scope_end = false
        local scope_col_start_single = 0

        local virt_text = vt.get(
            config,
            char_map,
            whitespace_tbl,
            scope_active,
            scope_index,
            scope_start,
            scope_end,
            scope_col_start_single
        )

        assert.are.same(virt_text, {
            { "f", { "@ibl.whitespace.char.1", "@ibl.indent.char.1" } },
            { "e", { "@ibl.whitespace.char.1" } },
            { "f", { "@ibl.whitespace.char.2", "@ibl.indent.char.2" } },
            { "e", { "@ibl.whitespace.char.2" } },
            { "f", { "@ibl.whitespace.char.3", "@ibl.indent.char.3" } },
            { "e", { "@ibl.whitespace.char.3" } },
        })
    end)

    it("handles multiple highlight groups with scope", function()
        local config = conf.set_config {
            whitespace = { highlight = { "Error", "Function", "Label" } },
            indent = { highlight = { "Error", "Function", "Label" } },
            scope = { highlight = { "Error", "Function", "Label" } },
        }
        highlights.setup()
        local char_map = {
            [TAB_START] = "a",
            [TAB_START_SINGLE] = "b",
            [TAB_FILL] = "c",
            [TAB_END] = "d",
            [SPACE] = "e",
            [INDENT] = "f",
        }
        local whitespace_tbl = { INDENT, SPACE, INDENT, SPACE, INDENT, SPACE }
        local scope_active = true
        local scope_index = 2
        local scope_start = false
        local scope_end = false
        local scope_col_start_single = 2

        local virt_text = vt.get(
            config,
            char_map,
            whitespace_tbl,
            scope_active,
            scope_index,
            scope_start,
            scope_end,
            scope_col_start_single
        )

        assert.are.same(virt_text, {
            { "f", { "@ibl.whitespace.char.1", "@ibl.indent.char.1" } },
            { "e", { "@ibl.whitespace.char.1" } },
            { "f", { "@ibl.whitespace.char.2", "@ibl.scope.char.2" } },
            { "e", { "@ibl.whitespace.char.2" } },
            { "f", { "@ibl.whitespace.char.3", "@ibl.indent.char.3" } },
            { "e", { "@ibl.whitespace.char.3" } },
        })
    end)

    it("handles multiple highlight groups with scope on scope end", function()
        local config = conf.set_config {
            whitespace = { highlight = { "Error", "Function", "Label" } },
            indent = { highlight = { "Error", "Function", "Label" } },
            scope = { highlight = { "Error", "Function", "Label" } },
        }
        highlights.setup()
        local char_map = {
            [TAB_START] = "a",
            [TAB_START_SINGLE] = "b",
            [TAB_FILL] = "c",
            [TAB_END] = "d",
            [SPACE] = "e",
            [INDENT] = "f",
        }
        local whitespace_tbl = { INDENT, SPACE, INDENT, SPACE, INDENT, SPACE }
        local scope_active = true
        local scope_index = 2
        local scope_start = false
        local scope_end = true
        local scope_col_start_single = 2

        local virt_text = vt.get(
            config,
            char_map,
            whitespace_tbl,
            scope_active,
            scope_index,
            scope_start,
            scope_end,
            scope_col_start_single
        )

        assert.are.same(virt_text, {
            { "f", { "@ibl.whitespace.char.1", "@ibl.indent.char.1" } },
            { "e", { "@ibl.whitespace.char.1" } },
            { "f", { "@ibl.whitespace.char.2", "@ibl.scope.char.2", "@ibl.scope.underline.2" } },
            { "e", { "@ibl.whitespace.char.2", "@ibl.scope.underline.2" } },
            { "f", { "@ibl.whitespace.char.3", "@ibl.indent.char.3", "@ibl.scope.underline.2" } },
            { "e", { "@ibl.whitespace.char.3", "@ibl.scope.underline.2" } },
        })
    end)

    it("handles multiple highlight groups with scope on scope start", function()
        local config = conf.set_config {
            whitespace = { highlight = { "Error", "Function", "Label" } },
            indent = { highlight = { "Error", "Function", "Label" } },
            scope = { highlight = { "Error", "Function", "Label" } },
        }
        highlights.setup()
        local char_map = {
            [TAB_START] = "a",
            [TAB_START_SINGLE] = "b",
            [TAB_FILL] = "c",
            [TAB_END] = "d",
            [SPACE] = "e",
            [INDENT] = "f",
        }
        local whitespace_tbl = { INDENT, SPACE, INDENT, SPACE, INDENT, SPACE }
        local scope_active = true
        local scope_index = 2
        local scope_start = true
        local scope_end = false
        local scope_col_start_single = 2

        local virt_text = vt.get(
            config,
            char_map,
            whitespace_tbl,
            scope_active,
            scope_index,
            scope_start,
            scope_end,
            scope_col_start_single
        )

        assert.are.same(virt_text, {
            { "f", { "@ibl.whitespace.char.1", "@ibl.indent.char.1" } },
            { "e", { "@ibl.whitespace.char.1" } },
            { "f", { "@ibl.whitespace.char.2", "@ibl.indent.char.2", "@ibl.scope.underline.2" } },
            { "e", { "@ibl.whitespace.char.2", "@ibl.scope.underline.2" } },
            { "f", { "@ibl.whitespace.char.3", "@ibl.indent.char.3", "@ibl.scope.underline.2" } },
            { "e", { "@ibl.whitespace.char.3", "@ibl.scope.underline.2" } },
        })
    end)
end)
