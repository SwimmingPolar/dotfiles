local function on_attach(client, bufnr)
  if client.server_capabilities.documentSymbolProvider then require("nvim-navic").attach(client, bufnr) end
end

local required_tools = lazy_require("required-tools")

return { -- Order should be:
  -- 	1: mason
  -- 	2: mason-lspconfig
  -- 	3: lspconfig
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufAdd" },
    init = function()
      local bufopts = {
        noremap = true,
        silent = true,
      }
      -- vim.keymap.set('n', '<C-r>', vim.lsp.buf.rename, bufopts)
      -- vim.keymap.set('n', '<M-CR>', vim.lsp.buf.code_action, bufopts)
      -- vim.keymap.set('n', '<C-a>', vim.lsp.buf.hover, bufopts) use boo.nvim for that
      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
        border = "rounded",
        focusable = false,
      })
    end,
    opts = {
      servers = {
        eslint = {},
      },
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
    },
  },
  {
    "williamboman/mason.nvim",
    opts = {
      ui = {
        border = "rounded",
        height = 0.8,
      },
    },
  },
  {
    "dnlhc/glance.nvim",
    keys = {
      { "gr", "<CMD>Glance references<CR>" },
      { "gd", "<CMD>Glance definitions<CR>" },
      { "gi", "<CMD>Glance implementations<CR>" },
      { "gt", "<CMD>Glance type_definitions<CR>" },
    },
    config = function()
      local glance = require("glance")
      local actions = glance.actions
      glance.setup({
        height = 22,
        detached = function(winid) return vim.api.nvim_win_get_width(winid) < 100 end,
        preview_win_opts = {
          cursorline = true,
          number = true,
          wrap = true,
        },
        list = {
          position = "right",
          width = 0.33,
        },
        border = {
          enable = false,
        },
        theme = {
          enable = true,
          mode = "auto",
          multiplier = 2,
        },
        mappings = {
          list = {
            ["<Down>"] = actions.next,
            ["<Up>"] = actions.previous,
            ["<Tab>"] = actions.next_location,
            ["<S-Tab>"] = actions.previous_location,
            ["v"] = actions.jump_vsplit,
            ["s"] = actions.jump_split,
            ["t"] = actions.jump_tab,
            ["<CR>"] = actions.jump,
            ["<space>"] = actions.enter_win("preview"),
            ["q"] = actions.close,
            ["Q"] = actions.close,
            ["<esc>"] = actions.close,
          },
          preview = {
            ["q"] = actions.close,
            ["Q"] = actions.close,
            ["<esc>"] = actions.close,
            ["<Tab>"] = actions.next_location,
            ["<S-Tab>"] = actions.previous_location,
            ["<space>"] = actions.enter_win("list"),
          },
        },
        hooks = {
          before_open = function(results, open, jump, _)
            local uri = vim.uri_from_bufnr(0)
            if #results == 1 then
              local target_uri = results[1].uri or results[1].targetUri
              if target_uri == uri then
                jump(results[1])
              else
                open(results)
              end
            else
              open(results)
            end
          end,
        },
        folds = {
          fold_closed = icons.arrow.right,
          fold_open = icons.arrow.down,
          folded = true,
        },
        indent_lines = {
          enable = true,
          icon = " ",
        },
        winbar = {
          enable = true,
        },
      })
    end,
  },
  {
    "mrded/nvim-lsp-notify",
    dependencies = { "rcarriga/nvim-notify" },
  },
}
