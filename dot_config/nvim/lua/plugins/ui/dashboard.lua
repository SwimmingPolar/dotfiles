local padding = string.rep("\n", 6)
return {
  "nvimdev/dashboard-nvim",
  opts = {
    config = {
      header = vim.split(padding, "\n"),
      footer = {},
    },
  },
}
