#!/bin/bash

# This script must be run as root.
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Install RVM/ruby-2.3.1
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
\curl -sSL https://get.rvm.io | bash -s stable --ruby=2.3.1

# Load in current shell
source /usr/local/rvm/scripts/rvm

# Install required gems
gem install sinatra rest-client

# Install nginx+passenger
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
echo "deb https://oss-binaries.phusionpassenger.com/apt/passenger jessie main" > /etc/apt/sources.list.d/passenger.list
apt-get update
apt-get install -y nginx-extras passenger

# Enable passenger in nginx config
sed -i 's/# \(include \/etc\/nginx\/passenger.conf;\)/\1/' /etc/nginx/nginx.conf

# Enable/restart nginx service
update-rc.d nginx enable

# Add users to RVM group
usermod -a -G rvm admin
usermod -a -G rvm grid

# Delete default site
rm -f /etc/nginx/sites-enabled/default

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
