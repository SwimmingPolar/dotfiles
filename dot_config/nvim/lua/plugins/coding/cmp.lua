vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })

return {
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "mlaursen/vim-react-snippets",
    },
    opts = {
      -- border
      window = {
        documentation = {
          border = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
          winhighlight = "Normal:CmpPmenu,FloatBorder:CmpPmenuBorder,CursorLine:PmenuSel,Search:None",
        },
        completion = {
          border = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
          winhighlight = "Normal:CmpPmenu,FloatBorder:CmpPmenuBorder,CursorLine:PmenuSel,Search:None",
        },
      },
      fields = { "menu", "kind", "abbr" },
      -- Menu position above/auto
      view = {
        entries = { name = "custom", selection_order = "near_cursor" },
      },
      sources = {
        -- Copilot Source
        { name = "codeium", group_index = 2 },
        { name = "copilot", group_index = 2 },
        -- Other Sources
        { name = "nvim_lsp", group_index = 2 },
        { name = "path", group_index = 2 },
        { name = "luasnip", group_index = 2 },
      },
    },
    config = function(_, opts)
      require("cmp").setup(opts)
      require("vim-react-snippets").lazy_load()
    end,
  },
}
