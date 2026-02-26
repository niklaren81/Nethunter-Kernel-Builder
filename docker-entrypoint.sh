#!/bin/bash
set -e

# Configuration
KERNEL_NAME="JeterNethunter"
KERNEL_REPO="https://github.com/LineageOS/android_kernel_motorola_msm8937.git"
KERNEL_BRANCH="lineage-18.1"
DEFCONFIG="jeter_defconfig"
OUT_DIR="out"
JOBS=$(nproc)

echo "============================================"
echo "NetHunter Kernel Builder for Moto G6 Play"
echo "LineageOS 18.1 (Android 11)"
echo "Running in Docker"
echo "============================================"

# Check if kernel source is already mounted
if [ ! -d "/build/kernel-source" ]; then
    echo ""
    echo "Cloning LineageOS kernel..."
    echo "Repository: $KERNEL_REPO"
    echo "Branch: $KERNEL_BRANCH"
    git clone --recursive --branch "$KERNEL_BRANCH" \
        "$KERNEL_REPO" "$KERNEL_NAME" --depth=1
    cd "$KERNEL_NAME"
else
    echo ""
    echo "Using mounted kernel source..."
    KERNEL_NAME="kernel-source"
    cd "$KERNEL_NAME"
fi

# Create output directory
mkdir -p "$OUT_DIR"

echo ""
echo "============================================"
echo "Starting kernel build..."
echo "Architecture: $ARCH"
echo "Defconfig: $DEFCONFIG"
echo "Jobs: $JOBS"
echo "============================================"

# Generate defconfig
echo ""
echo "[1/2] Generating defconfig..."
make O="$OUT_DIR" "$DEFCONFIG"

# Build kernel
echo ""
echo "[2/2] Building kernel (this may take 20-60 minutes)..."
echo ""
make -j"$JOBS" O="$OUT_DIR"

# Collect artifacts
echo ""
echo "============================================"
echo "Build complete!"
echo "============================================"

mkdir -p /build/output

# Copy zImage
if [ -f "$OUT_DIR/arch/arm/boot/zImage" ]; then
    cp -v "$OUT_DIR/arch/arm/boot/zImage" /build/output/
    echo "✓ zImage copied"
fi

# Copy DTB files
if [ -d "$OUT_DIR/arch/arm/boot/dts" ]; then
    cp -vr "$OUT_DIR/arch/arm/boot/dts" /build/output/dts
    echo "✓ DTB files copied"
fi

# Copy Image if it exists
if [ -f "$OUT_DIR/arch/arm/boot/Image" ]; then
    cp -v "$OUT_DIR/arch/arm/boot/Image" /build/output/
    echo "✓ Image copied"
fi

# Copy any other important files
if [ -f "$OUT_DIR/System.map" ]; then
    cp -v "$OUT_DIR/System.map" /build/output/
    echo "✓ System.map copied"
fi

if [ -f "$OUT_DIR/.config" ]; then
    cp -v "$OUT_DIR/.config" /build/output/kernel-config
    echo "✓ Kernel config copied"
fi

echo ""
echo "Output files:"
ls -lh /build/output/

echo ""
echo "============================================"
echo "Build finished successfully!"
echo "Artifacts available in: /build/output"
echo "============================================"
