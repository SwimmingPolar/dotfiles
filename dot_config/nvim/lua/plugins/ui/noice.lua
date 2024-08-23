return {
  "folke/noice.nvim",
  -- disable damm annoying lsp signature help documentation window
  -- which looks like coming from nvim-cmp when it is actually noice.lua
  -- that opens up the window automatically.
  dependencies = {
    "hrsh7th/nvim-cmp",
  },
  opts = {
    presets = {
      lsp_doc_border = true,
    },
    lsp = {
      override = {
        ["cmp.entry.get_documentation"] = true,
      },
    },
  },
  config = function(_, opts)
    require("noice").setup(opts)

    local win_highlight = {
      NoicePopupBorder = "CmpPmenuBorder",
      NoicePopup = "CmpPmenu",
    }

    for noice_hl, theme_hl in pairs(win_highlight) do
      vim.api.nvim_set_hl(0, noice_hl, { link = theme_hl })
    end
  end,
}
