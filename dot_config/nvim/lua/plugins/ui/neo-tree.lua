return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    dependency = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    window = {
      width = 35,
    },
    buffers = {
      follow_current_file = {
        enabled = true, -- This will find and focus the file in the active buffer every time
        leave_dirs_open = true, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
      },
    },
    filesystem = {
      bind_to_cwd = true,
    },
  },
}
