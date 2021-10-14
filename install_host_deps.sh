#!/bin/bash
set -x

sudo apt update
sudo apt install python3 python3-pip python3-lxc libssl-dev git -y
pip3 install --upgrade setuptools
pip3 install ansible
pip3 install -U cryptography

echo 'installed ansible to ~/.local/bin, make sure this is in $PATH'

