#! /bin/bash

bash -c "$(curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
echo "Reload and run 'zinit self-update' to update zinit."
