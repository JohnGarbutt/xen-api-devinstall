#!/usr/bin/env bash

THIS_DIR=$(cd $(dirname "$0") && pwd)

. $THIS_DIR/install-utils.sh

xen_install

. $THIS_DIR/build-utils.sh

opam_build
xapi_deps_install
xapi_build
