require("lspconfig.ui.windows").default_options.border = "single"
require("lspconfig").lua_ls.setup {
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
    },
  },
}

return {}
