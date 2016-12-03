#!/bin/bash

# This runs directly on linux to build the firmware.

# Add x for debug
set -euo pipefail
IFS=$'\n\t'

# Root location of asuswrt-merlin tree 
MROOT=$HOME/asuswrt-merlin

# Name assigned in virtualBox to folder shared between host and virtualBox 
# running linux that is mounted below and outputs files are copied to.
# Also define the linux mount point.
SHARE_NAME=shared
OUTPUTS_MPOINT=${MROOT}/outputs

# Fix-ups needed because of different version of autotools 
# Skipped if already done, i.e., configure.in moved to configure.ac 
#
function do_autoconfig_fixups() {
  cd ${MROOT}/release/src/router/libxml2
  if [ -e configure.in ]
  then
    sed -i s/AM_C_PROTOTYPES/dnl\ AM_C_PROTOTYPES/g configure.in
    mv configure.in configure.ac
    libtoolize
    aclocal
    autoheader
    automake --force-missing --add-missing
    autoconf

    cd ${MROOT}/release/src/router/libdaemon
    libtoolize
    aclocal
    autoheader
    automake --force-missing --add-missing
    autoconf
  fi
}

# Called before each router build when "clean-src" option used.
# This is needed between builds of multiple routers when the architecture
# changes between sucessive build, e.g., current build mips, previous build
# was arm such as when "all" option is used. "make cleankernel" and 
# "make clean" don't 100% remove files from a previous build and
# some residual (untracked maybe .gitignore'd) files cause build failure.
# Of course, this may remove changes not yet committed to git so use
# option "clean-src" with care and *only* when
# source tree is controlled by git so a proper restore can occur.
#
function rm_and_restore_src_from_git {
  # Note: must cd into git tree before git command works.
  cd ${MROOT}
  echo "removing ${MROOT}/release/src/router"
  rm -rf ./release/src/router
  echo "checking out clean ${MROOT}/release/src/router"
  git checkout ./release/src/router
}

function reset_git_lock {
  cd ${MROOT}
  # if script terminated with git operations in progress, lock on git index
  # remains set that will prevent starting the script again. Remove lock.
  if [ -e ./.git/index.lock ] ; then
    rm ./.git/index.lock
    # restart the checkout that was interrupted
    echo "First, continue checkout of clean ${MROOT}/release/src/router..."
    git checkout ./release/src/router
  fi
}

function create_symlinks_and_mount_switch_non_root_user {
    # Note: setting symlinks into /opt must be done as root which
    # this runs as. PATH must be set later by non-root user since build,
    # after su below, runs as non-root user.
    # This will be called again after symlinks and mounts are already done
    # when more than one router built at a time.
    ln -sf ${MROOT}/tools/brcm /opt/brcm
    ln -sf ${MROOT}/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3 /opt/brcm-arm
    # make outputs directory which becomes the mount point for accessing
    # output *.trx files on the host. To avoid root ownership, the 
    # non-root script runner's gid and uid are passed to mount so cp
    # of files to host occur with no permission problems. Must do this
    # before switching to non-root user.
    mountpoint -q "${OUTPUTS_MPOINT}" 
    if [ $? -ne 0 ] ; then
      # not currently a mountpoint. create it and do the mount. The mountpoint
      # will already exists after the first script call so this avoids error 
      # stoppage.
      mkdir -p ${OUTPUTS_MPOINT}
      mount -t vboxsf -o uid=${user_id},gid=${group_id} ${SHARE_NAME} ${OUTPUTS_MPOINT}
    fi
    # re-run this script as non-root user but with already "consumed" leading
    # options stripped off. This does the bulk of the build. su requires 
    # a user name which must be determined from user_id.
    exec su "$(getent passwd ${user_id} | cut -d: -f1)" -c "$0 $residue"
}

function build_router_fw {
    if [ "${restore_src_from_git}" == "y" ] 
    then
        rm_and_restore_src_from_git
        do_autoconfig_fixups
    fi 
    cd ${MROOT}/release/${router_dir}
    if [ "${MAKE_CLEANKERNEL_STRING}" != "" ] ; then
        MAKE_CLEANKERNEL_STRING="make ${MAKE_CLEANKERNEL_STRING}"
        eval ${MAKE_CLEANKERNEL_STRING}
    fi
    rm -f .config
    if [ "${MAKE_CLEAN_STRING}" != "" ] ; then
        MAKE_CLEAN_STRING="make ${MAKE_CLEAN_STRING}"
        eval ${MAKE_CLEAN_STRING}
    fi
    eval make ${router} 
    if compgen -G "./image/*.trx" > /dev/null
    then
        # copy only newest (just built) firmware file to asuswrt-merlin 
        # top level. Note: Existing firmware files are not affected by
        # various "clean" targets it seems, so with just a simple cp, old  
        # files are copied too. So this just copies the newest *.trx.
        cp -p "`ls -dtr1 ./image/*.trx | tail -1`" ${OUTPUTS_MPOINT}
    fi
}


MAKE_CLEAN_STRING=""
MAKE_CLEANKERNEL_STRING=""
do_build="n"
do_reset_git_lock="n"

while [ $# -gt 0 ]
do
  case "$1" in
    --group-id)
      group_id="$2"
      shift 2
      ;;
    --user-id)
      user_id="$2"
      shift 2
      residue="$@"
      create_symlinks_and_mount_switch_non_root_user
      ;;
    --make-clean-target)
      make_clean_target="$2"
      shift 2
      PATH=$PATH:/opt/brcm/hndtools-mipsel-linux/bin:/opt/brcm/hndtools-mipsel-uclibc/bin:/opt/brcm-arm/bin
      ;;
    --make-cleankernel-target)
      make_cleankernel_target="$2"
      shift 2
      ;;
    --restore-src-from-git)
      restore_src_from_git="$2"
      shift 2
      ;;
    --)
      # Above 5 items now known, set some strings based on them
      if [ "${restore_src_from_git}" == "n" ] 
      then
          do_autoconfig_fixups
      fi
      if [ "${make_cleankernel_target}" == "y" ] 
      then
          MAKE_CLEANKERNEL_STRING="cleankernel"
      fi
      if [ "${make_clean_target}" == "y" ] 
      then
          MAKE_CLEAN_STRING="clean"
      fi
      shift
      ;;
    --do-build-rt-n66u)
      do_build="$2"
      router="rt-n66u"
      router_dir=src-rt-6.x
      shift 2
      ;;
    --do-build-rt-ac66u)
      do_build="$2"
      router="rt-ac66u"
      router_dir=src-rt-6.x
      shift 2
      ;;
    --do-build-rt-ac56u)
      do_build="$2"
      router="rt-ac56u"
      router_dir=src-rt-6.x.4708
      shift 2
      ;;
    --do-build-rt-ac68u)
      do_build="$2"
      router="rt-ac68u"
      router_dir=src-rt-6.x.4708
      shift 2
      ;;
    --do-build-rt-ac87u)
      do_build="$2"
      router="rt-ac87u"
      router_dir=src-rt-6.x.4708
      shift 2
      ;;
    --do-build-rt-ac3200)
      do_build="$2"
      router="rt-ac3200"
      router_dir=src-rt-7.x.main/src
      shift 2
      ;;
    --do-build-rt-ac88u)
      do_build="$2"
      router="rt-ac88u"
      router_dir=src-rt-7.14.114.x/src
      shift 2
      ;;
    --do-build-rt-ac3100)
      do_build="$2"
      router="rt-ac3100"
      router_dir=src-rt-7.14.114.x/src
      shift 2
      ;;
    --do-build-rt-ac5300)
      do_build="$2"
      router="rt-ac5300"
      router_dir=src-rt-7.14.114.x/src
      shift 2
      ;;
    --do-reset-git-lock)
      do_reset_git_lock="$2"
      do_build="n"
      shift 2
      ;;
    *)
      echo "Unknown option $1, exit."
      exit 1
  esac
  if [ "${do_build}" == "y" ]
  then
      build_router_fw
  elif [ "${do_reset_git_lock}" == "y" ] ; then
      # this always done last 
      echo "Check and reset possible git lock..."
      reset_git_lock
  fi
done

