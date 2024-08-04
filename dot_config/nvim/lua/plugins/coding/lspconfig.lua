return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = { eslint = {} },
    setup = {
      eslint = function()
        require("lazyvim.util").lsp.on_attach(function(client)
          if client.name == "eslint" then
            client.server_capabilities.documentFormattingProvider = true
          elseif client.name == "tsserver" then
            client.server_capabilities.documentFormattingProvider = false
          end
        end)
      end,
    },
    source_selector = {
      winbar = true, -- toggle to show selector on winbar
      statusline = false, -- toggle to show selector on statusline
      tabs_layout = "start",
      tab_labels = { -- falls back to source_name if nil
        filesystem = " Files",
        buffers = " Buffers",
        git_status = " Git",
      },
      tabs_min_width = 11,
      separator = " ",
      highlight_tab = "NeoTreeTab",
      highlight_tab_active = "NeoTreeActiveTab",
      highlight_separator = "NeoTreeSeparator",
      highlight_separator_active = "NeoTreeSeparator",
      highlight_background = "NeoTreeTabBackground",
    },
  },
}
