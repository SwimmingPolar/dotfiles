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

-- Window
config.initial_rows = 30
config.initial_cols = 120

-- Window decorations
config.window_decorations = "RESIZE"

-- Font
config.font = wezterm.font("JetBrains Mono NL", { weight = "DemiBold", italic = false })
config.font_size = 13
config.line_height = 1.1

return config
