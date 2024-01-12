#!/bin/bash

# START OF SCRIPT
# Check if running the script with sudo
if [[ "$EUID" -ne 0 ]]; then
	echo "This script requires root privilege. Please run it with sudo"
	exit 10
fi

if ! [[ "$USER" == "root" && "$SUDO_USER" != "$(whoami)" ]]; then
	echo "This script requires root privilege but should not be ran as root"
	exit 10
fi

if [[ "$(ps --no-headers -o comm 1)" != "systemd" ]]; then
	echo "Systemd is not running"
	exit 20
fi

set -euo pipefail
shutdown() {
	# enable terminal echo
	stty echo
	# reset cursor
	tput cnorm 
}
trap shutdown EXIT
exitOnError() {
	# enable terminal echo
	stty echo
	echo "An error occurred. Check ./bootstrap.log"
	exit 1
}
trap exitOnError ERR

stty -echo

function spinner() {
	# make sure we use non-unicode character type locale
	# (that way it works for any locale as long as the font supports the characters)
	local LC_CTYPE=C

	# Process Id of the previous running command
	local pid=$!
	local spin='-\|/'
	local charwidth=1
	local message=${1:-"processing..."}

	local i=0
	# cursor invisible
	tput civis 
	while kill -0 $pid 2>/dev/null; do
		local i=$(((i + $charwidth) % ${#spin}))
		echo -en "\033[1K\033[G"
		printf "$message %s" "${spin:$i:$charwidth}"

		sleep .1
	done
	tput cnorm
	wait $pid # capture exit code
	echo -en "\033[1K\033[G"
	return $?
}

function snap_install() {
	install() {
		snap install "$package" --classic
	}

	package=$1

	set +e
		install
	set -e

	if [ $? -eq 1 ]; then
		install
	elif [ $? -gt 1 ]; then
		exit 40
	fi
}

HOME_DIR=$(getent passwd "$SUDO_USER" | cut -d: -f6)
BASE_DIR=$(dirname $(readlink -f $0))
LOG_FILE="$BASE_DIR/bootstrap.log"

initBootstrap() {
	apt-get update
	apt-get install -y dialog whiptail
	apt-get install -y apt-utils
	apt-get install -y snapd 
	apt-get install -y git curl wget
	apt-get install -y ripgrep unzip vim apt
	PATH="/snap/bin:$PATH"
	systemctl restart snapd.seeded.service
	systemctl restart snapd.service
	snap install core
}

initBootstrap >/dev/null 2>>$LOG_FILE & spinner "installing dependencies..."

# Install oh-my-bash
echo "+------------------------------------+"
echo "| Installing oh-my-bash for fallback |"
echo "+------------------------------------+"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended >/dev/null 2>>$LOG_FILE & spinner oh-my-bash
echo -e "\033[4A"
echo -e "\e[38;5;232;48;5;255m+----------------------------------+\e[0m\033[K"
echo -e "\e[38;5;232;48;5;255m|    OMB Installation Completed    |\e[0m\033[K"
echo -e "\e[38;5;232;48;5;255m+----------------------------------+\e[0m\033[K"

echo ""
sleep 1

# Install zsh
echo "+----------------------------------+"
echo "|           Installing zsh         |"
echo "+----------------------------------+"
apt install zsh --yes >/dev/null 2>>$LOG_FILE & spinner zsh
echo -e "\033[4A"
echo -e "\e[38;5;232;48;5;255m+----------------------------------+\e[0m\033[K"
echo -e "\e[38;5;232;48;5;255m|   zsh Installation Completed     |\e[0m\033[K"
echo -e "\e[38;5;232;48;5;255m+----------------------------------+\e[0m\033[K"

echo ""
sleep 1

# Install oh-my-zsh
echo "+----------------------------------+"
echo "|       Installing oh-my-zsh       |"
echo "+----------------------------------+"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >/dev/null 2>>$LOG_FILE & spinner oh-my-zsh
echo -e "\033[4A"
echo -e "\e[38;5;232;48;5;255m+----------------------------------+\e[0m\033[K"
echo -e "\e[38;5;232;48;5;255m|    OMZ Installation Completed    |\e[0m\033[K"
echo -e "\e[38;5;232;48;5;255m+----------------------------------+\e[0m\033[K"

echo ""
sleep 1

#Install nvim
echo "+----------------------------------+"
echo "|        Installing nvim           |"
echo "+----------------------------------+"
snap_install nvim >/dev/null 2>>$LOG_FILE & spinner nvim
echo -e "\033[4A"
echo -e "\e[38;5;232;48;5;255m+----------------------------------+\e[0m\033[K"
echo -e "\e[38;5;232;48;5;255m|  Neovim Installation Completed   |\e[0m\033[K"
echo -e "\e[38;5;232;48;5;255m+----------------------------------+\e[0m\033[K"

echo ""
sleep 1
mkdir -p "$HOME_DIR/.local/bin"
ln -s /snap/bin/nvim "$HOME_DIR/.local/bin/nvim" >/dev/null 2>>$LOG_FILE
sleep 1

# Install NvChad
echo "+----------------------------------+"
echo "|         Installing NvChad        |"
echo "+----------------------------------+"
# optional but recommended
set +e
{
NVIM_BACKUP="$HOME_DIR/.config/.shell-configs-backup/nvim"
mkdir -p "$NVIM_BACKUP"
mv "$HOME_DIR/.config/nvim" "$NVIM_BACKUP/"
mv "$HOME_DIR/.local/share/nvim" "$NVIM_BACKUP/"
mv "$HOME_DIR/.local/state/nvim" "$NVIM_BACKUP/"
mv "$HOME_DIR/.cache/nvim" "$NVIM_BACKUP/"
} >/dev/null 2>&1
set -e
git clone https://github.com/NvChad/NvChad "$HOME_DIR/.config/nvim" --depth 1 >/dev/null 2>>$LOG_FILE & spinner NvChad
echo -e "\033[4A"
echo -e "\e[38;5;232;48;5;255m+----------------------------------+\e[0m\033[K"
echo -e "\e[38;5;232;48;5;255m|  NvChad Installation Completed   |\e[0m\033[K"
echo -e "\e[38;5;232;48;5;255m+----------------------------------+\e[0m\033[K"

echo ""
sleep 1

# move ~/.oh-my-zsh and ~/.oh-my-bash to ~/.config/shell-configs
{
mv "$HOME_DIR/.oh-my-zsh" "$HOME_DIR/.config/shell-configs/"
mv "$HOME_DIR/.oh-my-bash" "$HOME_DIR/.config/shell-configs/"
} >/dev/null 2>&1

echo "+----------------------------------+"
echo "|        Installing chezmoi        |"
echo "+----------------------------------+"
# Install chezmoi
snap_install chezmoi >/dev/null 2>>$LOG_FILE & spinner chezmoi
echo -e "\033[4A"
echo -e "\e[38;5;232;48;5;255m+----------------------------------+\e[0m\033[K"
echo -e "\e[38;5;232;48;5;255m|  chezmoi Installation Completed  |\e[0m\033[K"
echo -e "\e[38;5;232;48;5;255m+----------------------------------+\e[0m\033[K"
echo ""
sleep 1

echo "+----------------------------------+"
echo "|        Installing starship       |"
echo "+----------------------------------+"
# Install starship
sh -c "$(curl -sS https://starship.rs/install.sh)" "" --yes >/dev/null 2>>LOG_FILE & spinner starship
echo -e "\033[4A"
echo -e "\e[38;5;232;48;5;255m+----------------------------------+\e[0m\033[K"
echo -e "\e[38;5;232;48;5;255m| starship Installation Completed  |\e[0m\033[K"
echo -e "\e[38;5;232;48;5;255m+----------------------------------+\e[0m\033[K"
echo ""
sleep 1

# Before copying rc files, make backups for each one
# Make backup folder ~/.config/.shell-configs-backup
# .bashrc, .zshrc, .vimrc, .vim(if any), ~/.starship.tolm(if any), ~/.config/starship.toml(if any)
SHELL_CONFIGS="$BASE_DIR/shell-configs"
# Define an associative array with source and destination pairs
declare -A files_to_copy=(
    ["$SHELL_CONFIGS/bashrc"]="$HOME_DIR/.bashrc"
    ["$SHELL_CONFIGS/zshrc"]="$HOME_DIR/.zshrc"
    ["$SHELL_CONFIGS/shrc"]="$HOME_DIR/.shrc"
    ["$SHELL_CONFIGS/vimrc"]="$HOME_DIR/.vimrc"
    ["$SHELL_CONFIGS/starship.toml"]="$HOME_DIR/.starship.toml"
)
# Function to copy a file with a backup
copy_with_backup() {
    local source_file=$1
    local dest_file=$2

    # copy original file/directory to backup folder if any (~/.config/shell-configs-backup/)
    set +e
    mkdir -p "$HOME_DIR/.config/.shell-configs-backup"
    cp -r "$dest_file" "$HOME_DIR/.config/.shell-configs-backup/"
    # remove orignal
    rm -rf "$dest_file"
    set -e
    # copy config files to appropriate path
    cp -r "$source_file" "$dest_file"
}
# Iterate over the files and copy them
for src in "${!files_to_copy[@]}"; do
    copy_with_backup "$src" "${files_to_copy[$src]}" >/dev/null 2>&1
done

ln -s "$HOME_DIR/.starship.toml" "$HOME_DIR/.config/starship.toml" >/dev/null 2>>$LOG_FILE

# Install wslu for wsl utilities
# This is to use host browser instead of wsl browser.
{
add-apt-repository ppa:wslutilities/wslu
apt update
apt install wslu
apt install ubuntu-wsl
} >/dev/null 2>>$LOG_FILE & spinner wslu

export BROWSER=wslview >> "$HOME_DIR/.bashrc"
export BROWSER=wslview >> "$HOME_DIR/.zshrc"

source "$HOME_DIR/.bashrc"
source "$HOME_DIR/.zshrc"

# Ignore if it errors out or not. It's for fun.
set +e
sudo snap install lolcat >/dev/null 2>&1 & spinner finale🎉
set -e

echo "+-----------------------------------------+"
echo "|           Bootstrap Successful          |"
echo "+-----------------------------------------+"
