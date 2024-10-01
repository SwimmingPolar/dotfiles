vim.cmd("language en_US")

-- Disable god damn annoying auto-commenting
vim.cmd("autocmd BufEnter * set formatoptions-=cro")
vim.cmd("autocmd BufEnter * setlocal formatoptions-=cro")

--set named registers with macros
vim.cmd([[
let @C = "/export const.*= \rztf(\e%j0ztm1M"
let @c = "/const.*= \rztf(\e%j0ztm1M"
let @R = "?return\rzzm0"
let @E = "\e/useeffect\rztV%"
]])

vim.cmd("autocmd FileType help setlocal number")
