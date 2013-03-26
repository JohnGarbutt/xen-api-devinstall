#!/usr/bin/env bash

kernel_version=$( rpm -q kernel | grep 3.4 | sed "s/kernel-//" )
rmmod bridge
insmod /lib/modules/${kernel_version}/kernel/net/openvswitch/openvswitch.ko

ovsdb-server --remote=punix:/usr/var/run/openvswitch/db.sock \
             --remote=db:Open_vSwitch,manager_options \
             --private-key=db:SSL,private_key \
             --certificate=db:SSL,certificate \
             --bootstrap-ca-cert=db:SSL,ca_cert \
             --pidfile --detach

ovs-vswitchd --pidfile --detach
