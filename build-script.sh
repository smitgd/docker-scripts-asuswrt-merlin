#!/bin/bash

# This runs inside the ubuntu docker container to build the firmware.

# Add x for debug
set -euo pipefail
IFS=$'\n\t'

# Project root in docker container (mapped to project root in host with
# docker run --volume parameter). Note: expanded to actual value here due to 
# unquoted EOF above.
MROOT=/asuswrt-merlin-root



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

function reset_files_owner {
  cd ${MROOT}
  # if script terminated with git operations in progress, lock on git index
  # remains set that will prevent starting the script again. Remove lock.
  if [ -e ./.git/index.lock ] ; then
    rm ./.git/index.lock
    # restart the checkout that was interrupted
    echo "First, continue checkout of clean ${MROOT}/release/src/router..."
    git checkout ./release/src/router
  fi
  if [ "${host_uname}" == "Linux" ]
  then
    # set owner of files checked out from root to the id of the user running 
    # the script. Also changes other files produced by the build. This is not
    # essential but makes mananging the source tree easier for the user since 
    # files do not remain owned by root. 
    chown -R ${user_id}:${group_id} ./release
    # change owner of firmware files copied to top level
    chown ${user_id}:${group_id} ./*.trx 
    # change owner of .git/index that also gets set to root if checkout occurs 
    chown ${user_id}:${group_id} ./.git/index 
  fi
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
	# copy firmware file(s) to asuswrt-merlin top level
        cp -p ./image/*.trx ${MROOT}/
    fi
}

# Asuswrt merlin root mapped to ${MROOT} by --volume 
# option of the "run docker" command. Set symbolic links in 
# /opt and set PATH, both needed for toolchain access.
#
ln -s ${MROOT}/tools/brcm /opt/brcm
ln -s ${MROOT}/release/src-rt-6.x.4708/toolchains/hndtools-arm-linux-2.6.36-uclibc-4.5.3 /opt/brcm-arm
PATH=$PATH:/opt/brcm/hndtools-mipsel-linux/bin:/opt/brcm/hndtools-mipsel-uclibc/bin:/opt/brcm-arm/bin

MAKE_CLEAN_STRING=""
MAKE_CLEANKERNEL_STRING=""
do_build="n"
do_owner_reset="n"

while [ $# -gt 0 ]
do
  case "$1" in
    --make-clean-target)
      make_clean_target="$2"
      shift 2
      ;;
    --make-cleankernel-target)
      make_cleankernel_target="$2"
      shift 2
      ;;
    --restore-src-from-git)
      restore_src_from_git="$2"
      shift 2
      ;;
    --group-id)
      group_id="$2"
      shift 2
      ;;
    --user-id)
      user_id="$2"
      shift 2
      ;;
    --host-uname)
      host_uname="$2"
      shift 2
      ;;
    --)
      # Above 6 items now known, set some strings based on them
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
    --do-reset-file-owner)
      do_owner_reset="$2"
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
  elif [ "${do_owner_reset}" == "y" ] ; then
      # this always done last 
      echo "Resetting file ownership from root to script user..."
      reset_files_owner
  fi
done

