#!/bin/bash

# Script to create a new info-display release
# This script will create a git tag and push it to trigger the GitHub Action

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get the current version from Cargo.toml
VERSION=$(grep '^version' raspi-info-display/Cargo.toml | head -1 | cut -d'"' -f2)
TAG_NAME="info-display-v${VERSION}"

print_status "Current info-display version: $VERSION"
print_status "Tag name: $TAG_NAME"

# Check if tag already exists
if git tag -l | grep -q "^${TAG_NAME}$"; then
    print_error "Tag $TAG_NAME already exists!"
    print_warning "Either:"
    print_warning "  1. Update the version in raspi-info-display/Cargo.toml"
    print_warning "  2. Delete the existing tag: git tag -d $TAG_NAME && git push origin :refs/tags/$TAG_NAME"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "raspi-info-display/Cargo.toml" ]; then
    print_error "Please run this script from the homelab project root directory"
    exit 1
fi

# Check if there are uncommitted changes in raspi-info-display
if ! git diff --quiet HEAD -- raspi-info-display/; then
    print_error "You have uncommitted changes in raspi-info-display/"
    print_warning "Please commit your changes first:"
    print_warning "  git add raspi-info-display/"
    print_warning "  git commit -m 'Update info-display to version $VERSION'"
    exit 1
fi

# Create and push the tag
print_status "Creating tag $TAG_NAME..."
git tag -a "$TAG_NAME" -m "info-display release v$VERSION

Release of the Raspberry Pi OLED display service.

Features:
- System information display (hostname, IP, CPU temp, memory, disk, uptime)
- SSD1306 OLED display support via I2C
- Systemd service integration
- ARM64 architecture support"

print_status "Pushing tag to trigger GitHub Action..."
git push origin "$TAG_NAME"

print_success "Release tag created and pushed!"
print_status "GitHub Action will now:"
print_status "  1. Build the ARM64 binary"
print_status "  2. Create the Debian package"
print_status "  3. Create a GitHub release"
print_status "  4. Upload the .deb package as a release asset"
print_status ""
print_status "Monitor the build progress at:"
print_status "  https://github.com/$(git remote get-url origin | sed 's/.*github.com[:/]\([^.]*\).*/\1/')/actions"