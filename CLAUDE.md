# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**bizzaroclaude** is a lightweight orchestrator for running multiple Claude Code agents on container pentesting targets in controlled lab environments. Each agent runs in its own tmux window with an isolated workspace, enabling parallel autonomous security testing on local infrastructure.

**Inspired by [multiclaude](https://github.com/dlorenc/multiclaude)**: This project adapts the multi-agent coordination architecture from multiclaude (a GitHub repository orchestrator) to the domain of container security testing. This is a standalone security research tool with no connection to GitHub operations.

### The Parallel Discovery Philosophy

This project embraces coordinated exploration: multiple agents work simultaneously using different techniques, potentially duplicating effort or finding overlapping vulnerabilities. **Validation is the ratchet** - if a finding can be verified and reproduced, it gets reported. Progress is permanent.

**Core Beliefs (hardcoded, not configurable):**
- Validation is King: Every finding must be reproducible and verified
- Parallel Coverage > Sequential Perfection: Multiple techniques beat linear testing
- Redundancy is Expected: Overlapping discoveries are cheaper than missed vulnerabilities
- Researcher Controls: Agents discover and propose, humans validate and decide

**CRITICAL SECURITY CONTEXT:**
- **LAB USE ONLY**: This tool is exclusively for authorized security research in controlled lab environments
- **Local Targets Only**: Only test local containers and infrastructure you own
- **No Remote Testing**: Never point this at remote systems or infrastructure you don't own
- **Authorization Required**: Only test systems with explicit authorization
- **Responsible Disclosure**: Follow responsible disclosure for any vulnerabilities found

## Quick Reference

```bash
# Build & Install
go build ./cmd/bizzaroclaude         # Build binary
go install ./cmd/bizzaroclaude       # Install to $GOPATH/bin

# CI Guard Rails (run before pushing)
make pre-commit                    # Fast checks: build + unit tests + verify docs
make check-all                     # Full CI: all checks that GitHub CI runs
make install-hooks                 # Install git pre-commit hook

# Test (run before pushing)
go test ./...                      # All tests
go test ./internal/daemon          # Single package
go test -v ./test/...              # E2E tests (requires tmux)
go test ./internal/state -run TestSave  # Single test

# Development
go generate ./pkg/config           # Regenerate CLI docs for prompts
MULTICLAUDE_TEST_MODE=1 go test ./test/...  # Skip Claude startup

# Local Container Testing Commands
docker ps                          # List running containers
docker inspect <container>         # Inspect container configuration
docker exec -it <container> sh     # Exec into container
docker export <container> -o dump.tar  # Extract filesystem
```

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         CLI (cmd/bizzaroclaude)                    │
└────────────────────────────────┬────────────────────────────────┘
                                 │ Unix Socket
┌────────────────────────────────▼────────────────────────────────┐
│                          Daemon (internal/daemon)                │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐        │
│  │ Health   │  │ Message  │  │ Wake/    │  │ Socket   │        │
│  │ Check    │  │ Router   │  │ Nudge    │  │ Server   │        │
│  │ (2min)   │  │ (2min)   │  │ (2min)   │  │          │        │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘        │
└────────────────────────────────┬────────────────────────────────┘
                                 │
    ┌────────────────────────────┼────────────────────────────────┐
    │                            │                                │
┌───▼───┐  ┌───────────┐  ┌─────▼─────┐  ┌──────────┐  ┌────────┐
│super- │  │coordi-    │  │workspace  │  │recon-N   │  │exploit │
│visor  │  │nator      │  │           │  │          │  │        │
└───────┘  └───────────┘  └───────────┘  └──────────┘  └────────┘
    │           │              │              │             │
    └───────────┴──────────────┴──────────────┴─────────────┘
           tmux session: mc-<target>  (one window per agent)
```

### Package Responsibilities

| Package | Purpose | Key Types |
|---------|---------|-----------|
| `cmd/bizzaroclaude` | Entry point | `main()` |
| `internal/cli` | All CLI commands | `CLI`, `Command` |
| `internal/daemon` | Background process | `Daemon`, daemon loops |
| `internal/state` | Persistence | `State`, `Agent`, `Target` |
| `internal/messages` | Inter-agent IPC | `Manager`, `Message` |
| `internal/prompts` | Agent system prompts | Embedded `*.md` files, `GetSlashCommandsPrompt()` |
| `internal/prompts/commands` | Slash command templates | `GenerateCommandsDir()`, embedded `*.md` |
| `internal/hooks` | Claude hooks config | `CopyConfig()` |
| `internal/worktree` | Workspace isolation | `Manager`, `WorkspaceInfo` |
| `internal/socket` | Unix socket IPC | `Server`, `Client`, `Request` |
| `internal/errors` | User-friendly errors | `CLIError`, error constructors |
| `internal/names` | Agent name generation | `Generate()` (adjective-animal) |
| `internal/templates` | Agent prompt templates | Template loading and embedding |
| `internal/agents` | Agent management | Agent definition loading |
| `pkg/config` | Path configuration | `Paths`, `NewTestPaths()` |
| `pkg/tmux` | **Public** tmux library | `Client` (multiline support) |
| `pkg/claude` | **Public** Claude runner | `Runner`, `Config` |

### Data Flow

1. **CLI** parses args → sends `Request` via Unix socket
2. **Daemon** handles request → updates `state.json` → manages tmux
3. **Agents** run in tmux windows with embedded prompts and per-agent slash commands (via `CLAUDE_CONFIG_DIR`)
4. **Messages** flow via filesystem JSON files, routed by daemon
5. **Health checks** (every 2 min) attempt self-healing restoration before cleanup of dead agents
6. **Findings** are collected, validated, and deduplicated by the coordinator agent

## Key Files to Understand

| File | What It Does |
|------|--------------|
| `internal/cli/cli.go` | **Large file** (~5500 lines) with all CLI commands |
| `internal/daemon/daemon.go` | Daemon implementation with all loops |
| `internal/state/state.go` | State struct with mutex-protected operations |
| `internal/prompts/*.md` | Supervisor/workspace prompts (embedded at compile) |
| `internal/templates/agent-templates/*.md` | Recon/exploit/coordinator/privilege prompt templates |
| `pkg/tmux/client.go` | Public tmux library with `SendKeysLiteralWithEnter` |

## Patterns and Conventions

### Error Handling

Use structured errors from `internal/errors` for user-facing messages:

```go
// Good: User gets helpful message + suggestion
return errors.DaemonNotRunning()  // "daemon is not running" + "Try: bizzaroclaude daemon start"

// Good: Wrap with context
return errors.TargetOperationFailed("scan", err)

// Avoid: Raw errors lose context for users
return fmt.Errorf("scan failed: %w", err)
```

### State Mutations

Always use atomic writes for crash safety:

```go
// internal/state/state.go pattern
func (s *State) saveUnlocked() error {
    data, err := json.MarshalIndent(s, "", "  ")
    if err != nil {
        return fmt.Errorf("failed to marshal state: %w", err)
    }
    return atomicWrite(s.path, data)  // Atomic write via temp file + rename
}
```

### Tmux Text Input

Use `SendKeysLiteralWithEnter` for atomic text + Enter (prevents race conditions):

```go
// Good: Atomic operation
tmux.SendKeysLiteralWithEnter(session, window, message)

// Avoid: Race condition between text and Enter
tmux.SendKeysLiteral(session, window, message)
tmux.SendEnter(session, window)  // Enter might be lost!
```

### Agent Context Detection

Agents infer their context from working directory:

```go
// internal/cli/cli.go pattern
func (c *CLI) inferTargetFromCwd() (string, error) {
    // Checks if cwd is under ~/.bizzaroclaude/workspaces/<target>/
}
```

## Testing

### Test Categories

| Directory | What | Requirements |
|-----------|------|--------------|
| `internal/*/` | Unit tests | None |
| `test/` | E2E integration | tmux installed, docker |
| `test/recovery_test.go` | Crash recovery | tmux installed |

### Test Mode

```bash
# Skip actual Claude startup in tests
MULTICLAUDE_TEST_MODE=1 go test ./test/...
```

### Writing Tests

```go
// Create isolated test environment using the helper
tmpDir, _ := os.MkdirTemp("", "bizzaroclaude-test-*")
paths := config.NewTestPaths(tmpDir)  // Sets up all paths correctly
defer os.RemoveAll(tmpDir)

// Use NewWithPaths for testing
cli := cli.NewWithPaths(paths)
```

## Agent System

See `docs/AGENTS.md` for detailed agent documentation including:
- Agent types and their roles (Recon, Exploit, Privilege, Coordinator)
- Message routing implementation
- Prompt system and customization
- Agent lifecycle management
- Adding new agent types

### Security Testing Agent Types

| Agent Class | Purpose | When to Use |
|-------------|---------|-------------|
| **Recon** | Initial reconnaissance, service enumeration, fingerprinting | First phase of testing |
| **Exploit** | Vulnerability testing, exploit verification | After identifying potential vulnerabilities |
| **Privilege** | Privilege escalation, container escape testing | Post-exploitation phase |
| **Coordinator** | Finding validation, deduplication, reporting | Always running to manage results |
| **Custom** | Specialized testing (fuzzing, specific CVE testing, etc.) | Domain-specific needs |

## Local Container Testing Focus

### Attack Surfaces (Local Docker)

- Exposed Docker socket (`/var/run/docker.sock`)
- Privileged containers
- CAP_SYS_ADMIN and other dangerous capabilities
- Host PID/Network/IPC namespace sharing
- Mounted host filesystem paths
- Weak seccomp/apparmor profiles
- Container runtime vulnerabilities

### Example Security Checks

```bash
# Check if container is privileged
docker inspect <container> | grep Privileged

# Check capabilities
docker inspect <container> --format '{{.HostConfig.CapAdd}}'

# Check for host PID namespace
docker inspect <container> | grep PidMode

# Check for mounted docker socket
docker inspect <container> | grep docker.sock

# Check mounted volumes
docker inspect <container> --format '{{.Mounts}}'
```

## Extensibility

External tools can integrate via:

| Extension Point | Use Cases | Documentation |
|----------------|-----------|---------------|
| **State File** | Monitoring, analytics, reporting | [`docs/extending/STATE_FILE_INTEGRATION.md`](docs/extending/STATE_FILE_INTEGRATION.md) |
| **Socket API** | Custom CLIs, automation, orchestration | [`docs/extending/SOCKET_API.md`](docs/extending/SOCKET_API.md) |
| **Findings API** | Export to vulnerability databases, integrate with report tools | [`docs/extending/FINDINGS_API.md`](docs/extending/FINDINGS_API.md) |

**Note:** Web UIs and remote access are explicitly out of scope for security reasons.

## Contributing Checklist

When modifying agent behavior:
- [ ] Update the relevant prompt (supervisor/workspace in `internal/prompts/*.md`, others in `internal/templates/agent-templates/*.md`)
- [ ] Run `go generate ./pkg/config` if CLI changed
- [ ] Test with tmux: `go test ./test/...`
- [ ] Check state persistence: `go test ./internal/state/...`
- [ ] Verify security constraints (local-only, authorization checks)

When adding CLI commands:
- [ ] Add to `registerCommands()` in `internal/cli/cli.go`
- [ ] Use `internal/errors` for user-facing errors
- [ ] Add help text with `Usage` field
- [ ] Regenerate docs: `go generate ./pkg/config`
- [ ] Add authorization/safety checks for destructive operations

When modifying daemon loops:
- [ ] Consider interaction with health check (2 min cycle)
- [ ] Test crash recovery: `go test ./test/ -run Recovery`
- [ ] Verify state atomicity with concurrent access tests

When adding security testing capabilities:
- [ ] Ensure all operations are local-only (no remote targeting)
- [ ] Add clear authorization warnings in help text
- [ ] Document ethical use in relevant docs
- [ ] Test against authorized lab targets only
- [ ] Include validation/reproducibility steps

## Runtime Directories

```
~/.bizzaroclaude/
├── daemon.pid              # Daemon PID (lock file)
├── daemon.sock             # Unix socket for CLI<->daemon
├── daemon.log              # Daemon logs (rotated at 10MB)
├── state.json              # All state (targets, agents, config)
├── prompts/                # Generated prompt files for agents
├── targets/<target>/       # Target-specific data
├── workspaces/<target>/<agent>/ # Isolated workspaces per agent
├── messages/<target>/<agent>/   # Message JSON files
├── output/<target>/        # Agent output logs
│   ├── recon/              # Recon agent logs
│   ├── exploit/            # Exploit agent logs
│   └── privilege/          # Privilege escalation logs
├── findings/<target>/      # Validated findings (JSON format)
└── claude-config/<target>/<agent>/ # Per-agent CLAUDE_CONFIG_DIR
    └── commands/           # Slash command files (*.md)
```

## Common Operations

### Debug a stuck agent

```bash
# Attach to see what it's doing
bizzaroclaude agent attach <agent-name> --read-only

# Check its messages
bizzaroclaude message list  # (from agent's tmux window)

# Manually nudge via daemon logs
tail -f ~/.bizzaroclaude/daemon.log
```

### Repair inconsistent state

```bash
# Local repair (no daemon)
bizzaroclaude repair

# Daemon-side repair
bizzaroclaude cleanup --dry-run  # See what would be cleaned
bizzaroclaude cleanup            # Actually clean up
```

### Test prompt changes

```bash
# Prompts are embedded at compile time
# Supervisor/workspace prompts: internal/prompts/*.md
# Recon/exploit/coordinator prompts: internal/templates/agent-templates/*.md
vim internal/templates/agent-templates/recon.md
go build ./cmd/bizzaroclaude
# New recon agents will use updated prompt
```

### Review findings

```bash
# List all findings for a target
bizzaroclaude findings list <target>

# List only validated findings
bizzaroclaude findings list <target> --validated

# Export findings to JSON
bizzaroclaude findings export <target> --format json > findings.json

# View detailed finding
bizzaroclaude findings view <finding-id>
```

## Lab Testing Workflow

### Phase 1: Reconnaissance

```bash
# Initialize target (local container)
bizzaroclaude target init my-vulnerable-app

# Spawn recon agent
bizzaroclaude agent create recon "Enumerate all exposed services and configurations"

# Agent will:
# - List running processes
# - Enumerate network connections
# - Check file permissions
# - Identify SUID binaries
# - Map mounted volumes
```

### Phase 2: Misconfiguration Discovery

```bash
# Spawn config auditor
bizzaroclaude agent create audit "Check for dangerous capabilities and misconfigurations"

# Agent checks:
# - Privileged mode
# - Dangerous capabilities (SYS_ADMIN, SYS_PTRACE, etc.)
# - Host namespace sharing
# - Mounted docker socket
# - Writable host paths
```

### Phase 3: Exploitation

```bash
# After identifying vulnerabilities, test exploitation
bizzaroclaude agent create exploit "Test container escape via docker socket"

# Agent attempts:
# - Container escape techniques
# - Privilege escalation
# - Capability abuse
# - Kernel vulnerabilities
```

### Phase 4: Validation

```bash
# Coordinator validates all findings
bizzaroclaude findings list --validated

# Each finding includes:
# - Exact reproduction steps
# - Commands executed
# - Expected vs actual output
# - Impact assessment
```

## Security & Ethics Guidelines for Development

**When working on this codebase, always remember:**

1. **This is a security research tool for lab use only**
   - Never add features that enable remote or unauthorized testing
   - Always include safety checks and authorization warnings
   - Document ethical use prominently

2. **Local-only by design**
   - Target selection should only work with local containers
   - Docker socket access should be local only
   - No network scanning beyond localhost
   - No remote container runtime APIs

3. **Validation-first approach**
   - Findings must be reproducible
   - Include validation steps in all testing agent prompts
   - Coordinator must verify before reporting

4. **Clear documentation**
   - Every new feature needs ethical use documentation
   - CLI help text must include authorization warnings
   - README security section must stay prominent

5. **Responsible development**
   - Consider dual-use implications of new features
   - Prefer defensive capabilities over offensive
   - Think about how features could be misused and add safeguards
   - Always test against vulnerable containers you created yourself

## Container Escape Techniques (For Testing)

Common techniques agents may test (local lab only):

1. **Docker Socket Abuse**
   ```bash
   # If socket is mounted
   docker run -v /:/host --rm -it alpine chroot /host sh
   ```

2. **Privileged Container Escape**
   ```bash
   # Test if container can access host devices
   ls -la /dev/
   ```

3. **Capability Abuse**
   ```bash
   # Test dangerous capabilities
   capsh --print
   ```

4. **cgroups release_agent**
   - Test classic container escape via cgroups

5. **Kernel Vulnerabilities**
   - Test for known CVEs (Dirty Pipe, etc.)

**All testing must:**
- Be reproducible
- Document exact steps
- Include cleanup procedures
- Only run on authorized lab infrastructure
