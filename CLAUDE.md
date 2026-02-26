# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a GitHub Actions-based Android kernel builder specifically configured for building the Moto G6 Play (jeter) NetHunter kernel. It clones the Motorola kernel source, patches it, and builds it using a cross-compilation toolchain.

## Repository Structure

- `.github/workflows/build.yml` - Main GitHub Actions workflow for kernel building
- `repos.json` - Kernel configuration file defining sources, toolchains, and build parameters
- `README.md` / `README_cn.md` - Documentation in English and Chinese
- `.assets/` - Contains images used in documentation

## Build System

### GitHub Actions Workflow (Primary)

The project is designed to run on GitHub Actions via manual trigger (`workflow_dispatch`).

**Trigger workflow:**
1. Push changes to GitHub
2. Go to Actions tab → "Build Moto G6 Play (jeter) Kernel"
3. Click "Run workflow"

### Local Testing with `act`

To test the workflow locally, use [nektos/act](https://github.com/nektos/act):

```bash
# Run workflow and collect artifacts to /tmp/artifacts
act --artifact-server-path /tmp/artifacts

# Verbose mode for debugging
act --artifact-server-path /tmp/artifacts -v
```

### Manual Local Build (without act)

Dependencies required:
```bash
sudo apt-get update
sudo apt-get install -y bc bison flex libssl-dev make gcc-arm-linux-gnueabi git zip
```

Build commands:
```bash
# Clone kernel source
git clone --recursive --branch oreo-8.0.0-release-jeter \
  https://github.com/MotorolaMobilityLLC/kernel-msm.git JeterNethunter --depth=1

cd JeterNethunter

# Apply F2FS Kconfig patch (removes broken include)
sed -i '/f2fs\/Kconfig/d' fs/Kconfig

# Set build environment
export ARCH=arm
export SUBARCH=arm
export CROSS_COMPILE=arm-linux-gnueabi-
export ANDROID_MAJOR_VERSION=o
export HOSTCFLAGS="-fcommon"
export CFLAGS_KERNEL="-Wno-error=attribute-alias"

# Build
mkdir -p out
make O=out msm8937-perf_defconfig
make -j$(nproc) O=out

# Output artifacts
# out/arch/arm/boot/zImage
# out/arch/arm/boot/dts/
```

## Configuration File (repos.json)

The `repos.json` file defines kernel build configurations:

```json
{
  "kernelSource": {
    "name": "KernelName",
    "repo": "https://github.com/vendor/kernel-repo.git",
    "branch": "branch-name",
    "device": "device-codename",
    "defconfig": "defconfig-name"
  },
  "withKernelSU": false,
  "toolchains": [
    {
      "repo": "https://...",
      "branch": "master",
      "name": "toolchain-name",
      "binaryEnv": ["$GITHUB_WORKSPACE/toolchain/bin"]
    }
  ],
  "params": {
    "ARCH": "arm",
    "CROSS_COMPILE": "arm-linux-androideabi-",
    ...
  },
  "AnyKernel3": {
    "use": false,
    "release": false
  }
}
```

### Current Configuration

- **Device**: Moto G6 Play (jeter)
- **Kernel**: Motorola MSM kernel, branch `oreo-8.0.0-release-jeter`
- **Architecture**: ARM (32-bit)
- **Toolchain**: GCC ARM Linux Androideabi 4.9
- **Defconfig**: `msm8937-perf_defconfig`
- **KernelSU**: Disabled

## Key Build Parameters

| Variable | Value | Description |
|----------|-------|-------------|
| `ARCH` | `arm` | Target architecture |
| `SUBARCH` | `arm` | Sub-architecture |
| `CROSS_COMPILE` | `arm-linux-androideabi-` | Cross compiler prefix |
| `ANDROID_MAJOR_VERSION` | `o` | Android version (Oreo) |
| `HOSTCFLAGS` | `-fcommon` | Host compiler flags |
| `CFLAGS_KERNEL` | `-Wno-error=attribute-alias` | Kernel compiler flags |

## Known Build Fixes

The workflow applies a patch to fix a broken Kconfig:

```bash
# Removes invalid F2FS include that causes build failure
sed -i '/f2fs\/Kconfig/d' fs/Kconfig
```

## Build Artifacts

Successful builds produce:
- `zImage` - Compressed kernel image
- `dts/` - Device tree source files

Artifacts are uploaded via GitHub Actions artifact upload.
