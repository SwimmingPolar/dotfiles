#!/bin/bash
# 
# Github cli installtation and authentication
#

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
echo "- Github credential check out"

