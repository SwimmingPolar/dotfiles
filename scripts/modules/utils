#!/bin/bash

function script_path() {
    local script_path=$(dirname $(readlink -f $(basename "$0")))
    echo "$script_path"
}

function script_name() {
    local scriptPath = $(script_path)
    echo $(basename "$scriptPath")
}
