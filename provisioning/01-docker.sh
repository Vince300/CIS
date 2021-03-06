#!/bin/bash
# This file is a provisioning script that setups required software for this project to run on a x64 jessie system.
# Note: this shell script is self-contained, once uploaded to a host it can be run with only internet access as a
# dependency

# This script must be run as root.
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Just in case
service docker stop

# See docker install procedure
apt-get purge "lxc-docker*"
apt-get purge "docker.io*"
apt-get update

# Configure repository
apt-get install -y apt-transport-https ca-certificates
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
echo "deb https://apt.dockerproject.org/repo debian-jessie main" >/etc/apt/sources.list.d/docker.list

# Update with new sources
apt-get update

# Install docker
apt-get install -y docker-engine

# Enable docker for non-root
gpasswd -a grid docker

# Change settings : max 1G
sed -i 's/ExecStart=.*/ExecStart=\/usr\/bin\/dockerd -H fd:\/\/ --storage-driver=devicemapper --storage-opt dm.basesize=1G/' /lib/systemd/system/docker.service

# Fix the kernel for next boot install
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet cgroup_enable=memory swapaccount=1"/' /etc/default/grub
update-grub

# Enable service
update-rc.d docker enable
service docker start
