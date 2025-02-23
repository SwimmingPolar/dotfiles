return {
    "l3mon4d3/LuaSnip",
    dependencies = {
        {
            "rafamadriz/friendly-snippets",
            config = function()
                require("luasnip.loaders.from_vscode").lazy_load()
                local ls = require("luasnip")
                ls.filetype_set("typescriptreact", { "javascript" })
            end,
        },
        {
            "mlaursen/vim-react-snippets",
            config = function()
                require("vim-react-snippets").lazy_load()
                vim.api.nvim_create_autocmd("InsertLeave", {
                    callback = function()
                        if
                            require("luasnip").session.current_nodes[vim.api.nvim_get_current_buf()]
                            and not require("luasnip").session.jump_active
                        then
                            require("luasnip").unlink_current()
                        end
                    end,
                })
            end,
        },
    },
}
