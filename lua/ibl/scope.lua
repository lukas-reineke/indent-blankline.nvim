local utils = require "ibl.utils"
local scope_lang = require "ibl.scope_languages"
local M = {}

---@param win number
---@return table<number, number>
M.get_cursor_range = function(win)
    local pos = vim.api.nvim_win_get_cursor(win)
    local row, col = pos[1] - 1, pos[2]
    return { row, 0, row, col }
end

--- Takes a language tree and a range, and returns the child language tree for that range
---
---@param language_tree vim.treesitter.LanguageTree
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

    if not utils.tbl_contains(config.scope.exclude.language, language_tree:lang()) then
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

    local win
    if bufnr ~= vim.api.nvim_get_current_buf() then
        win = utils.get_win(bufnr)
        if not win then
            return nil
        end
    else
        win = 0
    end

    local range = M.get_cursor_range(win)
    lang_tree = M.language_for_range(lang_tree, range, config)
    if not lang_tree then
        return nil
    end

    local lang = lang_tree:lang()

    local include_node_types =
        utils.tbl_join(config.scope.include.node_type["*"] or {}, config.scope.include.node_type[lang] or {})
    local include_capture_names =
        utils.tbl_join(config.scope.include.capture_name["*"] or {}, config.scope.include.capture_name[lang] or {})

    if not scope_lang[lang] and #include_node_types == 0 and #include_capture_names == 0 then
        -- Nothing configured to be included for this language
        return nil
    end

    local node = lang_tree:named_node_for_range(range, { bufnr = bufnr })
    if not node then
        return nil
    end

    local excluded_node_types =
        utils.tbl_join(config.scope.exclude.node_type["*"] or {}, config.scope.exclude.node_type[lang] or {})
    local excluded_capture_names =
        utils.tbl_join(config.scope.exclude.capture_name["*"] or {}, config.scope.exclude.capture_name[lang] or {})

    local query = config.scope.use_captures and vim.treesitter.query.get(lang, config.scope.query_name) or nil

    while node and node:byte_length() > 0 do
        local type = node:type()

        if
            ((scope_lang[lang] and scope_lang[lang][type]) and not utils.tbl_contains(excluded_node_types, type))
            or utils.tbl_contains(include_node_types, type)
            or utils.tbl_contains(include_node_types, "*")
        then
            return node
        elseif query then
            for id, n in query:iter_captures(node, bufnr, node:start(), node:end_(), {}) do
                local capture_name = query.captures[id]
                if
                    (n:start() <= range[1] and n:end_() >= range[3])
                    and (utils.tbl_contains(include_capture_names, capture_name) or utils.tbl_contains(
                        include_capture_names,
                        "*"
                    ))
                    and (not utils.tbl_contains(excluded_capture_names, capture_name))
                then
                    return n
                end
            end
        end
        node = node:parent()
    end
end

return M
