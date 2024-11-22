---Need some kind of heuristics to determine if the
---target buffer is a real file or not. For now, is as follow:
local function is_real_file()
    local bufnr = vim.api.nvim_get_current_buf()
    -- check if buf is nil or is not number which is not correct bufnr
    if not bufnr or type(bufnr) ~= "number" then
        return false
    end

    if not vim.api.nvim_buf_is_valid(bufnr) then
        return false
    end

    -- Assumed, any real file has a file name
    local bufname = vim.api.nvim_buf_get_name(bufnr)
    if bufname == "" then
        return false
    end

    -- Also assumed, any file has some sort of file type
    local filetype = vim.api.nvim_get_option_value("filetype", { buf = bufnr })
    -- and should be listed(visible to users, us)
    local buflisted = vim.api.nvim_get_option_value("buflisted", { buf = bufnr })

    return filetype ~= "" and buflisted == true
end

local function toggle_zen_mode()
    if not is_real_file() then
        return
    end

    vim.cmd("ZenMode")
end

return {
    "folke/zen-mode.nvim",
    opts = {
        window = {
            backdrop = 0.8, -- shade the backdrop of the Zen window. Set to 1 to keep the same as Normal
            -- height and width can be:
            -- * an absolute number of cells when > 1
            -- * a percentage of the width / height of the editor when <= 1
            -- * a function that returns the width or the height
            width = 160, -- width of the Zen window
            height = 1, -- height of the Zen window
            -- by default, no options are changed for the Zen window
            -- uncomment any of the options below, or add other vim.wo options you want to apply
            options = {
                -- ruler = false,
                -- signcolumn = "no", -- disable signcolumn
                -- number = false, -- disable number column
                -- relativenumber = false, -- disable relative numbers
                -- cursorline = false, -- disable cursorline
                -- cursorcolumn = false, -- disable cursor column
                -- foldcolumn = "0", -- disable fold column
                -- list = false, -- disable whitespace characters
            },
        },
        plugins = {
            -- disable some global vim options (vim.o...)
            -- comment the lines to not apply the options
            options = {
                enabled = true,
                ruler = false, -- disables the ruler text in the cmd line area
                showcmd = false, -- disables the command in the last line of the screen
                -- you may turn on/off statusline in zen mode by setting 'laststatus'
                -- statusline will be shown only if 'laststatus' == 3
                laststatus = 0, -- turn off the statusline in zen mode
            },
            twilight = { enabled = true }, -- enable to start Twilight when zen mode opens
            gitsigns = { enabled = false }, -- disables git signs
            tmux = { enabled = false }, -- disables the tmux statusline
            todo = { enabled = false }, -- if set to "true", todo-comments.nvim highlights will be disabled
            -- this will change the font size on wezterm when in zen mode
            -- See alse also the Plugins/Wezterm section in this projects README
            wezterm = {
                enabled = true,
                -- can be either an absolute font size or the number of incremental steps
                -- font = "+1", -- (10% increase per step)
            },
        },
        -- callback where you can add custom code when the Zen window opens
        -- on_open = function(win) end,
        -- callback where you can add custom code when the Zen window closes
        -- on_close = function() end,
    },
    config = function(_, opts)
        require("zen-mode").setup(opts)

        vim.keymap.set("n", "\\z", toggle_zen_mode, { noremap = true, silent = true, desc = "Toggle zen" })
    end,
}
