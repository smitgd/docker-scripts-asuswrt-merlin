#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Script to build asuswrt-merlin firmware. This and other files are assumed to
# be located in a folder (docker-scripts/) located at the root of the 
# asuswrt-merlin project already cloned/pulled from git.
#
# Developed on OS X.
# Also tested on:
#   -
#
# Build using Docker containers.
# The build is structured in 2 steps, one running on the host machine
# and one running inside the Docker container.
#
# At first run, Docker will download/build 3 relatively large
# images (1-2GB) from Docker Hub.
#
# Prerequisites for build host:
#
#   Docker
#   curl, git, automake, patch, tar, unzip
#
# When running on OS X, MacPorts with the following ports installed:
#
#   sudo port install libtool automake autoconf pkgconfig
#   sudo port install cmake boost libconfuse swig-python
#   sudo port install texinfo texlive
#

# 
CONTAINER_NAME=build-asuswrt-merlin
IMAGE_NAME=asuswrt-merlin-addons
BUILD_SCRIPT=build-script.sh

# Mandatory definition.
APP_NAME="AsusWrt-Merlin"

APP_LC_NAME=$(echo "${APP_NAME}" | tr '[:upper:]' '[:lower:]')

# This *assumes* docker-scripts/ folder containing this file is at the 
# top level (root) of the already checked out asuswrt-merlin git project tree.
#
WORK_FOLDER=$(dirname `pwd`)

# Project root in docker container (mapped to project root in host with
# docker run --volume parameter).
MROOT="/asuswrt-merlin-root"

# reset these before before next call to do_docker_run() 
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
    echo "Run build script inside docker container"

    # Run the script in a fresh Docker container.
    docker run \
      --name="${CONTAINER_NAME}" \
      --tty \
      -i \
      --hostname "docker" \
      --workdir="/root" \
      --volume="${WORK_FOLDER}:/${MROOT}" \
      ${IMAGE_NAME} \
      /bin/bash "/${MROOT}/$(basename `pwd`)/${BUILD_SCRIPT}" \
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
        --do-build-rt-ac5300 "${DO_BUILD_RT_AC5300}" 

    # Remove the container.
    docker rm --force -v "${CONTAINER_NAME}"

    reset_build_parameters
}

source ./produce-build-script.sh

# ----- Parse actions and command line options. -----
reset_build_parameters

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

    help)
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
      exit 1
      ;;

    *)
      echo "Unknown action/option $1: Run \"$0 help\""
      exit 1
      ;;
  esac

done

# ----- Done. -----
exit 0
