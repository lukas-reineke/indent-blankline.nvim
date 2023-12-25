local utils = require "ibl.utils"

local M = {}

--- The current global configuration
---
---@type ibl.config.full?
M.config = nil

--- Map from buffer numbers to their partial configuration
---
--- Anything not included here will fall back to the global configuration
---@type table<number, ibl.config>
M.buffer_config = {}

--- The default configuration
---
---@type ibl.config.full
M.default_config = {
    enabled = true,
    debounce = 200,
    viewport_buffer = {
        min = 30,
        max = 500,
    },
    indent = {
        char = "▎",
        tab_char = nil,
        highlight = "IblIndent",
        smart_indent_cap = true,
        priority = 1,
        repeat_linebreak = true,
    },
    whitespace = {
        highlight = "IblWhitespace",
        remove_blankline_trail = true,
    },
    scope = {
        enabled = true,
        char = nil,
        show_start = true,
        show_end = true,
        show_exact_scope = false,
        injected_languages = true,
        highlight = "IblScope",
        priority = 1024,
        include = {
            node_type = {},
        },
        exclude = {
            language = {},
            node_type = {
                ["*"] = {
                    "source_file",
                    "program",
                },
                lua = {
                    "chunk",
                },
                python = {
                    "module",
                },
            },
        },
    },
    exclude = {
        filetypes = {
            "lspinfo",
            "packer",
            "checkhealth",
            "help",
            "man",
            "gitcommit",
            "TelescopePrompt",
            "TelescopeResults",
            "",
        },
        buftypes = {
            "terminal",
            "nofile",
            "quickfix",
            "prompt",
        },
    },
}

---@param char string
---@return boolean, string?
local validate_char = function(char)
    if type(char) == "string" then
        local length = vim.fn.strdisplaywidth(char)
        return length <= 1, string.format("'%s' has a display width of %d", char, length)
    else
        if #char == 0 then
            return false, "table is empty"
        end
        for i, c in ipairs(char) do
            local length = vim.fn.strdisplaywidth(c)
            if length > 1 then
                return false, string.format("index %d '%s' has a display width of %d", i, c, length)
            end
        end
        return true
    end
end

---@param config ibl.config?
local validate_config = function(config)
    if not config then
        return
    end

    utils.validate({
        enabled = { config.enabled, "boolean", true },
        debounce = { config.debounce, "number", true },
        viewport_buffer = { config.viewport_buffer, "table", true },
        indent = { config.indent, "table", true },
        whitespace = { config.whitespace, "table", true },
        scope = { config.scope, "table", true },
        exclude = { config.exclude, "table", true },
    }, config, "ibl.config")

    if config.viewport_buffer then
        utils.validate({
            min = { config.viewport_buffer.min, "number", true },
            max = { config.viewport_buffer.max, "number", true },
        }, config.viewport_buffer, "ibl.config.viewport_buffer")
    end

    if config.indent then
        utils.validate({
            char = { config.indent.char, { "string", "table" }, true },
            tab_char = { config.indent.char, { "string", "table" }, true },
            highlight = { config.indent.highlight, { "string", "table" }, true },
            smart_indent_cap = { config.indent.smart_indent_cap, "boolean", true },
            priority = { config.indent.priority, "number", true },
            repeat_linebreak = { config.indent.repeat_linebreak, "boolean", true },
        }, config.indent, "ibl.config.indent")
        if config.indent.char then
            vim.validate {
                char = {
                    config.indent.char,
                    validate_char,
                    "indent.char to have a display width of 0 or 1",
                },
            }
        end
        if config.indent.tab_char then
            vim.validate {
                tab_char = {
                    config.indent.tab_char,
                    validate_char,
                    "indent.tab_char to have a display width of 0 or 1",
                },
            }
        end
        if type(config.indent.highlight) == "table" then
            vim.validate {
                tab_char = {
                    config.indent.highlight,
                    function(highlight)
                        return #highlight > 0
                    end,
                    "indent.highlight to be not empty",
                },
            }
        end
    end

    if config.whitespace then
        utils.validate({
            highlight = { config.whitespace.highlight, { "string", "table" }, true },
            remove_blankline_trail = { config.whitespace.remove_blankline_trail, "boolean", true },
        }, config.whitespace, "ibl.config.whitespace")
        if type(config.whitespace.highlight) == "table" then
            vim.validate {
                tab_char = {
                    config.whitespace.highlight,
                    function(highlight)
                        return #highlight > 0
                    end,
                    "whitespace.highlight to be not empty",
                },
            }
        end
    end

    if config.scope then
        utils.validate({
            enabled = { config.scope.enabled, "boolean", true },
            char = { config.scope.char, { "string", "table" }, true },
            show_start = { config.scope.show_start, "boolean", true },
            show_end = { config.scope.show_end, "boolean", true },
            show_exact_scope = { config.scope.show_exact_scope, "boolean", true },
            injected_languages = { config.scope.injected_languages, "boolean", true },
            highlight = { config.scope.highlight, { "string", "table" }, true },
            priority = { config.scope.priority, "number", true },
            include = { config.scope.include, "table", true },
            exclude = { config.scope.exclude, "table", true },
        }, config.scope, "ibl.config.scope")
        if config.scope.char then
            vim.validate {
                char = {
                    config.scope.char,
                    validate_char,
                    "scope.char to have a display width of 0 or 1",
                },
            }
        end
        if type(config.scope.highlight) == "table" then
            vim.validate {
                tab_char = {
                    config.scope.highlight,
                    function(highlight)
                        return #highlight > 0
                    end,
                    "scope.highlight to be not empty",
                },
            }
        end
        if config.scope.exclude then
            utils.validate({
                language = { config.scope.exclude.language, "table", true },
                node_type = { config.scope.exclude.node_type, "table", true },
            }, config.scope.exclude, "ibl.config.scope.exclude")
        end
        if config.scope.include then
            utils.validate({
                node_type = { config.scope.include.node_type, "table", true },
            }, config.scope.include, "ibl.config.scope.include")
        end
    end

    if config.exclude then
        if config.exclude then
            utils.validate({
                filetypes = { config.exclude.filetypes, "table", true },
                buftypes = { config.exclude.buftypes, "table", true },
            }, config.exclude, "ibl.config.exclude")
        end
    end
end

---@param behavior "merge"|"overwrite"
---@param base ibl.config.full
---@param input ibl.config?
---@return ibl.config.full
local merge_configs = function(behavior, base, input)
    local result = vim.tbl_deep_extend("keep", input or {}, base) --[[@as ibl.config.full]]

    if behavior == "merge" and input then
        result.scope.exclude.language =
            utils.tbl_join(base.scope.exclude.language, vim.tbl_get(input, "scope", "exclude", "language"))

        local node_type = vim.tbl_get(input, "scope", "exclude", "node_type")
        if node_type then
            for k, v in pairs(node_type) do
                result.scope.exclude.node_type[k] = utils.tbl_join(v, base.scope.exclude.node_type[k])
            end
        end
        result.exclude.filetypes = utils.tbl_join(base.exclude.filetypes, vim.tbl_get(input, "exclude", "filetypes"))
        result.exclude.buftypes = utils.tbl_join(base.exclude.buftypes, vim.tbl_get(input, "exclude", "buftypes"))
    end

    return result
end

--- Sets the global configuration
---
--- All values that are not passed are set to the default value
--- List values get merged with the default values
---@param config ibl.config?
---@return ibl.config.full
M.set_config = function(config)
    validate_config(config)
    M.config = merge_configs("merge", M.default_config, config)

    return M.config
end

--- Updates the global configuration
---
--- All values that are not passed are kept as they are
---@param config ibl.config
---@return ibl.config.full
M.update_config = function(config)
    validate_config(config)
    M.config = merge_configs("merge", M.config or M.default_config, config or {})

    return M.config
end

--- Overwrites the global configuration
---
--- Same as `update_config`, but all list values are overwritten instead of merged
---@param config ibl.config
---@return ibl.config.full
M.overwrite_config = function(config)
    validate_config(config)
    M.config = merge_configs("overwrite", M.config or M.default_config, config)

    return M.config
end

--- Sets the configuration for a buffer
---
--- All values that are not passed are cleared, and will fall back to the global config
---@param bufnr number
---@param config ibl.config
---@return ibl.config.full
M.set_buffer_config = function(bufnr, config)
    validate_config(config)
    bufnr = utils.get_bufnr(bufnr)
    M.buffer_config[bufnr] = config

    return M.get_config(bufnr)
end

--- Clears the configuration for a buffer
---
---@param bufnr number
M.clear_buffer_config = function(bufnr)
    M.buffer_config[bufnr] = nil
end

--- Returns the configuration for a buffer
---
---@param bufnr number
---@return ibl.config.full
M.get_config = function(bufnr)
    bufnr = utils.get_bufnr(bufnr)
    return merge_configs("merge", M.config or M.default_config, M.buffer_config[bufnr])
end

return M
