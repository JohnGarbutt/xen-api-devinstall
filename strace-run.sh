#!/usr/bin/env bash

THIS_DIR=$(cd $(dirname "$0") && pwd)
STRACE_CMD="strace -fff -v -s 250 -e trace=open"
. $THIS_DIR/run.sh
