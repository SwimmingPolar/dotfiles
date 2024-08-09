return {
  "hrsh7th/nvim-cmp",
  dependencies = {
    "mlaursen/vim-react-snippets",
  },
  ---@param opts cmp.ConfigSchema
  opts = function(_, opts)
    vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
    require("vim-react-snippets").lazy_load()

    local has_words_before = function()
      unpack = unpack or table.unpack
      local line, col = unpack(vim.api.nvim_win_get_cursor(0))
      return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
    end

    local cmp = require("cmp")

    -- border
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
    -- Menu position above/auto
    opts.view = {
      entries = { name = "custom", selection_order = "near_cursor" },
    }
    opts.sources = {
      { name = "luasnip" },
      { name = "nvim_lsp" },
      { name = "codeium" },
      { name = "copilot" },
      { name = "path" },
      { name = "emoji" },
    }

    opts.mapping = vim.tbl_extend("force", opts.mapping, {
      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          -- You could replace select_next_item() with confirm({ select = true }) to get VS Code autocompletion behavior
          cmp.select_next_item()
        elseif vim.snippet.active({ direction = 1 }) then
          vim.schedule(function()
            vim.snippet.jump(1)
          end)
        elseif has_words_before() then
          cmp.complete()
        else
          fallback()
        end
      end, { "i", "s" }),
      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif vim.snippet.active({ direction = -1 }) then
          vim.schedule(function()
            vim.snippet.jump(-1)
          end)
        else
          fallback()
        end
      end, { "i", "s" }),
    })
  end,
}
