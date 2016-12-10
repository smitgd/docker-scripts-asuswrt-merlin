#!/bin/bash

# Run this with sudo to add needed packages to ubuntu xenial
# which is assumed to be running in virtualbox.
# This also sets the owner:group of /opt to the non-root user running
# this script.

# Setup the build environment (i386 arch needed for libelf1:i386
# since host os and ubuntu:xenial are 64-bit)
dpkg --add-architecture i386
apt-get update
apt-get install -y apt-utils
apt-get -y dist-upgrade
apt-get install -y git ccache vim

# install dependencies
apt-get install -y git autoconf automake bash bison bzip2 diffutils file flex \
  m4 g++ gawk groff-base libncurses-dev libtool libslang2 make patch perl \
  pkg-config shtool subversion tar texinfo zlib1g zlib1g-dev git-core gettext \
  libexpat1-dev libssl-dev cvs gperf unzip python libxml-parser-perl gcc-multilib \
  gconf-editor libxml2-dev g++-4.7 g++-multilib gitk libncurses5 mtd-utils \
  libncurses5-dev libstdc++6-4.7-dev libvorbis-dev g++-4.7-multilib git autopoint \
  autogen sed build-essential intltool libelf1:i386 libglib2.0-dev  

# A few more because this this is 64-bit xenial:
apt-get install -y git lib32z1-dev lib32stdc++6 

# Install one more to allow mounting of host directory in linux on virtualbox
# so files produces are available on host system.
apt-get install -y virtualbox-guest-utils

# print this file see if it is actaully Ubuntu Xenial (16.04) you are running.
cat /etc/lsb-release
