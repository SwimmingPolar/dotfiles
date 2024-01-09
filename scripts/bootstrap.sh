#!/bin/sudo /bin/bash

# Check if running the script with sudo
if [ "$EUID" -ne 0 ]; then
	echo "This script requires root privileges. Please run it with sudo."
	exit 1
fi

# Check if snap is installed
if ! [ -x "$(command -v snap)" ]; then
	echo "Snap is not installed. Please install snapd first."
	exit 1
fi

# Make temporary directory and cd to it
mkdir -p ~/temp
cd ~/temp

# Install oh-my-bash
echo "+----------------------------------+"
echo "|Installing oh-my-bash for fallback|"
echo "+----------------------------------+"
sleep 1
curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh
echo "+----------------------------------+"
echo "|        Download completed        |"
echo "+----------------------------------+"
echo "Configure oh-my-bash to default"
echo "Press any key to continue..."
read
./install.sh --unattended
rm ./install.sh
echo "+----------------------------------+"
echo "|    OMB Installation completed    |"
echo "+----------------------------------+"
sleep 1

# Install zsh
echo "+----------------------------------+"
echo "|           Installing zsh         |"
echo "+----------------------------------+"
sleep 1
apt install zsh --yes
echo "+----------------------------------+"
echo "|   zsh Installation completed     |"
echo "+----------------------------------+"
sleep 1

# Run zsh
zsh

# Make sure working directory is ~/temp
cd ~/temp

# Install oh-my-zsh
echo "+----------------------------------+"
echo "|       Installing oh-my-zsh       |"
echo "+----------------------------------+"
sleep 1
curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
echo "+----------------------------------+"
echo "|        Download completed        |"
echo "+----------------------------------+"
echo "Configure oh-my-zsh to default"
echo "Press any key to continue..."
read
./install.sh --unattended
rm ./install.sh
echo "+----------------------------------+"
echo "|    OMZ Installation completed    |"
echo "+----------------------------------+"
sleep 1

#Install nvim
echo "+----------------------------------+"
echo "|         Installing nvim          |"
echo "+----------------------------------+"
snap install nvim --classic
echo "+----------------------------------+"
echo "|  Neovim Installation completed   |"
echo "+----------------------------------+"
sleep 1
echo "Creating symblic link for nvim"
mkdir -p ~/.local/bin
ln -s /snap/bin/nvim ~/.local/bin/nvim
sleep 1

# Install LazyVim
echo "+----------------------------------+"
echo "|         Installing LazyVim       |"
echo "+----------------------------------+"
# required
mv ~/.config/nvim{,.bak}
# optional but recommended
mv ~/.local/share/nvim{,.bak}
mv ~/.local/state/nvim{,.bak}
mv ~/.cache/nvim{,.bak}
# clone LazyVim starter
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
echo "+----------------------------------+"
echo "|  LazyVim Installation completed  |"
echo "+----------------------------------+"
sleep 1

# move ~/.oh-my-zsh and ~/.oh-my-bash to ~/.config/shell-configs
mv ~/.oh-my-zsh ~/.config/shell-configs/
mv ~/.oh-my-bash ~/.config/shell-configs/

# Install chezmoi
snap insall chezmoi --classic

# Install starship
curl -sS https://starship.rs/install.sh | sh

# Before copying rc files, make backups for each one
# Make backup folder ~/.config/shell-configs-backup
mkdir -p ~/.config/shell-configs-backup
# .bashrc, .zshrc, .vimrc, .vim(if any), ~/.starship.tolm(if any), ~/.config/starship.toml(if any)
{
	cp ~/.bashrc ~/.config/shell-configs-backup/ -r
	cp ~/.zshrc ~/.config/shell-configs-backup/ -r
	cp ~/.vimrc ~/.config/shell-configs-backup/ -r
	cp ~/.vim ~/.config/shell-configs-backup/ -r
	cp ~/.starship.toml ~/.config/shell-configs-backup/ -r
	cp ~/.config/starship.toml ~/.config/shell-configs-backup/ -r
} >/dev/null 2>&1

# Copy rc files to their corresponding paths
# .bashrc, .zshrc, .shrc to ~/
# .vim to ~/ and make symlink from ~/.vim/vimrc/.vimrc to ~/.vimrc
# .starship.toml to ~/ and make symlink from ~/starship.toml to ~/.config/starship.toml
cp ./shell-configs/bashrc ~/.bashrc
cp ./shell-configs/zshrc ~/.zshrc
cp ./shell-configs/shrc ~/.shrc
cp ./shell-configs/vimrc ~/.vimrc
cp ./shell-configs/starship.toml ~/.starship.toml
ln -s ~/.starship.toml ~/.config/starship.toml

# ~ further configuration later ~

# Install wslu for wsl utilities
# add-apt-repository ppa:wslutilities/wslu
# apt update
# apt install wslu
# apt install ubuntu-wsl
