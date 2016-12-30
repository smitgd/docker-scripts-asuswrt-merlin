Script linux-build-asuswrt-merlin.sh assists with the asuswrt-merlin builds in a
standardized enviroment (Ubuntu Xenial) using VirtualBox or directly on linux.
A typical usage is to run VirtualBox on a windows host while running Ubuntu
Xenial as the guest OS. The script also works when running directly (natively)
on linux and has been tested on Fedora 23 and Debian Stretch.

Here are some example build environments that are possible using VirtualBox:
```
Host                           Guest

Windows7                       Ubuntu Xenial
Windows10                      Fedora 25 (non-standard)
Fedora23                       Ubuntu Xenial
DebianStretch                  Fedora 23 (non-standard)
```
Build on Xenial, Ubuntu 16.04.1 LTS (Xenial Xerus), is currently designated in
project asuswrt-merlin as the "official" build environment. See
asuswrt-merlin/README.TXT.

Set-up for Windows VirtualBox with guest OS Ubuntu Xenial is described now.
This assumes modern 64-bit Intel/AMD hardware and should work for at least
Windows versions 7 to 10 (tested on Windows 7 and 10 home editions).

Download the desired Ubuntu Xenial ISO file. A full desktop version or a server
version can be installed. A third smaller ISO file that does most of the install
via the internet is also available and installs the server version. It can be
found by seaching for "ubuntu xenial mini.iso". The larger desktop and server
ISO's can also be found by seaching for "ubuntu xenial iso". Be sure to download
the 64-bit ISO for the selected version.

Go to VirtualBox site and download and install the 64-bit version for Windows,
accepting the defaults. Run the VirtualBox program.

Click the "New" icon and enter a "Name" for the virtual machine (e.g., xenial).

For "Type" select "Linux" and for Version select "Ubuntu (64-bit)". (If only
32-bit OS types appear, you probably need to reboot and access the bios
setting and ensure that hardware virtualization is selected.)

Next, a screen to allocate RAM memory to the virtual machine appears. The
default of 1024 MB is acceptable. More than that can be allocated within the
"green" region and it may improve virtual machine performance. Click "Next".

Now a series of screens appear to define a hard disk. Select "Create a virtual
hard disk now" and click "Create". On the next screen select "VDI" and click
"Next". Then select "Fixed size" on the next screen and click "Next". Finally,
on the last screen set the disk size to at least 30G for the server Ubuntu
installation or 40G for desktop and click "Create". Several minutes may be
required to create and format the virtual disk.

Next click the "Setting" icon and select "Storage". Select (highlight) the
"Controller:IDE" item in the tree and click the "+" icon having the pop-up
description "Adds optical drive". Navigate to the Ubuntu ISO file
downloaded above (e.g., mini.iso) and open it.

Now back on the VirtualBox program, click the green "Start" icon. This will
boot the Ubuntu installation just opened above and a typical installation
can begin choosing mostly defaults except for personalization items such as
user name, password, timezone, keyboard type, etc. No need to encrypt or do
special formatting or partitioning on the "disk".

When the installation is complete, a reboot will be required. Some installation
programs automatically remove (eject) the installation ISO . If not
automatically removed, to avoid re-entering the installation program again, the
installation ISO must be manually removed. This is accomplished by first
"powering down" the virtual machine by selecting the VirtualBox menu item "File"
followed by "Close..." then select "Power off the machine" and click OK. At the
main VirtualBox program click the "Settings" icon and then again select the
"Storage" item from the list. In the tree select the installation ISO (e.g.,
mini.iso) and then click the "-" icon having the pop-up description "Removes
selected storage attachment" and complete the removal by clicking OK.  Then,
back at the VirtualBox program, click "Start" again and the just installed
Ubuntu Xenial will boot.

The following instructions assume that the server version is installed so only
simple 100-column "tty" terminals are available.  Full desktop GUI operational
description is beyond the scope of this README, however it can still be used if
preferred and if installed.

Log in to Ubuntu Xenial at the prompt with your non-root user name. If the
default server installation does not include git, it is needed to obtain the
projects.  So, you must manually install it:
```
$ cd
$ sudo apt-get install git
```
Next clone the asuswrt-merlin project from the repository, e.g.,:
```
$ git clone https://github.com/RMerl/asuswrt-merlin
```
Depending on network and processor speeds, this may take some time. While
project cloning occurs you can open another terminal and obtain this script
project, via another git clone:
```
$ # If clone above still going, do ctrl-alt-F2 (or RightCtrl-F2) and log in to
$ # the new "tty".
$ cd asuswrt-merlin
$ git clone https://github.com/smitgd/docker-scripts-asuswrt-merlin
```
This script project is small and should load quickly. Before router firmware can
be built using the scripts, the git clone of asuswrt-merlin must complete and
several additional Ubuntu packages also must be obtained. Run this script (in
another tty if necessary) to obtain and install the required Ubuntu packages:
```
$ cd ~/asuswrt-merlin/docker-scripts-asuswrt-merlin
$ sudo ./linux-apt-setup.sh
```
By default, the build scripts copy the resulting firmware file for each built
router model into ~/asuswrt-merlin/outputs/ folder and are not visible on
the host O/S (e.g., Window). If visiblity of outputs/ on the host is wanted
then "Guest Additions" must be enabled on VirtualBox. The Ubuntu package that
supports this is installed by the linux-apt-setup.sh script, but it does not
enable it.

To enable host visibility of firmware files, first, on the host O/S (e.g.,
Windows) create or choose a location such as c:\Users\<yourName>\router-files
that will be configured to access the built firmware files. This path must exist
on the host.

Then back on the running guest O/S (Ubuntu Xenial) choose the VirtualBox menu
item along the top called "Devices" and click "Shared Folders" followed by
"Shared Folders Settings...". In the "Shared Folders" dialog, click the "+" icon
having the pop-up description "Adds new shared folder".  In the "Add Share"
dialog, enter the host directory that was chosen or created above in "Folder
Path", e.g., c:\Users\<yourName>\router-files. Then change the the next item
"Folder Name" from router-files to shared. (The build script requires the
"Folder Name" always have the name "shared" to successfully mount the vboxsf
filesystem device.) Finally, select the "Make Permanent" item and click OK twice
to complete the setup and return to running Ubuntu.

After asuswrt-merlin and scripts projects are cloned and the require Ubuntu
packages are installed and (optionally) after "guest additions" are configured,
router firmware build can begin.

No pull or other git command occurs that contact the asuswrt-merlin git
repository in the build script. So if a pull or other git command is needed to
set up the local tree, it must be done manually before running the script.

One or more or all supported router models can be built with a single script
execution as shown in these examples:
```
$ sudo ./linux-build-asuswrt-merlin.sh clean rt-ac5300 cleankernel clean clean-src rt-ac56u
$ sudo ./linux-build-asuswrt-merlin.sh rt-n66u
$ sudo ./linux-build-asuswrt-merlin.sh all
```
See "./linux-build-asuswrt-merlin.sh help" for more details. Optional user
selected "clean" action(s) must precede the router name being built. The "all"
option automatically does pre-determined clean actions before each supported
router is built and should be the only option when it is used.

Sudo is required because root access is required to set symbolic links in /opt
and to mount the shared outputs/ directory for accessing the generated router
firmware file on the host O/S as described above. However, after these actions
are accomplished at script startup, the script runs as a normal user to complete
the build.

Hint: It can take a long time to complete the script even when only one router
model is built. To prevent the console from blanking after about 10 minutes
the follow command can be entered (in a new tty if necessary, e.g.,
RightCrtl-F6):
```
$ setterm -blank 0 -powerdown 0
```
It is important that asuswrt-merlin project be under git control since the
"clean-src" option and "all" option require that portions of the source tree be
deleted and "git checkout" occur. So, if these build options are used, make sure
that any changes are committed at least locally (or stashed) before starting a
build to avoid possible loss of work.

This information and the linux-build-asuswrt-merlin.sh script can also be used
on natively running Ubuntu Xenial without VirtualBox. Only the information
regarding "Guest Additions" does not apply since mapping the outputs/ folder
on to a "host" system is not relevant.

This information and script can also be used on other linux distributions and
versions with or without VirtualBox. A setup file to install the needed
dependencies for Fedora is provided, linux-dnf-setup.sh and the build script
linux-build-asuswrt-merlin.sh can also be used there in the same way as
described above. Note: Setup of "Guest Addition" in VirtualBox for other
distributions can differ from the Ubuntu method described above and is beyond
the scope of this README.
