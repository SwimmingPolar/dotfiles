-- https://github.com/chrisgrieser/nvim-spider

-- Example Strings:
-- if foo:find("%d") and foo == bar then print("[foo] has" .. bar) end
-- local myVariableName = FOO_BAR_BAZ

vim.keymap.set("i", "<C-f>", "<Esc>l<cmd>lua require('spider').motion('w')<CR>i")
vim.keymap.set("i", "<C-b>", "<Esc><cmd>lua drequire('spider').motion('b')<CR>i")

return {
  "chrisgrieser/nvim-spider",
  lazy = true,
  opts = {},
  keys = {
    {
      "e",
      "<cmd>lua require('spider').motion('e')<CR>",
      mode = { "n", "o", "x" },
    },
    {
      "w",
      "<cmd>lua require('spider').motion('w')<CR>",
      mode = { "n", "o", "x" },
    },
    {
      "b",
      "<cmd>lua require('spider').motion('b')<CR>",
      mode = { "n", "o", "x" },
    },
  },
}
