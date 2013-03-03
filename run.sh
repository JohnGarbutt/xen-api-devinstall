#!/usr/bin/env bash

THIS_DIR=$(cd $(dirname "$0") && pwd)

. $THIS_DIR/screen.sh

# start ovs
. $THIS_DIR/ovs.sh

# start xcp
screen_it xcp-fe /root/.opam/system/bin/xcp-fe
screen_it v6d /opt/xensource/libexec/v6d
screen_it networkd /opt/xensource/libexec/xcp-networkd
screen_it xenopsd /opt/xensource/libexec/xenopsd
screen_it xapi "/opt/xensource/bin/xapi -nowatchdog"
screen_it logs "tail -f /var/log/messages" 

echo "**********************************"
echo "To attach to screen: screen -x xcp"
echo "**********************************"
