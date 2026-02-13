# Cleanup Plan for Bizarro-Multiclaude Refactoring

## Files/Directories to Remove

### Git History & Old Project Context
- [x] `.git/` - Remove old git history (1.3M)
- [x] `.github/` - Remove old CI workflows
- [x] `.multiclaude/` - Remove old project config
- [x] `.claude/` - Remove old Claude context

### Documentation (Old Project)
- [x] `ARCHITECTURAL_REVIEW.md` - Original architecture review
- [x] `ARCHITECTURE.md` - Old architecture doc
- [x] `dev_log.md` - Development log from original
- [x] `SPEC.md` - Original spec
- [x] `DESIGN.md` - Original design doc
- [x] `ROADMAP.md` - Original project roadmap
- [x] `docs/GASTOWN.md` - Comparison with another tool
- [x] `docs/WORKFLOWS.md` - GitHub-centric workflows
- [x] `docs/TASK_MANAGEMENT.md` - Old task system
- [x] `docs/CRASH_RECOVERY.md` - May not be relevant
- [x] `docs/DIRECTORY_STRUCTURE.md` - Old directory structure
- [x] `docs/COMMANDS.md` - Old commands (needs update)
- [x] `docs/ARCHITECTURE.md` - Duplicate architecture doc

### Template Files (GitHub-focused)
- [x] `internal/prompts/supervisor.md` - GitHub-focused supervisor
- [x] `internal/prompts/workspace.md` - GitHub-focused workspace
- [x] `internal/templates/agent-templates/worker.md` - GitHub worker
- [x] `internal/templates/agent-templates/merge-queue.md` - GitHub merge queue
- [x] `internal/templates/agent-templates/pr-shepherd.md` - GitHub PR shepherd
- [x] `internal/templates/agent-templates/reviewer.md` - GitHub reviewer

## Files to Keep

### Core Infrastructure
- `go.mod`, `go.sum` - Dependencies
- `Makefile` - Build system
- `.gitignore` - Git ignore rules
- `.golangci.yml` - Linter config

### New Documentation
- `README.md` - Updated for container pentesting
- `CLAUDE.md` - Updated for security research
- `LICENSE` - Keep if exists

### Source Code
- `cmd/bizzaroclaude/` - Main binary
- `internal/` - All internal packages
- `pkg/` - Public packages
- `test/` - Test files

### Security Testing Artifacts
- `findings/` - Security reports
- `recon-output/` - Reconnaissance results
- `targets.txt` - Target list
- `*.sh` - Testing scripts

## New Files to Create

### Documentation
- [ ] `docs/PENTESTING.md` - Container pentesting guide
- [ ] `docs/AGENT_TEMPLATES.md` - Security agent templates
- [ ] `docs/CVE_TESTING.md` - CVE testing methodology
- [ ] `docs/FINDINGS_FORMAT.md` - How to document findings

### Agent Templates (Security-focused)
- [ ] `internal/templates/agent-templates/recon.md`
- [ ] `internal/templates/agent-templates/exploit.md`
- [ ] `internal/templates/agent-templates/privilege.md`
- [ ] `internal/templates/agent-templates/coordinator.md`

### Configuration
- [ ] `.github/workflows/security-scan.yml` - If we want CI for the tool itself
