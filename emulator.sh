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

merge_args()
{
  EMULATOR_GOLDFISH_ARGS=""
  EMULATOR_QEMU_ARGS=""

  found_qemu=false
  for arg in ${EMULATOR_COMMON_ARGS}; do
    if [ "${arg}" == "-qemu" ]; then
        found_qemu=true
        continue
    fi

    if ${found_qemu}; then
        EMULATOR_QEMU_ARGS="$EMULATOR_QEMU_ARGS $arg"
    else
        EMULATOR_GOLDFISH_ARGS="$EMULATOR_GOLDFISH_ARGS $arg"
    fi
  done

  found_qemu=false
  for arg in ${EMULATOR_EXTRA_ARGS}; do
    if [ "${arg}" == "-qemu" ]; then
        found_qemu=true
        continue
    fi

    if ${found_qemu}; then
        EMULATOR_QEMU_ARGS="$EMULATOR_QEMU_ARGS $arg"
    else
        EMULATOR_GOLDFISH_ARGS="$EMULATOR_GOLDFISH_ARGS $arg"
    fi
  done

  echo ${EMULATOR_GOLDFISH_ARGS} -qemu ${EMULATOR_QEMU_ARGS}
}

# for out-of-tree artifacts
if test -e "$1/.config"; then
  OUT_DIR="$1"
  shift
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
  if grep -q '^CONFIG_ARCH_CHIP_QEMU=y' ${OUT_DIR}/.config; then
    EMULATOR_DIR="${TOP_DIR}/prebuilts/qemu/${HOST_OS}-${HOST_ARCH}"
    EMULATOR_BIN="${EMULATOR_DIR}/bin/qemu-system-${QEMU_ARCH}"
    EMULATOR_ARGS="-L ${EMULATOR_DIR}/share/qemu -kernel ${OUT_DIR}/nuttx $(cat ${OUT_DIR}/qemu_args.txt)"
    echo "RUN ${EMULATOR_BIN} ${EMULATOR_ARGS}"
    ${EMULATOR_BIN} ${EMULATOR_ARGS}
  elif grep -Eq '^CONFIG_ARCH_CHIP_GOLDFISH_(ARM|ARM64|X86_64)=y' ${OUT_DIR}/.config; then
    mkdir -p ${OUT_DIR}/system
    echo "ro.product.cpu.abi=${QEMU_ARCH}" | sed 's/aarch64/arm64/g' > ${OUT_DIR}/system/build.prop
    export ANDROID_EMULATOR_VELA=true
    export ANDROID_BUILD_TOP=${TOP_DIR}
    export ANDROID_PRODUCT_OUT=${OUT_DIR}
    export EMULATOR_COMMON_ARGS="-show-kernel -verbose"
    if [[ "${QEMU_ARCH}" = "x86"* ]]; then
      EMULATOR_COMMON_ARGS="${EMULATOR_COMMON_ARGS} -qemu -cpu Skylake-Client,-hle,-rtm,-mpx"
    else
      EMULATOR_COMMON_ARGS="${EMULATOR_COMMON_ARGS} -qemu -device virtio-snd,bus=virtio-mmio-bus.2 -allow-host-audio"
    fi
    EMULATOR_EXTRA_ARGS="$@"
    EMULATOR_MERGED_ARGS=$(merge_args ${EMULATOR_COMMON_ARGS} ${EMULATOR_EXTRA_ARGS})
    echo "RUN ${EMULATOR_BIN} ${EMULATOR_MERGED_ARGS}"
    ${EMULATOR_BIN} ${EMULATOR_MERGED_ARGS}
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
