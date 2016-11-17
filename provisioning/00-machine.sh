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

# Remove debian cdrom entry
sed -i 's/deb cdrom.*//' /etc/apt/sources.list

# Update repositories
apt-get update
apt-get install -y sudo git curl wget

# Install "install" as sudo
gpasswd -a install sudo

# Passwordless sudo, as the admin user has no password
sed -i 's/%sudo\tALL=(ALL:ALL) ALL/%sudo\tALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

# Create the admin user who can sudo
useradd -m -s /bin/bash -G sudo admin

# Setup the SSH key for admin
mkdir ~admin/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDZshon/eKqUXY3/5+jCh7SJ/QpMUQDqd2QqYzHLDmuHXHoN++W1pcypOfa+aUYY4o9ZVIEM4m96IR/LBiWdlAa6S9pW4PUG6bJYwxHJPXH/wmFrLj97v53oQALeJ84HZLoGzHgWdWx15vPb0ND9eDWso6lil1zLNGpGzSsY1eHxDvw76MeSc3a5eCavn/2hKJswrh68EPeZfJY3mzpqIOPKr+Kp/bZgkPp+NP5gbqcYvPW1zYwHdyHTaQFKj8dDtd7GzvLnD95XzxruHLZW6/JscbPlcE1zoz48oQNMAsVFBB231sVtVESPqHUa8GP9QpcfevmqTwCG1K62KXoPeON admin@worker" >~admin/.ssh/authorized_keys
chown -R admin:admin ~admin/.ssh

# Create the grid user for workers
useradd -m -s /bin/bash grid

# Setup the SSH key for worker
mkdir ~grid/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDkVnd07+O24hQhSre1KO7zLkCFdaiCcLf01fl+0qvFQLXgsqGdcSwq0uMFgumeBW3s6Zjd4KK0CIduakMqJVJFPSlw3kPdOljECe7cN7OQtRX2IKVm0jCH+uM30wTYuzThhspFGXqJgg9/Uf7X7h/MgIf1QD8r6sK+xiPB7PYja30Jo39y/etgCFkMRSKKa4PP3gfJjxV2GDiYOHi+9Cgl5EUVhkZG2LVYfC4dbIRAqHM0e3JHCuZLqPbFEFxUHgTyNCBIzJwRMzmnDh/DbTwN0GOoqDfwUwdmlFESShAyK1RGRaU9mGZT9vQ0pGcMKAm/WiHMav23onh90dsGMcBr grid@worker" >~grid/.ssh/authorized_keys
chown -R grid:grid ~grid/.ssh

# Lock the root account
passwd -l root

# Ensure ssh root login is impossible through SSH
echo "PermitRootLogin no" >>/etc/ssh/sshd_config
