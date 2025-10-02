#!/usr/bin/env bash
set -euo pipefail

if [ -z "${WASI_SDK_PATH:-}" ]; then
	echo "Error: WASI_SDK_PATH must be set" >&2
	exit 1
fi

DEFAULT_VERSION="27"
WASI_SDK_VERSION="${1:-$DEFAULT_VERSION}"

UNAME_M="$(uname -m)"
case "$UNAME_M" in
	x86_64) WASI_ARCH="x86_64" ;;
	aarch64|arm64) WASI_ARCH="arm64" ;;
	*) echo "Unsupported architecture: $UNAME_M" >&2; exit 1 ;;
esac

UNAME_S="$(uname -s)"
case "$UNAME_S" in
	Linux) WASI_OS="linux" ;;
	Darwin) WASI_OS="macos" ;;
	*) echo "Unsupported OS: $UNAME_S" >&2; exit 1 ;;
esac

WASI_SDK_NAME="wasi-sdk-${WASI_SDK_VERSION}.0-${WASI_ARCH}-${WASI_OS}"
WASI_SDK_BASE_URL="https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-${WASI_SDK_VERSION}"
WASI_SDK_URL="${WASI_SDK_BASE_URL}/${WASI_SDK_NAME}.tar.gz"

echo "Installing WASI SDK ${WASI_SDK_VERSION} for ${WASI_ARCH}-${WASI_OS}..."
echo "Destination: ${WASI_SDK_PATH}"
echo "URL: ${WASI_SDK_URL}"

mkdir -p "$WASI_SDK_PATH"
curl -sSL "$WASI_SDK_URL" | tar xzC "$WASI_SDK_PATH" --strip-components=1

echo "Checking WASI SDK binaries..."
test -x "$WASI_SDK_PATH/bin/clang"   || { echo "clang not found"; exit 1; }
test -x "$WASI_SDK_PATH/bin/clang++" || { echo "clang++ not found"; exit 1; }

echo "WASI SDK installed successfully at $WASI_SDK_PATH"

