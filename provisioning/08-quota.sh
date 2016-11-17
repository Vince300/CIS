#!/bin/bash

# Fail if any command fail
set -eo pipefail

# This script must be run as root.
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

if ! grep /etc/fstab usrquota >/dev/null 2>&1 ; then
    sed -i 's/\(.*\/.*ext4.*errors=remount-ro\)/\1,usrquota/' /etc/fstab
    echo "Please reboot the machine now!" 1>&2
else
    echo "Already run" 1>&2
fi