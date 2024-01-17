#!/bin/bash

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

# Function to display a colored diff of a changed file and ask to add it to Chezmoi
show_diff_and_ask_to_add() {
	local chezmoi_file="$1"
	local original_file="$2"

	# Display diff
	if command -v colordiff &>/dev/null; then
		colordiff -u "$chezmoi_file" "$original_file" | less -R
	else
		diff -u "$chezmoi_file" "$original_file" | less -R
	fi

	# Ask user whether to add the original file to Chezmoi
	read -p "Do you want to add this file to Chezmoi? [y/N]: " -r
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		chezmoi add "$original_file"
	fi
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
# Function to process a path component by component
process_path() {
	local path="$1"
	local processed_path=""
	IFS='/' read -ra ADDR <<<"$path"
	for component in "${ADDR[@]}"; do
		if [ ! -z "$component" ]; then
			if [ -z "$processed_path" ]; then
				# First component, add without leading '/'
				processed_path="$(translate_name "$component")"
			else
				# Subsequent components, add with leading '/'
				processed_path+="/$(translate_name "$component")"
			fi
		fi
	done
	echo "$processed_path"
}

# Function to recursively process files and directories in the Chezmoi local repo
process_chezmoi_repo() {
	local repo_path="$1"
	for item in "$repo_path"/*; do
		if [ -d "$item" ]; then
			# It's a directory, recurse into it
			process_chezmoi_repo "$item"
		elif [ -f "$item" ]; then
			# It's a file, process the path
			local relative_path="${item#$CHEZMOI_LOCAL_REPO}"
			local processed_path=$(process_path "$relative_path")
			local original_file="$HOME/$processed_path"
			# Check if the file is ignored
			if is_ignored "$processed_path"; then
				continue
			fi
			# Compare the file with its original counterpart
			if ! diff -q "$item" "$original_file" >/dev/null; then
				# Files are different, echo the file name
				show_diff_and_ask_to_add "$item" "$original_file"
				echo "Changed file: $original_file"
			fi
		fi
	done
}

# Read .chezmoiignore patterns
IGNORE_PATTERNS=($(read_chezmoiignore))

# Start processing the Chezmoi local repository
process_chezmoi_repo "$CHEZMOI_LOCAL_REPO"
