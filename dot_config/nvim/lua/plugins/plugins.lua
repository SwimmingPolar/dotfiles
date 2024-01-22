return {
  {
    "utilyre/barbecue.nvim",
    name = "barbecue",
    version = "*",
    dependencies = {
      "SmiteshP/nvim-navic",
      "nvim-tree/nvim-web-devicons", -- optional dependency
    },
    opts = {
      -- configurations go here
    },
  },
  {
    "nvim-neo-tree/neo-tree.nvim",
    config = {
      -- default configs, will apply to all sources
      window = {
        width = 35,
        mappings = {
          ["h"] = {
            function(state)
              local node = state.tree:get_node()
              local renderers = state.renderers
              print("~~~~~~~~~~~~~~~state.window.fuzzy_finder_mappings~~~~~~~~~~~~")
              for key, value in pairs(state.window.fuzzy_finder_mappings) do
                print(key, " --- ", value)
              end
              print("~~~~~~~~~~~~~~~state.commands~~~~~~~~~~~~")
              for key, value in pairs(state.commands) do
                print(key, " --- ", value)
              end
              local commands = state.commands
              print("~~~~~~~~~~~~~~~window.mappings~~~~~~~~~~~~")
              for key, value in pairs(state.window.mappings) do
                print(key, " --- ", value)
              end
              local direction = state.window.fuzzy_finder_mappings
              if node.type == "file" then
                direction["<up>"]()
              end
            end,
          },
          ["l"] = {
            function(state)
              local node = state.tree:get_node()
              local commands = state.commands
              if node.type == "directory" then
                commands.open(state)
              end
            end,
          },
          ["L"] = "focus_preview",
        },
      },
      filesystem = {
        bind_to_cwd = true,
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufReadPost", "BufNewFile" },
    dependencies = {
      { "folke/neodev.nvim", opts = {} },
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      preview = {
        -- Limit preview size to 10MB
        filesize_limit = 10,
        -- Preview image files listed in image_extensions
        mime_hook = function(filepath, bufnr, opts)
          local is_image = function(filepath)
            local image_extensions = { "png", "jpg" } -- Supported image formats
            local split_path = vim.split(filepath:lower(), ".", { plain = true })
            local extension = split_path[#split_path]
            return vim.tbl_contains(image_extensions, extension)
          end
          if is_image(filepath) then
            local term = vim.api.nvim_open_term(bufnr, {})
            local function send_output(_, data, _)
              for _, d in ipairs(data) do
                vim.api.nvim_chan_send(term, d .. "\r\n")
              end
            end
            vim.fn.jobstart({
              "catimg",
              filepath, -- Terminal image viewer command
            }, { on_stdout = send_output, stdout_buffered = true, pty = true })
          else
            require("telescope.previewers.utils").set_preview_message(bufnr, opts.winid, "Binary cannot be previewed")
          end
        end,
      },
      -- Disable binary preview
      buffer_previewer_maker = function(filepath, bufnr, opts)
        local previewers = require("telescope.previewers")
        local Job = require("plenary.job")
        filepath = vim.fn.expand(filepath)
        Job:new({
          command = "file",
          args = { "--mime-type", "-b", filepath },
          on_exit = function(j)
            local mime_type = vim.split(j:result()[1], "/")[1]
            if mime_type == "text" then
              previewers.buffer_previewer_maker(filepath, bufnr, opts)
            else
              -- maybe we want to write something to the buffer here
              vim.schedule(function()
                vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "BINARY" })
              end)
            end
          end,
        }):sync()
      end,
    },
  },
}
