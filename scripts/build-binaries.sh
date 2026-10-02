#!/bin/sh

. ./ci-vars.sh
. ./scripts/common-functions.sh

ROOT=$(pwd)
BUILD_DIR=${ROOT}/build
echo "${0}: BUILD_DIR - ${BUILD_DIR}"
CMAKE_DEFAULT_ARGS=$(get_cmake_default_args ${BUILD_DIR})
CMAKE_DEFAULT_ARGS=${CMAKE_DEFAULT_ARGS}" ${ADDL_CMAKE_FLAGS}"

if [ "$(uname)" = "Darwin" ]; then
    CMAKE_DEFAULT_ARGS=${CMAKE_DEFAULT_ARGS}" -DCMAKE_CROSSCOMPILING=1 -DRUN_HAVE_STD_REGEX=0 -DRUN_HAVE_POSIX_REGEX=0"
fi

echo "CMAKE_DEFAULT_ARGS: ${CMAKE_DEFAULT_ARGS}"

### build openfhe-development
OPENFHE_REPO="https://github.com/openfheorg/openfhe-development.git"
OPENFHE_DIR="${BUILD_DIR}/openfhe-development"
OPENFHE_CMAKE_ARGS=${CMAKE_DEFAULT_ARGS}
OPENFHE_CMAKE_ARGS=${OPENFHE_CMAKE_ARGS}" -DBUILD_STATIC=OFF -DBUILD_SHARED=ON"
OPENFHE_CMAKE_ARGS=${OPENFHE_CMAKE_ARGS}" -DBUILD_BENCHMARKS=OFF -DBUILD_UNITTESTS=OFF -DBUILD_EXAMPLES=OFF"
# OPENFHE_CMAKE_ARGS=${OPENFHE_CMAKE_ARGS}" -DWITH_OPENMP=OFF"

clone ${OPENFHE_REPO} ${OPENFHE_DIR}

### optionally overlay the Intel HEXL backend onto openfhe-development
if [ "${BUILD_HEXL}" = "ON" ]; then
  separator
  echo "BUILD_HEXL=ON - staging Intel HEXL overlay"
  separator

  OPENFHE_HEXL_DIR="${BUILD_DIR}/openfhe-hexl"
  clone "${OPENFHE_HEXL_REPO}" "${OPENFHE_HEXL_DIR}"

  # check out the matching tags so the overlay lands on the intended source tree
  checkout_tag "${OPENFHE_DIR}" "${OPENFHE_TAG}"
  checkout_tag "${OPENFHE_HEXL_DIR}" "${OPENFHE_HEXL_TAG}"

  overlay_hexl "${OPENFHE_HEXL_DIR}" "${OPENFHE_DIR}"

  OPENFHE_CMAKE_ARGS=${OPENFHE_CMAKE_ARGS}" -DWITH_INTEL_HEXL=ON"
fi

build_install_tag_with_args ${OPENFHE_DIR} ${OPENFHE_TAG} "${OPENFHE_CMAKE_ARGS}" ${PARALELLISM}

### build openfhe-python
OPENFHE_PYTHON_REPO="https://github.com/openfheorg/openfhe-python.git"
OPENFHE_PYTHON_DIR="${BUILD_DIR}/openfhe-python"
OPENFHE_PYTHON_CMAKE_ARGS=${CMAKE_DEFAULT_ARGS}

clone ${OPENFHE_PYTHON_REPO} ${OPENFHE_PYTHON_DIR}
build_install_tag_with_args ${OPENFHE_PYTHON_DIR} ${OPENFHE_PYTHON_TAG} "${OPENFHE_PYTHON_CMAKE_ARGS}" ${PARALELLISM}

separator

