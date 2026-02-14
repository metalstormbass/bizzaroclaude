# Tool Integration

Integrating external security and development tools with bizzaroclaude.

## Table of Contents

- [Overview](#overview)
- [Git and GitHub Integration](#git-and-github-integration)
- [CI/CD Integration](#cicd-integration)
- [Development Tools](#development-tools)
- [Monitoring and Observability](#monitoring-and-observability)
- [Custom Tool Integration](#custom-tool-integration)

## Overview

bizzaroclaude agents can use any command-line tools available in their environment. This guide covers common integrations and patterns.

## Git and GitHub Integration

### GitHub CLI (`gh`)

Agents have full access to the GitHub CLI for PR and issue management.

**Common Operations:**

```bash
# Create PR
gh pr create --title "Add feature" --body "Description"

# List PRs
gh pr list

# View PR
gh pr view 123

# Merge PR
gh pr merge 123

# Create issue
gh issue create --title "Bug" --body "Description"

# Comment on PR
gh pr comment 123 --body "LGTM"
```

**In Agent Prompts:**

```markdown
When you complete your work:
1. Commit changes
2. Push to your branch
3. Create PR: `gh pr create --title "..." --body "..."`
4. Signal completion: `bizzaroclaude agent complete`
```

### Git Hooks

**Pre-commit hooks** can be configured to run before agents create commits:

```bash
# In .git/hooks/pre-commit
#!/bin/bash
go test ./...
golangci-lint run
```

Agents will run these hooks automatically when committing.

### Git Worktree Commands

Agents can inspect their worktree:

```bash
# See all worktrees
git worktree list

# Get current branch
git branch --show-current

# Check worktree status
git worktree prune --dry-run
```

## CI/CD Integration

### GitHub Actions

**Monitor CI from agents:**

```bash
# Check workflow runs
gh run list

# View specific run
gh run view 123456

# Watch run in real-time
gh run watch

# Download artifacts
gh run download 123456
```

**Example agent task:**

```markdown
Your task: Monitor CI and report failures

1. Watch for new commits to main
2. Check CI status: `gh run list --branch main`
3. If failures, download logs: `gh run view --log`
4. Analyze logs and create issue with findings
5. Message supervisor with summary
```

### Jenkins Integration

If you have Jenkins CLI configured:

```bash
# Trigger build
java -jar jenkins-cli.jar build <job-name>

# Get build status
java -jar jenkins-cli.jar get-build <job-name> <build-number>
```

### CI Status Checks

**Monitor CI in custom agents:**

```bash
#!/bin/bash
# check-ci-status.sh

PR_NUM=$1
STATUS=$(gh pr checks $PR_NUM --json state -q '.[].state')

if [[ "$STATUS" == "FAILURE" ]]; then
  bizzaroclaude message send supervisor "CI failing on PR #$PR_NUM"
fi
```

## Development Tools

### Language-Specific Linters

**Go:**

```bash
# golangci-lint
golangci-lint run ./...

# go vet
go vet ./...

# staticcheck
staticcheck ./...
```

**JavaScript/TypeScript:**

```bash
# ESLint
eslint src/

# Prettier
prettier --check .

# TypeScript compiler
tsc --noEmit
```

**Python:**

```bash
# pylint
pylint src/

# black
black --check .

# mypy
mypy src/
```

**Agent Integration:**

```markdown
# Code Quality Agent

Before creating PR:
1. Run linter: `golangci-lint run`
2. If errors, fix them
3. Run tests: `go test ./...`
4. Only create PR if all checks pass
```

### Formatters

**Auto-formatting in agents:**

```bash
# Go
gofmt -w .
go fmt ./...

# JavaScript
prettier --write .

# Python
black .
```

### Testing Frameworks

**Running tests in agents:**

```bash
# Go
go test ./...
go test -v ./internal/...
go test -race ./...

# JavaScript
npm test
npm run test:watch

# Python
pytest
pytest --cov=src
```

**Test-focused worker:**

```bash
bizzaroclaude worker "Add tests for authentication module"
```

The worker can:
1. Write tests
2. Run them: `go test ./internal/auth`
3. Verify coverage: `go test -cover ./internal/auth`
4. Create PR when tests pass

### Build Tools

**Make, CMake, Gradle, etc.:**

```bash
# Make
make build
make test
make clean

# Gradle
./gradlew build

# Maven
mvn clean install
```

**Builder agent example:**

```markdown
Your task: Ensure project builds on all platforms

1. Build for Linux: `GOOS=linux go build`
2. Build for macOS: `GOOS=darwin go build`
3. Build for Windows: `GOOS=windows go build`
4. If any fail, report to supervisor
5. If all pass, update build documentation
```

## Monitoring and Observability

### Log Aggregation

**Viewing agent logs:**

```bash
# Real-time monitoring
bizzaroclaude logs -f <agent-name>

# Search logs
bizzaroclaude logs search "error"

# External log analysis
tail -f ~/.bizzaroclaude/output/<repo>/<agent>.log | grep -i error
```

### Metrics Collection

**Custom metrics script:**

```bash
#!/bin/bash
# collect-metrics.sh

# Count PRs created today
TODAY=$(date +%Y-%m-%d)
PR_COUNT=$(gh pr list --created $TODAY | wc -l)

# Count active workers
WORKER_COUNT=$(bizzaroclaude worker list | tail -n +2 | wc -l)

# Log to metrics file
echo "$TODAY,prs:$PR_COUNT,workers:$WORKER_COUNT" >> metrics.csv
```

### Status Dashboards

**Simple dashboard with watch:**

```bash
watch -n 10 'bizzaroclaude status'
```

**Custom dashboard script:**

```bash
#!/bin/bash
# dashboard.sh

clear
echo "=== bizzaroclaude Dashboard ==="
echo ""
echo "Daemon Status:"
bizzaroclaude daemon status
echo ""
echo "Active Workers:"
bizzaroclaude worker list
echo ""
echo "Recent Messages:"
bizzaroclaude message list
```

### Alerting

**Simple alerting:**

```bash
#!/bin/bash
# alert-on-failure.sh

# Check for crashed agents
if bizzaroclaude status | grep -i "crashed"; then
  # Send notification (Slack, email, etc.)
  curl -X POST -H 'Content-type: application/json' \
    --data '{"text":"Agent crashed!"}' \
    $SLACK_WEBHOOK_URL
fi
```

**Run periodically with cron:**

```cron
*/5 * * * * /path/to/alert-on-failure.sh
```

## Custom Tool Integration

### Creating Tool-Specific Agents

**Example: Security Scanner Agent**

```markdown
# Security Scanner Agent

You run security scans and report vulnerabilities.

## Tools Available

- `gosec` - Go security checker
- `npm audit` - JavaScript dependency scanner
- `safety` - Python dependency checker
- `trivy` - Container vulnerability scanner

## Workflow

1. Run appropriate scanner for the codebase
2. Parse output
3. Create GitHub issues for each vulnerability
4. Message coordinator with summary

## Example Commands

```bash
# Go security scan
gosec ./...

# Node.js dependency scan
npm audit --json

# Python dependency scan
safety check --json

# Container scan
trivy image <image-name>
```

## Reporting Format

For each vulnerability found:
```bash
gh issue create \
  --title "[Security] <vulnerability-name>" \
  --body "Severity: <severity>\nDescription: <desc>\nFix: <fix>" \
  --label security
```
```

**Spawn the agent:**

```bash
cat > security-scanner.md <<EOF
[paste prompt above]
EOF

bizzaroclaude agents spawn \
  --name sec-scan \
  --class security-scanner \
  --prompt-file security-scanner.md
```

### Integrating External APIs

**Agent accessing external APIs:**

```bash
# Example: Jira integration
curl -u $JIRA_USER:$JIRA_TOKEN \
  -H "Content-Type: application/json" \
  -d '{"fields":{"project":{"key":"PROJ"},"summary":"Bug"}}' \
  https://your-domain.atlassian.net/rest/api/2/issue/
```

**Example: Slack notifications:**

```bash
# Post to Slack
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"PR ready for review"}' \
  $SLACK_WEBHOOK_URL
```

### Database Tools

**If your project uses databases:**

```bash
# PostgreSQL
psql -h localhost -U user -d dbname -c "SELECT * FROM users;"

# MySQL
mysql -h localhost -u user -p dbname -e "SHOW TABLES;"

# MongoDB
mongosh --eval "db.collection.find()"
```

**Database migration agent:**

```markdown
Your task: Create and apply database migration

1. Create migration file
2. Review schema changes
3. Test on local database
4. Generate rollback migration
5. Create PR with migrations
```

### Infrastructure Tools

**Docker:**

```bash
# Build image
docker build -t app:latest .

# Run container
docker run -d app:latest

# Check logs
docker logs <container-id>
```

**Kubernetes:**

```bash
# Deploy
kubectl apply -f deployment.yaml

# Check status
kubectl get pods

# View logs
kubectl logs <pod-name>
```

**Terraform:**

```bash
# Plan
terraform plan

# Apply
terraform apply

# Show state
terraform show
```

### Documentation Generators

**Auto-generating docs:**

```bash
# Go doc
godoc -http=:6060

# Swagger/OpenAPI
swag init

# Sphinx (Python)
sphinx-build -b html docs/ docs/_build/

# JSDoc
jsdoc src/ -r -d docs/
```

**Documentation agent:**

```bash
bizzaroclaude worker "Update API documentation"
```

The agent can:
1. Run documentation generator
2. Review output
3. Fix broken links or formatting
4. Commit and create PR

## Environment Setup for Agents

### Installing Tools

**Before using tools in agents, install them system-wide:**

```bash
# Go tools
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Node tools
npm install -g eslint prettier

# Python tools
pip install pylint black mypy

# Security tools
brew install trivy gosec  # macOS
apt-get install trivy     # Linux
```

### Tool Configuration Files

Agents inherit tool configurations from the repository:

- `.eslintrc.json` - ESLint config
- `.prettierrc` - Prettier config
- `pyproject.toml` - Python tools config
- `.golangci.yml` - golangci-lint config

Place these in your repository root; agents will use them automatically.

### Environment Variables

Agents inherit your environment. For secrets:

```bash
# Set before starting daemon
export GITHUB_TOKEN=ghp_xxxxx
export SLACK_WEBHOOK_URL=https://hooks.slack.com/...
export JIRA_TOKEN=xxx

bizzaroclaude daemon start
```

Agents will have access to these variables.

**⚠️ Security Note:** Be careful with secrets. Consider using a secret management tool.

## Best Practices

### Tool Availability Checks

**In agent prompts:**

```markdown
Before running tool:
1. Check if installed: `which golangci-lint`
2. If not found, message supervisor: "golangci-lint not installed"
3. Do not proceed without required tools
```

### Error Handling

**Robust tool invocations:**

```bash
# Check exit code
if ! golangci-lint run; then
  bizzaroclaude message send supervisor "Linting failed"
  exit 1
fi
```

### Tool Versioning

**Document tool versions:**

```markdown
# Requirements

- golangci-lint >= 1.55.0
- node >= 18.0.0
- go >= 1.21

Check with:
```bash
golangci-lint --version
node --version
go version
```
```

### Idempotency

**Make tool operations idempotent:**

```bash
# Safe: can run multiple times
gofmt -w .
prettier --write .

# Unsafe: creates new resources each time
gh pr create ...  # Only run once!
```

## Integration Examples

### Example 1: Code Review Bot

```bash
bizzaroclaude agents spawn \
  --name review-bot \
  --class reviewer \
  --task "Review all PRs and run linters"
```

**Agent behavior:**
1. Monitors for new PRs: `gh pr list`
2. For each PR, checks out code
3. Runs linters: `golangci-lint run`
4. Posts review: `gh pr comment <num> --body "..."`

### Example 2: Release Manager

```bash
bizzaroclaude worker "Prepare v1.2.0 release"
```

**Agent behavior:**
1. Updates CHANGELOG
2. Bumps version in files
3. Runs full test suite
4. Creates git tag
5. Generates release notes
6. Creates GitHub release: `gh release create v1.2.0`

### Example 3: Dependency Updater

```bash
bizzaroclaude worker "Update dependencies"
```

**Agent behavior:**
1. Runs `go get -u ./...` or `npm update`
2. Tests still pass: `go test ./...`
3. Commits changes
4. Creates PR with dependency update

## See Also

- [Getting Started Guide](GETTING_STARTED.md)
- [Commands Reference](COMMANDS.md)
- [Agent Guide](AGENTS.md)
- [Common Workflows](WORKFLOWS.md)
- [Architecture Overview](ARCHITECTURE.md)
