# -------------------------------------------------------
# Build stage
# -------------------------------------------------------
FROM rust:1.81.0-bookworm AS builder

WORKDIR /polkadot

# Install native build dependencies required by Polkadot/Substrate
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        clang \
        cmake \
        pkg-config \
        libssl-dev \
        libclang-dev \
        git \
        protobuf-compiler \
    && rm -rf /var/lib/apt/lists/*

COPY . .

# Add the components required for Substrate WASM builds
RUN rustup component add rust-src && \
    rustup target add wasm32-unknown-unknown

# Verify the build environment
RUN echo "=== Rust environment ===" && \
    rustc --version && \
    cargo --version && \
    rustup show active-toolchain && \
    echo "=== Protobuf compiler ===" && \
    protoc --version && \
    which protoc && \
    echo "=== Installed targets ===" && \
    rustup target list --installed && \
    echo "=== Installed components ===" && \
    rustup component list --installed

# Download dependencies exactly as specified by Cargo.lock
RUN cargo fetch --locked

# Build the parachain node and WASM runtime
RUN cargo build --locked --release


# -------------------------------------------------------
# Runtime stage
# -------------------------------------------------------
FROM docker.io/parity/base-bin:latest

COPY --from=builder \
    /polkadot/target/release/parachain-template-node \
    /usr/local/bin/parachain-template-node

USER root

RUN useradd -m -u 1001 -U -s /bin/sh -d /polkadot polkadot && \
    mkdir -p /data /polkadot/.local/share && \
    chown -R polkadot:polkadot /data /polkadot && \
    ln -s /data /polkadot/.local/share/polkadot && \
    /usr/local/bin/parachain-template-node --version && \
    rm -rf /usr/bin /usr/sbin

USER polkadot

EXPOSE 30333
EXPOSE 9933
EXPOSE 9944
EXPOSE 9615

VOLUME ["/data"]

ENTRYPOINT ["/usr/local/bin/parachain-template-node"]