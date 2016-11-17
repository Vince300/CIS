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
apt-get install python-dev

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

tar xf frontend_scripts

mkdir /srv/certs

cp lancerjob /usr/local/bin/lancerjob
cp parseargs.py /usr/local/bin/parseargs.py
cp bashcall.py /usr/local/bin/bashcall.py
cp config_lancerjob.yml /usr/local/etc/config_lancerjob.yml
chown root:root /usr/local/etc/config_lancerjob.yml

cp createuser /home/admin/createuser
cp config_createuser.yml /usr/local/etc/config_createuser.yml
cp deleteuser /home/admin/deleteuser
chown root:root /usr/local/etc/config_createuser.yml

cp localhost_frontend /etc/nginx/sites-available
cp machine_frontend /etc/nginx/sites-available
ln -s /etc/nginx/sites-available/localhost_frontend /etc/nginx/sites-enabled/localhost_frontend
ln -s /etc/nginx/sites-available/machie_frontend /etc/nginx/sites-enabled/machine_frontend

cp -r machine /srv/machine
cp -r localhost /srv/localhost


