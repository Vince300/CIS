#!/bin/bash

# This script must be run as root.
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Create config for worker site
echo "server {
	root /srv/worker/public;
	passenger_enabled on;
	passenger_ruby /usr/local/rvm/rubies/ruby-2.3.1/bin/ruby;
}" >/etc/nginx/sites-available/worker
ln -s /etc/nginx/sites-available/worker /etc/nginx/sites-enabled/worker

# Edit nginx config to run as grid user
sed -i 's/user .*;/user grid;/'

# Create server directory
mkdir -p /srv/worker/public

# Ownership to grid
chown -R grid:grid /srv/worker

# Restart nginx server
service nginx restart
