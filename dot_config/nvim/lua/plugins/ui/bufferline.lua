local bufferline = require("bufferline")

return {
  "akinsho/bufferline.nvim",
  event = "BufWinEnter",
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
          -- highlight = "BufferLineTab",
          text_align = "center",
        },
      },
      close_icon = " ",
      show_close_icon = false,
      show_buffer_close_icons = false,
      auto_toggle_bufferline = true,
      always_show_bufferline = true,
    },
  },
  config = function(_, opts)
    -- Get the current git repo name if any
    local function get_repo_name()
      local is_git_repo = vim.trim(vim.fn.system("git rev-parse --is-inside-work-tree"))

      if is_git_repo == "true" then
        return vim.trim(vim.fn.system("git rev-parse --show-toplevel"))
      else
        return vim.trim(vim.fn.getcwd())
      end
    end

    -- Split the name by "/" and set default name if there isn't one
    -- Or prefix the name with "~/"
    local project_name = get_repo_name()
    local paths = vim.split(project_name, "/")
    project_name = paths[#paths - 1] .. "/" .. paths[#paths]
    if project_name == "" then
      project_name = "File Explorer"
    else
      project_name = "~/" .. project_name
    end

    -- call setup with the name
    opts.options.offsets[1].text = project_name
    bufferline.setup(opts)
  end,
}
