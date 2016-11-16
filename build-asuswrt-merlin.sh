#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Script to build asuswrt-merlin firmware. This and the other project files are
# assumed to be located in a folder (docker-scripts-asuswrt-merlin/) located at 
# the root of the asuswrt-merlin project tree cloned/pulled/checked-out from git.
#
# Developed on Linux (Fedora 23).
# Also tested on:
#   -Debian Stretch (a.k.a, Testing)
#
# Build using Docker containers.
# The build is structured in 2 steps, one running on the host machine
# and one running inside the Docker container.
#
# Uses locally built docker image called "asuswrt-merlin-addons". 
# See README.md for details. 
#
# Prerequisites for build host:
#
#   Docker, git
#

CONTAINER_NAME=build-asuswrt-merlin
IMAGE_NAME=asuswrt-merlin-addons
BUILD_SCRIPT=build-script.sh
GROUP_ID=$(id -g)
USER_ID=$(id -u)
HOST_UNAME="$(uname)"

# Flag that script did or did not run docker
DOCKER_DID_RUN="n"

# Flag that on last docker run call, just reset file owners
# from root back to script user.
RESET_OWNER="n"

# This *assumes* docker-scripts/ folder containing this file is at the 
# top level (root) of the already checked out asuswrt-merlin git project tree.
#
WORK_FOLDER=$(dirname `pwd`)

# Project root in docker container (mapped to project root in host with
# docker run --volume parameter).
MROOT="/asuswrt-merlin-root"

# define a crtl-c handler since ctrl-c (SIGINT) will result in the container
# continuing to run in the background even though this script exits.
trap ctrl_c_handler INT
function ctrl_c_handler() {
  printf "\nCleaning up running container, please wait..."
  # Remove the possibly still running container 
  docker rm --force -v "${CONTAINER_NAME}" > /dev/null 2> /dev/null
  sleep 3
  # Run container once more to reset owner of files back to
  # the user/group ID of the script runner.
  reset_build_parameters
  RESET_OWNER="y"
  RESTORE_SRC_FROM_GIT="y"  # actually, this avoids some actions
  do_docker_run
  echo "Container removed and file owners reset back to script user."
  # Note: if ctrl-c done during git checkout, all files previously
  # deleted will not be restored. Do a normal git checkout from
  # the top level or re-run script with option clean-src for the 
  # first router built; or use option "all" which also restores the files. 
} 
    
# resets parameters before before next call to do_docker_run() 
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

function do_docker_run() {
    set +e
    # Remove a possible previous early-terminated or crashed container.
    docker rm --force -v "${CONTAINER_NAME}" > /dev/null 2> /dev/null
    set -e

    echo
    echo "Running script inside docker container"

    # Run the script in a fresh Docker container.
    docker run \
      --name="${CONTAINER_NAME}" \
      --tty \
      --hostname "docker" \
      --workdir="/root" \
      --volume="${WORK_FOLDER}:/${MROOT}" \
      ${IMAGE_NAME} \
      /bin/bash "/${MROOT}/$(basename `pwd`)/${BUILD_SCRIPT}" \
        --make-clean-target "${MAKE_CLEAN_TARGET}" \
        --make-cleankernel-target "${MAKE_CLEANKERNEL_TARGET}" \
        --restore-src-from-git "${RESTORE_SRC_FROM_GIT}" \
        --group-id "${GROUP_ID}" \
	--user-id "${USER_ID}" \
	--host-uname "${HOST_UNAME}" \
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
        --do-reset-file-owner "${RESET_OWNER}"

    # Remove the container.
    docker rm --force -v "${CONTAINER_NAME}"

    reset_build_parameters
    DOCKER_DID_RUN="y" 
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
      do_docker_run
      ;;

    rt-ac66u)
      DO_BUILD_RT_AC66U="y"
      shift
      do_docker_run
      ;;

    rt-ac56u)
      DO_BUILD_RT_AC56U="y"
      shift
      do_docker_run
      ;;

    rt-ac68u)
      DO_BUILD_RT_AC68U="y"
      shift
      do_docker_run
      ;;

    rt-ac87u)
      DO_BUILD_RT_AC87U="y"
      shift
      do_docker_run
      ;;

    rt-ac3200)
      DO_BUILD_RT_AC3200="y"
      shift
      do_docker_run
      ;;

    rt-ac88u)
      DO_BUILD_RT_AC88U="y"
      shift
      do_docker_run
      ;;

    rt-ac3100)
      DO_BUILD_RT_AC3100="y"
      shift
      do_docker_run
      ;;

    rt-ac5300)
      DO_BUILD_RT_AC5300="y"
      shift
      do_docker_run
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
      do_docker_run

      MAKE_CLEAN_TARGET="y"
      DO_BUILD_RT_AC66U="y"
      do_docker_run

      # now arch is ARM so need full clean
      # specific arch dir is src-rt-6.x.4708
      RESTORE_SRC_FROM_GIT="y"
      MAKE_CLEANKERNEL_TARGET="y"
      MAKE_CLEAN_TARGET="y"
      DO_BUILD_RT_AC56U="y"
      do_docker_run
      MAKE_CLEAN_TARGET="y"
      DO_BUILD_RT_AC68U="y"
      do_docker_run
      # clean-src seems to be needed for rt-ac87u at this point...
      RESTORE_SRC_FROM_GIT="y"
      MAKE_CLEAN_TARGET="y"
      DO_BUILD_RT_AC87U="y"
      do_docker_run

      # specific arch dir is src-rt-7.x.main/src
      MAKE_CLEAN_TARGET="y"
      DO_BUILD_RT_AC3200="y"
      do_docker_run

      # specific arch dir is src-rt-7.14.114.x/src
      MAKE_CLEAN_TARGET="y"
      DO_BUILD_RT_AC88U="y"
      do_docker_run
      MAKE_CLEAN_TARGET="y"
      DO_BUILD_RT_AC3100="y"
      do_docker_run
      MAKE_CLEAN_TARGET="y"
      DO_BUILD_RT_AC5300="y"
      do_docker_run
      ;;

    *)
      print_usage
      exit 1
      ;;
  esac
done

if [ $DOCKER_DID_RUN == "n" ] ; then
  # no router name provided on command line
  print_usage
  exit 1
else
  # docker did run, run once more to reset owner of files back to
  # the user/group ID of the script runner.
  RESET_OWNER="y"
  do_docker_run
fi

# ----- Done. -----
exit 0
