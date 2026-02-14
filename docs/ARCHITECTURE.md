# Architecture Overview

Understanding how bizzaroclaude works under the hood.

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      CLI (cmd/bizzaroclaude)                      │
│                                                                   │
│  User commands parsed and sent via Unix socket                   │
└────────────────────────────────┬──────────────────────────────────┘
                                 │ Unix Socket (/tmp/bizzaroclaude.sock)
┌────────────────────────────────▼──────────────────────────────────┐
│                       Daemon (background process)                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐            │
│  │ Health Check │  │ Message      │  │ Wake/Nudge   │            │
│  │ Loop (2min)  │  │ Router (2min)│  │ Loop (2min)  │            │
│  └──────────────┘  └──────────────┘  └──────────────┘            │
│                                                                   │
│  ┌──────────────────────────────────────────────────┐            │
│  │ State Manager (state.json)                        │            │
│  │ - Repos, agents, config (mutex-protected)         │            │
│  └──────────────────────────────────────────────────┘            │
└─────────────────────────────────┬─────────────────────────────────┘
                                  │
    ┌─────────────────────────────┼─────────────────────────────────┐
    │                             │                                 │
┌───▼───────┐  ┌─────────┐  ┌────▼────┐  ┌─────────┐  ┌─────────┐
│supervisor │  │workspace│  │worker-1 │  │worker-2 │  │worker-N │
│           │  │         │  │         │  │         │  │         │
│ Tmux      │  │ Tmux    │  │ Tmux    │  │ Tmux    │  │ Tmux    │
│ window    │  │ window  │  │ window  │  │ window  │  │ window  │
└───────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘
      │              │            │            │            │
      └──────────────┴────────────┴────────────┴────────────┘
            Tmux Session: mc-<repo> (one window per agent)
```

## Components

### CLI (`cmd/bizzaroclaude`, `internal/cli`)

**Purpose:** User interface for bizzaroclaude.

**Responsibilities:**
- Parse command-line arguments
- Validate inputs
- Send requests to daemon via Unix socket
- Display results to user
- Provide helpful error messages

**Key Files:**
- `cmd/bizzaroclaude/main.go` - Entry point
- `internal/cli/cli.go` - All CLI commands (~5500 lines)

**Design:**
- Command pattern with `Command` struct
- Subcommand hierarchy (e.g., `repo init`, `worker create`)
- Structured errors from `internal/errors`

### Daemon (`internal/daemon`)

**Purpose:** Background orchestrator managing all agents.

**Responsibilities:**
- Agent lifecycle management
- State persistence
- Message routing
- Health checks and recovery
- Socket server for CLI communication

**Key Files:**
- `internal/daemon/daemon.go` - Main daemon implementation
- `internal/daemon/loops.go` - Health check, message routing, nudge loops

**Loops:**
1. **Health Check Loop** (every 2 minutes)
   - Checks if agent tmux windows exist
   - Verifies Claude processes are running
   - Attempts recovery for crashed agents
   - Removes dead agents from state

2. **Message Router Loop** (every 2 minutes)
   - Scans message directories
   - Delivers unread messages to agents
   - Cleans up acknowledged messages

3. **Wake/Nudge Loop** (every 2 minutes)
   - Checks for idle agents
   - Sends nudge messages if needed

### State Management (`internal/state`)

**Purpose:** Persistent storage of all system state.

**File:** `~/.bizzaroclaude/state.json`

**Structure:**
```json
{
  "repos": [
    {
      "name": "myproject",
      "url": "https://github.com/org/myproject",
      "path": "/home/user/.bizzaroclaude/repos/myproject",
      "agents": [
        {
          "name": "supervisor",
          "class": "supervisor",
          "tmux_window": "mc-myproject:0",
          "status": "running",
          "worktree": "/home/user/.bizzaroclaude/worktrees/myproject/supervisor"
        }
      ],
      "config": {
        "merge_queue_enabled": true,
        "merge_queue_track": "all"
      }
    }
  ],
  "current_repo": "myproject",
  "version": "1"
}
```

**Atomicity:**
- All writes use atomic file operations (write to temp → rename)
- Mutex protection for concurrent access
- Crash-safe persistence

**Key Operations:**
- `Load()` - Read state from disk
- `Save()` - Write state to disk atomically
- `AddAgent()`, `RemoveAgent()` - Modify agent list
- `GetAgents()` - Query agents

### Message System (`internal/messages`)

**Purpose:** Inter-agent communication.

**How it works:**
1. Agent A sends message to Agent B
2. Message written as JSON file: `~/.bizzaroclaude/messages/<repo>/<agent-b>/<msg-id>.json`
3. Daemon's message router detects new message (2 min poll)
4. Daemon delivers message to Agent B via tmux
5. Agent B acknowledges message
6. Message file deleted

**Message Structure:**
```go
type Message struct {
    ID        string    `json:"id"`
    From      string    `json:"from"`
    To        string    `json:"to"`
    Content   string    `json:"content"`
    Timestamp time.Time `json:"timestamp"`
    Read      bool      `json:"read"`
}
```

**Advantages:**
- Asynchronous (non-blocking)
- Persisted (survives crashes)
- Simple (just JSON files)

**Limitations:**
- 2-minute delivery latency (polling interval)
- No guaranteed delivery if recipient agent crashes

### Worktree Management (`internal/worktree`)

**Purpose:** Isolated git working directories for each agent.

**Why Worktrees?**
- Agents work on different branches simultaneously
- No conflicts between agents
- Independent git state per agent
- Easy cleanup when agent done

**Structure:**
```
~/.bizzaroclaude/worktrees/<repo>/<agent>/
```

**Operations:**
- Create: `git worktree add <path> -b <branch>`
- Remove: `git worktree remove <path>`
- List: `git worktree list`

Each agent's worktree is a full working copy of the repo, checked out to a specific branch.

### Prompts (`internal/prompts`, `internal/templates`)

**Purpose:** System prompts for agents.

**Locations:**
- `internal/prompts/supervisor.md` - Supervisor agent
- `internal/prompts/workspace.md` - Workspace agent
- `internal/templates/agent-templates/*.md` - Worker, reviewer, etc.

**Embedding:**
- Prompts are embedded at compile time using Go's `embed` directive
- Changes require recompilation

**Slash Commands:**
- Defined in `internal/prompts/commands/*.md`
- Also embedded at compile time
- Automatically available to all agents

### Socket Server (`internal/socket`)

**Purpose:** IPC between CLI and daemon.

**Protocol:** Unix domain socket at `~/.bizzaroclaude/daemon.sock`

**Request/Response:**
```go
type Request struct {
    Command string                 `json:"command"`
    Args    map[string]interface{} `json:"args"`
}

type Response struct {
    Success bool                   `json:"success"`
    Data    interface{}            `json:"data"`
    Error   string                 `json:"error"`
}
```

**Advantages:**
- Fast (local socket, no network)
- Secure (filesystem permissions)
- Simple (JSON over socket)

### Tmux Integration (`pkg/tmux`)

**Purpose:** Public library for programmatic tmux control.

**Key Functions:**
- `NewSession()` - Create tmux session
- `NewWindow()` - Create window in session
- `SendKeys()` - Send keystrokes to window
- `SendKeysLiteralWithEnter()` - **Atomic** text + Enter (prevents race conditions)
- `KillWindow()` - Destroy window

**Important:** Always use `SendKeysLiteralWithEnter()` for sending commands to agents. The separate `SendKeys()` + `SendEnter()` pattern has race conditions.

### Claude Integration (`pkg/claude`)

**Purpose:** Public library for launching Claude Code instances.

**Key Functions:**
- `Run()` - Start Claude in a directory with custom prompt
- `Config` - Configure Claude behavior

**Agent Setup:**
Each agent gets:
1. Custom `CLAUDE_CONFIG_DIR` pointing to `~/.bizzaroclaude/claude-config/<repo>/<agent>/`
2. System prompt generated from template
3. Slash commands copied to config dir

## Data Flow Examples

### Creating a Worker

```
User: bizzaroclaude worker "Fix bug"
  │
  ├─> CLI parses args
  │
  ├─> CLI sends Request{"command": "create_worker", "args": {...}} via socket
  │
  ├─> Daemon receives request
  │
  ├─> Daemon:
  │     ├─> Generates worker name (e.g., "swift-eagle")
  │     ├─> Adds agent to state.json
  │     ├─> Creates git worktree
  │     ├─> Generates system prompt
  │     ├─> Creates tmux window
  │     ├─> Launches Claude in tmux window
  │     └─> Returns Response{success: true}
  │
  └─> CLI displays: "Worker swift-eagle created"
```

### Message Delivery

```
Agent A: bizzaroclaude message send supervisor "Task done"
  │
  ├─> CLI writes message JSON to ~/.bizzaroclaude/messages/<repo>/supervisor/<id>.json
  │
  ├─> CLI returns immediately
  │
  [Time passes, up to 2 minutes]
  │
  ├─> Daemon's message router loop wakes up
  │
  ├─> Scans message directories
  │
  ├─> Finds new message for supervisor
  │
  ├─> Sends message to supervisor's tmux window:
  │     tmux send-keys -t mc-repo:supervisor "Message from Agent A: Task done"
  │
  └─> Supervisor sees message in Claude
```

### Health Check and Recovery

```
[Every 2 minutes]
  │
  ├─> Daemon health check loop runs
  │
  ├─> For each agent in state:
  │     │
  │     ├─> Check if tmux window exists
  │     │
  │     ├─> If not:
  │     │     ├─> Attempt to recreate window
  │     │     ├─> Relaunch Claude
  │     │     └─> If recovery fails:
  │     │           └─> Mark agent as "dead" and remove from state
  │     │
  │     └─> If yes:
  │           └─> Agent still healthy, continue
  │
  └─> Save updated state
```

## Directory Structure

```
~/.bizzaroclaude/
├── daemon.pid              # Daemon PID (lock file)
├── daemon.sock             # Unix socket
├── daemon.log              # Daemon logs (rotated at 10MB)
├── state.json              # All state (atomic writes)
│
├── repos/<name>/           # Cloned repositories
│   └── .git/
│
├── worktrees/<repo>/<agent>/  # Isolated worktrees
│   ├── .git/               # Git metadata (linked to main repo)
│   └── <repo files>
│
├── messages/<repo>/<agent>/   # Message JSON files
│   └── msg-<id>.json
│
├── output/<repo>/          # Agent output logs
│   └── <agent>.log
│
├── prompts/<agent>.md      # Generated agent prompts
│
└── claude-config/<repo>/<agent>/  # Per-agent Claude config
    ├── commands/           # Slash command files
    │   ├── status.md
    │   ├── messages.md
    │   └── workers.md
    └── hooks/              # Claude hooks (if configured)
```

## Concurrency and Safety

### Mutex Protection

State access is protected:
```go
func (s *State) AddAgent(agent *Agent) {
    s.mu.Lock()
    defer s.mu.Unlock()
    // ... modify state ...
    s.saveUnlocked()
}
```

### Atomic File Writes

```go
func atomicWrite(path string, data []byte) error {
    // Write to temp file
    tmpPath := path + ".tmp"
    if err := os.WriteFile(tmpPath, data, 0644); err != nil {
        return err
    }
    // Atomic rename
    return os.Rename(tmpPath, path)
}
```

### Crash Recovery

1. **PID File:** `daemon.pid` contains daemon PID
   - Checked on CLI commands
   - Stale PID file → `repair` command

2. **State Validation:** `repair` command:
   - Loads state.json
   - Validates each agent
   - Removes agents with missing tmux windows
   - Rewrites state

3. **Health Checks:** Every 2 minutes:
   - Verify agent processes exist
   - Attempt recovery
   - Remove truly dead agents

## Performance Characteristics

### Resource Usage Per Agent

- **Disk:** ~100-500 MB (worktree)
- **Memory:** ~500 MB - 1 GB (Claude process)
- **Network:** GitHub API calls (rate limited)

### Recommended Limits

- **Max concurrent workers:** 5-10 (depends on system)
- **Repos per daemon:** No hard limit, but 5-10 practical

### Bottlenecks

1. **Polling Interval:** 2-minute delay for messages and health checks
2. **GitHub API Rate Limits:** 5000 requests/hour for authenticated users
3. **Disk I/O:** Worktree creation can be slow for large repos
4. **tmux Windows:** System limit (~dozens to hundreds)

## Extension Points

### Adding Custom Agent Types

1. Create prompt template in `internal/templates/agent-templates/custom.md`
2. Rebuild: `go build ./cmd/bizzaroclaude`
3. Spawn: `bizzaroclaude agents spawn --class custom ...`

### Extending the CLI

1. Add command in `internal/cli/cli.go` → `registerCommands()`
2. Implement command handler
3. Regenerate docs: `go generate ./pkg/config`

### Custom Slash Commands

1. Add `.md` file to `internal/prompts/commands/`
2. Rebuild to embed new command
3. New agents will have the command available

### Socket API Integration

External tools can integrate via the socket API. See `docs/extending/SOCKET_API.md` for details.

## Security Considerations

1. **File Permissions:**
   - Socket: 0600 (owner only)
   - State: 0644 (readable by all)
   - Logs: 0644

2. **GitHub Credentials:**
   - Stored in git credential helper
   - Never in state.json or logs
   - Inherited from user's git config

3. **Agent Isolation:**
   - Each agent in separate tmux window
   - Separate worktrees
   - Shared filesystem (no sandboxing)

4. **Command Injection:**
   - All commands validated before execution
   - User input sanitized for tmux session names

## Debugging the System

### Daemon Issues

```bash
# Check daemon logs
tail -f ~/.bizzaroclaude/daemon.log

# Check if daemon is actually running
ps aux | grep bizzaroclaude
cat ~/.bizzaroclaude/daemon.pid

# Daemon state
cat ~/.bizzaroclaude/state.json | jq .
```

### Agent Issues

```bash
# Check agent state
cat ~/.bizzaroclaude/state.json | jq '.repos[0].agents'

# Check agent logs
cat ~/.bizzaroclaude/output/<repo>/<agent>.log

# Check tmux window exists
tmux list-windows -t mc-<repo> | grep <agent>

# Check worktree exists
ls -la ~/.bizzaroclaude/worktrees/<repo>/<agent>/
```

### Message Issues

```bash
# Check pending messages
ls ~/.bizzaroclaude/messages/<repo>/<agent>/

# Read message content
cat ~/.bizzaroclaude/messages/<repo>/<agent>/msg-*.json | jq .
```

## See Also

- [Getting Started Guide](GETTING_STARTED.md)
- [Commands Reference](COMMANDS.md)
- [Agent Guide](AGENTS.md)
- [Common Workflows](WORKFLOWS.md)
- [Socket API Integration](extending/SOCKET_API.md)
- [State File Integration](extending/STATE_FILE_INTEGRATION.md)
