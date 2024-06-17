local wezterm = require("wezterm")

local config = {}

require("./lua/autocmds")

-------------------------
--- WSL Domain Config ---
-------------------------
config.wsl_domains = {
	{
		name = "WSL:Ubuntu-22.04",
		distribution = "Ubuntu-22.04",
		username = "swimmingpolar",
		default_cwd = "~",
	},
}
config.default_domain = "WSL:Ubuntu-22.04"

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
config.window_background_opacity = 0.9
config.win32_system_backdrop = "Tabbed"
config.window_decorations = "RESIZE"
-- Window size
config.initial_rows = 30
config.initial_cols = 120
-- Font
config.font = wezterm.font({
	family = "JetBrainsMonoNL Nerd Font",
	weight = "Medium",
})
config.font_size = 10
config.line_height = 1.1

return config
