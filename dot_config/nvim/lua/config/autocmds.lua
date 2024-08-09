-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

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
