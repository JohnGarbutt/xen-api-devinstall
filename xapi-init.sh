#!/usr/bin/env bash


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
