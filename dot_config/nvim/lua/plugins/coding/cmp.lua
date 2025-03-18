require "config.ui"

local WIDE_HEIGHT = 40

return {
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      {
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-nvim-lua",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/cmp-path",
        "saadparwaiz1/cmp_luasnip",
        "onsails/lspkind.nvim",
        "dcampos/cmp-emmet-vim",
      },
    },
    ---@param opts cmp.ConfigSchema
    opts = function(_, opts)
      local cmp = require "cmp"
      local luasnip = require "luasnip"
      local lspkind = require "lspkind"
      local icons = vim.g.icons
      local source_mapping = vim.g.source_mapping

      local has_words_before = function()
        unpack = unpack or table.unpack
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match "%s" == nil
      end

      opts.completion = {
        autocomplete = {
          cmp.TriggerEvent.TextChanged,
          cmp.TriggerEvent.InsertEnter,
        },
        completeopt = "menu,menuone,noinsert,noselect,preview,popup",
      }
      opts.experimental.ghost_text = {
        hl = "LspCodeLens",
        hl_group = "LspCodeLens",
      }
      opts.formatting = {
        expandable_indicator = true,
        fields = { "abbr", "kind", "menu" },
        format = function(entry, vim_item)
          local kind = vim_item and vim_item.kind or " "
          local symbol = icons[kind] or lspkind.symbolic(vim_item.kind, { mode = "symbol" })
          vim_item.kind = " " .. (symbol or "?") .. " " .. kind
          vim_item.menu = source_mapping[entry.source.name] or entry.source.name or ""
          return require("tailwindcss-colorizer-cmp").formatter(entry, vim_item)
        end,
      }
      opts.snippet = {
        expand = function(args)
          require("luasnip").lsp_expand(args.body)
        end,
      }
      opts.window = {
        completion = {
          border = vim.fn.thin_border "CmpBorder",
          winhighlight = "Normal:CmpPmenu,FloatBorder:CmpPmenuBorder,CursorLine:PmenuSel,Search:None",
          scrollbar = false,
          winblend = 0,
          scrolloff = 0,
          col_offset = 0,
          side_padding = 1,
        },
        documentation = {
          border = vim.fn.thin_border "CmpBorder",
          winhighlight = "Normal:CmpBorder",
          max_height = math.floor(WIDE_HEIGHT * (WIDE_HEIGHT / vim.o.lines)),
          max_width = math.floor((WIDE_HEIGHT * 2) * (vim.o.columns / (WIDE_HEIGHT * 2 * 16 / 9))),
          winblend = vim.o.pumblend,
        },
      }
      opts.view = {
        entries = { name = "custom", selection_order = "top_down", follow_cursor = false },
        docs = {
          auto_open = true,
        },
      }
      opts.sources = {
        {
          name = "nvim_lsp",
          priority = 1,
          max_item_count = 30,
          group_index = 0,
          entry_filter = function(entry, ctx)
            local open_paren = ctx.cursor_before_line:sub(-1)
            local close_paren = ctx.cursor_after_line
            local is_paren_context = open_paren == "(" and close_paren == ")"

            return not entry.exact and not is_paren_context
          end,
          option = {
            get_completion_item = function(entry)
              return require("cmp_lsp").get_completion_item(entry)
            end,
          },
        },
        {
          name = "copilot",
          max_item_count = 3,
          keyword_length = 1,
          group_index = 0,
          entry_filter = function(entry, ctx)
            return not entry.exact
          end,
        },
        { name = "luasnip", max_item_count = 5, priority = 2, group_index = 0 },
        { name = "emmet_vim", max_item_count = 3, group_index = 1, keyword_length = 2, trigger_characters = { "?" } },
        { name = "path", max_item_count = 3, group_index = 2 },
        { name = "cmp-cmdline", max_item_count = 3, group_index = 2 },
        { name = "nvim_lua", group_index = 1 },
      }
      opts.matching = {
        disallow_fuzzy_matching = false,
        disallow_fullfuzzy_matching = true,
        disallow_partial_fuzzy_matching = true,
        disallow_partial_matching = false,
        disallow_prefix_unmatching = false,
        disallow_symbol_nonprefix_matching = false,
      }
      opts.performance = {
        max_view_entries = 32,
        throttle = 80,
        debounce = 300,
      }
      local extended_mapping = vim.tbl_extend("force", opts.mapping, {
        ["<Tab>"] = cmp.mapping(function(fallback)
          local selected_entry = cmp.get_selected_entry()
          local first_entry = cmp.get_entries()[1]

          if selected_entry then
            cmp.confirm { select = true }
          elseif luasnip.locally_jumpable(1) then
            luasnip.jump(1)
          elseif cmp.visible() and has_words_before() then
            cmp.confirm { select = true }
          elseif not selected_entry and first_entry and first_entry.source.name == "copilot" then
            cmp.confirm { select = true }
          else
            fallback()
          end
        end, { "i", "s" }),

        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if luasnip.locally_jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      })
      extended_mapping["<CR>"] = nil
      opts.mapping = extended_mapping
    end,
  },
}
