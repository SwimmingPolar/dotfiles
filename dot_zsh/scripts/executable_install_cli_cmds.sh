#!/bin/bash

install_cmds() {
  local cli_cmds=(
    neovim
    bpytop
    tlrc
    lf
    chezmoi
    bat
    # eza
  )
  for cmd in "${cli_cmds[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
      echo "$(green Installing:) $cmd..."
      brew install "$cmd"
    fi
  done
}
# Check if 'brew' is installed
if ! command -v brew &>/dev/null; then
  echo "$(yellow Warning:) Homebrew is not installed."
  echo "$(yellow Install Homebrew and restart the shell.)"
else
  install_cmds
fi
