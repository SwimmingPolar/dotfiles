local padding = string.rep("\n", 7)
local buttons = {
  {
    action = "lua LazyVim.pick()()",
    desc = " Find File",
    icon = " ",
    key = "f",
  },
  {
    action = "ene | startinsert",
    desc = " New File",
    icon = " ",
    key = "n",
  },
  {
    action = 'lua LazyVim.pick("oldfiles")()',
    desc = " Recent Files",
    icon = " ",
    key = "r",
  },
  {
    action = 'lua LazyVim.pick("live_grep")()',
    desc = " Find Text",
    icon = " ",
    key = "g",
  },
  {
    action = "lua LazyVim.pick.config_files()()",
    desc = " Config",
    icon = " ",
    key = "c",
  },
  {
    action = 'lua require("persistence").load()',
    desc = " Restore Session",
    icon = " ",
    key = "s",
  },
  {
    action = "LazyExtras",
    desc = " Lazy Extras",
    icon = " ",
    key = "x",
  },
  {
    action = "Lazy",
    desc = " Lazy",
    icon = "󰒲 ",
    key = "l",
  },
  {
    action = function()
      vim.api.nvim_input "<cmd>qa<cr>"
    end,
    desc = " Quit",
    icon = " ",
    key = "q",
  },
}

for _, button in ipairs(buttons) do
  button.icon_hl = "Blue"
  button.key_hl = "Orange"
  button.key_format = " [%s]"
  button.desc = button.desc .. string.rep(" ", 45 - #button.desc)
end

return {
  "nvimdev/dashboard-nvim",
  opts = {
    config = {
      header = vim.split(padding, "\n"),
      center = buttons,
      footer = {},
    },
  },
}
