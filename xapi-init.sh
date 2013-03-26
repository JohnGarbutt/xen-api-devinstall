#!/usr/bin/env bash

set -eux

mkdir -p /root/vhds
sr_uuid=`xe sr-create type=file device-config:location=/root/vhds name-label=localstorage sm-config:type=vhd`
pool_uuid=`xe pool-list --minimal`
xe pool-param-set uuid=$pool_uuid default-SR=$sr_uuid

host_uuid=`xe host-list --minimal`
xe pif-scan host-uuid=$host_uuid
# assuming a single pif
pif_uuid=`xe pif-list --minimal`
xe pif-reconfigure-ip uuid=$pif_uuid mode=dhcp
xe host-management-reconfigure pif-uuid=$pif_uuid

xe host-call-plugin host-uuid=$host_uuid plugin=openvswitch-cfg-update fn=update

vm_uuid=$(xe vm-create name-label=hvm-test)
xe vm-param-set uuid=$vm_uuid HVM-boot-policy="BIOS order"
network_uuid=$(xe network-list bridge=xenbr0 --minimal)
vif_uuid=$(xe vif-create vm-uuid=$vm_uuid network-uuid=$network_uuid device=0)
vdi_uuid=$(xe vdi-create vm-uuid=$vm_uuid sr-uuid=$sr_uuid virtual-size=1000 name-label="hvm-test" type=user)
xe vm-start uuid=$vm_uuid &
sleep 5
domain_id=$(xe vm-param-get uuid=$vm_uuid param-name=dom-id)
xenstore-write /xapi/${domain_id}/hotplug/vif/0/hotplug "online"
xe vm-list
