This describes a way to build asuswrt-merlin on OSX using the same build script 
but using a separate Linux box as the docker host instead of using boot2docker or
newer docker methods only on the OSX machine. This is probably mostly of 
academic interest since the build can probably just be done on the linux machine
as described in README.md with much less trouble.
```
Symbols used in description below:
OSX user name = auser
OSX hostname = ahost  (or IP address)
Linux hostname = lhost (or IP address)
```
The first issue is that the default filesystem on OSX is case insensitive. 
Unfortunately the asuswrt-merlin tree contains several places where, for
example, different files such as foo.c and foO.c both exist in the same 
directory. OSX only lists foO.c and git on OSX see this a change in the 
contents of foO.c. The solution is to create a new disk image that is case 
sensitive and mount it at a convenient place and move the asuswrt-merlin git
tree onto it. (Note: Doing this is necessary regardless of how the build is 
done on OSX.)

Run the built-in OSX program "Disk Utility" to allocate unused disk space
for a new .dmg (disk image) file:
```
File | New | Blank Disk Image
Save as: git-stuff  (becomes the name of the .dmg file)
Where: ahost  (directory where git-stuff.dmg disk image file is saved)
Size: 20G  (cloned asuswrt-merlin tree is about 5G so 20G should be OK)
Format: MacOS Extended (Case-sensitive, journaled)  <---Most important!
Encryption: None   (default)
Partition: Single partition - GUID Partition map (default)
Image Format: read/write disk image (default)
```
This creates the file /Users/auser/git-stuff.dmg and mounts it at 
/Volumes/Disk Image/git-stuff

Spaces in "Disk Image" mount point seem to cause problems so to change the 
mount point to auser home do:
```
$ diskutil umount /Volumes/Disk\ Image/
$ mkdir -p /Users/auser/git-stuff 
$ hdiutil attach -mountpoint /Users/auser/git-stuff /Users/auser/git-stuff.dmg 
```
Move or copy asuswrt-merlin tree to /Users/auser/git-stuff or just clone from
repo there. If not cloned, may need to do a checkout from the top level
to clean-up "modified" files:
```
$ cd ~/auser/git-stuff/asuswrt-merlin
$ git checkout .
```
Automatic re-mount on reboot at the desired mountpoint can be set by
creating an executable file /Library/LaunchDaemons/system.dmg.mount.plist
containing this:
```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
          <key>RunAtLoad</key>
          <true/>
          <key>Label</key>
          <string>system.dmg.mount</string>
          <key>ProgramArguments</key>
          <array>
                    <string>hdiutil</string>
                    <string>attach</string>
                    <string>-mountpoint</string>
                    <string>/Users/auser/git-stuff</string>
                    <string>/Users/auser/git-stuff.dmg</string>
          </array>
</dict>
</plist>
```
This should solve the case insensitive issues which is necessary regardless
of how the OSX build of asuswrt-merlin is done. 

Now, to complete the build, configure an NFS server on OSX and NFS client on 
linux:

On OSX, edit the file /etc/export to contain this line:
```
/Users/auser/git-stuff/asuswrt-merlin  --mapall=auser ahost
```
On OSX, set this environment variable:
```
$ export DOCKER_HOST=tcp://lhost:4243
```
Start or restart the OSX NFS daemon:
```
$ sudo nfsd restart
```
Now on Linux, duplicate the OSX path to asuswrt-merlin at root:
```
$ sudo mkdir -p /Users/auser/git-stuff/asuswrt-merlin
```
On Linux, configure docker daemon so that communcation can occur via tcp/ip
as well as the default local unix socket. This allows the docker client on OSX
to use the docker daemon on the linux host. This can vary by distribution, but
for Fedora the file /etc/sysconfig/docker must be edited to allow connection 
via tcp using port 4243. The OPTIONS line (with added -H tcp:...) will look 
like this:
```
OPTIONS='--log-driver=journald -H unix:///var/run/docker.sock -H tcp://lhost:4243'
```
Now start or restart the docker daemon on linux (well, for Fedora) like this:
```
$ sudo systemctl restart docker 
```
It will also probably be necessary to open tcp port 4243 on the Linux firewall
to allow connections from the OSX docker client.

On linux, mount the exported NFS directory from OSX:
```
$ sudo mount -t nfs ahost:/Users/auser/git-stuff/asuswrt-merlin \
        /Users/auser/git-stuff/asuswrt-merlin
```
Now back on OSX, do the following to verify that docker host on Linux is 
working and being used. First make sure boot2docker is down and that only
DOCKER_HOST is set.
```
$ boot2docker down
$ unset <any other DOCKER_* environment vars that might be set except DOCKER_HOST>
$ docker run -it --volume=/Users/auser/git-stuff/asuswrt-merlin:/asuswrt-merlin-root \
    asus-merlin-addons bash
```
A root linux shell prompt should occur and asuswrt-merlin files should be 
visible at /asuswrt-merlin-root

On Linux the same project files should appear at 
/Users/auser/git-stuff/asuswrt-merlin

On OSX, exit the root shell and change to
```
$ cd ~/auser/git-stuff/asuswrt-merlin/docker-scripts-asuswrt-merlin 
```
and run build-asuswrt-merlin.sh as described in README.md to do the build
on OSX using Linux as the docker host.

