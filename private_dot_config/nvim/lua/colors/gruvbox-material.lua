return {
  "sainnhe/gruvbox-material",
  priority = 1000,
  lazy = false,
  config = function()
    -- Optionally configure and load the colorscheme
    -- directly inside the plugin declaration.
    vim.g.gruvbox_material_enable_italic = true
    vim.g.gruvbox_material_foreground = "mix"
    vim.cmd.colorscheme("gruvbox-material")
  end,
}
