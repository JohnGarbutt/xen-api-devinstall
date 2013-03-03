insmod /lib/modules/3.4.32-6.el6.centos.alt.x86_64/kernel/net/openvswitch/openvswitch.ko
ovsdb-server --remote=punix:/usr/var/run/openvswitch/db.sock \
                     --remote=db:Open_vSwitch,manager_options \
                     --pidfile --detach
ovs-vswitchd --pidfile --detach
