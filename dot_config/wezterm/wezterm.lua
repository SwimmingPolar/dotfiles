local wezterm = require("wezterm")

local config = wezterm.config_builder()
config.default_cwd = "~"

-- Theme
config.color_scheme = "Gruvbox dark, soft (base16)"

-- Padding
config.window_padding = {}
config.window_padding.left = 0
config.window_padding.right = 0
config.window_padding.top = 0
config.window_padding.bottom = 0

-- config.tab_bar_at_bottom = true
config.enable_tab_bar = false
config.tab_bar_at_bottom = true

-- Window
config.initial_rows = 32
config.initial_cols = 120

-- Window appearance
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.925

-- Font
config.font = wezterm.font_with_fallback({
	{ family = "JetBrains Mono NL", italic = false, weight = "Medium" },
})
config.font_size = 13
config.line_height = 1.175
config.front_end = "OpenGL"
config.freetype_load_target = "Light"
config.freetype_render_target = "HorizontalLcd"
config.cell_width = 0.9

config.keys = {
	{
		mods = "CTRL|SHIFT",
		key = "t",
		action = wezterm.action_callback(function(win, pane)
			local overrides = win:get_config_overrides() or {}
			local tab_visibility = overrides.enable_tab_bar
			if tab_visibility then
				overrides.enable_tab_bar = false
			else
				overrides.enable_tab_bar = true
			end
			win:set_config_overrides(overrides)

			wezterm.log_info("tab bar is " .. tostring(overrides.enable_tab_bar))
		end),
	},
}

return config
