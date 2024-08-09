-- https://github.com/andrewferrier/debugprint.nvim

return {
  "andrewferrier/debugprint.nvim",
  -- The 'keys' and 'cmds' sections of this configuration are optional and only needed if
  -- you want to take advantage of `lazy.nvim` lazy-loading. If you decide to
  -- customize the keys/commands (see below), you'll need to change these too.
  keys = {
    { "g?", mode = "n" },
    { "g?", mode = "x" },
  },
  cmd = {
    "ToggleCommentDebugPrints",
    "DeleteDebugPrints",
  },
  opts = {
    keymaps = {
      normal = {
        plain_below = "g?p",
        plain_above = "g?P",
        variable_below = "g?v",
        variable_above = "g?V",
        variable_below_alwaysprompt = nil,
        variable_above_alwaysprompt = nil,
        textobj_below = "g?o",
        textobj_above = "g?O",
        toggle_comment_debug_prints = nil,
        delete_debug_prints = nil,
      },
      visual = {
        variable_below = "g?v",
        variable_above = "g?V",
      },
    },
    commands = {
      toggle_comment_debug_prints = "ToggleCommentDebugPrints",
      delete_debug_prints = "DeleteDebugPrints",
    },
  },
}
