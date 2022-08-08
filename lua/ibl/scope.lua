local utils = require "ibl.utils"
local M = {}

---@return table<number, number>
M.get_cursor_range = function()
    local pos = vim.api.nvim_win_get_cursor(0)
    local row, col = pos[1] - 1, pos[2]
    return { row, 0, row, col }
end

---@param language_tree LanguageTree
---@param range table<number, number>
---@param config ibl.config.full
M.language_for_range = function(language_tree, range, config)
    if config.scope.injected_languages then
        for _, child in pairs(language_tree:children()) do
            if child:contains(range) then
                local tree = M.language_for_range(child, range, config)
                if tree then
                    return tree
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
    local tslocals_ok, tslocals = pcall(require, "nvim-treesitter.locals")
    if not tslocals_ok then
        return nil
    end

    local range = M.get_cursor_range()
    local root_lang_tree_ok, root_lang_tree = pcall(vim.treesitter.get_parser, bufnr)
    if not root_lang_tree_ok or not root_lang_tree then
        return nil
    end

    local tree = M.language_for_range(root_lang_tree, range, config)
    if not tree then
        return nil
    end
    local node = tree:named_node_for_range(range, { bufnr = bufnr })
    if not node then
        return nil
    end

    local excluded_node_types =
        utils.tbl_join(config.scope.exclude.node_type["*"] or {}, config.scope.exclude.node_type[tree:lang()] or {})

    local scope
    while not scope do
        if not node then
            return nil
        end
        scope = tslocals.containing_scope(node, bufnr)
        if not scope or vim.tbl_contains(excluded_node_types, scope:type()) then
            scope = nil
            node = node:parent()
        end
    end

    return scope
end

return M
