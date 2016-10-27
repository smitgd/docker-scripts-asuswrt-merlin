This assists with asuswrt-merlin builds in a standardized environment using 
a docker container.

Scripts are working only Linux (with no problems) and require that docker and 
git be installed. They also, require that the build machine be an intel 64-bit
processor since this uses a 64-bit docker image.
```
I tried to build on OSX 10.9.5 (Mavericks) using boot2docker which uses and 
installs VirtualBox. Unfortunately there is a unfixed bug in VirtualBox that 
prevents hard and symbolic links from being made. At least one router software 
component (e2fsprogs) creates hard links and fails with "Operation not allowed" 
during the build. Boot2docker (part of Docker Toolbox) is deprecated and 
replaced with "Docker for Mac" which no longer uses VirtualBox (uses "xhyve" 
instead) so it "may" work. However, it requires newer OSX and newer hardware so
I am unable to test it.
(See README-nfs.md for an another way to successfully build on OSX using a 
remote docker host. This method is a bit impractical, but does work.) 

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
I would probably fix the hard link problem (since it doesn't use VirtualBox)
but NTFS would probably have to be remounted as case senstive to resolve the
issue of filename in several directories of asuswrt-merlin differing only by 
case.
```
A one-time build of a docker image based on ubuntu:xenial from
docker hub is required using the Dockerfile of this project. From this project
directory containing the Dockerfile run:
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
"clean-src" options and "all" option require that "git checkout" occur.

One or more (or all) supported routers can be built with one script execution 
such as these examples:
```
$ ./build-asuswrt-merlin.sh clean rt-ac5300 cleankernel clean clean-src rt-ac56u
$ ./build-asuswrt-merlin.sh rt-n66u 
$ ./build-asuswrt-merlin.sh all 
```
See "./build-asuswrt-merlin.sh help" for more details. Optional user selected 
"clean" action(s) must precede the router name being built. The "all" option 
automatically does pre-determined clean actions before each supported router 
is built and should be the only option when it is used.
