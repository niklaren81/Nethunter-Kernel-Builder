# Docker build script for Moto G6 Play (jeter) NetHunter kernel
# Run this in PowerShell

$ErrorActionPreference = "Stop"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "NetHunter Kernel Builder for Moto G6 Play" -ForegroundColor Cyan
Write-Host "LineageOS 18.1 (Android 11)" -ForegroundColor Cyan
Write-Host "Docker Build" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Check if Docker is installed
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Docker is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install Docker Desktop from: https://www.docker.com/products/docker-desktop"
    exit 1
}

# Check if Docker is running
try {
    docker info > $null 2>&1
} catch {
    Write-Host "ERROR: Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Docker is installed and running ✓" -ForegroundColor Green

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $scriptDir

# Create output directory if it doesn't exist
$outputDir = "$scriptDir\output"
if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Building Docker image..." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

# Build the Docker image
docker build -t nethunter-jeter-builder .

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Failed to build Docker image" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Docker image built successfully ✓" -ForegroundColor Green

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Starting kernel build..." -ForegroundColor Cyan
Write-Host "This will take 20-60 minutes" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan

# Run the build container
docker run --rm `
    -v "${outputDir}:/build/output" `
    -e ARCH=arm `
    -e SUBARCH=arm `
    -e CROSS_COMPILE=arm-linux-gnueabi- `
    -e ANDROID_MAJOR_VERSION=r `
    nethunter-jeter-builder

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "ERROR: Build failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "Build completed successfully!" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green

Write-Host ""
Write-Host "Artifacts location: $outputDir" -ForegroundColor Cyan
Write-Host ""

# List output files
if (Test-Path $outputDir) {
    Write-Host "Output files:" -ForegroundColor Yellow
    Get-ChildItem $outputDir -Recurse | ForEach-Object {
        $size = if ($_.Length -gt 1MB) { "{0:N2} MB" -f ($_.Length / 1MB) } else { "{0:N2} KB" -f ($_.Length / 1KB) }
        Write-Host "  $($_.FullName.Replace($outputDir, '')) - $size"
    }
}

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Green
Write-Host "1. Package with AnyKernel3 or Android Image Kitchen"
Write-Host "2. Flash to your Moto G6 Play (jeter)"
