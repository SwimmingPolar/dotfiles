#!/bin/bash
#
# Trap default error handler 
#

# Exit on first error
set -e

# Start directing stdout to /dev/null
exec >/dev/null

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

    script_path=$(dirname $(readlink -f $(basename "$0")))
    log_file="$script_path.log"
    

    if [ $exit_status -ne 0 ]; then
      log_message="Script exited with error code $exit_status"
      mkdir -p ~/logs
      echo "$log_message" >> "~/logs/$log_file"
    fi
}

trap exit_handler EXIT ERR

