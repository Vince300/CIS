#!/bin/bash

# Fail if any command fail
set -eo pipefail

# This script must be run as root.
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

add_host () {
    if ! grep /etc/hosts $1 >/dev/null 2>&1; then
        echo "$2 $1" >/etc/hosts
    fi
}

add_host ensipc375 192.168.0.75
add_host ensipc377 192.168.0.77
