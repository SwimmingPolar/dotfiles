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
    },
    defaults = {
        lazy = false,
        version = false, -- always use the latest git commit
    },
    install = { colorscheme = { "gruvbox-material" } },
    checker = { enabled = true, notify = false }, -- automatically check for plugin updates
    ui = {
        icons = {
            ft = " ",
            lazy = "󰂠  ",
            loaded = " ",
            not_loaded = " ",
        },
        border = "rounded",
        backdrop = 70,
    },
    performance = {
        rtp = {
            disabled_plugins = {
                "2html_plugin",
                "tohtml",
                "getscript",
                "getscriptPlugin",
                "gzip",
                "logipat",
                "netrw",
                "netrwPlugin",
                "netrwSettings",
                "netrwFileHandlers",
                "matchit",
                "tar",
                "tarPlugin",
                "rrhelper",
                "spellfile_plugin",
                "vimball",
                "vimballPlugin",
                "zip",
                "zipPlugin",
                "tutor",
                "rplugin",
                "syntax",
                "synmenu",
                "optwin",
                "compiler",
                "bugreport",
                "ftplugin",
            },
        },
    },
})

-- set additional highlights

-- Change bad spell undercurl color
vim.api.nvim_set_hl(0, "SpellBad", {
    sp = "#8bba7f",
    undercurl = true,
})

-- default highlight groups
vim.api.nvim_set_hl(0, "NormalFloat", {})
vim.api.nvim_set_hl(0, "FloatBorder", {})
vim.api.nvim_set_hl(0, "FloatTitle", {
    bold = true,
    ctermfg = 208,
    ctermbg = "",
    fg = "#f28534",
    bg = "",
})

-- Neo-tree
vim.api.nvim_set_hl(0, "NeoTreeNormal", {
    force = true,
})
vim.api.nvim_set_hl(0, "NeoTreeEndOfBuffer", {})
vim.api.nvim_set_hl(0, "NeoTreeNormalNC", {
    link = "NeoTreeNormal",
})
vim.api.nvim_set_hl(0, "NeoTreeFloatNormal", {
    link = "NeoTreeNormal",
})
vim.api.nvim_set_hl(0, "NeoTreeFloatNormal", {
    link = "NeoTreeNormal",
})
vim.api.nvim_set_hl(0, "NeoTreeFloatTitle", {
    link = "NeoTreeNormal",
})
vim.api.nvim_set_hl(0, "NeoTreeFloatBorder", {
    link = "NeoTreeNormal",
})

-- Whichkey
vim.api.nvim_set_hl(0, "WhichKeyNormal", {})

-- LSP Info
vim.api.nvim_set_hl(0, "LspInfoBorder", {})
vim.api.nvim_set_hl(0, "LspInfoTitle", {})
