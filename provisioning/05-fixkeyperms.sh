#!/bin/bash

# This script must be run as root.
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Ownership to grid
chown grid:grid /srv/machine.{crt,key}
chmod 0600 /srv/machine.{crt,key}

