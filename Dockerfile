# -------------------------------------------------------
# Build stage
# -------------------------------------------------------
FROM docker.io/paritytech/ci-unified:latest AS builder

WORKDIR /polkadot

# Copy the project into the build container
COPY . .

# Download Rust dependencies
RUN cargo fetch --locked

# Compile optimized release binary
RUN cargo build --locked --release


# -------------------------------------------------------
# Runtime stage
# -------------------------------------------------------
FROM docker.io/parity/base-bin:latest

# Copy only the compiled node binary
COPY --from=builder \
    /polkadot/target/release/parachain-template-node \
    /usr/local/bin/parachain-template-node

USER root

# Create a non-root user and persistent blockchain data directory
RUN useradd \
        -m \
        -u 1001 \
        -U \
        -s /bin/sh \
        -d /polkadot \
        polkadot \
    && mkdir -p /data /polkadot/.local/share \
    && chown -R polkadot:polkadot /data /polkadot \
    && ln -s /data /polkadot/.local/share/polkadot \
    && /usr/local/bin/parachain-template-node --version \
    && rm -rf /usr/bin /usr/sbin

USER polkadot

# P2P
EXPOSE 30333

# HTTP RPC
EXPOSE 9933

# WebSocket RPC
EXPOSE 9944

# Prometheus metrics
EXPOSE 9615

VOLUME ["/data"]

ENTRYPOINT ["/usr/local/bin/parachain-template-node"]
