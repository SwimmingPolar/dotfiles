-- Change bad spell undercurl color
vim.api.nvim_set_hl(0, "SpellBad", {
  sp = "#8bba7f",
  undercurl = true,
})

-- Change 'Normal' to change the background color
-- vim.api.nvim_set_hl(0, "Normal", {
--     ctermfg = 223,
--     ctermbg = 236,
--     fg = "#e2cca9",
--     bg = "#303030",
-- })

-- default highlight groups
vim.api.nvim_set_hl(0, "NormalFloat", {})
vim.api.nvim_set_hl(0, "FloatBorder", {})
vim.api.nvim_set_hl(0, "FloatTitle", {
  bold = true,
  ctermfg = 208,
  ctermbg = "",
  fg = "#f28534",
  bg = "",
})

-- Neo-tree
vim.api.nvim_set_hl(0, "NeoTreeNormal", {
  force = true,
})
vim.api.nvim_set_hl(0, "NeoTreeEndOfBuffer", {})
vim.api.nvim_set_hl(0, "NeoTreeNormalNC", {
  link = "NeoTreeNormal",
})
vim.api.nvim_set_hl(0, "NeoTreeFloatNormal", {
  link = "NeoTreeNormal",
})
vim.api.nvim_set_hl(0, "NeoTreeFloatNormal", {
  link = "NeoTreeNormal",
})
vim.api.nvim_set_hl(0, "NeoTreeFloatTitle", {
  link = "NeoTreeNormal",
})
vim.api.nvim_set_hl(0, "NeoTreeFloatBorder", {
  link = "NeoTreeNormal",
})

-- Whichkey
vim.api.nvim_set_hl(0, "WhichKeyNormal", {})

-- LSP Info
vim.api.nvim_set_hl(0, "LspInfoBorder", {})
vim.api.nvim_set_hl(0, "LspInfoTitle", {})
