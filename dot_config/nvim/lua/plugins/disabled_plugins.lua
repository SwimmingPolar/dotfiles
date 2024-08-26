local M = {}

local disabled_plugins = {
    "echasnovski/mini.pairs",
    "mini.indentscope",
    "folke/persistence.nvim",
    "indent-blankline.nvim",
}

M = vim.tbl_map(function(plugin)
    local plugin_config = {
        plugin,
        enabled = false,
    }
    return plugin_config
end, disabled_plugins)

return M
