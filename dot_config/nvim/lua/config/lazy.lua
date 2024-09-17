local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)
require("lazy").setup({
    spec = {
        { "LazyVim/LazyVim", import = "lazyvim.plugins" },
        { import = "plugins.coding" },
        { import = "plugins.ui" },
        { import = "plugins.utils" },
        { import = "plugins.disabled_plugins" },
        { import = "plugins.leetcode" },
        { import = "plugins.custom" },
    },
    defaults = {
        lazy = false,
        version = false, -- always use the latest git commit
    },
    install = { colorscheme = { "catppucin", "gruvbox-material" } },
    checker = { enabled = true, notify = false }, -- automatically check for plugin updates
    ui = {
        icons = {
            ft = " ",
            lazy = "󰂠  ",
            loaded = " ",
            not_loaded = " ",
        },
        border = "single",
        backdrop = 70,
    },
    performance = {},
})

-- load highlights
require("config.highlights")
