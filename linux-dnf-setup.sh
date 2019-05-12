#!/bin/bash

# Fedora (uses dnf) build dependencies. Usage:
# sudo ./linux-dnf-setup 
# Do one time before running sudo ./linux-build-asuswrt-merlin.sh

# need due to initial conflicts of vim-minimal with vim 
dnf update 

# router build need all these except for git and vim) 
dnf -y install git vim autoconf automake libtool libtool-ltdl \
libtool-ltdl-devel ncurses-devel glibc.i686 elfutils-libelf.i686 \
libstdc++.i686 bison flex  gettext-devel gperf byacc intltool gcc-c++ \
zlib-devel imake rpcgen
