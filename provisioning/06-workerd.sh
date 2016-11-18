#!/bin/bash

# This script must be run as root.
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Extract the archive to /srv/worker
mkdir -p /srv/worker/public
tar -C /srv/worker --strip-components 1 -xf workerd.tar.gz

# Move the config file to nginx config dir
mv /srv/worker/worker /etc/nginx/sites-available

# Enable it
ln -fs /etc/nginx/sites-available/worker /etc/nginx/sites-enabled

# Prepare the systemd service
mv /srv/worker/cisd.service /etc/systemd/system
systemctl daemon-reload
systemctl enable cisd.service

# Ownership to grid
chown -R grid:grid /srv/worker

# Restart services
systemctl restart cisd.service nginx.service
