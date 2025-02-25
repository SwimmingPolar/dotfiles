-- Display settings
-- vim.opt.number = false         -- Show line numbers
-- vim.opt.relativenumber = false -- Relative line numbers
vim.opt.signcolumn = "no" -- No sign column
vim.opt.cursorline = true -- Highlight current line
vim.opt.list = false -- Show invisible characters

-- Wrapping & Formatting
vim.opt.wrap = false -- No line wrap
vim.opt.showbreak = "+++" -- Wrap-broken line prefix
vim.opt.textwidth = 120 -- Wrap text at 120 characters

-- Search behavior
vim.opt.hlsearch = true -- Highlight all search results
vim.opt.incsearch = true -- Incremental search
vim.opt.ignorecase = true -- Case-insensitive search
vim.opt.smartcase = true -- Case-sensitive if query contains uppercase

-- Indentation & Tabs
vim.opt.autoindent = true -- Auto-indent new lines
vim.opt.smartindent = true -- Smart indentation
vim.opt.cindent = true -- Use C-style indenting
vim.opt.expandtab = true -- Use spaces instead of tabs
vim.opt.shiftwidth = 2 -- Number of spaces for auto-indent
vim.opt.smarttab = true -- Smart tab handling
vim.opt.softtabstop = 2 -- Spaces per tab when editing
vim.opt.tabstop = 2 -- Number of spaces per Tab

-- Editing behavior
vim.opt.virtualedit = "block" -- Allow cursor to move in visual block mode
vim.opt.undolevels = 1000 -- Number of undo levels
vim.opt.swapfile = false -- No swap files

-- Visual enhancements
vim.opt.showmatch = true -- Highlight matching braces
vim.opt.visualbell = true -- Use visual bell instead of beeping

vim.diagnostic.config {
  float = {
    border = "single",
  },
}

vim.cmd [[let g:loaded_node_provider = 0]]
vim.cmd [[let g:loaded_perl_provider = 0]]
vim.cmd [[let g:loaded_ruby_provider = 0]]

vim.g.snacks_animate = false
