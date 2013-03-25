#!/usr/bin/env bash

THIS_DIR=$(cd $(dirname "$0") && pwd)

. $THIS_DIR/install-utils.sh

xen_install

. $THIS_DIR/build-utils.sh

opam_build

. $THIS_DIR/run-screen.sh
