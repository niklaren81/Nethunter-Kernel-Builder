# Dockerfile for building Moto G6 Play (jeter) NetHunter kernel
FROM ubuntu:22.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    bc \
    bison \
    flex \
    libssl-dev \
    make \
    gcc-arm-linux-gnueabi \
    git \
    zip \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set up build environment
ENV ARCH=arm
ENV SUBARCH=arm
ENV CROSS_COMPILE=arm-linux-gnueabi-
ENV ANDROID_MAJOR_VERSION=r
ENV HOSTCFLAGS="-fcommon"
ENV CFLAGS_KERNEL="-Wno-error=attribute-alias"

# Set working directory
WORKDIR /build

# Entry point for the build
CMD ["/build/docker-entrypoint.sh"]
