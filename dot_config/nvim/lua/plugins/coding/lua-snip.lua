require("luasnip.loaders.from_lua").load { paths = { vim.fn.stdpath "config" .. "/lua/snippets" } }

return {
  "L3MON4D3/LuaSnip",
  dependencies = {
    {
      "rafamadriz/friendly-snippets",
      config = function()
        require("luasnip.loaders.from_vscode").lazy_load()
        local ls = require "luasnip"

        ls.filetype_set("typescriptreact", { "javascript" })
        ls.filetype_set("typescript", { "javascript" })
        ls.filetype_set("astro", { "typescript" })
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
  config = function() end,
}
