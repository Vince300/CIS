#!/bin/bash

# Fail if any command fail
set -eo pipefail

# This script must be run as root.
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

FRONTEND_NAME=ensipc376
FRONTEND_IP=192.168.0.76

if ! grep /etc/hosts $FRONTEND_NAME >/dev/null 2>&1; then
    echo "$FRONTEND_IP $FRONTEND_NAME" >/etc/hosts
fi
