# Dockerfile to build modkit with bgzip, tabix, and bcftools
# Supports multi-architecture builds (linux/amd64, linux/arm64)

###########
# Builder #
###########
FROM rust:1.84.1-slim-bullseye AS builder
WORKDIR /build
# Install build dependencies and clone Modkit
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        build-essential \
        libbz2-dev \
        liblzma-dev \
        zlib1g-dev \
        pkg-config \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Clone and build Modkit
RUN git clone --depth 1 https://github.com/nanoporetech/modkit.git . && \
    cargo build --release

##########
# Final  #
##########
FROM debian:bullseye-slim AS final

WORKDIR /app

# Install runtime dependencies: bcftools & tabix (provides bgzip)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bcftools \
        tabix \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy Modkit binary from builder
COPY --from=builder /build/target/release/modkit /usr/local/bin/

ENV PATH="/usr/local/bin:${PATH}"

# Verify installations
RUN set -eux && \
    modkit --help && \
    bcftools --version && \
    bgzip --help && \
    tabix --help

# Default command
CMD ["modkit"]