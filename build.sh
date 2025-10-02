#!/bin/bash
set -euo pipefail

WASI_HOST_TRIPLE="wasm32-wasip1"
BUILD_SCRIPT="python3 cpython/Tools/wasm/wasi"
BUILD_GNU_TYPE=$(python3 -c 'import sysconfig; print(sysconfig.get_config_var("BUILD_GNU_TYPE"), end="")')
PYTHON_BUILD_DIR="cpython/cross-build/${BUILD_GNU_TYPE}"
PYTHON_HOST_DIR="cpython/cross-build/${WASI_HOST_TRIPLE}"
INSTALL_PREFIX=$(realpath ./install)

# Step 1: make build python
${BUILD_SCRIPT} configure-build-python
${BUILD_SCRIPT} make-build-python

# the rest of the steps all need to use wasi-sdk
export PATH="$WASI_SDK_PATH/bin:$PATH"
export SYSROOT="$WASI_SDK_PATH/share/wasi-sysroot"
export AR="${WASI_SDK_PATH}/bin/ar"
export RANLIB="${WASI_SDK_PATH}/bin/ranlib"
export CC="${WASI_SDK_PATH}/bin/clang"
export CFLAGS="--target=wasm32-wasi --sysroot=${SYSROOT} -I${SYSROOT}/include/${WASI_HOST_TRIPLE} -D_WASI_EMULATED_SIGNAL -fPIC"
export LDFLAGS="--target=wasm32-wasi --sysroot=${SYSROOT} -L${SYSROOT}/lib -lwasi-emulated-signal"

# Step 2: build dependencies
pushd zlib
./configure --static --prefix=${INSTALL_PREFIX}
make AR=${AR} ARFLAGS="rcs"
make install
popd

make -C bzip2 CC=clang libbz2.a
cp bzip2/*.h ${INSTALL_PREFIX}/include
cp bzip2/libbz2.a ${INSTALL_PREFIX}/lib

pushd xz
./autogen.sh
./configure \
	--prefix=${INSTALL_PREFIX} \
	--host=wasm32-unknown-wasi \
	--enable-threads=no \
	--disable-xz \
	--disable-xzdec \
	--disable-lzmadec \
	--disable-lzmainfo \
	--disable-lzma-links \
	--disable-scripts \
	--disable-doc \
	--disable-shared \
	-enable-static
make
make install
popd

make -C zstd/lib libzstd.a
cp zstd/lib/*.h ${INSTALL_PREFIX}/include
cp zstd/lib/libzstd.a ${INSTALL_PREFIX}/lib

# FIXME: util-linux needs to be patched to not use linux headers for string functions
# pushd util-linux
# ./configure \
# 	--prefix=${INSTALL_PREFIX} \
# 	--host=wasm32-unknown-wasi \
# 	--disable-all-programs \
# 	--disable-shared \
# 	--enable-static \
# 	--enable-libuuid \
# 	--enable-libuuid-force-uuid
# make
# make install
# popd

rm -rf ${INSTALL_PREFIX}/bin ${INSTALL_PREFIX}/share ${INSTALL_PREFIX}/sbin

export CFLAGS="${CFLAGS} -I${INSTALL_PREFIX}/include"
export LDFLAGS="${LDFLAGS} -L${INSTALL_PREFIX}/lib"

# Step 3: make host (wasi) python
# FIXME: host-runner echo is needed because the current python.wasm hangs on exit,
# but we never run the main function so this does not affect us
${BUILD_SCRIPT} configure-host \
	--host-triple ${WASI_HOST_TRIPLE} \
	--host-runner echo \
	-- \
	--enable-shared \
	--disable-test-modules \
	--prefix=${INSTALL_PREFIX}

${BUILD_SCRIPT} make-host
