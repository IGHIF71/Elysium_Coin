# Use Ubuntu 20.04 as the base image
FROM ubuntu:20.04

# Disable interactive frontend during build
ENV DEBIAN_FRONTEND=noninteractive

# Update package lists and install required packages
RUN apt-get update && \
    apt-get install -y \
      build-essential \
      curl \
      git \
      clang \
      libssl-dev \
      pkg-config \
      llvm \
      libudev-dev \
      cmake \
      wget \
      && rm -rf /var/lib/apt/lists/*

# Install rustup and Rust (stable toolchain)

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# (Optional) Install nightly if your project requires it:
# RUN rustup default nightly

# (Optional) Install additional cargo tools such as cargo-watch
RUN cargo install cargo-watch


WORKDIR /app

EXPOSE 9944 9933 30333 30334

CMD ["bash"]