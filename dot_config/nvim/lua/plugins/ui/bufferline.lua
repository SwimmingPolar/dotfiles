return {
  "akinsho/bufferline.nvim",
  event = "LazyFile",
  opts = {
    options = {
      alwats_show_bufferline = true,
      offsets = {
        {
          filetype = "neo-tree",
          text = "File Explorer",
          text_align = "left",
        },
      },
    },
  },
}
