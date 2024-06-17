-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Easy scape from vim
vim.cmd([[
fun! SetupCommandAlias(from, to)
	exec 'cnoreabbrev <expr> '.a:from
		\ .' ((getcmdtype() is# ":" && getcmdline() is# "'.a:from.'")'
		\ .'? ("'.a:to.'") : ("'.a:from.'"))'
endfun
call SetupCommandAlias("w","update")
call SetupCommandAlias("W","w")
call SetupCommandAlias("Wa","wa")
call SetupCommandAlias("Wqa","wqa")
call SetupCommandAlias("Qa","qa")
]])
