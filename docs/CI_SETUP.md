# CI/CD Setup Documentation

This document describes the comprehensive CI/CD pipeline for bizzaroclaude.

## Overview

The CI/CD system consists of multiple GitHub Actions workflows that ensure code quality, security, and reliability:

| Workflow | Trigger | Purpose |
|----------|---------|---------|
| `ci.yml` | Push/PR | Main CI pipeline (build, test, lint, coverage) |
| `pr-checks.yml` | PR events | PR validation (title, size, conflicts) |
| `release.yml` | Version tags | Build and publish releases |
| `codeql.yml` | Push/PR/Schedule | Security analysis |

## Main CI Workflow (`ci.yml`)

### Jobs

#### 1. Build
- **Matrix**: Tests against Go 1.21, 1.22, 1.23
- **Steps**:
  - Verify dependencies with `go mod verify`
  - Build all packages
  - Build CLI binary

#### 2. Lint
- **Tool**: golangci-lint
- **Config**: `.golangci.yml`
- **Checks**:
  - Standard linters
  - gocritic (code quality)
  - misspell (typo detection)
  - staticcheck (static analysis)

#### 3. Unit Tests
- **Scope**: `./internal/...` and `./pkg/...`
- **Features**:
  - Race detection enabled
  - Coverage reporting
  - Requires tmux installation

#### 4. E2E Tests
- **Scope**: `./test/...`
- **Requirements**:
  - tmux installed
  - Git configured (for integration tests)
- **Purpose**: Full integration testing

#### 5. Verify Docs
- **Checks**:
  - Generated docs are up to date (`docs/DIRECTORY_STRUCTURE.md`)
  - Extension docs consistency (`cmd/verify-docs`)
- **Fix**: Run `go generate ./pkg/config/...` locally

#### 6. Coverage
- **Threshold**: Tracked but not enforced
- **Outputs**:
  - Coverage summary in logs
  - Upload to Codecov (optional)
  - Artifact retention (30 days)

#### 7. Security
- **Tools**:
  - Gosec (security scanner)
  - govulncheck (vulnerability detection)
- **Status**: Non-blocking (continue-on-error)

#### 8. CI Success
- **Purpose**: Gate for branch protection
- **Requirement**: All jobs must pass

## PR Checks Workflow (`pr-checks.yml`)

### Validations

1. **Draft Status**: Blocks draft PRs from CI
2. **PR Title**: Enforces conventional commits format
   - Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
   - Must start with uppercase
3. **Merge Conflicts**: Detects conflicts with main
4. **Large Files**: Warns about files >1MB
5. **Debugging Code**: Detects `fmt.Println`, `TODO`, `FIXME`
6. **go.mod Tidy**: Ensures dependencies are tidy
7. **PR Size**: Warns if >1000 lines changed
8. **Documentation**: Suggests CLAUDE.md update for large changes

## Release Workflow (`release.yml`)

### Triggers
- **Automatic**: Push tags matching `v*.*.*`
- **Manual**: workflow_dispatch with tag input

### Build Matrix
| Platform | Architecture | Output |
|----------|--------------|--------|
| Linux | AMD64 | `bizzaroclaude-{version}-linux-amd64` |
| Linux | ARM64 | `bizzaroclaude-{version}-linux-arm64` |
| macOS | AMD64 | `bizzaroclaude-{version}-darwin-amd64` |
| macOS | ARM64 | `bizzaroclaude-{version}-darwin-arm64` |
| Windows | AMD64 | `bizzaroclaude-{version}-windows-amd64.exe` |

### Release Process
1. **Pre-Release Checks**: Full CI validation
2. **Build Binaries**: Cross-platform compilation
3. **Generate Checksums**: SHA256 for each binary
4. **Create Release**: GitHub release with artifacts
5. **Release Notes**: Auto-generated from commits

### Creating a Release

```bash
# Tag the release
git tag v1.0.0
git push origin v1.0.0

# Or trigger manually via GitHub UI
# Actions → Release → Run workflow
```

## CodeQL Workflow (`codeql.yml`)

- **Schedule**: Weekly on Mondays
- **Language**: Go
- **Queries**: security-extended + security-and-quality
- **Output**: Security alerts in GitHub Security tab

## Dependabot Configuration

Automatic dependency updates for:
- **Go modules**: Weekly on Mondays
- **GitHub Actions**: Weekly on Mondays

Updates create PRs with:
- Label: `dependencies`
- Commit prefix: `deps:` (Go) or `ci:` (Actions)
- Limit: 5 open PRs at a time

## Local Development

### Running CI Checks Locally

```bash
# Fast pre-commit checks (recommended before git commit)
make pre-commit

# Full CI validation (recommended before git push)
make check-all

# Individual checks
make build          # Build all packages
make unit-tests     # Run unit tests
make e2e-tests      # Run E2E tests
make verify-docs    # Check generated docs
make coverage       # Coverage analysis
make lint           # Run golangci-lint (add to Makefile if needed)
```

### Installing Pre-Commit Hook

```bash
make install-hooks
```

This installs a git hook that runs `make pre-commit` before each commit.

### Skipping Hooks

```bash
# Temporary skip (single commit)
git commit --no-verify -m "message"

# Disable permanently
rm .git/hooks/pre-commit
```

## CI/CD Best Practices

### Before Opening a PR

1. ✅ Run `make check-all` locally
2. ✅ Ensure generated docs are up to date
3. ✅ Verify `go.mod` is tidy (`go mod tidy`)
4. ✅ Check PR follows conventional commits
5. ✅ Review PR template checklist

### PR Title Format

```
<type>: <description>

Examples:
feat: Add container escape detection
fix: Resolve race condition in agent cleanup
docs: Update CLAUDE.md with new architecture
test: Add E2E tests for message routing
ci: Add CodeQL security scanning
```

### Handling CI Failures

#### Build Failure
```bash
# Verify locally
go build -v ./...
go build -v ./cmd/bizzaroclaude
```

#### Test Failure
```bash
# Run specific test
go test -v ./internal/state -run TestSave

# With race detection
go test -race ./...
```

#### Lint Failure
```bash
# Run golangci-lint locally
golangci-lint run

# Auto-fix issues
golangci-lint run --fix
```

#### Docs Verification Failure
```bash
# Regenerate docs
go generate ./pkg/config/...

# Commit the changes
git add docs/DIRECTORY_STRUCTURE.md
git commit -m "docs: Regenerate CLI documentation"
```

## Branch Protection Rules

Recommended settings for `main` branch:

- ✅ Require status checks to pass before merging
  - Required checks:
    - Build
    - Lint
    - Unit Tests
    - E2E Tests
    - Verify Generated Docs
    - Coverage Check
    - PR Ready (from pr-checks)
- ✅ Require branches to be up to date before merging
- ✅ Require pull request reviews (1 reviewer)
- ✅ Dismiss stale reviews when new commits are pushed
- ✅ Require linear history (no merge commits)
- ✅ Include administrators

## Troubleshooting

### "tmux not found" Error

```bash
# Ubuntu/Debian
sudo apt-get install tmux

# macOS
brew install tmux

# Arch Linux
sudo pacman -S tmux
```

### Race Condition Detected

```bash
# Run with race detector locally
go test -race ./...

# Fix the issue before pushing
```

### Coverage Too Low

```bash
# Check current coverage
make coverage

# View detailed coverage report
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

### CodeQL Alerts

1. Check Security tab in GitHub
2. Review alert details
3. Fix the issue
4. Re-scan will happen automatically

## CI Performance

### Typical Run Times

| Job | Duration |
|-----|----------|
| Build | 1-2 min |
| Lint | 2-3 min |
| Unit Tests | 2-4 min |
| E2E Tests | 3-5 min |
| Coverage | 2-4 min |
| Security | 2-3 min |
| **Total** | **10-15 min** |

### Optimization Tips

1. **Cache Hit Rate**: Go module cache reduces build time by 50%
2. **Parallel Jobs**: All jobs run concurrently
3. **Local Validation**: Run `make pre-commit` before pushing

## Security Scanning

### Gosec Findings

- **Location**: CI logs in Security job
- **Severity**: Annotated in code
- **Action**: Review and fix high/medium issues

### govulncheck Findings

- **Database**: Official Go vulnerability database
- **Updates**: Checked on every run
- **Action**: Update dependencies or add exclusions

### CodeQL Findings

- **Dashboard**: GitHub Security → Code scanning alerts
- **Queries**: security-extended
- **Action**: Review and remediate

## Extending CI

### Adding a New Check

1. Add job to `.github/workflows/ci.yml`:

```yaml
new-check:
  name: New Check
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-go@v5
      with:
        go-version: '1.23'
    - run: make new-check
```

2. Add to `ci-success` dependencies:

```yaml
ci-success:
  needs: [build, lint, unit-tests, e2e-tests, verify-docs, coverage, security, new-check]
```

3. Add Makefile target:

```makefile
new-check:
	@echo "==> Running new check..."
	@./scripts/new-check.sh
```

### Adding Custom Scripts

```bash
# Create scripts directory
mkdir -p scripts

# Add executable script
cat > scripts/custom-check.sh << 'EOF'
#!/bin/bash
set -euo pipefail
# Your check logic
EOF
chmod +x scripts/custom-check.sh

# Use in CI
- run: ./scripts/custom-check.sh
```

## Monitoring

### CI Health Dashboard

Monitor via:
- GitHub Actions tab
- Branch protection status
- Dependabot dashboard
- Security alerts tab

### Success Metrics

- ✅ All CI jobs passing
- ✅ <15 min average CI run time
- ✅ <5 open Dependabot PRs
- ✅ Zero critical security alerts

## Support

For CI/CD issues:
1. Check job logs in GitHub Actions
2. Run checks locally with `make check-all`
3. Review this documentation
4. Open an issue with `ci` label
