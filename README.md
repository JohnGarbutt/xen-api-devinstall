xcp-devinstall
==============

Shell scripts to help build run XCP as a developer on CentOS 6.4 minimal.

yum install git -y    
git clone https://github.com/JohnGarbutt/xcp-devinstall.git    
cd xcp-devinstall

There are two top level scripts...

install.sh
----------
Installs Xen and OCAML    
Builds OPAM, OVS and XAPI    
You must restart before running run.sh

run.sh
------
Starts OVS and runs all the XCP services in a separate screen
