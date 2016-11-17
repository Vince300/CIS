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

# Add fork bomb protection

echo "# Default limit for number of user's processes to prevent
# accidental fork bombs.
# See rhbz #432903 for reasoning.

*          soft    nproc     4096
admin      soft    nproc     unlimited
grid       soft    nproc     unlimited
root       soft    nproc     unlimited" > /etc/security/limits.d/20-nproc.conf

tar xf frontend_scripts

cp lancerjob /usr/local/bin/lancerjob
cp parseargs.py /usr/local/bin/parseargs.py
cp bashcall.py /usr/local/bin/bashcall.py

cp createuser /home/admin/createuser
cp deleteuser /home/admin/deleteuser
