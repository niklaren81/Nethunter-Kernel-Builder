#!/bin/bash
# Build script for Moto G6 Play (jeter) NetHunter kernel with LineageOS 18.1
# Auto-configures toolchain - run this in WSL

set -e

# Configuration
KERNEL_NAME="JeterNethunter"
KERNEL_REPO="https://github.com/LineageOS/android_kernel_motorola_msm8937.git"
KERNEL_BRANCH="lineage-18.1"
DEFCONFIG="jeter_defconfig"
OUT_DIR="out"
JOBS=$(nproc)

# Toolchain configuration
TOOLCHAIN_DIR="$HOME/toolchain"
TOOLCHAIN_NAME="android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9"
TOOLCHAIN_URL="https://github.com/LineageOS/android_prebuilts_gcc_linux-x86_arm_arm-linux-androideabi-4.9/archive/refs/heads/master.tar.gz"

# Build environment
export ARCH=arm
export SUBARCH=arm
export CROSS_COMPILE="$TOOLCHAIN_DIR/$TOOLCHAIN_NAME-master/bin/arm-linux-androideabi-"
export ANDROID_MAJOR_VERSION=r
export HOSTCFLAGS="-fcommon"
export CFLAGS_KERNEL="-Wno-error=attribute-alias"
export PATH="$TOOLCHAIN_DIR/$TOOLCHAIN_NAME-master/bin:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "============================================"
echo "NetHunter Kernel Builder for Moto G6 Play"
echo "LineageOS 18.1 (Android 11)"
echo "============================================"

# Check for dependencies
echo ""
echo "Checking dependencies..."
MISSING_DEPS=""

for cmd in bc bison flex make git zip wget; do
    if ! command -v $cmd &> /dev/null; then
        MISSING_DEPS="$MISSING_DEPS $cmd"
    fi
done

if [ -n "$MISSING_DEPS" ]; then
    echo "ERROR: Missing dependencies:$MISSING_DEPS"
    echo ""
    echo "Install with:"
    echo "sudo apt-get update"
    echo "sudo apt-get install -y bc bison flex libssl-dev make git zip wget"
    exit 1
fi

echo "All system dependencies found!"

# Download and setup toolchain
echo ""
echo "Setting up ARM Android toolchain..."

if [ ! -d "$TOOLCHAIN_DIR/$TOOLCHAIN_NAME-master" ]; then
    echo "Downloading toolchain..."
    mkdir -p "$TOOLCHAIN_DIR"
    cd "$TOOLCHAIN_DIR"
    wget -q --show-progress -O toolchain.tar.gz "$TOOLCHAIN_URL"
    echo "Extracting toolchain..."
    tar -xzf toolchain.tar.gz
    rm toolchain.tar.gz
    cd "$SCRIPT_DIR"
    echo "Toolchain installed!"
else
    echo "Toolchain already exists, skipping download."
fi

# Verify toolchain
if ! command -v arm-linux-androideabi-gcc &> /dev/null; then
    echo "ERROR: Toolchain not found at $TOOLCHAIN_DIR/$TOOLCHAIN_NAME-master/bin"
    exit 1
fi

echo "Toolchain verified: $(arm-linux-androideabi-gcc --version | head -1)"

# Clean up previous build (optional)
if [ -d "$KERNEL_NAME" ]; then
    echo ""
    read -p "Previous kernel source found. Delete and re-clone? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Removing previous kernel source..."
        rm -rf "$KERNEL_NAME"
    fi
fi

# Clone kernel source
if [ ! -d "$KERNEL_NAME" ]; then
    echo ""
    echo "Cloning LineageOS kernel..."
    git clone --recursive --branch "$KERNEL_BRANCH" \
        "$KERNEL_REPO" "$KERNEL_NAME" --depth=1
fi

cd "$KERNEL_NAME"

# Create output directory
mkdir -p "$OUT_DIR"

echo ""
echo "============================================"
echo "Starting kernel build..."
echo "Architecture: $ARCH"
echo "Defconfig: $DEFCONFIG"
echo "Jobs: $JOBS"
echo "Cross compiler: $CROSS_COMPILE"
echo "============================================"

# Generate defconfig
echo ""
echo "[1/2] Generating defconfig..."
make O="$OUT_DIR" "$DEFCONFIG"

# Build kernel
echo ""
echo "[2/2] Building kernel (this may take 20-60 minutes)..."
make -j"$JOBS" O="$OUT_DIR"

# Collect artifacts
echo ""
echo "============================================"
echo "Build complete!"
echo "============================================"

mkdir -p ../artifacts

# Copy zImage
if [ -f "$OUT_DIR/arch/arm/boot/zImage" ]; then
    cp -v "$OUT_DIR/arch/arm/boot/zImage" ../artifacts/
    echo "✓ zImage copied to artifacts/"
else
    echo "✗ zImage not found"
fi

# Copy DTB files
if [ -d "$OUT_DIR/arch/arm/boot/dts" ]; then
    cp -vr "$OUT_DIR/arch/arm/boot/dts" ../artifacts/dts
    echo "✓ DTB files copied to artifacts/dts/"
else
    echo "✗ DTB directory not found"
fi

# Also copy Image if it exists
if [ -f "$OUT_DIR/arch/arm/boot/Image" ]; then
    cp -v "$OUT_DIR/arch/arm/boot/Image" ../artifacts/
    echo "✓ Image copied to artifacts/"
fi

echo ""
echo "Output files:"
ls -lh ../artifacts/

echo ""
echo "============================================"
echo "Next steps:"
echo "1. Package with AnyKernel3 or Android Image Kitchen"
echo "2. Flash to your Moto G6 Play (jeter)"
echo "============================================"
