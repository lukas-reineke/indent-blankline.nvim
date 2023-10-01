local ibl = require "ibl"
local conf = require "ibl.config"

vim.api.nvim_create_user_command("IBLEnable", function()
    ibl.update { enabled = true }
end, {
    bar = true,
    desc = "Enables indent-blankline",
})

vim.api.nvim_create_user_command("IBLDisable", function()
    ibl.update { enabled = false }
end, {
    bar = true,
    desc = "Disables indent-blankline",
})

vim.api.nvim_create_user_command("IBLToggle", function()
    if ibl.initialized then
        ibl.update { enabled = not conf.get_config(-1).enabled }
    else
        ibl.setup {}
    end
end, {
    bar = true,
    desc = "Toggles indent-blankline on and off",
})

vim.api.nvim_create_user_command("IBLEnableScope", function()
    ibl.update { scope = { enabled = true } }
end, {
    bar = true,
    desc = "Enables indent-blanklines scope",
})

vim.api.nvim_create_user_command("IBLDisableScope", function()
    ibl.update { scope = { enabled = false } }
end, {
    bar = true,
    desc = "Disables indent-blanklines scope",
})

vim.api.nvim_create_user_command("IBLToggleScope", function()
    if ibl.initialized then
        ibl.update { scope = { enabled = not conf.get_config(-1).scope.enabled } }
    else
        ibl.setup {}
    end
end, {
    bar = true,
    desc = "Toggles indent-blanklines scope on and off",
})

vim.api.nvim_create_user_command("IBLEnableCurrentIndent", function()
    ibl.update { current_indent = { enabled = true } }
end, {
    bar = true,
    desc = "Enables indent-blanklines current_indent",
})

vim.api.nvim_create_user_command("IBLDisableCurrentIndent", function()
    ibl.update { current_indent = { enabled = false } }
end, {
    bar = true,
    desc = "Disables indent-blanklines current_indent",
})

vim.api.nvim_create_user_command("IBLToggleCurrentIndent", function()
    if ibl.initialized then
        ibl.update { current_indent = { enabled = not conf.get_config(-1).current_indent.enabled } }
    else
        ibl.setup {}
    end
end, {
    bar = true,
    desc = "Toggles indent-blanklines current_indent on and off",
})

