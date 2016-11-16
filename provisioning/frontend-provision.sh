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

# Add fork bomb protection
echo "# Default limit for number of user's processes to prevent
# accidental fork bombs.
# See rhbz #432903 for reasoning.

*          soft    nproc     4096
admin      soft    nproc     unlimited
grid       soft    nproc     unlimited
root       soft    nproc     unlimited" > /etc/security/limits.d/20-nproc.conf

# Set ACL so that grid can write result in user's home
setfacl -m user:grid:rwx /home

# Set quota for / partition
sed -i 's/\(UUID\=.*\/.*ext4.*errors=remount-ro\)/\1,usrquota/'

echo "Please verify that usrquota has been set for / in /etc/fstab then restart the machine and and launch frontend-provision-end.sh"
