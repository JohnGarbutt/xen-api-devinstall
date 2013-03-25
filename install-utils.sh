#!/usr/bin/env bash

function _install {
    yum install -y $@
}

function _tools_install {
    _install make gcc
}

function opam_build {
    _tools_install

    wget https://github.com/OCamlPro/opam/archive/latest.tar.gz -O opam-latest.tgz
    tar -xf opam-latest.tgz

    cd opam-latest
    ./configure
    make
    make install

    opam init
    opam_config_env
    echo 'eval `opam config env`' >> ~/.bash_profile
}

function opam_config_env {
    eval `opam config env`
}
