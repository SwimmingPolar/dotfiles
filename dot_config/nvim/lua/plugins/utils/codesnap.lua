return {
  "mistricky/codesnap.nvim",
  build = "make build_generator",
  keys = {
    { "<leader>xc", "<cmd>CodeSnap<cr>", mode = "x", desc = "Save selected code snapshot into clipboard" },
    { "<leader>xs", "<cmd>CodeSnapSave<cr>", mode = "x", desc = "Save selected code snapshot" },
  },
  opts = {
    save_path = "~/Desktop/",
    has_breadcrumbs = true,
    bg_color = "#535c68",
    mac_window_bar = true,
    title = "CodeSnap.nvim",
    code_font_family = "CaskaydiaCove Nerd Font",
    watermark_font_family = "Pacifico",
    watermark = "swimming.polar",
    bg_theme = "default",
    breadcrumbs_separator = "/",
    has_line_number = false,
    show_workspace = false,
    min_width = 0,
    bg_x_padding = 122,
    bg_y_padding = 82,
  },
}
