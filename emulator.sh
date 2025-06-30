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

usage()
{
  echo "Usage:"
  echo "Run Emulator with out-of-tree artifacts:"
  echo "  Example: $0 cmake_out/vela_qemu-arm64-v8a-ap"
  echo "Run Emulator with board name [deprecated]:"
  echo "  Example: $0 vela"
  exit 1
}

# for out-of-tree artifacts
if test -e "$1/.config"; then
  OUT_DIR="$1"
  if grep -q '^CONFIG_ARCH_CHIP_QEMU=y' ${OUT_DIR}/.config; then
    if grep -q '^CONFIG_ARCH_ARM=y' ${OUT_DIR}/.config; then
      QEMU_ARCH="arm"
    elif grep -q '^CONFIG_ARCH_ARM64=y' ${OUT_DIR}/.config; then
      QEMU_ARCH="aarch64"
    elif grep -q '^CONFIG_ARCH_X86=y' ${OUT_DIR}/.config; then
      QEMU_ARCH="i386"
    elif grep -q '^CONFIG_ARCH_X86_64=y' ${OUT_DIR}/.config; then
      QEMU_ARCH="x86_64"
    elif grep -q '^CONFIG_ARCH_RISCV=y' ${OUT_DIR}/.config; then
      QEMU_ARCH="riscv32"
    fi
    EMULATOR_DIR="${TOP_DIR}/prebuilts/qemu/${HOST_OS}-${HOST_ARCH}"
    EMULATOR_BIN="${EMULATOR_DIR}/bin/qemu-system-${QEMU_ARCH}"
    EMULATOR_ARGS="-L ${EMULATOR_DIR}/share/qemu -kernel ${OUT_DIR}/nuttx $(cat ${OUT_DIR}/qemu_args.txt)"
    echo "RUN ${EMULATOR_BIN} ${EMULATOR_ARGS}"
    ${EMULATOR_BIN} ${EMULATOR_ARGS}
  fi
# for deprecated method
else
  if test -n "$1"; then
    BOARD_NAME=$1
  else
    usage
  fi

  if test -d ${TOP_DIR}/vendor/qemu/boards/${BOARD_NAME}; then
    TARGETDIR=${TOP_DIR}/vendor/qemu/boards/${BOARD_NAME}
  elif test -d ${TOP_DIR}/vendor/openvela/boards/${BOARD_NAME}; then
    TARGETDIR=${TOP_DIR}/vendor/openvela/boards/${BOARD_NAME}
  else
    usage
  fi

  echo "TARGETDIR = ${TARGETDIR}"
  shift

  source ${TARGETDIR}/prebuilts/tools/run_emulator.sh
fi
