local wezterm = require("wezterm")

local config = {}

-------------------------
-- Colors & Appearance --
-------------------------

-- Theme
config.color_scheme = "Gruvbox dark, soft (base16)"
-- Tab bar
config.tab_bar_at_bottom = true
-- Padding
config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

-- Window decorations
config.win32_system_backdrop = "Tabbed"
config.window_decorations = "RESIZE"

-- Font
config.font = wezterm.font("JetBrains Mono")
config.font_size = 12
config.line_height = 1.2
config.cell_width = 1.05

return config
