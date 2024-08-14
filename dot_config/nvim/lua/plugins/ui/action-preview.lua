-- https://github.com/aznhe21/actions-preview.nvim
-- @TODO: Reconfig keymap and add whichkey

return {
  "aznhe21/actions-preview.nvim",
  keys = {
    {
      "<leader>cp",
      "<cmd>lua require('actions-preview').code_actions<CR>",
      mode = { "v", "n" },
      desc = "Preview code action",
    },
  },
  config = true,
}
