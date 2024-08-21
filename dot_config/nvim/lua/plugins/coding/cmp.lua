---@diagnostic disable: missing-fields

local source_mapping = {
  buffer = "[Buffer]",
  nvim_lsp = "[LSP]",
  nvim_lua = "[Lua]",
  codeium = "[Codeium]",
  copilot = "[Copilot]",
  luasnip = "[Snippet]",
  path = "[Path]",
  spell = "[Spell]",
  emoji = "[Emoji]",
}
local icons = {
  Namespace = "󰌗 ",
  Text = "󰉿 ",
  Method = "󰆧 ",
  Function = "󰆧 ",
  Constructor = " ",
  Field = "󰜢 ",
  Variable = "󰀫 ",
  Class = "󰠱 ",
  Interface = " ",
  Module = " ",
  Property = "󰜢 ",
  Unit = "󰑭 ",
  Value = "󰎠 ",
  Enum = " ",
  Keyword = "󰌋 ",
  Snippet = " ",
  Color = "󰏘 ",
  File = "󰈚 ",
  Reference = "󰈇 ",
  Folder = "󰉋 ",
  EnumMember = " ",
  Constant = "󰏿 ",
  Struct = "󰙅 ",
  Event = " ",
  Operator = "󰆕 ",
  TypeParameter = "󰊄 ",
  Table = " ",
  Object = "󰅩 ",
  Tag = " ",
  Array = "[] ",
  Boolean = " ",
  Number = " ",
  Null = "󰟢 ",
  Supermaven = " ",
  String = "󰉿 ",
  Calendar = " ",
  Watch = "󰥔 ",
  Package = " ",
  Copilot = " ",
  Codeium = " ",
  TabNine = " ",
}
local function border(hl_name)
  return {
    { "╭", hl_name },
    { "─", hl_name },
    { "╮", hl_name },
    { "│", hl_name },
    { "╯", hl_name },
    { "─", hl_name },
    { "╰", hl_name },
    { "│", hl_name },
  }
end
return {
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
    },
  },
  ---@param opts cmp.ConfigSchema
  opts = function(_, opts)
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    local lspkind = require("lspkind")

    opts.completion.autocomplete = {
      cmp.TriggerEvent.TextChanged,
      cmp.TriggerEvent.InsertEnter,
    }
    opts.preselect = cmp.PreselectMode.None
    opts.experimental.ghost_text = {
      hl = "LspCodeLens",
    }
    opts.formatting = {
      fields = { "abbr", "kind", "menu" },
      format = function(entry, vim_item)
        local kind = vim_item.kind
        local symbol = icons[kind] or lspkind.symbolic(vim_item.kind, { mode = "symbol" })
        vim_item.kind = " " .. (symbol or "?") .. " " .. kind
        vim_item.menu = source_mapping[entry.source.name]
        return vim_item
      end,
    }
    opts.snippet = {
      expand = function(args)
        require("luasnip").lsp_expand(args.body)
      end,
    }
    opts.window = {
      completion = {
        border = border("CmpBorder"),
        winhighlight = "Normal:CmpPmenu,FloatBorder:CmpPmenuBorder,CursorLine:PmenuSel,Search:None",
        scrollbar = false,
      },
      documentation = {
        border = border("CmpBorder"),
        winhighlight = "Normal:CmpBorder",
      },
    }
    opts.view = {
      entries = { name = "custom", selection_order = "near_cursor", follow_cursor = true },
      docs = {
        auto_open = false,
      },
    }
    opts.sources = {
      {
        name = "codeium",
        group_index = 2,
        max_item_count = 3,
        entry_filter = function(entry, ctx)
          return not entry.exact
        end,
      },
      { name = "luasnip", group_index = 2, max_item_count = 3 },
      {
        name = "nvim_lsp",
        group_index = 2,
        max_item_count = 20,
        entry_filter = function(entry, ctx)
          local open_paren = ctx.cursor_before_line:sub(-1)
          local close_paren = ctx.cursor_after_line
          local is_paren_context = open_paren == "(" and close_paren == ")"

          return not entry.exact and not is_paren_context
        end,
      },
      { name = "nvim_lua" },
      { name = "buffer", group_index = 3, max_item_count = 3 },
      { name = "cmp-cmdline", group_index = 3, max_item_count = 3 },
      { name = "path", group_index = 3, max_item_count = 3 },
    }
    opts.matching = {
      disallow_fuzzy_matching = false,
      disallow_fullfuzzy_matching = true,
      disallow_partial_fuzzy_matching = true,
      disallow_partial_matching = false,
      disallow_prefix_unmatching = false,
    }
    opts.performance = {
      max_view_entries = 20,
    }
    opts.mapping = vim.tbl_extend("force", opts.mapping, {
      ["<Tab>"] = cmp.mapping(function(fallback)
        if luasnip.locally_jumpable(1) then
          luasnip.jump(1)
        elseif cmp.visible() then
          cmp.select_next_item()
        else
          fallback()
        end
      end, { "i", "s" }),

      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if luasnip.locally_jumpable(-1) then
          luasnip.jump(-1)
        elseif cmp.visible() then
          cmp.select_prev_item()
        else
          fallback()
        end
      end, { "i", "s" }),
    })
  end,
}
