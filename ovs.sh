#!/usr/bin/env bash

kernel_version=$(rpm -q kernel | grep 3.4)
insmod /lib/modules/${kernel_version}/kernel/net/openvswitch/openvswitch.ko

ovsdb-server --remote=punix:/usr/var/run/openvswitch/db.sock \
                     --remote=db:Open_vSwitch,manager_options \
                     --pidfile --detach
ovs-vswitchd --pidfile --detach
