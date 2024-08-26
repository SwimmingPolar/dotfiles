vim.cmd("language en_US")

-- Disable god damn annoying auto-commenting
vim.cmd("autocmd BufEnter * set formatoptions-=cro")
vim.cmd("autocmd BufEnter * setlocal formatoptions-=cro")

-- Function to set a named register with a macro
vim.cmd([[
let @C = "/export const.*= \rztf(\e%j0ztm1M"
let @c = "/const.*= \rztf(\e%j0ztm1M"
let @R = "?return\rzzm0"
let @E = "\e/useeffect\rztV%"
]])

-- Change bad spell undercurl color
vim.api.nvim_set_hl(0, "SpellBad", {
  sp = "#8bba7f",
  undercurl = true,
})

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
vim.api.nvim_set_hl(0, "NeoTreeNormal", {})
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
