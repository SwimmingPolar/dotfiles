#!/bin/bash

# Check for --confirm flag
CONFIRM_CHANGES=false
if [ "$1" == "--confirm" ]; then
	CONFIRM_CHANGES=true
fi

# Global arrays for changed and deleted files
# Associative array for CHANGED (chezmoi file path, original file path)
declare -A CHANGED
CHANGED=()
DELETED=()

# Chezmoi local repository
CHEZMOI_LOCAL_REPO="$HOME/.local/share/chezmoi"

# Function to translate Chezmoi encoded names to original names
translate_name() {
	local name="$1"
	# Handle 'dot_' prefix first
	name="${name/dot_/.}"
	# Handle other prefixes and suffixes
	# Stop attribute parsing if 'literal_' prefix or '.literal' suffix is found
	if [[ $name == literal_* ]] || [[ $name == *.literal ]]; then
		name="${name#literal_}"
		name="${name%.literal}"
	else
		# Handle other prefixes
		name="${name#after_}"
		name="${name#before_}"
		name="${name#create_}"
		name="${name#empty_}"
		name="${name#encrypted_}"
		name="${name#external_}"
		name="${name#exact_}"
		name="${name#executable_}"
		name="${name#modify_}"
		name="${name#once_}"
		name="${name#onchange_}"
		name="${name#private_}"
		name="${name#readonly_}"
		name="${name#remove_}"
		name="${name#run_}"
		name="${name#symlink_}"

		# Handle suffixes
		name="${name%.tmpl}"
		name="${name%.age}"
		name="${name%.asc}"
	fi
	echo "$name"
}

# Function to read .chezmoiignore and create an array of ignored patterns
read_chezmoiignore() {
	local ignore_file="$CHEZMOI_LOCAL_REPO/.chezmoiignore"
	local patterns=()
	if [ -f "$ignore_file" ]; then
		while IFS= read -r line || [[ -n "$line" ]]; do
			# Skip empty lines and comments
			[[ -z "$line" || "$line" == \#* ]] && continue

			# Convert '**' glob patterns to '*'
			local pattern="${line/\*\*/\*}"

			# Add the pattern to the array
			patterns+=("$pattern")
		done <"$ignore_file"
	fi
	echo "${patterns[@]}"
}

# Function to check if a file is ignored based on .chezmoiignore patterns
is_ignored() {
	local file="$1"
	for pattern in "${IGNORE_PATTERNS[@]}"; do
		# Debugging output
		if [[ "$file" == "$pattern" ]]; then
			return 0 # File is ignored
		fi
	done
	return 1 # File is not ignored
}

# Function to execute tasks based on the confirm flag
execute_task() {
	if $CONFIRM_CHANGES; then
		# For files deleted, ask to remove from Chezmoi
		for original_file in "${DELETED[@]}"; do
			echo -e "\e[1;31mDeleted: \e[0m$original_file"
			read -p "Do you want to remove this target from Chezmoi? [y/N]: " -r
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				chezmoi remove "$original_file"
			fi
		done
		echo ""

		# For files changed, show diff and ask to add to Chezmoi
		for original_file in "${!CHANGED[@]}"; do
			local chezmoi_file="${CHANGED[$original_file]}"

			# Display diff
			if command -v colordiff &>/dev/null; then
				colordiff -u "$chezmoi_file" "$original_file" | less -R
			else
				diff -u "$chezmoi_file" "$original_file" | less -R
			fi

			# Ask user whether to add the original file to Chezmoi
			echo -e "\e[1;36mModified: \e[0m$original_file"
			read -p "Do you want to run 'chezmoi add' to this file? [y/N]: " -r
			if [[ $REPLY =~ ^[Yy]$ ]]; then
				chezmoi add "$original_file"
			fi
		done
	else
		# Output modified information
		# without running tasks
		for original_file in "${DELETED[@]}"; do
			echo -e "\e[1;31mDeleted: \e[0m$original_file"
		done
		echo ""
		for original_file in "${!CHANGED[@]}"; do
			echo -e "\e[1;36mModified: \e[0m$original_file"
		done
	fi
}

# Function to process a path component by component
process_path() {
	local path="$1"
	local processed_path=""
	IFS='/' read -ra ADDR <<<"$path"
	for component in "${ADDR[@]}"; do
		processed_path+="/$(translate_name "$component")"
	done
	# Remove leading slash
	echo "${processed_path#/}"
}

# Determine if file/directory has changed/deleted
# Run corresponding tasks for each case
process_file() {
	local chezmoi_file="$1"
	local original_file="$2"

	if [ ! -e "$original_file" ]; then
		DELETED+=("$original_file")
	elif ! diff -q "$chezmoi_file" "$original_file" >/dev/null; then
		CHANGED["$original_file"]="$chezmoi_file"
	fi
}

# Determine if directory or file
process_chezmoi_repo() {
	local repo_path="$1"
	for item in "$repo_path"/*; do
		# It's a directory, recurse into it
		if [ -d "$item" ]; then
			process_chezmoi_repo "$item"
		# It's a file, process the path
		elif [ -f "$item" ]; then
			local relative_path="${item#$CHEZMOI_LOCAL_REPO/}"
			# Remove leading '/' from relative path
			local processed_path=$(process_path "$relative_path")
			# Add '/' here when concatenating with $HOME
			local original_file="$HOME/$processed_path"
			if is_ignored "$processed_path"; then
				continue
			fi
			process_file "$item" "$original_file"
		fi
	done
}

# Read .chezmoiignore patterns
IGNORE_PATTERNS=($(read_chezmoiignore))

# Start processing the Chezmoi local repository
process_chezmoi_repo "$CHEZMOI_LOCAL_REPO"

# Actually run tasks
execute_task
