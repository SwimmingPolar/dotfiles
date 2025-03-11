-- function Move_line_to_top()
--     -- Get the current cursor position
--     local cursor = vim.api.nvim_win_get_cursor(0)
--     local current_line = cursor[1]
--
--     -- Get the current line content
--     local line_content = vim.api.nvim_get_current_line()
--
--     -- Delete the current line
--     vim.api.nvim_del_current_line()
--
--     -- Insert the line at the top of the file
--     vim.api.nvim_buf_set_lines(0, 0, 0, false, {line_content})
--
--     -- Adjust the cursor position if it was above the first line
--     if current_line > 1 then
--         vim.api.nvim_win_set_cursor(0, {current_line - 1, cursor[2]})
--     end
-- end

return {
  "nvim-telescope/telescope.nvim",
  opts = {
    defaults = {
      mappings = {
        i = {
          ["<M-p>"] = require("telescope.actions.layout").toggle_preview,
        },
        n = {
          ["<M-p>"] = require("telescope.actions.layout").toggle_preview,
        },
      },
    },
  },
}
