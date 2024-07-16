-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- General
vim.opt.number = true -- Show line numbers
vim.opt.wrap = false -- No line wrap
vim.opt.showbreak = "+++" -- Wrap-broken line prefix
vim.opt.textwidth = 100 -- Line wrap (number of cols)
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

-- Advanced
vim.opt.undolevels = 1000 -- Number of undo levels
vim.opt.backspace = "indent,eol,start" -- Backspace behaviour
