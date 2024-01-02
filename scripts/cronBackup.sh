#!/bin/bash

# Exit on first error
set -e

# List of files or directories to be backup
list_of_directories=(
  /home/swimmingpolar/scripts
  /home/swimmingpolar/playground
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
      echo "$log_message" >> ~/logs/backup.log
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

# Preserve path of the script when executed to access .ignore file
# .ignore and backup script should be placed at the same directory
script_path=$(dirname $(readlink -f $(basename "$0")))

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

git add .
git commit -m "Update backup"
git push origin main
echo "Commit and push to remote repository"

