#!/bin/bash

FIGLET_PATH=$(dirname $0)

# Clear screen
printf "\033[2J\033[H"
# Print figlet
python3 "$FIGLET_PATH/generate_layout.py" 90 25 >"$FIGLET_PATH/layout.txt"
python3 "$FIGLET_PATH/overlap_cats.py" "$FIGLET_PATH/welcome.cat" "$FIGLET_PATH/layout.txt" 
rm "$FIGLET_PATH/layout.txt" >/dev/null 2>&1 || true

