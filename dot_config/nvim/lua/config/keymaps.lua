-- Easy scape from vim
vim.cmd([[
fun! SetupCommandAlias(from, to)
	exec 'cnoreabbrev <expr> '.a:from
		\ .' ((getcmdtype() is# ":" && getcmdline() is# "'.a:from.'")'
		\ .'? ("'.a:to.'") : ("'.a:from.'"))'
endfun
call SetupCommandAlias("W","w")
call SetupCommandAlias("Q","q")
call SetupCommandAlias("A","a")
]])

-- Remap C-x to close buffer
vim.keymap.set("", "<C-x>", LazyVim.ui.bufremove, { desc = "Close current buffer" })

-- Move current line
vim.keymap.set("n", "<A-j>", ":m .+1<CR>==", { noremap = true, silent = true })
vim.keymap.set("n", "<A-k>", ":m .-2<CR>==", { noremap = true, silent = true })
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { noremap = true, silent = true })
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { noremap = true, silent = true })

-- Remap H(High) M(Middle) L(Low)
vim.keymap.set("n", "<leader>H", ":normal!H<cr>", { silent = true })
vim.keymap.set("n", "<leader>M", ":normal!M<cr>", { silent = true })
vim.keymap.set("n", "<leader>L", ":normal!L<cr>", { silent = true })
