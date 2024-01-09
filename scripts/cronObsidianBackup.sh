#!/bin/bash

# Preserve path of the script when executed to access .ignore file
# .ignore and backup script should be placed at the same directory
script_path=$(dirname $(readlink -f $(basename "$0")))

# Add error handler
source "${script_path}/modules/errorHandler.sh"
# Check github credential
source "${script_path}/modules/gitAuth.sh"

obsidian_path=/mnt/c/Users/swimm/Documents/Dasan\ Desktop/_obsidian

cd "$obsidian_path"

commit_msg=$(date +'%Y-%m-%d')

{
  git add .
  git commit -m "$commit_msg commit by scheduler"
  git push origin main
  
  if [ "$?" -ne 0 ]; then
    exit 10
  fi
}
