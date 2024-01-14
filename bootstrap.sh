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

# Path variables
HOME_DIR=$(getent passwd "$SUDO_USER" | cut -d: -f6)
BASE_DIR=$(dirname $(readlink -f "$0"))
LOG_FILE="$BASE_DIR/.bootstrap.log"
DOTFILES_BACKUP="$HOME_DIR/.config/.dotfiles.backups"
# Make a backup directory for configs
mkdir -p "$DOTFILES_BACKUP"

shutdown() {
	# enable terminal echo
	stty echo
	# reset cursor
	tput cnorm 
	# remove log file
	rm -f "$LOG_FILE"
}
trap shutdown EXIT
exitOnError() {
	# enable terminal echo
	stty echo
	cat "$LOG_FILE"
	# remove log file
	rm -f "$LOG_FILE"
	exit 1
}
trap exitOnError ERR

# Disable terminal echo
stty -echo

# Load ui functions (message_box, message_box_clear)
source "$BASE_DIR/scripts/modules/ui"

# Show spinner for instead of stdout messages
spinner() {
	# make sure we use non-unicode character type locale
	# (that way it works for any locale as long as the font supports the characters)
	local LC_CTYPE=C

	# Process Id of the previous running command
	local spin='-\|/'
	local charwidth=1
	local message=${1:-"processing..."}
	local pid=$2

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

	# execute command
	eval "$command" >/dev/null 2>>"$LOG_FILE" &

	pid=$!

	# Show spinner 
	spinner "$loading_msg" $pid
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

#
# Backup before making any changes
#
DOTFILES_PATH="$BASE_DIR"
# Define an associative array with source and destination pairs
files_to_override=(".bashrc" ".zshrc" ".shrc" ".vimrc" ".starship.toml" ".oh-my-bash" ".oh-my-zsh")
backup_configs() {
    local file="$1"
    # Make a copy of original config file,
    cp -rf "$HOME_DIR/$file" "$DOTFILES_BACKUP/$file"
    # Remove original config file
    rm -rf "$HOME_DIR/$file"
}
# Later, it will be called to move configs to override defaults
copy_configs() {
    # Copy from dotfiles
    cp -rf "$DOTFILES_PATH/$file" "$HOME_DIR/$file"
}
# Iterate over the files and make backups
for file in "${files_to_override[@]}"; do
    backup_configs "$file" >/dev/null 2>&1 || true
done

# Function to install all necessary packages at once
initBootstrap() {
	apt-get update
	apt-get install -y dialog whiptail
	apt-get install -y apt-utils
	apt-get install -y snapd 
	apt-get install -y git curl wget
	apt-get install -y ripgrep unzip vim apt
	apt install software-properties-common --yes
	apt install python3 python3-pip --yes
	export PATH="/snap/bin:$PATH"
	systemctl restart snapd.seeded.service
	systemctl restart snapd.service
	snap install core
}

# Install dependencies
execute_installation \
"initBootstrap" \
"Installing dependencies..." \
"Dependencies Installed" \
"installing dependencies 📚 "

# Install oh-my-bash
mv "$HOME_DIR/.oh-my-bash" "$DOTFILES_BACKUP/" >/dev/null 2>&1 || true
execute_installation \
'sudo -u $SUDO_USER bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)" --unattended' \
"Installing oh-my-bash for fallback" \
"OMB Installation Completed" \
"installing omb 🚨 "

# Install zsh
execute_installation \
'apt install zsh --yes' \
"Installing zsh" \
"zsh Installation Completed" \
"installing zsh 🎈 "
# Change default shell to zsh
chsh -s $(which zsh)

# Install oh-my-zsh
mv "$HOME_DIR/.oh-my-zsh" "$DOTFILES_BACKUP/" >/dev/null 2>&1 || true
execute_installation \
'sudo -u $SUDO_USER sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended' \
"Installing oh-my-zsh" \
"OMZ Installation Completed" \
"installing oh-my-zsh 🎨 "

# Install nvim
execute_installation \
'snap install nvim --classic' \
"Installing nvim" \
"Neovim Installation Completed" \
"installing nvim 🪄 "
mkdir -p "$HOME_DIR/.local/bin/"
ln -s /snap/bin/nvim "$HOME_DIR/.local/bin/" >/dev/null 2>>$LOG_FILE

# Backup before installing nvim theme
{
NVIM_BACKUP="$DOTFILES_BACKUP/nvim/"
mkdir -p "$NVIM_BACKUP"
mv "$HOME_DIR/.config/nvim" "$NVIM_BACKUP"
mv "$HOME_DIR/.local/share/nvim" "$NVIM_BACKUP"
mv "$HOME_DIR/.local/state/nvim" "$NVIM_BACKUP"
mv "$HOME_DIR/.cache/nvim" "$NVIM_BACKUP"
} >/dev/null 2>&1 || true

# Install NvChad
execute_installation \
"git clone https://github.com/NvChad/NvChad $HOME_DIR/.config/nvim --depth 1" \
"Installing NvChad" \
"NvChad Installation Completed" \
"installing NvChad 🤨 "

# Install chezmoi
execute_installation \
'snap install chezmoi --classic' \
"Installing chezmoi" \
"chezmoi Installation Completed" \
"installing chezmoi 🏠 "

# Install starship
execute_installation \
'curl -sS https://starship.rs/install.sh' \
"Installing starship" \
"starship Installation Completed" \
"installing starship 🚀 "
ln -s "$HOME_DIR/.starship.toml" "$HOME_DIR/.config/starship.toml" >/dev/null 2>>$LOG_FILE

#
# Iterate over the files and copy to override defaults
#
for file in "${files_to_override[@]}"; do
    copy_configs "$file" >/dev/null 2>&1 || true
done

# Move $HOME/.oh-my-bash and $/HOME/.oh-my-zsh to $HOME/.config/
{
mv "$HOME_DIR/.oh-my-bash" "$HOME_DIR/.config/"
mv "$HOME_DIR/.oh-my-zsh" "$HOME_DIR/.config/"
}>/dev/null 2>&1 || true

# Install wslu for wsl utilities
# This is to use host browser instead of wsl browser.
{
add-apt-repository -y ppa:wslutilities/wslu
apt update
apt install wslu
apt install ubuntu-wsl
} >/dev/null 2>>$LOG_FILE & spinner "installing wslu..." $! || true

echo "export BROWSER=wslview
export PATH=/snap/bin:/$HOME_DIR/.local/bin:$PATH" >> "$HOME_DIR/.shrc"

# Ignore if it errors out or not. It's for fun.
snap install lolcat >/dev/null 2>&1 & spinner "" $! || true

{
# Copy figlet directory to local home directory
mkdir -p "$HOME_DIR/.local/lib/"
cp -r "$BASE_DIR/figlet" "$HOME_DIR/.local/lib/"

# Print welcome figlet
FIGLET_DIR="$HOME_DIR/.local/lib/figlet"
"$FIGLET_DIR/print.sh"

# Print bootstrap successful message box
echo ""
message_box "Bootstrap Successful" 
echo ""
} | lolcat
