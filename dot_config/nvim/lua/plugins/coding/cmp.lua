---@diagnostic disable: missing-fields
local source_mapping = {
  buffer = "[Buffer]",
  nvim_lsp = "[LSP]",
  nvim_lua = "[Lua]",
  codeium = "[Codeium]",
  luasnip = "[Snippet]",
  path = "[Path]",
  spell = "[Spell]",
  emoji = "[Emoji]",
}
local icons = {
  Text = " ",
  Method = "󰆧 ",
  Function = "󰊕 ",
  Constructor = " ",
  Field = "󰇽 ",
  Variable = "󰂡 ",
  Class = "󰠱 ",
  Interface = " ",
  Module = " ",
  Property = "󰜢 ",
  Unit = " ",
  Value = "󰎠 ",
  Enum = " ",
  Keyword = "󰌋 ",
  Snippet = "󰅱 ",
  Color = "󰏘 ",
  File = "󰈙 ",
  Reference = " ",
  Folder = "󰉋 ",
  EnumMember = " ",
  Constant = "󰏿 ",
  Struct = " ",
  Event = " ",
  Operator = " ",
  TypeParameter = " ",
  Codeium = " ",
  Copilot = " ",
}
return {
  "hrsh7th/nvim-cmp",
  dependencies = {
    {
      "l3mon4d3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-nvim-lua",
      "hrsh7th/cmp-path",
      "f3fora/cmp-spell",
      "Exafunction/codeium.nvim",
      -- "windwp/nvim-autopairs",
      "onsails/lspkind.nvim",
    },
    {
      "mlaursen/vim-react-snippets",
      config = function()
        require("vim-react-snippets").lazy_load()
      end,
    },
  },
  ---@param opts cmp.ConfigSchema
  opts = function(_, opts)
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    local lspkind = require("lspkind")
    -- If you want insert `(` after select function or method item
    local cmp_autopairs = require("nvim-autopairs.completion.cmp")
    local npairs = require("nvim-autopairs")
    npairs.completion_confirm()
    cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

    vim.api.nvim_set_hl(0, "CmpGhostText", {
      fg = "#808080",
    })
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
    opts.window = {
      documentation = {
        border = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
        winhighlight = "Normal:CmpPmenu,FloatBorder:CmpPmenuBorder,CursorLine:PmenuSel,Search:None",
      },
      completion = {
        border = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
        winhighlight = "Normal:CmpPmenu,FloatBorder:CmpPmenuBorder,CursorLine:PmenuSel,Search:None",
      },
    }
    opts.view = {
      entries = { name = "custom", selection_order = "near_cursor", follow_cursor = true },
    }
    opts.sources = {
      {
        name = "codeium",
        group_index = 2,
        max_item_count = 3,
      },
      {
        name = "luasnip",
        group_index = 2,
        max_item_count = 3,
      },
      {
        name = "nvim_lsp",
        group_index = 2,
        max_item_count = 20,
      },
      { name = "spell", group_index = 3, max_item_count = 3 },
      { name = "buffer", group_index = 3, max_item_count = 3 },
      { name = "path", group_index = 3, max_item_count = 3 },
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
