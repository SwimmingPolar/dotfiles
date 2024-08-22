local bufferline = require("bufferline")
return {
  "akinsho/bufferline.nvim",
  event = "LazyFile",
  opts = {
    options = {
      separator_style = "slant",
      style_preset = {
        bufferline.style_preset.no_italic,
      },
      offsets = {
        {
          filetype = "neo-tree",
          text = "File Explorer",
          highlight = "BufferLineTab",
          text_align = "center",
        },
      },
      close_icon = " ",
      show_close_icon = false,
      show_buffer_close_icons = false,
    },
  },
}
