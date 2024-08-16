local wezterm = require("wezterm")

local config = {}

-- Theme
config.color_scheme = "Gruvbox dark, soft (base16)"

-- Padding
config.window_padding = {
	left = "5",
	right = "5",
	top = "0",
	bottom = "0",
}

-- config.tab_bar_at_bottom = true
config.enable_tab_bar = false

-- Window
config.initial_rows = 32
config.initial_cols = 120

-- Window decorations
config.window_decorations = "RESIZE"

-- Font
config.font = wezterm.font("JetBrains Mono NL", { weight = "Bold", italic = false })
config.font_size = 13
config.line_height = 1.175

return config
