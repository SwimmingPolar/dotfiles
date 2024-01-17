-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Checks if Neovide is running and allows setting Neovide-specific configurations.
if vim.g.neovide then
  -- Sets the font used by Neovide.
  -- vim.o.guifont = "Noto Sans Mono:h10:#e-subpixelantialias:#h-none"
  vim.o.guifont = "JetBrainsMono Nerd Font:h10:#e-subpixelantialias:#h-none"

  -- Controls spacing between lines.
  vim.opt.linespace = 1.0
  -- Adjusts the scale of the Neovide interface.
  -- vim.g.neovide_scale_factor = 1.0

  -- Sets padding for each side of the Neovide window.
  -- vim.g.neovide_padding_top = 0
  -- vim.g.neovide_padding_bottom = 0
  -- vim.g.neovide_padding_right = 0
  -- vim.g.neovide_padding_left = 0

  -- Helper function for transparency formatting
  local alpha = function()
    return string.format("%x", math.floor(255 * (vim.g.transparency or 0.8)))
  end

  -- Sets the opacity of the Neovide window.
  vim.g.neovide_transparency = 0.8
  -- Sets the background color of the Neovide window.
  vim.g.transparency = 0.8
  -- vim.g.neovide_background_color = "#0f1117" .. alpha()
  vim.g.neovide_background_color = "#fff" .. alpha()

  -- Controls blur radius for floating windows.
  -- vim.g.neovide_floating_blur_amount_x = 2.0
  -- vim.g.neovide_floating_blur_amount_y = 2.0

  -- Configures shadow for floating windows.
  -- vim.g.neovide_floating_shadow = true
  -- vim.g.neovide_floating_z_height = 10
  -- vim.g.neovide_light_angle_degrees = 45
  -- vim.g.neovide_light_radius = 5

  -- Determines scroll animation duration.
  -- vim.g.neovide_scroll_animation_length = 0.3

  -- Configures scroll animation for large distances.
  -- vim.g.neovide_scroll_animation_far_lines = 1

  -- Hides the mouse cursor when typing.
  vim.g.neovide_hide_mouse_when_typing = true

  -- Adjusts underline stroke width.
  -- vim.g.neovide_underline_stroke_scale = 1.0

  -- Sets the theme for Neovide.
  vim.g.neovide_theme = 'auto'

  -- Fixes border and winbar scrolling glitches.
  vim.g.neovide_unlink_border_highlights = true

  -- Sets the refresh rate of Neovide.
  vim.g.neovide_refresh_rate = 143

  -- Sets idle refresh rate.
  -- vim.g.neovide_refresh_rate_idle = 0

  -- Keeps Neovide redrawing all the time.
  vim.g.neovide_no_idle = true

  -- Requires confirmation to quit with unsaved changes.
  vim.g.neovide_confirm_quit = true

  -- Enables fullscreen mode.
  vim.g.neovide_fullscreen = false

  -- Remembers previous window size on startup.
  -- With this option enabled, for some reason, Neovide starts in fullscreen.
  vim.g.neovide_remember_window_size = false
end
