#!/bin/bash
# This file is a provisioning script that setups required software for this project to run on a x64 jessie system.
# Note: this shell script is self-contained, once uploaded to a host it can be run with only internet access as a
# dependency

# Fail if any command fail
set -eo pipefail

# This script must be run as root.
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Create quota files
quotacheck  -cu /

# Generate the table of current disk usage
quota -avu
