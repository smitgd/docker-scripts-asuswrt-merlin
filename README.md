This assists with asuswrt-merlin builds in a standardized environment using
a docker container.

The script works with Linux (tested on Fedora 23 and Debian Stretch/Testing) and
requires that docker and git be installed. It also, requires that the build 
machine runs on an Intel/AMD 64-bit processor since this uses a 64-bit docker
image. Instructions for installing docker can be found in the documentation for
the distribution in use (search: "<distroName> install docker"). Some additional
docker install information is provided below.
```
I tried to build on OSX 10.9.5 (Mavericks) using boot2docker which uses and
installs VirtualBox. Unfortunately there is a unfixed bug in VirtualBox that
prevents hard links from being created. At least one router software
component (e2fsprogs) creates hard links and fails with "Operation not allowed"
during the build. Boot2docker (part of Docker Toolbox) is deprecated and
replaced with "Docker for Mac" which no longer uses VirtualBox (uses "xhyve"
instead) so it *may* work. However, it requires newer OSX and newer hardware so
I am unable to test it.
(See README-nfs.md for an another way to successfully build on OSX using a
remote docker host. This method is a bit impractical, but it does work.)

Building on OSX also requires the creation and mounting of a case insensitive
filesystem (i.e., a .dmg file) as described in README-nfs.md that is needed
for any build method on OSX since asuswrt-merlin contains several files in a
few directories that differ only by case. See
release/src/router/iptables/extensions/ where some filenames differ only by
case, e.g., libipt_TTL.c and libipt_ttl.c.

Docker Toolbox can also be installed on Windows. However, it also uses
VirtualBox so creating hard links won't work with it either. However, there is
a newer "Docker For Windows" that use native virtualization, similar to
"Docker for Mac", but it currently requires Windows 10 Pro which I don't have.
It would probably fix the hard link problem (since it doesn't use VirtualBox)
but NTFS would probably have to be remounted as case senstive to resolve the
issue of filenames in several directories of asuswrt-merlin differing only by
case.
```
To allow docker commands to be run as a normal user without sudo, do this one
time:
```
$ sudo groupadd docker
$ sudo gpasswd -a ${USER} docker
$ systemctl [re]start docker  # start or restart docker daemon (Fedora specific)
$ # fully log-off and then back in
$ sudo systemctl enable docker  # without this, step 3 required after reboot (Fedora specific)
```
A one-time build of a docker image based on ubuntu:xenial from
docker hub is required using the Dockerfile of this project. From this script 
project directory containing the Dockerfile run:
```
$ docker build -t "asuswrt-merlin-addons" .
```
This will take some time since many required packages will be downloaded from
ubuntu and installed in the produced docker image called asuswrt-merlin-addons.

This produces a standard xenial build environment (Ubuntu 16.04 LTS) described
in asuswrt-merlin build instruction, README.TXT, found at the asuswrt-merlin
project root.

Verify that the image was created successfully by checking (with the docker
daemon running) that the asuswrt-merlin-addons image is present:
```
$ docker images
REPOSITORY            TAG    IMAGE ID     CREATED     SIZE
asuswrt-merlin-addons latest d3348e4351a0 1 days ago  1.027 GB
:
```
and that it can run successfully in a container and is the expected version:
```
$ docker run asuswrt-merlin-addons
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=16.04
DISTRIB_CODENAME=xenial
DISTRIB_DESCRIPTION="Ubuntu 16.04.1 LTS"
```
Place the directory containing this script project at the root of the
asuswrt-merlin tree and run build-asuswrt-merlin.sh script from this project's
directory.

It is important that asuswrt-merlin project be under git control since the
"clean-src" option and "all" option require that portions of the source tree 
are deleted and "git checkout" occurs. So, if these build options are used, 
make sure that any changes are committed at least locally and "git status" is 
reasonably clean before starting a build. 

No pull or other git command occurs that contact the github asuswrt-merlin repo
in the build script. So if a pull or other git command is needed to set up the 
local repo, it must be done manually before running the script.

One or more or all supported routers can be built with a single script execution
as shown in these examples:
```
$ ./build-asuswrt-merlin.sh clean rt-ac5300 cleankernel clean clean-src rt-ac56u
$ ./build-asuswrt-merlin.sh rt-n66u
$ ./build-asuswrt-merlin.sh all
```
If "permission denied" errors occur shortly after starting the build, it may be 
due to selinux problems. The easiest way to "fix" the problem (Fedora specific)
is to just remove the OPTION "--selinux-enabled" from /etc/sysconfig/docker and 
restart the docker daemon as shown above and try the build again. Alternatively,
selinux enforcing can be disabled. Of course both ways could introduce security
issues (on the build system, not in the router firmware).

See "./build-asuswrt-merlin.sh help" for more details. Optional user selected
"clean" action(s) must precede the router name being built. The "all" option
automatically does pre-determined clean actions before each supported router
is built and should be the only option when it is used.

For convenience, at the completion of each router build the resulting firmware
file is copied by the script to the asuswrt-merlin top level root directory from 
the architecture-router dependent locations 
```
"asuswrt-merlin/release/src-rt-*/*/image/RT-*.trx"
```
So a build with the "all" options will result in nine 
```
RT-*.trx
```
files appearing at the asuswrt-merlin top level. 

By default the docker container runs as root, so files checked out by git and
produced by the the script running in the container would become owned by root.
However, after the script does some things that must be done by root, it 
creates a new user and group ID in the container equal to the IDs of the 
user running the script. The container then completes the build while running 
as that new user. Therefore, the script does not create or change the ownership
of any file in the source tree.
