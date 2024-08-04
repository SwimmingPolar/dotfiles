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
call SetupCommandAlias("wq","wqa")
call SetupCommandAlias("Wq","wqa")
]])

-- Move current line / block with Alt-j/k ala vscode.
vim.keymap.set("n", "<A-j>", ":m .+1<CR>==", { noremap = true, silent = true })
vim.keymap.set("n", "<A-k>", ":m .-2<CR>==", { noremap = true, silent = true })
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true })
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { noremap = true, silent = true })

-- Remap C-x to close buffer
vim.keymap.set("n", "<C-x>", LazyVim.ui.bufremove, { desc = "Close current buffer" })
