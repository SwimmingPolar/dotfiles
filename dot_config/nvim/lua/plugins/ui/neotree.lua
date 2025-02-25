return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    window = {
      position = "float",
      width = 32,
      mappings = {
        ["l"] = function(state)
          local node = state.tree:get_node()

          -- before updated, check if expanded or not
          local is_expanded = node:is_expanded()
          if not is_expanded then
            local M = state.commands
            M.open(state)
          end

          -- if the node is dir and has children
          -- move cur 1 line down
          if node.type == "directory" then
            local children = vim.fn.readdir(node.path)
            if #children > 0 then
              local cur = vim.api.nvim_win_get_cursor(0)
              local row, col = unpack(cur)
              vim.api.nvim_win_set_cursor(0, { row + 1, col })
            end
          end
        end,
      },
    },
    buffers = {
      bind_to_cwd = false,
      follow_current_file = {
        enabled = true, -- This will find and focus the file in the active buffer every time
        leave_dirs_open = true, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
      },
    },
    popup_border_style = "single",
    hide_root_node = true,
    filesystem = {
      bind_to_cwd = false,
      components = {
        -- add padding to the right of each file names
        name = function(config, node, state)
          local name = require("neo-tree.sources.common.components").name(config, node, state)
          name.text = " " .. name.text
          return name
        end,
      },
    },
    sources = {
      "filesystem",
      -- "document_symbols",
    },
    source_selector = {
      sources = {
        { source = "filesystem" },
        -- { source = "document_symbols" },
      },
      winbar = true,
      content_layout = "center",
      separator = "",
      highlight_tab = "NeoTreeTabInActive",
      highlight_tab_active = "NeoTreeNormal",
    },
    default_component_configs = {
      indent = {
        with_markers = false,
      },
    },
  },
  config = function(_, opts)
    -- init setup
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
