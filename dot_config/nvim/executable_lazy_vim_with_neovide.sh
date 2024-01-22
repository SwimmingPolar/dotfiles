#!/usr/bin/zsh

#kitty @ set-spacing padding=0
exec /usr/bin/neovide --frame=none -- -u "/home/swimmingpolar/.config/nvim/init.lua" "$@" -V9"/home/swimmingpolar/.cache/nvim/nvim.log"
#kitty @ set-spacing padding=default
