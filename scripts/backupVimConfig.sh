#!/bin/bash

# Exit on first error
set -e

# List of files or directories to be backup
list_of_directories=(
  /home/swimmingpolar/scripts
)

exit_handler() {
    # Preserve error code before next command
    exit_status=$?

    # Cleanup
    cd "$workDir"
    rm -f "$compressedFile"
    rm -rf "$repoDir"
    rm -rf .vim

    # Stop directing stdout
    exec >&-

    if [ $exit_status -ne 0 ]; then
      log_message="Script exited with error code $exit_status"
      mkdir -p ~/logs
      echo "$log_message" >> ~/logs/vim-backup.log
    fi
}

trap exit_handler EXIT ERR

# Start directing stdout to /dev/null
exec >/dev/null

# check for github cli and install
dpkg -l gh | grep gh
if [ $? -ne 0 ]; then
  echo "- Install github cli"
  sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0
  sudo apt-add-repository https://cli.github.com/packages
  sudo apt update
  sudo apt -y install gh
fi

# check git hub cli auth status
gh auth status
if [ $? -ne 0 ]; then
  gh auth login
fi
echo "- Github credential check"

# Define the working and destination directories
workDir=~/_temp
repoDir=ubuntu
repoURL="https://github.com/SwimmingPolar/ubuntu.git"
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

# Ensure the branch is main and pull the latest changes
cd "$repoDir"
git checkout main
git pull origin main
echo "- Checkout and pull main branch"

# Copy the compressed file to the ubuntu directory and push to GitHub
cp "../$compressedFile" .
git add "$compressedFile"

# Copy any other directories or files listed at the top
for target in "${list_of_directories[@]}"
do
  cp -r $target .
  git add $(basename "$target")
done

git commit -m "Update $compressedFile"
git push origin main
echo "Commit and push to remote repository"

