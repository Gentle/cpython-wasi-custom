FROM debian:trixie-slim

ARG WASI_SDK_VERSION="27"
ARG WASMTIME_VERSION="37.0.1"
ENV WASI_SDK_PATH="/opt/wasi-sdk"
ADD install_wasi_sdk.sh /

RUN apt-get update && apt-get install -y \
    autoconf \
    autopoint \
    bison \
    clang \
    curl \
    flex \
    git \
    libtool \
    make \
    pkg-config \
    po4a \
    python3 \
 && apt-get clean && rm -rf /var/lib/apt/lists/* \
 && bash /install_wasi_sdk.sh ${WASI_SDK_VERSION} \
 && rm /install_wasi_sdk.sh \
 && WASMTIME_ARCH=$([ "$TARGETARCH" = "amd64" ] && echo x86_64 || echo aarch64) \
 && curl -sSL "https://github.com/bytecodealliance/wasmtime/releases/download/v${WASMTIME_VERSION}/wasmtime-v${WASMTIME_VERSION}-${WASMTIME_ARCH}-linux.tar.xz" \
  | tar xJ --strip-components=1 -C "/usr/local/bin/" --wildcards '*/wasmtime'
WORKDIR /opt/code
ENTRYPOINT ["bash"]
