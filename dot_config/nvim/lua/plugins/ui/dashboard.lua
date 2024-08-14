local padding = string.rep("\n", 8)
return {
  "nvimdev/dashboard-nvim",
  opts = {
    config = {
      header = vim.split(padding, "\n"),
      footer = {},
    },
  },
}
