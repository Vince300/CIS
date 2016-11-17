#!/bin/bash

# This script must be run as root.
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# We need the daemons gem
/usr/local/rvm/bin/rvm default do gem install daemons

# Edit nginx config to run as grid user
sed -i 's/user .*;/user grid;/'

# Extract the archive to /srv/worker
mkdir -p /srv/worker/public
tar -C /srv/worker -xf workerd.tar.gz

# Move the config file to nginx config dir
mv /srv/worker/worker /etc/nginx/sites-available

# Enable it
ln -s /etc/nginx/sites-available/worker /etc/nginx/sites-enabled

# Prepare the systemd service
mv /srv/worker/cisd.service /etc/systemd/system
systemctl daemon-reload
systemctl start cisd.service
systemctl enable cisd.service

# Ownership to grid
chown -R grid:grid /srv/worker

# Restart nginx server
service nginx reload
