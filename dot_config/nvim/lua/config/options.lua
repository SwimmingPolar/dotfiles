-- General
-- vim.opt.number = false -- Show line numbers
-- vim.opt.relativenumber = false -- Relative line numbers
vim.opt.signcolumn = "no" -- No sign column
vim.opt.wrap = false -- No line wrap
vim.opt.showbreak = "+++" -- Wrap-broken line prefix
vim.opt.textwidth = 100 -- Line wrap ()
vim.opt.showmatch = true -- Highlight matching brace
vim.opt.visualbell = true -- Use visual bell (no beeping)
vim.opt.hlsearch = true -- Highlight all search results
vim.opt.smartcase = true -- Enable smart-case search
vim.opt.ignorecase = true -- Always case-insensitive
vim.opt.incsearch = true -- Searches for strings incrementally
vim.opt.autoindent = true -- Auto-indent new lines
vim.opt.cindent = true -- Use 'C' style program indenting
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.shiftwidth = 2 -- Number of auto-indent spaces
vim.opt.smartindent = true -- Enable smart-indent
vim.opt.smarttab = true -- Enable smart-tabs
vim.opt.softtabstop = 2 -- Number of spaces per Tab
vim.opt.tabstop = 2 -- Number of spaces per Tab
vim.opt.undolevels = 1000 -- Number of undo levels
vim.opt.swapfile = false -- No swap files
vim.opt.virtualedit = "block" -- Virtual block mode
vim.opt.list = false -- Show invisible characters
vim.opt.cursorline = true -- Enable highlighting of the current line

vim.diagnostic.config({
    float = {
        border = "single",
    },
})

vim.cmd([[let g:loaded_node_provider = 0]])
vim.cmd([[let g:loaded_perl_provider = 0]])
vim.cmd([[let g:loaded_ruby_provider = 0]])

vim.g.snacks_animate = false
