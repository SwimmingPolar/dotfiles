#!/bin/bash

# Check  who's running the script
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

# Make sure all variales are predefined.
set -u

# Path variables
HOME_DIR=$(getent passwd "$SUDO_USER" | cut -d: -f6)
BASE_DIR=$(dirname $(readlink -f $0))
LOG_FILE="$BASE_DIR/bootstrap.log"
SHELL_CONFIGS_BACKUP="$HOME_DIR/.config/.shell-configs-backup"
# Make backup directory for configs
mkdir -p "$SHELL_CONFIGS_BACKUP"

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
	cat "$LOG_FILE"
	rm -f "$LOG_FILE"
	exit 1
}
trap exitOnError ERR

# Disable terminal echo (cr)
# When enter is pressed, last command line is copied.
# This prevents the described behavior.
stty -echo

# Load ui functions (message_box, message_box_clear)
source "$BASE_DIR/modules/ui"

# Show spinner for instead of stdout messages
spinner() {
	# make sure we use non-unicode character type locale
	# (that way it works for any locale as long as the font supports the characters)
	local LC_CTYPE=C

	# Process Id of the previous running command
	local pid=$!
	local spin='-\|/'
	local charwidth=1
	local message=${1:-"processing..."}

	local i=0
	# Cursor will be hidden 
	tput civis 
	# While last backgrounded process is running,
	# Background process is a command delegated to 
	# execute_installation function below
	while kill -0 $pid 2>/dev/null; do
		local i=$(((i + $charwidth) % ${#spin}))
		# Clear from the beginning of the line to the end
		# and move to beginning of the line
		# -e: escape ascii
		# -n: no new line
		echo -en "\033[1K\033[G"
		# Print spin character at current i index
		printf "$message %s" "${spin:$i:$charwidth}"

		sleep .1
	done
	# Restore cursor visibility
	tput cnorm
	# Wait to get exit code from background process
	wait $pid 
	echo -en "\033[1K\033[G"
	# Return exit code of delegated process(command)
	return $?
}

# Execute command and show message boxes
execute_installation() {
	# Exit immediately on error
	set -e

	command=$1
	start_msg=$2
	finish_msg=$3
	loading_msg=${4:-"$start_msg"}

	if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
		echo "wrong usage of execute_installtation function"
		exit 100
	fi

	# show message box with text
	message_box "$start_msg"

	# If command has curl, shell will invoke it after downloading
	if [[ $command == *"curl"* ]]; then
	    bash -c "$command" "--unattended" "--unattended" >/dev/null 2>>"$LOG_FILE" &
	# Otherwise, run the command as it is
	else
	    $command >/dev/null 2>>"$LOG_FILE" &
	fi

	# Show spinner 
	pid=spinner "$loading_msg"
	# Get exit code of command and
	# check for any error
	wait $pid
	err=$?

	if [ $err -ne 0 ]; then
		echo "Exiting with error code: $err"
		cat "$LOG_FILE"
		exit $err
	fi

	# Clear the message box and show completed message box with different text
	message_box_clear "$finish_msg"
	echo ""
	sleep 1

	# Disable flag
	set +e
}

# Install all necessary packages
initBootstrap() {
	apt-get update
	apt-get install -y dialog whiptail
	apt-get install -y apt-utils
	apt-get install -y snapd 
	apt-get install -y git curl wget
	apt-get install -y ripgrep unzip vim apt
	export PATH="/snap/bin:$PATH"
	systemctl restart snapd.seeded.service
	systemctl restart snapd.service
	snap install core
}

# Install dependencies
execute_installation \
"initBootstrap" \
"installing dependencies..." \
"Dependencies Installed"

# Install oh-my-bash
mv "$HOME_DIR/.oh-my-bash" "$SHELL_CONFIGS_BACKUP/" 2>&1 >/dev/null
execute_installation \
'curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh'
"Installing oh-my-bash for fallback" \
"OMB Installation Completed" \
"installing omb..."

# Install zsh
execute_installation \
'apt install zsh --yes' \
"Installing zsh" \
"zsh Installation Completed" \
"installing zsh..."

# Install oh-my-zsh
mv "$HOME_DIR/.oh-my-zsh" "$SHELL_CONFIGS_BACKUP/" 2>&1 >/dev/null
execute_installation \
'curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh' \
"Installing oh-my-zsh" \
"OMZ Installation Completed" \
"installing oh-my-zsh..."

# Install nvim
execute_installation \
'snap install nvim --classic' \
"Installing nvim" \
"Neovim Installation Completed" \
"installing nvim..."
mkdir -p "$HOME_DIR/.local/bin/"
ln -s /snap/bin/nvim "$HOME_DIR/.local/bin/" >/dev/null 2>>$LOG_FILE

# Backup before installing nvim theme
{
NVIM_BACKUP="$SHELL_CONFIGS_BACKUP/nvim/"
mkdir -p "$NVIM_BACKUP"
mv "$HOME_DIR/.config/nvim" "$NVIM_BACKUP"
mv "$HOME_DIR/.local/share/nvim" "$NVIM_BACKUP"
mv "$HOME_DIR/.local/state/nvim" "$NVIM_BACKUP"
mv "$HOME_DIR/.cache/nvim" "$NVIM_BACKUP"
} >/dev/null 2>&1

# Install NvChad
execute_installation \
"git clone https://github.com/NvChad/NvChad $HOME_DIR/.config/nvim --depth 1" \
"Installing NvChad" \
"NvChad Installation Completed" \
"installing NvChad..."

# Install chezmoi
execute_installation \
'snap install chezmoi --classic' \
"Installing chezmoi" \
"chezmoi Installation Completed" \
"installing chezmoi..."

# Install starship
execute_installation \
'curl -sS https://starship.rs/install.sh' \
"Installing starship" \
"starship Installation Completed" \
"installing starship..."

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

    # copy original to backup folder if any (~/.config/shell-configs-backup/)
    cp -r "$dest_file" "$SHELL_CONFIGS_BACKUP/"
    # remove orignal
    rm -rf "$dest_file"
    # copy config files to appropriate path
    cp -r "$source_file" "$dest_file"
}
# Iterate over the files and copy them
set +e
for src in "${!files_to_copy[@]}"; do
    copy_with_backup "$src" "${files_to_copy[$src]}" >/dev/null 2>&1
done
set -e

ln -s "$HOME_DIR/.starship.toml" "$HOME_DIR/.config/starship.toml" >/dev/null 2>>$LOG_FILE

# Install wslu for wsl utilities
# This is to use host browser instead of wsl browser.
{
add-apt-repository ppa:wslutilities/wslu
apt update
apt install wslu
apt install ubuntu-wsl
} >/dev/null 2>>$LOG_FILE & spinner wslu

export BROWSER=wslview >> "$HOME_DIR/.shrc"
export PATH="/snap/bin:/$HOME_DIR/.local/bin:$PATH" >> "$HOME_DIR/.shrc"

# Ignore if it errors out or not. It's for fun.
set +e
sudo snap install lolcat >/dev/null 2>&1 & spinner finale🎉
set -e

echo "+-----------------------------------------+"
echo "|           Bootstrap Successful          |"
echo "+-----------------------------------------+"
echo "restart the terminal"
