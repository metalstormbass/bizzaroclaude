# Getting Started with bizzaroclaude

This guide will help you install and start using bizzaroclaude for the first time.

## Prerequisites

Before installing bizzaroclaude, ensure you have:

- **Go 1.21+** (if installing from source)
- **tmux** - Required for agent isolation
  ```bash
  # macOS
  brew install tmux

  # Ubuntu/Debian
  sudo apt-get install tmux

  # Fedora/RHEL
  sudo dnf install tmux
  ```
- **Git** - For repository management
- **Claude CLI** - Install from https://claude.ai/download

## Installation

### Option 1: Install from Source

```bash
go install github.com/dlorenc/bizzaroclaude/cmd/bizzaroclaude@latest
```

This will install the `bizzaroclaude` binary to `$GOPATH/bin` (typically `~/go/bin`).

Make sure `$GOPATH/bin` is in your PATH:
```bash
export PATH="$PATH:$(go env GOPATH)/bin"
```

### Option 2: Download Pre-built Binary

Visit the [releases page](https://github.com/dlorenc/bizzaroclaude/releases) or use these quick install scripts:

**Linux AMD64:**
```bash
VERSION=$(curl -s https://api.github.com/repos/dlorenc/bizzaroclaude/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -L "https://github.com/dlorenc/bizzaroclaude/releases/download/${VERSION}/bizzaroclaude-${VERSION}-linux-amd64" -o bizzaroclaude
chmod +x bizzaroclaude
sudo mv bizzaroclaude /usr/local/bin/
```

**macOS ARM64 (Apple Silicon):**
```bash
VERSION=$(curl -s https://api.github.com/repos/dlorenc/bizzaroclaude/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -L "https://github.com/dlorenc/bizzaroclaude/releases/download/${VERSION}/bizzaroclaude-${VERSION}-darwin-arm64" -o bizzaroclaude
chmod +x bizzaroclaude
sudo mv bizzaroclaude /usr/local/bin/
```

Available platforms: Linux (amd64/arm64), macOS (amd64/arm64), Windows (amd64)

### Verify Installation

```bash
bizzaroclaude version
```

## Quick Start

### 1. Start the Daemon

The bizzaroclaude daemon coordinates all agents and manages state:

```bash
bizzaroclaude start
```

Check daemon status:
```bash
bizzaroclaude daemon status
```

### 2. Initialize a Repository

bizzaroclaude works with GitHub repositories. Initialize your first repo:

```bash
bizzaroclaude repo init https://github.com/yourusername/yourrepo
```

Or use a shorthand:
```bash
bizzaroclaude init https://github.com/yourusername/yourrepo
```

This will:
- Clone the repository
- Create isolated worktrees for agents
- Set up the supervisor and workspace agents
- Start them in a tmux session

### 3. Connect to Your Workspace

Attach to the tmux session to see your agents:

```bash
tmux attach -t mc-yourrepo
```

You'll see multiple tmux windows:
- **supervisor** - Coordinates agents
- **workspace** - Your personal workspace to control agents

Navigate between windows with `Ctrl-b` + `n` (next) or `Ctrl-b` + `p` (previous).

Detach from tmux: `Ctrl-b` + `d`

### 4. Spawn Worker Agents

From outside tmux:
```bash
bizzaroclaude worker create "Add unit tests for authentication module"
```

Or from within your workspace window, use Claude to communicate with the supervisor.

### 5. Monitor Progress

List active workers:
```bash
bizzaroclaude worker list
```

View agent output logs:
```bash
bizzaroclaude logs <agent-name>
bizzaroclaude logs -f <agent-name>  # Follow mode
```

Check overall system status:
```bash
bizzaroclaude status
```

## Common Workflows

### Creating and Managing Workers

```bash
# Create a worker with a task
bizzaroclaude worker "Fix bug in login handler"

# List all workers for current repo
bizzaroclaude worker list

# Remove a completed worker
bizzaroclaude worker rm <worker-name>
```

### Repository Management

```bash
# List all tracked repositories
bizzaroclaude repo list

# Set default repository (so you don't need --repo flag)
bizzaroclaude repo use myrepo

# Show current default repo
bizzaroclaude repo current

# View task history
bizzaroclaude repo history
```

### Attaching to Agents

```bash
# Attach to a specific agent's tmux window
bizzaroclaude agent attach <agent-name>

# Attach in read-only mode (watch without interaction)
bizzaroclaude agent attach <agent-name> --read-only
```

### Maintenance

```bash
# Clean up orphaned resources
bizzaroclaude cleanup

# Repair state after a crash
bizzaroclaude repair

# Sync agent worktrees with main branch
bizzaroclaude refresh
```

## Understanding the Architecture

bizzaroclaude runs agents in isolated tmux windows. Each agent:
- Has its own git worktree
- Runs Claude Code with a specialized system prompt
- Can communicate with other agents via messages

The daemon runs in the background and:
- Manages agent lifecycle
- Routes messages between agents
- Performs health checks
- Handles crash recovery

## Directory Structure

All bizzaroclaude data lives in `~/.bizzaroclaude/`:

```
~/.bizzaroclaude/
├── daemon.pid              # Daemon process ID
├── daemon.sock             # Unix socket for CLI communication
├── daemon.log              # Daemon logs
├── state.json              # All state (repos, agents, config)
├── repos/                  # Cloned repositories
├── worktrees/              # Isolated worktrees per agent
├── messages/               # Inter-agent message files
├── output/                 # Agent output logs
├── prompts/                # Generated agent prompts
└── claude-config/          # Per-agent Claude configuration
```

## Troubleshooting

### Daemon won't start

```bash
# Check if daemon is already running
bizzaroclaude daemon status

# View daemon logs
bizzaroclaude daemon logs

# Stop and restart
bizzaroclaude daemon stop
bizzaroclaude daemon start
```

### Agents are stuck or crashed

```bash
# Repair state
bizzaroclaude repair

# Clean up orphaned resources
bizzaroclaude cleanup

# Restart a specific agent
bizzaroclaude agent restart <agent-name>
```

### Can't find tmux session

```bash
# List all tmux sessions
tmux ls

# If session exists but you can't attach, try:
tmux attach -t mc-<repo-name>
```

### State inconsistencies

```bash
# Generate a diagnostic report
bizzaroclaude bug

# View system diagnostics
bizzaroclaude diagnostics
```

## Next Steps

- Read the [Commands Reference](COMMANDS.md) for detailed CLI documentation
- Learn about [Agent Types and Customization](AGENTS.md)
- Explore [Common Workflows](WORKFLOWS.md)
- Understand the [Architecture](ARCHITECTURE.md)

## Getting Help

- `bizzaroclaude --help` - Show all commands
- `bizzaroclaude <command> --help` - Help for specific command
- `bizzaroclaude docs` - View generated CLI documentation
- Report issues at https://github.com/dlorenc/bizzaroclaude/issues
