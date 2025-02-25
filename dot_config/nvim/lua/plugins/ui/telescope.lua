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
    pickers = {
      buffers = {
        previewer = false,
        mode = "normal",
        theme = "dropdown",
        initial_mode = "normal",
      },
    },
    extensions = {
      import = {
        initial_mode = "normal",
        theme = "dropdown",
        results_title = false,
        sorting_strategy = "ascending",
        layout_strategy = "center",
        layout_config = {
          preview_cutoff = 1, -- Preview should always show (unless previewer = false)
          width = function(_, max_columns, _)
            return math.min(max_columns, 80)
          end,
          height = function(_, _, max_lines)
            return math.min(max_lines, 15)
          end,
        },
        border = true,
        borderchars = {
          { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
          prompt = { "─", "│", " ", "│", "┌", "┐", "│", "│" },
          results = { "─", "│", "─", "│", "├", "┤", "┘", "└" },
          preview = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
        },
      },
    },
  },
}
