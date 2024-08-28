return {
  "folke/twilight.nvim",
  opts = {
    dimming = {
      alpha = 0.25, -- amount of dimming
      inactive = true, -- when true, other windows will be fully dimmed (unless they contain the same buffer)
    },
    context = 120, -- amount of lines we will try to show around the current line
    expand = { -- for treesitter, we we always try to expand to the top-most ancestor with these types
      -- react
      "jsx_expression",
      "jsx_element",
      "template_string",
    },
    exclude = {}, -- exclude these filetypes
  },
}
