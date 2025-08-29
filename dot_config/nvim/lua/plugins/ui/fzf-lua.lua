return {
  "ibhagwan/fzf-lua",
  opts = {
    winopts = {
      title_pos = "left",
      row = 0.475,
      backdrop = 100,
      border = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },

      preview = {
        border = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
      },
    },
    oldfiles = {
      previewer = false,
      winopts = {
        width = 0.7,
        height = 0.7,
        -- preview = {
        --   layout = "vertical",
        --   vertical = "down:60%",
        -- },
      },
    },
    buffers = {
      previewer = false,
      winopts = {
        width = 0.5,
        height = 0.3,
      },
    },
  },
}
