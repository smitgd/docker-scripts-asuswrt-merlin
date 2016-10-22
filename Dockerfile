# this builds openwrt-merlin firmware
FROM ubuntu:xenial
MAINTAINER gds <gds@chartertn.net>
WORKDIR /root

# setup the build environment (i386 arch needed for libelf1:i386
# since host os and ubuntu:xenial are 64-bit)
RUN dpkg --add-architecture i386
RUN apt-get update
RUN apt-get install -y apt-utils
RUN apt-get -y dist-upgrade
RUN apt-get install -y git ccache vim

# install dependencies
RUN apt-get install -y git autoconf automake bash bison bzip2 diffutils file flex \
  m4 g++ gawk groff-base libncurses-dev libtool libslang2 make patch perl \
  pkg-config shtool subversion tar texinfo zlib1g zlib1g-dev git-core gettext \
  libexpat1-dev libssl-dev cvs gperf unzip python libxml-parser-perl gcc-multilib \
  gconf-editor libxml2-dev g++-4.7 g++-multilib gitk libncurses5 mtd-utils \
  libncurses5-dev libstdc++6-4.7-dev libvorbis-dev g++-4.7-multilib git autopoint \
  autogen sed build-essential intltool libelf1:i386 libglib2.0-dev ccache vim

# A few more because this this is 64-bit xenial:
RUN apt-get install -y git lib32z1-dev lib32stdc++6 

# Run "docker run <this-image>" to verify it is Ubuntu Xenial (16.04)
CMD ["/bin/cat", "/etc/lsb-release"]
