#!/bin/bash

# Preserve path of the script when executed to access .ignore file
# .ignore and backup script should be placed at the same directory
script_path=$(dirname $(readlink -f $(basename "$0")))

# Add error handler
source "${script_path}/modules/errorHandler.sh"
# Check github credential
source "${script_path}/modules/gitAuth.sh"

# List of files or directories to be backup
list_of_directories=(
  /home/swimmingpolar/scripts
)

# Define the working and destination directories
workDir=~/_temp
repoDir=_ubuntu
repoURL="https://github.com/SwimmingPolar/_ubuntu.git"
compressedFile="vim.tar.gz"

# Go to the working directory and compress the ~/.vim directory
mkdir -p "$workDir"
cd "$workDir"
echo "- Move to $workDir"

cp -r ~/.vim "./"
echo "- Copy ~/.vim to ./"

# Remove .netrwhist if it exists (user specific file)
if [ -f .vim/.netrwhist ]; then
    rm .vim/.netrwhist
    echo "- Remove .netrwhist file"
fi

# Compress .vim directory
tar -czf "$compressedFile" .vim
echo "- Compress .vim directory"

# Check for ubuntu directory and clone if it doesn't exist
if [ ! -d "$repoDir" ]; then
    git clone "$repoURL" "$repoDir"
    echo "- Clone remote repository"
fi

# CD into the repository directory
cd "$repoDir"

# Delete all fiels in the repository
rm -rf *

# Copy the compressed file to the ubuntu directory and push to GitHub
cp "../$compressedFile" .

if [ -f "$script_path" ]; then
  echo "Without .ignore file, node_modules can be copied"
  exit 10
fi

# Copy any other directories or files listed at the top
for target in "${list_of_directories[@]}"
do
  rsync -av --delete --exclude-from "${script_path}/.ignore" $target ./
done

# Commit and push to remote repository
git add .
git commit -m "Update backup"
git push origin main

