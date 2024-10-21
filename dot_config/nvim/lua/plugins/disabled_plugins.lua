local M = {}

local disabled_plugins = {
    "echasnovski/mini.pairs",
    "folke/persistence.nvim",
    "indent-blankline.nvim",
    "nvim-tree/nvim-web-devicons",
}

M = vim.tbl_map(function(plugin)
    local plugin_config = {
        plugin,
    }
    return plugin_config
end, disabled_plugins)

return M
