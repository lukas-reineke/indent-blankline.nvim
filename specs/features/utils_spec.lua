assert = require "luassert"
local utils = require "ibl.utils"
local conf = require "ibl.config"

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

describe("has_repeat_indent", function()
    local config = conf.get_config(0)

    after_each(function()
        vim.opt.breakindent = false
        vim.opt.breakindentopt = ""
        config.indent.repeat_linebreak = true
    end)

    -- test for old Neovim versions
    if vim.fn.has "nvim-0.10" ~= 1 then
        it("does not use repeat indent on old Neovim versions", function()
            vim.opt.breakindent = true
            assert.are.equal(utils.has_repeat_indent(0, config), false)
        end)

        return
    end

    it("does not use repeat indent with breakindent off", function()
        assert.are.equal(utils.has_repeat_indent(0, config), false)
    end)

    it("does not use repeat indent with breakindent on", function()
        vim.opt.breakindent = true
        assert.are.equal(utils.has_repeat_indent(0, config), true)
    end)

    it("does not use repeat indent when disabled in the config", function()
        config.indent.repeat_linebreak = false
        vim.opt.breakindent = true
        assert.are.equal(utils.has_repeat_indent(0, config), false)
    end)

    it("does not use repeat indent when breakindentopt includes sbr", function()
        vim.opt.breakindent = true
        vim.opt.breakindentopt = "min:5,sbr"
        assert.are.equal(utils.has_repeat_indent(0, config), false)
    end)

    it("does not use repeat indent when breakindentopt includes column", function()
        vim.opt.breakindent = true
        vim.opt.breakindentopt = "min:5,column:9"
        assert.are.equal(utils.has_repeat_indent(0, config), false)
    end)

    it("does not use repeat indent when breakindentopt includes a negative value for shift", function()
        vim.opt.breakindent = true
        vim.opt.breakindentopt = "min:5,shift:-5"
        assert.are.equal(utils.has_repeat_indent(0, config), false)
    end)

    it("does use repeat indent when breakindentopt includes a positive value for shift", function()
        vim.opt.breakindent = true
        vim.opt.breakindentopt = "min:5,shift:5"
        assert.are.equal(utils.has_repeat_indent(0, config), true)
    end)
end)
