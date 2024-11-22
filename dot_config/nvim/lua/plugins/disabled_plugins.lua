local M = {}

local disabled_plugins = {
    "echasnovski/mini.pairs",
    "folke/persistence.nvim",
    "indent-blankline.nvim",
    "monaqa/dial.nvim",
    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
    },
    "akinsho/bufferline.nvim",
}

M = vim.tbl_map(function(plugin)
    local plugin_config = type(plugin) == "table" and plugin or { plugin }
    return vim.tbl_extend("force", plugin_config, {
        enabled = false,
    })
end, disabled_plugins)

return M
