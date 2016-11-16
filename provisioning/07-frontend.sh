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
