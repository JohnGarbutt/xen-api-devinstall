#!/usr/bin/env bash

BUILD_DEST=~

function _install {
    sudo yum install -y $@
}

function _tools_install {
    _install make gcc wget git
}

function opam_config_env {
    eval `opam config env`
}

function ocaml_install {
    if [ `which ocaml` ]
    then
        echo "ocaml already installed"
        return
    fi

    _install gdbm-devel ncurses-devel rpm-build

    ocaml_repo="https://nazar.karan.org/results/misc/ocaml/20130319164433/4.00.1-2.el6.x86_64/"
    rpm_suffix="-4.00.1-2.el6.centos.alt.x86_64.rpm"
    rpm_prefixes="ocaml% ocaml-camlp4% ocaml-camlp4-devel% ocaml-compiler-libs% ocaml-debuginfo% ocaml-docs% ocaml-ocamldoc% ocaml-runtime% ocaml-source%"
    rpms=$(echo $rpm_prefixes | sed "s/%/${rpm_suffix}/g")
    for rpm_name in $rpms
    do
        if [ -a ${rpm_name} ]
        then
            echo "Skipping download of ${rpm_name}"
        else
            wget ${ocaml_repo}${rpm_name}
        fi
    done

    rpm -i --replacepkgs $rpms
}

function opam_build {
    cd $BUILD_DEST

    if [ `which opam` ]
    then
        echo "opam already installed"
        return
    fi

    _tools_install
    ocaml_install
    
    if [ -a opam-latest ]
    then
        echo "Skipping download of Opam"
    else
        wget https://github.com/OCamlPro/opam/archive/latest.tar.gz -O opam-latest.tgz
        tar -xf opam-latest.tgz
        rm -rf opam-latest.tgz
    fi

    cd opam-latest
    ./configure
    
    make clean
    make uninstall
    rm -rf ~/.opam

    make
    make install

    opam init -y
    opam_config_env
    echo 'eval `opam config env`' >> ~/.bash_profile
}

function _download_and_extract_tar {
    url=$1
    dir=$2
    prog=$3
    tar=${dir}.tgz

    if [ `which $prog` ]
    then
        echo "$prog already installed"
        return
    fi

    cd $BUILD_DEST

    if [ -a $dir ]
    then
        echo "Skipping download of $prog"
    else
        wget $1 -O $tar
        tar -xf $tar
        rm -f $tar
    fi

    cd $dir
}

function _build_tar {
    _download_and_extract_tar $@

    prog=$3
    if [ `which $prog` ]
    then
        return
    fi

    ./configure
    make
    make install
}

function install_automake_autoconf {
    # we build this becuase ovs build needs autoconf > 2.64
    _build_tar "http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.gz" "autoconf-2.69" "autoconf"
    _build_tar "http://ftp.gnu.org/gnu/automake/automake-1.13.tar.gz" "automake-1.13" "automake"
}

function xapi_deps_install {
    install_automake_autoconf
    _install xen-devel libuuid-devel time pam-devel tk-devel libvirt-devel zlib-devel

    wget http://a94cd2de16980073c274-9e5915cce229bfd373f03bf01a9a7c85.r57.cf3.rackcdn.com/vncterm-1.6.10-251.x86_64.rpm
    rpm -i --replacepkgs vncterm-1.6.10-251.x86_64.rpm

    wget http://a94cd2de16980073c274-9e5915cce229bfd373f03bf01a9a7c85.r57.cf3.rackcdn.com/eliloader -O /usr/bin/eliloader
    chmod +x /usr/bin/eliloader

    opam_config_env

    opam install -y ocamlfind omake

    opam remote -y add xen-dev git://github.com/xen-org/opam-repo-dev || true
    opam install -y xen-api-libs-transitional stdext nbd tapctl libvhd oclock cdrom netdev xenopsd

    rpm_name=epel-release-6-8.noarch.rpm
    wget "http://dl.fedoraproject.org/pub/epel/6/x86_64/${rpm_name}"
    rpm -i --replacepkgs $rpm_name
    _install bash-completion
}

function xapi_configure {
    echo openvswitch >/etc/xensource/network.conf
    sed -i "s/MANAGEMENT_INTERFACE.*/MANAGEMENT_INTERFACE='xenbr0'/" /etc/xensource-inventory

    (
        cd /etc/xapi.d/plugins
        wget http://a94cd2de16980073c274-9e5915cce229bfd373f03bf01a9a7c85.r57.cf3.rackcdn.com/openvswitch-cfg-update
        chmod +x openvswitch-cfg-update
    )
}

function xapi_build {
    cd $BUILD_DEST

    if [ `which xe` ]
    then
        echo "xen-api already installed"
        return
    fi

    xapi_deps_install

    if [ -a xen-api ]
    then
        echo "Skipping download of xen-api"
        cd xen-api
    else
        git clone https://github.com/JohnGarbutt/xen-api.git
        cd xen-api
        git checkout centos64
    fi

    make

    set DEST_DIR=/
    make install

    xapi_configure
}


function xapi_sm_build {
    cd $BUILD_DEST

    if [ -a /opt/xensource/sm/FileSR ]
    then
        echo "xapi sm already installed"
    fi

    _install swig python-devel
    install_automake_autoconf

    if [ -a xcp-storage-managers ]
    then
        echo "Skipping download of xen-api"
        cd xcp-storage-managers
    else
        git clone https://github.com/JohnGarbutt/xcp-storage-managers.git
        cd xcp-storage-managers
        git checkout centos63-hacks 
    fi

    export DESTDIR=/
    export PYTHON_INCLUDE=/usr/include/python2.6/
    make
    make install
}


function ovs_build {
    cd $BUILD_DEST

    _install openssl-devel
    install_automake_autoconf

    if [ `which ovs-vsctl` ]
    then
        echo "ovs already installed"
        return
    fi

    # HACK see: http://openvswitch.org/pipermail/discuss/2012-August/008064.html
    #mkdir -p /usr/local/share/aclocal-1.13/
    #cp /usr/share/aclocal/pkg.m4 /usr/local/share/aclocal-1.13/

    _download_and_extract_tar "http://openvswitch.org/releases/openvswitch-1.4.6.tar.gz" "openvswitch-1.4.6" "ovs-vsctl"
    ./configure --prefix=/usr --localstatedir=/var
    export PREFIX=/usr
    export LOCALSTATEDIR=/var
    make
    make install

    echo "
# Stop using bridge, using openvswitch instead
blacklist bridge
" >>/etc/modprobe.d/blacklist.conf
    

    # do first time start
    rm -rf "/usr/etc/openvswitch"
    mkdir -p "/usr/etc/openvswitch"
    ovsdb-tool create "/usr/etc/openvswitch/conf.db" "vswitchd/vswitch.ovsschema"
    ovsdb-server --remote=punix:/var/run/openvswitch/db.sock \
                 --remote=db:Open_vSwitch,manager_options \
                 --private-key=db:SSL,private_key \
                 --certificate=db:SSL,certificate \
                 --bootstrap-ca-cert=db:SSL,ca_cert \
                 --pidfile --detach
    ovs-vsctl --no-wait init
    ovs-vswitchd --pidfile --detach
}
