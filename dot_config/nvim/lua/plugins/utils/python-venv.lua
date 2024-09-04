return {
    "linux-cultist/venv-selector.nvim",
    dependencies = {
        -- "neovim/nvim-lspconfig",
        -- "mfussenegger/nvim-dap",
        -- "mfussenegger/nvim-dap-python", --optional
        -- { "nvim-telescope/telescope.nvim", branch = "0.1.x", dependencies = { "nvim-lua/plenary.nvim" } },
    },
    opts = {
        -- Your options go here
        -- name = "venv",
        -- auto_refresh = false
    },
    config = function()
        require("venv-selector").setup()
    end,
    lazy = false,
    branch = "regexp",
    keys = {
        -- Keymap to open VenvSelector to pick a venv.
        { ",v", "<cmd>VenvSelect<cr>" },
    },
}
