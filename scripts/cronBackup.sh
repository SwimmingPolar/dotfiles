#!/bin/bash

# Preserve path of the script when executed to access .ignore file
# .ignore and backup script should be placed at the same directory
script_path=$(dirname $(readlink -f $(basename "$0")))

# Add error handler
source "${script_path}/modules/errorHandler.sh"
# Check github credential
source "${script_path}/modules/gitAuth.sh"

# List of directories to backup
list_of_directories=(
  ~/.oh-my-bash
  ~/scripts
  ~/.vim
  ~/.config/nvim
)
# List of files to backup
list_of_files=(
  ~/.bashrc
  ~/.gitconfig
)
# Files under this directory will be copied to root directory of the repo
files_dir=~/._ubuntu

# Define the working and destination directories
workDir=~/_temp
repoDir=_ubuntu
repoURL="https://github.com/SwimmingPolar/_ubuntu.git"

cleanup() {
  rm -rf "$workDir/$repoDir"
}

trap cleanup EXIT

# Go to the working directory 
mkdir -p "$workDir"
cd "$workDir"
echo "- Move to $workDir"

# Check for ubuntu directory and clone if it doesn't exist
if [ ! -d "$repoDir" ]; then
    git clone "$repoURL" "$repoDir"
    echo "- Clone remote repository"
fi

# CD into the repository directory
cd "$repoDir"

# Delete all fiels in the repository
rm -rf *

if [ -f "$script_path" ]; then
  echo "Without .ignore file, node_modules can be included in backup"
  exit 10
fi

# Copy directories
for directory in "${list_of_directories[@]}"
do
  rsync -av --delete --exclude-from "${script_path}/.ignore" $directory ./
done

# Copy files
for file in "${list_of_files[@]}"
do
  cp $file ./
done

# Copy all from ~/._ubuntu
cp "$files_dir"/* ./

# Commit and push to remote repository
git add .
git commit -m "$(date +'%Y-%m-%d') commit by scheduler"
git push origin main

