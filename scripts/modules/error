#!/bin/bash
#
# Trap default error handler 
#

# Exit on first error
set -e

# Start directing stdout to /dev/null
exec >/dev/null

error_handler() {
    # Preserve error code before next command
    exit_status=$?

    # Stop directing stdout
    exec >&-

    log_path=".logs/$(basename $0).log"
    
    if [ $exit_status -ne 0 ]; then
      log_message="Script exited with error code $exit_status"
      mkdir -p ~/.logs
      echo "$(date +"%Y-%m-%d %H:%M:%S") - $log_message" >> ~/$log_path
    fi
}

trap error_handler ERR

