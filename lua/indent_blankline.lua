return {
    setup = function()
        vim.notify_once(
            "You are trying to call the setup function of indent-blankline version 2, but you have version 3 installed.\nTake a look at the GitHub wiki for instructions on how to migrate, or revert back to version 2.",
            vim.log.levels.ERROR
        )
    end,
}
