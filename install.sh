#!/usr/bin/env bash

THIS_DIR=$(cd $(dirname "$0") && pwd)

# hack to turn off selinux
setenforce 0

. $THIS_DIR/install-utils.sh

xen_install

. $THIS_DIR/build-utils.sh

opam_build
xapi_build
ovs_build

echo "*************************************"
echo " Xen has been installed."
echo " OVS has been built."
echo " XAPI has been built and installed."
echo "*************************************"
echo " Please reboot now!"
echo "*************************************"
