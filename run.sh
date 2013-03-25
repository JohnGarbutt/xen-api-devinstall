#!/usr/bin/env bash

set -eux

THIS_DIR=$(cd $(dirname "$0") && pwd)

. $THIS_DIR/screen.sh

# hack to turn of selinux
setenforce 0

# start ovs
. $THIS_DIR/ovs.sh

# setup OCAML
STRACE_CMD="export OCAMLRUNPARAM=b; $STRACE_CMD"

# start xcp
screen_it xcp-fe "$STRACE_CMD /root/.opam/system/bin/xcp-fe"
screen_it v6d "$STRACE_CMD /opt/xensource/libexec/v6d"
screen_it networkd "$STRACE_CMD /opt/xensource/libexec/xcp-networkd"
screen_it xenopsd "$STRACE_CMD /opt/xensource/libexec/xenopsd"
screen_it squeezed "$STRACE_CMD /opt/xensource/libexec/squeezed"
screen_it xapi "$STRACE_CMD /opt/xensource/bin/xapi -nowatchdog"
screen_it logs "tail -f /var/log/messages" 

echo "**********************************"
echo "To attach to screen: screen -x xcp"
echo "**********************************"
