# Release Process

This document describes how to create and publish releases for bizzaroclaude.

## Overview

Releases are automated via GitHub Actions. The release workflow builds binaries for multiple platforms, generates release notes, and publishes everything to GitHub Releases.

## Prerequisites

- Maintainer access to the repository
- All changes merged to `main` branch
- All CI checks passing on `main`
- Version number decided (following [Semantic Versioning](https://semver.org/))

## Release Workflow

### 1. Decide on Version Number

Follow [Semantic Versioning](https://semver.org/) (MAJOR.MINOR.PATCH):

- **MAJOR**: Incompatible API changes
- **MINOR**: New functionality (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

Examples: `v1.0.0`, `v1.2.3`, `v2.0.0`

### 2. Pre-Release Checklist

Before creating a release, verify:

```bash
# Ensure you're on main branch
git checkout main
git pull origin main

# Run all CI checks locally
make check-all

# Verify documentation is up to date
make verify-docs
```

All checks should pass before proceeding.

### 3. Create a Release

There are two methods to create a release:

#### Method A: Create and Push a Tag (Recommended)

This triggers the release workflow automatically:

```bash
# Create an annotated tag
git tag -a v1.0.0 -m "Release v1.0.0"

# Push the tag to GitHub
git push origin v1.0.0
```

The GitHub Actions workflow will:
1. Run all pre-release checks (build, test, docs verification)
2. Build binaries for all supported platforms
3. Generate checksums for each binary
4. Create a GitHub Release with auto-generated release notes
5. Attach all binaries and checksums to the release

#### Method B: Manual Workflow Dispatch

Trigger the release workflow manually via GitHub UI:

1. Go to **Actions** → **Release** workflow
2. Click **Run workflow**
3. Enter the version tag (e.g., `v1.0.0`)
4. Click **Run workflow**

This method is useful for:
- Creating a release without pushing a tag first
- Re-running a failed release
- Testing the release process

### 4. Monitor the Release

1. Go to the [Actions tab](../../actions) in GitHub
2. Watch the **Release** workflow execution
3. Verify all jobs complete successfully:
   - ✓ Pre-Release Checks
   - ✓ Build Release Binaries (all platforms)
   - ✓ Create Release

### 5. Verify the Release

After the workflow completes:

1. Go to [Releases](../../releases)
2. Verify the new release appears
3. Check that all binaries are attached:
   - `bizzaroclaude-v1.0.0-linux-amd64`
   - `bizzaroclaude-v1.0.0-linux-arm64`
   - `bizzaroclaude-v1.0.0-darwin-amd64`
   - `bizzaroclaude-v1.0.0-darwin-arm64`
   - `bizzaroclaude-v1.0.0-windows-amd64.exe`
   - SHA256 checksums for each binary
4. Verify release notes look correct
5. Test downloading and running a binary for your platform

### 6. Announce the Release

- Update the README if installation instructions changed
- Post announcement in relevant channels
- Update any external documentation

## Supported Platforms

The release workflow builds for:

| Platform | Architecture | Binary Name |
|----------|--------------|-------------|
| Linux | AMD64 | `bizzaroclaude-VERSION-linux-amd64` |
| Linux | ARM64 | `bizzaroclaude-VERSION-linux-arm64` |
| macOS | AMD64 (Intel) | `bizzaroclaude-VERSION-darwin-amd64` |
| macOS | ARM64 (Apple Silicon) | `bizzaroclaude-VERSION-darwin-arm64` |
| Windows | AMD64 | `bizzaroclaude-VERSION-windows-amd64.exe` |

All binaries are:
- Built with `CGO_ENABLED=0` (static binaries)
- Stripped (`-s -w` ldflags for smaller size)
- Trimmed (`-trimpath` for reproducible builds)
- Versioned (version embedded via `-X main.Version=VERSION`)

## Version Verification

Users can verify the version of an installed binary:

```bash
bizzaroclaude version

# JSON output
bizzaroclaude version --json
```

The version is embedded at build time via:
```bash
go build -ldflags="-X main.Version=v1.0.0" ./cmd/bizzaroclaude
```

## Troubleshooting

### Release Workflow Fails at Pre-Release Checks

**Problem**: Tests fail or docs are out of date

**Solution**:
```bash
# Run checks locally
make check-all

# Fix any issues and push to main
git push origin main

# Delete the tag locally and remotely
git tag -d v1.0.0
git push origin :refs/tags/v1.0.0

# Create a new tag and push again
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

### Release Workflow Fails at Build Step

**Problem**: Build fails for a specific platform

**Solution**:
1. Check the Actions logs for the specific error
2. Test building locally for that platform:
   ```bash
   GOOS=linux GOARCH=amd64 go build ./cmd/bizzaroclaude
   ```
3. Fix the issue, merge to main, and re-run release

### Binary Doesn't Run

**Problem**: Downloaded binary fails to execute

**Solution**:
- Verify checksum: `sha256sum bizzaroclaude-*`
- Check file permissions: `chmod +x bizzaroclaude-*`
- For macOS: May need to allow in System Preferences (unsigned binary)

### Version Shows "dev"

**Problem**: `bizzaroclaude version` shows "dev" instead of release version

**Solution**: The version is set at build time. If building from source:
```bash
# Build with version
go build -ldflags="-X main.Version=v1.0.0" ./cmd/bizzaroclaude

# Or use development version (will show VCS info if available)
go build ./cmd/bizzaroclaude
./bizzaroclaude version  # Shows "0.0.0-dev" or commit hash
```

## Release Checklist

Use this checklist when creating a release:

- [ ] All changes merged to `main`
- [ ] All CI checks passing on `main`
- [ ] Version number decided (vX.Y.Z)
- [ ] `make check-all` passes locally
- [ ] Tag created and pushed: `git tag -a vX.Y.Z -m "Release vX.Y.Z"`
- [ ] Release workflow completed successfully
- [ ] All binaries attached to GitHub Release
- [ ] Release notes look correct
- [ ] Tested downloading and running binary
- [ ] README updated if needed
- [ ] Release announced

## Semantic Versioning Guidelines

### Major Version (X.0.0)

Increment when making incompatible changes:
- Breaking API changes
- Removing features
- Changing command-line interface
- Changing configuration file format

### Minor Version (0.X.0)

Increment when adding functionality:
- New commands or features
- New agent types
- New configuration options
- Backward-compatible improvements

### Patch Version (0.0.X)

Increment for bug fixes:
- Bug fixes
- Security patches
- Performance improvements
- Documentation updates

## Historical Releases

View all releases at: [github.com/dlorenc/bizzaroclaude/releases](../../releases)

## Questions?

For questions about the release process:
- Check [CONTRIBUTING.md](../CONTRIBUTING.md) for general contribution guidelines
- Open an issue for release-specific questions
- Contact maintainers
