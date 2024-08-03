return {
  {
    "hrsh7th/nvim-cmp",
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
    },
  },
  -- lualine icon
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    event = "VeryLazy",
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, 2, LazyVim.lualine.cmp_source("codeium"))
    end,
  },
}
