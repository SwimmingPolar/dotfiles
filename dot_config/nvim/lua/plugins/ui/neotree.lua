return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    window = {
      width = 32,
    },
    buffers = {
      follow_current_file = {
        enabled = true, -- This will find and focus the file in the active buffer every time
        leave_dirs_open = true, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
      },
    },
    filesystem = {
      bind_to_cwd = false,
    },
  },
  config = function(_, opts)
    require("neo-tree").setup(opts)

    -- Neotree highlights
    vim.api.nvim_set_hl(0, "NeoTreeDirectoryIcon", {
      fg = "#e9b143",
    })
    vim.api.nvim_set_hl(0, "NeotreeDirectoryName", {
      fg = "#e9b143",
    })
    vim.api.nvim_set_hl(0, "NeoTreeRootName", {
      fg = "#e9b143",
    })
  end,
}
