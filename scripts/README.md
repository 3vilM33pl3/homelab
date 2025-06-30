# Homelab Scripts

This directory contains utility scripts for managing the homelab infrastructure.

## release-info-display.sh

Creates a new release of the info-display Raspberry Pi service.

### Usage

```bash
# From the homelab project root
./scripts/release-info-display.sh
```

### What it does

1. Reads the current version from `raspi-info-display/Cargo.toml`
2. Creates a git tag in the format `info-display-vX.Y.Z`
3. Pushes the tag to GitHub
4. Triggers the GitHub Action to build and release the package

### Prerequisites

- All changes in `raspi-info-display/` must be committed
- Version in `Cargo.toml` should be updated before running
- Git remote should be properly configured

### GitHub Action Workflow

The `build-info-display.yml` workflow will:

- Build the Rust binary for ARM64 (aarch64) architecture
- Create a Debian package using `cargo-deb`
- Upload the package as a GitHub release
- Generate release notes with installation instructions

### Manual Release

You can also trigger a release manually from the GitHub Actions tab by:

1. Go to Actions → Build and Release info-display
2. Click "Run workflow"
3. Check "Create a release" option
4. Click "Run workflow"