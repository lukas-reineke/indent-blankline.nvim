assert = require "luassert"
local utils = require "ibl.utils"

describe("get_listchars", function()
    local listchars = vim.opt.listchars:get()

    after_each(function()
        vim.opt.listchars = listchars
        vim.opt.list = false
    end)

    it("returns fallback listchars if list is off", function()
        assert.are.same(utils.get_listchars(0), {
            tabstop_overwrite = false,
            space_char = " ",
            tab_char_fill = " ",
        })
    end)

    it("returns default listchars", function()
        vim.opt.list = true
        assert.are.same(utils.get_listchars(0), {
            tabstop_overwrite = false,
            space_char = " ",
            tab_char_start = ">",
            tab_char_fill = " ",
            trail_char = "-",
        })
    end)

    it("sets tabstop_overwrite to true when there is are tab chars", function()
        vim.opt.list = true
        vim.opt.listchars = {}
        assert.are.same(utils.get_listchars(0), {
            tabstop_overwrite = true,
            space_char = " ",
            tab_char_start = "^",
            tab_char_fill = "I",
        })
    end)

    it("splits utf-8 chars correctly", function()
        vim.opt.list = true
        vim.opt.listchars = { tab = "󱢗󰗲" }
        assert.are.same(utils.get_listchars(0), {
            tabstop_overwrite = false,
            space_char = " ",
            tab_char_start = "󱢗",
            tab_char_fill = "󰗲",
        })
    end)

    it("supports hex values", function()
        vim.opt.list = true
        vim.opt.listchars = { tab = "\\x24\\u21b5\\U000021b5", space = "\\u00B7" }
        assert.are.same(utils.get_listchars(0), {
            tabstop_overwrite = false,
            space_char = "·",
            tab_char_start = "$",
            tab_char_fill = "↵",
            tab_char_end = "↵",
        })
    end)
end)
