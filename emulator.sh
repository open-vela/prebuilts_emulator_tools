#!/bin/bash

if [ x"$(uname)" == x"Linux" ]; then
  HOST_OS="linux"
elif [ x"$(uname)" == x"Darwin" ]; then
  HOST_OS="darwin"
fi

if [ x"$(uname -m)" == x"arm64" -o x"$(uname -m)" == x"aarch64" ]; then
  HOST_ARCH="aarch64"
elif [ x"$(uname -m)" == x"x86_64" ]; then
  HOST_ARCH="x86_64"
fi

if [ x"$(uname)" == x"Darwin" ]; then
TOP_DIR=$(realpath $0 | sed 's#/prebuilts/emulator/tools/emulator.sh##g')
else
TOP_DIR=$(readlink -f $0 | sed 's#/prebuilts/emulator/tools/emulator.sh##g')
fi

EMULATOR_DIR="${TOP_DIR}/prebuilts/emulator/${HOST_OS}-${HOST_ARCH}"
EMULATOR_BIN="${EMULATOR_DIR}/emulator"

TARGETDIR=${TOP_DIR}/vendor/openvela/boards/$1
echo "TARGETDIR = ${TARGETDIR}"
shift

source ${TARGETDIR}/prebuilts/tools/run_emulator.sh
