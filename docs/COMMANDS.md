# Commands Reference

Complete reference for all bizzaroclaude CLI commands.

## Global Commands

### `bizzaroclaude version`

Show version information.

```bash
bizzaroclaude version
bizzaroclaude version --json  # JSON output
```

### `bizzaroclaude status`

Show comprehensive system status overview including daemon status, tracked repositories, and active agents.

```bash
bizzaroclaude status
```

### `bizzaroclaude docs`

Display auto-generated CLI documentation (used internally by agents).

```bash
bizzaroclaude docs
```

## Daemon Management

### `bizzaroclaude daemon start`

Start the bizzaroclaude daemon in the background.

```bash
bizzaroclaude daemon start
# Or use the short alias:
bizzaroclaude start
```

The daemon:
- Manages agent lifecycle
- Routes messages between agents
- Performs health checks every 2 minutes
- Handles crash recovery

### `bizzaroclaude daemon stop`

Stop the running daemon.

```bash
bizzaroclaude daemon stop
```

**Note:** Stopping the daemon does NOT stop running agents in tmux. Use `stop-all` for that.

### `bizzaroclaude daemon status`

Check if the daemon is running and responsive.

```bash
bizzaroclaude daemon status
```

Output:
- `Daemon is running (PID: ...)` - Daemon is healthy
- `Daemon PID file exists but not responding` - Daemon crashed, run `repair`
- `Daemon is not running` - Need to start daemon

### `bizzaroclaude daemon logs`

View daemon logs.

```bash
bizzaroclaude daemon logs            # View logs
bizzaroclaude daemon logs -f         # Follow logs (live tail)
bizzaroclaude daemon logs -n 100     # Last 100 lines
```

### `bizzaroclaude stop-all`

Stop daemon and kill all bizzaroclaude tmux sessions.

```bash
bizzaroclaude stop-all                # Interactive confirmation
bizzaroclaude stop-all --yes          # Skip confirmation
bizzaroclaude stop-all --clean        # Also clean up state files
```

**Warning:** This kills all agents immediately. Use with caution.

## Repository Management

### `bizzaroclaude repo init`

Initialize and track a new repository.

```bash
bizzaroclaude repo init <github-url> [name]

# Examples:
bizzaroclaude repo init https://github.com/user/repo
bizzaroclaude repo init https://github.com/user/repo myrepo
bizzaroclaude repo init git@github.com:user/repo.git

# Options:
--no-merge-queue           # Disable merge queue agent
--mq-track=all|author|assigned  # Merge queue tracking mode
```

This will:
1. Clone the repository to `~/.bizzaroclaude/repos/<name>`
2. Create worktrees for supervisor and workspace agents
3. Spawn supervisor and workspace agents in a tmux session named `mc-<name>`
4. Set up message routing and configuration

**Aliases:** `bizzaroclaude init` (shorthand)

### `bizzaroclaude repo list`

List all tracked repositories.

```bash
bizzaroclaude repo list
# Or: bizzaroclaude list
```

Shows:
- Repository name
- GitHub URL
- Number of active agents
- Status

### `bizzaroclaude repo rm`

Remove a tracked repository.

```bash
bizzaroclaude repo rm <name>
```

**Warning:** This removes:
- All agent worktrees
- Cloned repository
- All agent data and logs
- Kills all related tmux windows

The command prompts for confirmation unless `--yes` is provided.

### `bizzaroclaude repo use`

Set the default repository (so you don't need `--repo` flag).

```bash
bizzaroclaude repo use <name>
```

### `bizzaroclaude repo current`

Show the currently selected default repository.

```bash
bizzaroclaude repo current
```

### `bizzaroclaude repo unset`

Clear the default repository setting.

```bash
bizzaroclaude repo unset
```

### `bizzaroclaude repo history`

Show task history for a repository.

```bash
bizzaroclaude repo history
bizzaroclaude repo history --repo <name>
bizzaroclaude repo history -n 20                # Last 20 tasks
bizzaroclaude repo history --status completed   # Filter by status
bizzaroclaude repo history --search "auth"      # Search task descriptions
bizzaroclaude repo history --full               # Show full details
```

### `bizzaroclaude repo hibernate`

Hibernate a repository by archiving uncommitted changes.

```bash
bizzaroclaude repo hibernate
bizzaroclaude repo hibernate --repo <name>
bizzaroclaude repo hibernate --all              # Hibernate all repos
bizzaroclaude repo hibernate --yes              # Skip confirmation
```

## Worker Management

Workers are task-focused agents that execute specific work items.

### `bizzaroclaude worker create`

Create a new worker agent.

```bash
bizzaroclaude worker create <task-description>
bizzaroclaude worker <task-description>  # Shorthand

# Examples:
bizzaroclaude worker "Add unit tests for authentication"
bizzaroclaude worker "Fix login bug" --repo myrepo
bizzaroclaude worker "Refactor database module" --branch feature/db-refactor

# Options:
--repo <name>           # Target repository (or use default)
--branch <branch>       # Branch to work on (default: creates work/<worker-name>)
--push-to <branch>      # Branch to push changes to
```

The worker:
- Gets its own tmux window in the repo's session
- Gets an isolated git worktree
- Receives a system prompt with the task description
- Automatically creates PRs when work is done

**Aliases:** `bizzaroclaude work`

### `bizzaroclaude worker list`

List all active workers.

```bash
bizzaroclaude worker list
bizzaroclaude worker list --repo <name>
```

Shows:
- Worker name
- Status (running, completed, crashed)
- Task description
- Created time

### `bizzaroclaude worker rm`

Remove a worker agent.

```bash
bizzaroclaude worker rm <worker-name>
```

This:
- Kills the tmux window
- Removes the worktree
- Cleans up worker state

## Workspace Management

Workspaces are personal interactive agents for manual control.

### `bizzaroclaude workspace`

List workspaces or connect to one.

```bash
bizzaroclaude workspace              # List all workspaces
bizzaroclaude workspace <name>       # Connect to workspace
```

### `bizzaroclaude workspace add`

Add a new workspace.

```bash
bizzaroclaude workspace add <name>
bizzaroclaude workspace add <name> --branch <branch>
```

### `bizzaroclaude workspace rm`

Remove a workspace.

```bash
bizzaroclaude workspace rm <name>
```

### `bizzaroclaude workspace list`

List all workspaces.

```bash
bizzaroclaude workspace list
```

### `bizzaroclaude workspace connect`

Connect to (attach to) a workspace's tmux window.

```bash
bizzaroclaude workspace connect <name>
```

## Agent Management

### `bizzaroclaude agent attach`

Attach to an agent's tmux window.

```bash
bizzaroclaude agent attach <agent-name>
bizzaroclaude agent attach <agent-name> --read-only

# Shorthand:
bizzaroclaude attach <agent-name>
```

**Interactive mode:** Full control, can type commands
**Read-only mode:** Watch only, cannot interact

Detach with `Ctrl-b` + `d`

### `bizzaroclaude agent restart`

Restart a crashed or exited agent.

```bash
bizzaroclaude agent restart <name>
bizzaroclaude agent restart <name> --repo <repo>
bizzaroclaude agent restart <name> --force     # Force restart even if running
```

### `bizzaroclaude agent complete`

Signal worker completion (called by worker agents).

```bash
bizzaroclaude agent complete
bizzaroclaude agent complete --summary "Completed authentication tests"
bizzaroclaude agent complete --failure "Could not access database"
```

This is typically called by worker agents themselves, not manually.

## Agent Definitions

Manage custom agent templates.

### `bizzaroclaude agents list`

List available agent definition templates.

```bash
bizzaroclaude agents list
bizzaroclaude agents list --repo <name>
```

Shows built-in and custom agent templates.

### `bizzaroclaude agents spawn`

Spawn an agent from a custom prompt file.

```bash
bizzaroclaude agents spawn --name <name> --class <class> --prompt-file <file>

# Example:
bizzaroclaude agents spawn \
  --name reviewer-1 \
  --class reviewer \
  --prompt-file custom-reviewer.md \
  --task "Review PR #123"
```

### `bizzaroclaude agents reset`

Reset agent definitions to defaults (re-copy from built-in templates).

```bash
bizzaroclaude agents reset
bizzaroclaude agents reset --repo <name>
```

## Message Passing

Agents communicate via the message system.

### `bizzaroclaude message send`

Send a message to another agent.

```bash
bizzaroclaude message send <recipient> <message>

# Example:
bizzaroclaude message send supervisor "Worker completed task"
```

**Aliases:** `bizzaroclaude agent send-message`

### `bizzaroclaude message list`

List pending messages for the current agent.

```bash
bizzaroclaude message list
```

**Aliases:** `bizzaroclaude agent list-messages`

### `bizzaroclaude message read`

Read a specific message.

```bash
bizzaroclaude message read <message-id>
```

**Aliases:** `bizzaroclaude agent read-message`

### `bizzaroclaude message ack`

Acknowledge (mark as read) a message.

```bash
bizzaroclaude message ack <message-id>
```

**Aliases:** `bizzaroclaude agent ack-message`

## Logs

### `bizzaroclaude logs`

View agent output logs.

```bash
bizzaroclaude logs <agent-name>
bizzaroclaude logs <agent-name> -f              # Follow mode
bizzaroclaude logs <agent-name> --repo <repo>
```

### `bizzaroclaude logs list`

List all log files.

```bash
bizzaroclaude logs list
bizzaroclaude logs list --repo <name>
```

### `bizzaroclaude logs search`

Search across all logs.

```bash
bizzaroclaude logs search <pattern>
bizzaroclaude logs search "error" --repo <name>
```

### `bizzaroclaude logs clean`

Remove old log files.

```bash
bizzaroclaude logs clean --older-than 7d    # Older than 7 days
bizzaroclaude logs clean --older-than 24h   # Older than 24 hours
```

## Maintenance

### `bizzaroclaude cleanup`

Clean up orphaned resources (dead agents, stale files).

```bash
bizzaroclaude cleanup
bizzaroclaude cleanup --dry-run      # Show what would be cleaned
bizzaroclaude cleanup --verbose      # Detailed output
bizzaroclaude cleanup --merged       # Also clean up merged PR branches
```

Run this:
- After crashes
- When you see "orphaned" warnings
- Periodically for housekeeping

### `bizzaroclaude repair`

Repair state after a crash or corruption.

```bash
bizzaroclaude repair
bizzaroclaude repair --verbose
```

This:
- Validates state.json
- Removes dead agents from state
- Fixes inconsistencies
- Rebuilds indexes

Run after:
- Daemon crashes
- Manual tmux window kills
- File system issues

### `bizzaroclaude refresh`

Sync agent worktrees with the main branch.

```bash
bizzaroclaude refresh
```

This rebases all agent worktrees onto the latest main branch.

### `bizzaroclaude config`

View or modify repository configuration.

```bash
bizzaroclaude config [repo]
bizzaroclaude config --mq-enabled=true
bizzaroclaude config --mq-track=author
bizzaroclaude config --ps-enabled=false
```

Options:
- `--mq-enabled=true|false` - Enable/disable merge queue
- `--mq-track=all|author|assigned` - Merge queue tracking mode
- `--ps-enabled=true|false` - Enable/disable PR shepherd
- `--ps-track=all|author|assigned` - PR shepherd tracking mode

## Debugging

### `bizzaroclaude bug`

Generate a comprehensive bug report for issue filing.

```bash
bizzaroclaude bug
bizzaroclaude bug --output report.txt
bizzaroclaude bug --verbose
bizzaroclaude bug "Daemon keeps crashing"
```

Includes:
- System information
- Daemon status and logs
- Agent states
- Recent error messages
- Configuration

### `bizzaroclaude diagnostics`

Show system diagnostics in machine-readable format.

```bash
bizzaroclaude diagnostics
bizzaroclaude diagnostics --json
bizzaroclaude diagnostics --output diag.json
```

## Pull Request Review

### `bizzaroclaude review`

Spawn a reviewer agent for a pull request.

```bash
bizzaroclaude review <pr-url>

# Example:
bizzaroclaude review https://github.com/user/repo/pull/123
```

The reviewer agent:
- Fetches the PR
- Analyzes code changes
- Posts review comments
- Suggests improvements

## Advanced

### `bizzaroclaude claude`

Restart Claude CLI in the current agent context (for agents only).

```bash
bizzaroclaude claude
```

This is used by agents to resume Claude after it exits.

## Flag Parsing

Most commands support these flag formats:

```bash
--flag=value
--flag value
-f (short flag)
```

Boolean flags:
```bash
--dry-run       # true
--dry-run=true
--dry-run=false
```

## Exit Codes

- `0` - Success
- `1` - General error
- `2` - Command not found
- `3` - Invalid arguments

## Environment Variables

- `MULTICLAUDE_TEST_MODE=1` - Skip Claude startup in tests
- `CLAUDE_CONFIG_DIR` - Custom Claude config directory (set by agents)

## Tips

1. **Use tab completion** - Install shell completions if available
2. **Set a default repo** - `bizzaroclaude repo use <name>` to avoid `--repo` flags
3. **Watch logs in real-time** - `bizzaroclaude logs -f <agent>`
4. **Regular cleanup** - Run `bizzaroclaude cleanup` after crashes
5. **Check status** - `bizzaroclaude status` for quick overview

## See Also

- [Getting Started Guide](GETTING_STARTED.md)
- [Agent Documentation](AGENTS.md)
- [Common Workflows](WORKFLOWS.md)
- [Architecture Overview](ARCHITECTURE.md)
