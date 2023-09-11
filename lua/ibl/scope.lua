local utils = require "ibl.utils"
local scope_lang = require "ibl.scope_languages"
local M = {}

---@return table<number, number>
M.get_cursor_range = function()
    local pos = vim.api.nvim_win_get_cursor(0)
    local row, col = pos[1] - 1, pos[2]
    return { row, 0, row, col }
end

--- Takes a language tree and a range, and returns the child language tree for that range
---
---@param language_tree LanguageTree
---@param range table<number, number>
---@param config ibl.config.full
M.language_for_range = function(language_tree, range, config)
    if config.scope.injected_languages then
        for _, child in pairs(language_tree:children()) do
            if child:contains(range) then
                local lang_tree = M.language_for_range(child, range, config)
                if lang_tree then
                    return lang_tree
                end
            end
        end
    end

    if not vim.tbl_contains(config.scope.exclude.language, language_tree:lang()) then
        return language_tree
    end
end

---@param bufnr number
---@param config ibl.config.full
---@return TSNode?
M.get = function(bufnr, config)
    local lang_tree_ok, lang_tree = pcall(vim.treesitter.get_parser, bufnr)
    if not lang_tree_ok or not lang_tree then
        return nil
    end

    local range = M.get_cursor_range()
    lang_tree = M.language_for_range(lang_tree, range, config)
    if not lang_tree then
        return nil
    end

    local lang = lang_tree:lang()
    if not scope_lang[lang] then
        return nil
    end

    local node = lang_tree:named_node_for_range(range, { bufnr = bufnr })
    if not node then
        return nil
    end

    local excluded_node_types =
        utils.tbl_join(config.scope.exclude.node_type["*"] or {}, config.scope.exclude.node_type[lang] or {})

    while node do
        local type = node:type()

        if scope_lang[lang][type] and not vim.tbl_contains(excluded_node_types, type) then
            return node
        else
            node = node:parent()
        end
    end
end

return M
