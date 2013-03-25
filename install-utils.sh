#!/usr/bin/env bash

function _install {
    yum install -y $@
}

function _xen_repo_install {
    _install wget
    cd /etc/yum.repos.d/
    wget http://dev.centos.org/centos/6/xen-c6/xen-c6.repo
    yum repolist
}

function _xen_update_grub_conf {
    mv /etc/grub.conf /etc/grub.conf.old.`date "+%Y%m%d%H%M%S"`

    dom0_mem=${dom0_mem:-"1024M"}
    kernel_version=$(rpm -q kernel | grep 3.4)
    vg=$(lvm vgdisplay | grep Name | cut -c 25- )

    cat > /etc/grub.conf << EOF
default=0
timeout=5
title xen
        root (hd0,0)
        kernel /xen.gz dom0_mem=${dom0_mem},max:${dom0_mem} loglvl=all guest_loglvl=all
        module /vmlinuz-${kernel_version} ro root=/dev/mapper/${vg}-lv_root rd_NO_LUKS  KEYBOARDTYPE=pc KEYTABLE=uk LANG=en_US.UTF-8 rd_LVM_LV=${vg}/lv_root rd_NO_MD quiet SYSFONT=latarcyrheb-sun16 rhgb crashkernel=auto rd_NO_DM rd_LVM_LV=${vg}/lv_swap
        module /initramfs-${kernel_version}.img
EOF
}

function xen_install {
    _xen_repo_install
    _install kernel kernel-firmware
    _install xen
    _xen_update_grub_conf
}
