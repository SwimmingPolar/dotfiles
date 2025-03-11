vim.g.source_mapping = {
  buffer = "[Buffer]",
  nvim_lsp = "[LSP]",
  nvim_lua = "[Lua]",
  codeium = "[Codeium]",
  copilot = "[Copilot]",
  luasnip = "[Snippet]",
  path = "[Path]",
  spell = "[Spell]",
  emoji = "[Emoji]",
  ["emmet_vim"] = "[Emmet]",
}
vim.g.icons = {
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
vim.fn.round_border = function(hl_name)
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

vim.fn.thick_border = function(hl_name)
  return {
    { "┏", hl_name },
    { "━", hl_name },
    { "┓", hl_name },
    { "┃", hl_name },
    { "┛", hl_name },
    { "━", hl_name },
    { "┗", hl_name },
    { "┃", hl_name },
  }
end

vim.fn.thin_border = function(hl_name)
  return {
    { "┌", hl_name },
    { "─", hl_name },
    { "┐", hl_name },
    { "│", hl_name },
    { "┘", hl_name },
    { "─", hl_name },
    { "└", hl_name },
    { "│", hl_name },
  }
end
