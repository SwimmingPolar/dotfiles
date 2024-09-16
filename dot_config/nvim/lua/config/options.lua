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
vim.opt.shiftwidth = 4 -- Number of auto-indent spaces
vim.opt.smartindent = true -- Enable smart-indent
vim.opt.smarttab = true -- Enable smart-tabs
vim.opt.softtabstop = 4 -- Number of spaces per Tab
vim.opt.tabstop = 4 -- Number of spaces per Tab
vim.opt.undolevels = 1000 -- Number of undo levels
vim.opt.swapfile = false -- No swap files
vim.opt.virtualedit = "block" -- Virtual block mode

vim.diagnostic.config({
    float = {
        border = "rounded",
    },
})

vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
