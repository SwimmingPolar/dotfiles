return {
    "monaqa/dial.nvim",
    keys = {
        {
            "<C-a>",
            function() end,
        },
        {
            "<C-x>",
            function()
                LazyVim.ui.bufremove()
            end,
        },
        {
            "g<C-a>",
            function() end,
        },
        {
            "g<C-x>",
            function() end,
        },
        {
            "<C-,>",
            "<cmd>DialDecrement<CR>",
            desc = "Decrement",
            mode = { "n", "v" },
        },
        {
            "<C-.>",
            "<cmd>DialIncrement<CR>",
            desc = "Increment",
            mode = { "n", "v" },
        },
    },
}
