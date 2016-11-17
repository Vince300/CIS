#!/bin/bash

# Fail if any command fail
set -eo pipefail

# This script must be run as root.
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root" 1>&2
    exit 1
fi

# Install requests python library

git clone git://github.com/kennethreitz/requests.git

apt-get install -y python-setuptools

cd requests
python setup.py install
cd ../
rm -rf requests

# Install python dev
apt-get install -y python-dev

# Install python yaml parser
wget http://pyyaml.org/download/pyyaml/PyYAML-3.12.tar.gz
tar -xf PyYAML-3.12.tar.gz 
cd PyYAML-3.12/
python setup.py install

# Add fork bomb protection

echo "# Default limit for number of user's processes to prevent
# accidental fork bombs.
# See rhbz #432903 for reasoning.

*          soft    nproc     4096
admin      soft    nproc     unlimited
grid       soft    nproc     unlimited
root       soft    nproc     unlimited" > /etc/security/limits.d/20-nproc.conf

# Restore wd
cd ..

# scripts provisioning
tar xf frontend_scripts.tar.gz
cd scripts

mkdir -p /srv/certs
chown admin:admin /srv/certs

cp lancerjob /usr/local/bin/lancerjob
chmod 750 /usr/local/bin/lancerjob
chown root:admin /usr/local/bin/lancerjob

cp parseargs.py /usr/local/bin/parseargs.py
cp bashrun.py /usr/local/bin/bashrun.py
chmod 644 /usr/local/bin/parseargs.py /usr/local/bin/bashrun.py
chown root:admin /usr/local/bin/parseargs.py /usr/local/bin/bashrun.py

cp config_lancerjob.yml /usr/local/etc/config_lancerjob.yml
chmod 640 /usr/local/etc/config_lancerjob.yml
chown root:admin /usr/local/etc/config_lancerjob.yml

cp createuser /usr/local/bin/createuser
chmod 750 /usr/local/bin/createuser
cp config_createuser.yml /usr/local/etc/config_createuser.yml
chmod 640 /usr/local/etc/config_createuser.yml
cp deleteuser /usr/local/bin/deleteuser
chmod 750 /usr/local/bin/deleteuser
chown root:admin /usr/local/etc/config_createuser.yml /usr/local/bin/deleteuser /usr/local/bin/createuser

# Restore wd
cd ..

# Extract files
tar xf frontend_servers.tar.gz
cd frontend_servers

cp localhost_frontend /etc/nginx/sites-available
cp machine_frontend /etc/nginx/sites-available
ln -fs /etc/nginx/sites-available/localhost_frontend /etc/nginx/sites-enabled
ln -fs /etc/nginx/sites-available/machine_frontend /etc/nginx/sites-enabled

mkdir -p /srv/machine/public
mkdir -p /srv/localhost/public

cp -r machine /srv/machine
cp -r localhost /srv/localhost

chown grid:grid -R /srv/machine
chown grid:grid -R /srv/localhost
