vim.api.nvim_command [[set rtp+=.]]

vim.opt.swapfile = false
local cwd = vim.fn.getcwd()

vim.api.nvim_command(string.format([[set rtp+=%s,%s/sepcs]], cwd, cwd))
vim.api.nvim_command(string.format([[set packpath=%s/.ci/vendor]], cwd))
vim.api.nvim_command [[packloadall]]
