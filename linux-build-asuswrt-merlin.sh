#!/bin/bash
#
# Script to build asuswrt-merlin firmware directly on linux. This and the other
# project files are assumed to be located in a folder
# (docker-scripts-asuswrt-merlin/) located at the root of the asuswrt-merlin
# project tree cloned/pulled/checked-out from git.
#
# Developed on Linux (Fedora 23).
# Also tested on:
#   -Debian Stretch (a.k.a, Testing)
#
# Prerequisites for build host:
#
#   git
#
set -euo pipefail
IFS=$'\n\t'

# call this script to do the main build
BUILD_SCRIPT=linux-build-script.sh

# Flag that script did or did not run
BUILD_DID_RUN="n"

# Flag that on last script run check that git was not left locked.
RESET_GIT_LOCK="n"

# define a crtl-c handler since ctrl-c (SIGINT) will result in the container
# continuing to run in the background even though this script exits.
# PROBABLY NOT NEEDED WHEN RUN ON LINUX  -- tbd
trap ctrl_c_handler INT
function ctrl_c_handler() {
  # Run script once more to make sure git is not locked
  reset_build_parameters
  RESET_GIT_LOCK="y"
  RESTORE_SRC_FROM_GIT="y"  # actually, this avoids some actions
  do_build_run
  # Note: if ctrl-c done during git checkout, all files previously
  # deleted will not be restored. Do a normal git checkout from
  # the top level or re-run script with option clean-src for the
  # first router built; or use option "all" which also restores the files.
}

# resets parameters before before next call to do_build_run()
#
function reset_build_parameters() {
    MAKE_CLEAN_TARGET="n"
    MAKE_CLEANKERNEL_TARGET="n"
    RESTORE_SRC_FROM_GIT="n"
    DO_BUILD_RT_N66U="n"
    DO_BUILD_RT_AC66U="n"
    DO_BUILD_RT_AC56U="n"
    DO_BUILD_RT_AC68U="n"
    DO_BUILD_RT_AC87U="n"
    DO_BUILD_RT_AC3200="n"
    DO_BUILD_RT_AC88U="n"
    DO_BUILD_RT_AC3100="n"
    DO_BUILD_RT_AC5300="n"
}

function do_build_run() {
    echo
    echo "Running script directly on linux"

    # Run the build script
    ./"${BUILD_SCRIPT}" \
        --group-id "${SUDO_GID}" \
	--user-id "${SUDO_UID}" \
        --make-clean-target "${MAKE_CLEAN_TARGET}" \
        --make-cleankernel-target "${MAKE_CLEANKERNEL_TARGET}" \
        --restore-src-from-git "${RESTORE_SRC_FROM_GIT}" \
        -- \
        --do-build-rt-n66u "${DO_BUILD_RT_N66U}" \
        --do-build-rt-ac66u "${DO_BUILD_RT_AC66U}" \
        --do-build-rt-ac56u "${DO_BUILD_RT_AC56U}" \
        --do-build-rt-ac68u "${DO_BUILD_RT_AC68U}" \
        --do-build-rt-ac87u "${DO_BUILD_RT_AC87U}" \
        --do-build-rt-ac3200 "${DO_BUILD_RT_AC3200}" \
        --do-build-rt-ac88u  "${DO_BUILD_RT_AC88U}" \
        --do-build-rt-ac3100 "${DO_BUILD_RT_AC3100}" \
        --do-build-rt-ac5300 "${DO_BUILD_RT_AC5300}" \
        --do-reset-git-lock "${RESET_GIT_LOCK}"

    reset_build_parameters
    BUILD_DID_RUN="y"
}

function print_usage {
      echo "Build the asuswrt-merlin firmware for listed router(s)."
      echo "Usage:"
      echo "    $0 [clean] [cleankernel] [clean-src] router ... | help | all"
      echo "    clean       Do \"make clean\" before router build"
      echo "    cleankernel Do \"make cleankernel\" before router build"
      echo "    clean-src   Do \"rm -r release/src/router ; git checkout release/src\" before router build"
      echo "                CAUTION: Deletes any uncommitted source changes!"
      echo "    help        Print this usage information"
      echo "    router      Router(s) to build, e.g., rt-ac5300 rt-ac56u. \"Clean\" option(s) must be before router."
      echo "    all         Build all routers: rt-n66u, rt-ac66u, rt-ac56u, rt-ac68u, rt-ac87u,"
      echo "                                   rt-ac3200, rt-ac88u, rt-ac3100, rt-ac5300. Appropriate clean options"
      echo "                                   will automatically precede each router build. \"all\" option will"
      echo "                                   also remove uncommited source changes!"
}

# ----- Parse actions and command line options. -----
reset_build_parameters

# Make sure at least one option was entered.
if [ $# -eq 0 ] ; then
  print_usage
  exit 1
fi

# Make sure each entered option is valid, i.e., no typos. Without this, later
# options are checked only after the leading routers are built which can be long
# after starting the script, depending on how many router types are entered on
# the command line. Also, make sure clean operation is followed by a router
# type and not last.
LAST_IS_CLEAN="n"
for opt in "$@"
do
  case "$opt" in
    clean|cleankernel|clean-src)
      LAST_IS_CLEAN="y"
      ;;
    rt-n66u|rt-ac66u|rt-ac56u|rt-ac68u|rt-ac87u|rt-ac3200|rt-ac88u|rt-ac3100|rt-ac5300|all)
      LAST_IS_CLEAN="n"
      ;;
    *)
      print_usage
      exit 1
      ;;
  esac
done
if [ $LAST_IS_CLEAN == "y" ] ; then
    print_usage
    exit 1
fi

# Now interate through options again and do build for each router listed.
while [ $# -gt 0 ]
do
  case "$1" in

    clean)
      MAKE_CLEAN_TARGET="y"
      shift
      ;;

    cleankernel)
      MAKE_CLEANKERNEL_TARGET="y"
      shift
      ;;

    clean-src)
      RESTORE_SRC_FROM_GIT="y"
      shift
      ;;

    rt-n66u)
      DO_BUILD_RT_N66U="y"
      shift
      do_build_run
      ;;

    rt-ac66u)
      DO_BUILD_RT_AC66U="y"
      shift
      do_build_run
      ;;

    rt-ac56u)
      DO_BUILD_RT_AC56U="y"
      shift
      do_build_run
      ;;

    rt-ac68u)
      DO_BUILD_RT_AC68U="y"
      shift
      do_build_run
      ;;

    rt-ac87u)
      DO_BUILD_RT_AC87U="y"
      shift
      do_build_run
      ;;

    rt-ac3200)
      DO_BUILD_RT_AC3200="y"
      shift
      do_build_run
      ;;

    rt-ac88u)
      DO_BUILD_RT_AC88U="y"
      shift
      do_build_run
      ;;

    rt-ac3100)
      DO_BUILD_RT_AC3100="y"
      shift
      do_build_run
      ;;

    rt-ac5300)
      DO_BUILD_RT_AC5300="y"
      shift
      do_build_run
      ;;

    all)
      shift
      # set build parameters to ensure successful and complete build
      # of all routers with differing architectures.

      reset_build_parameters

      # full clean needed in case previous build arch was ARM
      # (arch for first two routers is MIPS).
      RESTORE_SRC_FROM_GIT="y"
      MAKE_CLEANKERNEL_TARGET="y"
      MAKE_CLEAN_TARGET="y"
      DO_BUILD_RT_N66U="y"
      do_build_run

      MAKE_CLEAN_TARGET="y"
      DO_BUILD_RT_AC66U="y"
      do_build_run

      # now arch is ARM so need full clean
      # specific arch dir is src-rt-6.x.4708
      RESTORE_SRC_FROM_GIT="y"
      MAKE_CLEANKERNEL_TARGET="y"
      MAKE_CLEAN_TARGET="y"
      DO_BUILD_RT_AC56U="y"
      do_build_run
      MAKE_CLEAN_TARGET="y"
      DO_BUILD_RT_AC68U="y"
      do_build_run
      # clean-src seems to be needed for rt-ac87u at this point...
      RESTORE_SRC_FROM_GIT="y"
      MAKE_CLEAN_TARGET="y"
      DO_BUILD_RT_AC87U="y"
      do_build_run

      # specific arch dir is src-rt-7.x.main/src
      MAKE_CLEAN_TARGET="y"
      DO_BUILD_RT_AC3200="y"
      do_build_run

      # specific arch dir is src-rt-7.14.114.x/src
      MAKE_CLEAN_TARGET="y"
      DO_BUILD_RT_AC88U="y"
      do_build_run
      MAKE_CLEAN_TARGET="y"
      DO_BUILD_RT_AC3100="y"
      do_build_run
      MAKE_CLEAN_TARGET="y"
      DO_BUILD_RT_AC5300="y"
      do_build_run
      ;;

    *)
      print_usage
      exit 1
      ;;
  esac
done

if [ $BUILD_DID_RUN == "n" ] ; then
  # no router name provided on command line
  print_usage
  exit 1
else
  # rcript did run, run once more to make sure script running didn't
  # leave git locked by doing ctrl-c during a git checkout.
  RESET_GIT_LOCK="y"
  do_build_run
fi

# ----- Done. -----
exit 0
