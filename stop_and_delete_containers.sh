#!/bin/bash
set -x

for i in `sudo lxc-ls`;do  sudo lxc-stop $i && sudo lxc-destroy $i; done
