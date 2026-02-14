# Common Workflows

Real-world examples and patterns for using bizzaroclaude effectively.

## Table of Contents

- [Initial Setup](#initial-setup)
- [Daily Development](#daily-development)
- [Managing Multiple Repositories](#managing-multiple-repositories)
- [Code Review Workflow](#code-review-workflow)
- [Emergency Response](#emergency-response)
- [Cleanup and Maintenance](#cleanup-and-maintenance)

## Initial Setup

### First Time Setup

```bash
# 1. Install bizzaroclaude
go install github.com/dlorenc/bizzaroclaude/cmd/bizzaroclaude@latest

# 2. Verify installation
bizzaroclaude version

# 3. Start the daemon
bizzaroclaude start

# 4. Verify daemon is running
bizzaroclaude daemon status
```

### Adding Your First Repository

```bash
# Initialize a repository
bizzaroclaude repo init https://github.com/yourorg/yourproject

# Set as default (optional, avoids --repo flags later)
bizzaroclaude repo use yourproject

# Check status
bizzaroclaude status

# Attach to workspace
bizzaroclaude attach workspace
```

**What just happened?**
- Repository cloned to `~/.bizzaroclaude/repos/yourproject`
- Supervisor and workspace agents spawned
- Tmux session `mc-yourproject` created
- Ready to spawn workers

## Daily Development

### Spawning Workers for Tasks

**Scenario:** You have multiple tasks to work on.

```bash
# Spawn workers for different tasks
bizzaroclaude worker "Add user authentication endpoint"
bizzaroclaude worker "Fix memory leak in data processor"
bizzaroclaude worker "Update documentation for API v2"

# Check what's running
bizzaroclaude worker list
```

**Output:**
```
Workers for repository: yourproject
┌──────────────┬────────────┬────────────────────────────┬─────────────┐
│ Name         │ Status     │ Task                       │ Created     │
├──────────────┼────────────┼────────────────────────────┼─────────────┤
│ swift-eagle  │ running    │ Add user auth endpoint     │ 5 mins ago  │
│ brave-fox    │ running    │ Fix memory leak            │ 3 mins ago  │
│ wise-owl     │ running    │ Update API docs            │ 1 min ago   │
└──────────────┴────────────┴────────────────────────────┴─────────────┘
```

### Monitoring Progress

```bash
# Watch a specific worker
bizzaroclaude logs -f swift-eagle

# Attach to see what it's doing
bizzaroclaude attach swift-eagle

# Check all agents
tmux attach -t mc-yourproject
# Navigate: Ctrl-b n (next window), Ctrl-b p (previous window)
# Detach: Ctrl-b d
```

### When Workers Complete

Workers automatically:
1. Create commits
2. Push to their branch (e.g., `work/swift-eagle`)
3. Open a pull request
4. Call `bizzaroclaude agent complete`

You'll see:
```
Worker swift-eagle completed successfully
Pull request: https://github.com/yourorg/yourproject/pull/123
```

Clean up completed worker:
```bash
bizzaroclaude worker rm swift-eagle
```

## Managing Multiple Repositories

### Working Across Repositories

```bash
# Add multiple repos
bizzaroclaude repo init https://github.com/org/frontend webapp
bizzaroclaude repo init https://github.com/org/backend api
bizzaroclaude repo init https://github.com/org/infra infra

# List all repos
bizzaroclaude repo list
```

**Output:**
```
Tracked Repositories:
┌─────────┬────────────────────────────┬────────┬──────────┐
│ Name    │ URL                        │ Agents │ Status   │
├─────────┼────────────────────────────┼────────┼──────────┤
│ webapp  │ github.com/org/frontend    │ 3      │ active   │
│ api     │ github.com/org/backend     │ 2      │ active   │
│ infra   │ github.com/org/infra       │ 1      │ active   │
└─────────┴────────────────────────────┴────────┴──────────┘
```

### Setting Default Repository

```bash
# Set default for this work session
bizzaroclaude repo use webapp

# Now commands default to webapp
bizzaroclaude worker "Add login form"  # Goes to webapp

# Explicitly target different repo
bizzaroclaude worker "Update DB schema" --repo api
```

### Switching Between Repository Sessions

Each repo has its own tmux session:

```bash
# View all tmux sessions
tmux ls

# Output:
# mc-webapp: 4 windows (created Thu Jan 15 10:00:00 2024)
# mc-api: 3 windows (created Thu Jan 15 10:05:00 2024)
# mc-infra: 2 windows (created Thu Jan 15 10:10:00 2024)

# Attach to specific repo's session
tmux attach -t mc-webapp
# Detach: Ctrl-b d

# Switch to another repo
tmux attach -t mc-api
```

## Code Review Workflow

### Reviewing Pull Requests

```bash
# Spawn a reviewer for a specific PR
bizzaroclaude review https://github.com/yourorg/yourproject/pull/123

# The reviewer agent will:
# 1. Fetch the PR
# 2. Analyze the code changes
# 3. Check for issues (bugs, style, security)
# 4. Post review comments
# 5. Suggest improvements
```

### Batch Review Multiple PRs

```bash
# Review several PRs at once
bizzaroclaude review https://github.com/yourorg/yourproject/pull/123
bizzaroclaude review https://github.com/yourorg/yourproject/pull/124
bizzaroclaude review https://github.com/yourorg/yourproject/pull/125

# Each gets its own reviewer agent
bizzaroclaude worker list --repo yourproject
```

### Monitoring Review Progress

```bash
# Watch reviewer output
bizzaroclaude logs -f reviewer-123

# Attach to see what it's reviewing
bizzaroclaude attach reviewer-123
```

## Emergency Response

### Handling Crashes

**Scenario:** Daemon crashed or agents are stuck.

```bash
# 1. Check daemon status
bizzaroclaude daemon status

# If not running:
bizzaroclaude daemon logs | tail -50  # Check what went wrong

# 2. Repair state
bizzaroclaude repair

# 3. Restart daemon
bizzaroclaude daemon start

# 4. Verify agents
bizzaroclaude status
```

### Recovering from Agent Failures

```bash
# List all agents
bizzaroclaude status

# If agent shows as "crashed":
bizzaroclaude agent restart <agent-name>

# If restart fails, check logs
bizzaroclaude logs <agent-name> | tail -100

# Generate bug report if needed
bizzaroclaude bug "Agent <name> keeps crashing"
```

### Complete System Reset

**Warning:** This stops all agents and clears state.

```bash
# Stop everything
bizzaroclaude stop-all --yes

# Clean up
bizzaroclaude cleanup

# Restart fresh
bizzaroclaude daemon start

# Reinitialize repos if needed
bizzaroclaude repo list  # Check what's still tracked
```

## Cleanup and Maintenance

### Regular Maintenance

**Recommended:** Weekly or after major work sessions.

```bash
# 1. Clean up completed workers
bizzaroclaude worker list
bizzaroclaude worker rm <completed-worker-name>

# 2. Remove orphaned resources
bizzaroclaude cleanup --dry-run  # Preview
bizzaroclaude cleanup            # Execute

# 3. Clean old logs
bizzaroclaude logs clean --older-than 7d

# 4. Verify state
bizzaroclaude status
```

### Managing Disk Space

```bash
# Check space usage
du -sh ~/.bizzaroclaude

# Breakdown by component
du -sh ~/.bizzaroclaude/repos/*
du -sh ~/.bizzaroclaude/worktrees/*
du -sh ~/.bizzaroclaude/output/*

# Remove old repos you're not using
bizzaroclaude repo rm old-project

# Clean up merged branches
bizzaroclaude cleanup --merged
```

### Hibernating Repositories

**Scenario:** Not working on a repo for a while but want to keep it.

```bash
# Hibernate (archives uncommitted changes)
bizzaroclaude repo hibernate --repo inactive-project

# Later, when you want to resume:
bizzaroclaude repo init https://github.com/org/inactive-project inactive-project
```

## Advanced Workflows

### Custom Agent Deployment

**Scenario:** You need a specialized agent for a specific task.

```bash
# 1. Create custom agent prompt
cat > security-scanner.md <<EOF
# Security Scanner Agent

You perform security scans on the codebase.

## Tools
- gosec (Go security checker)
- npm audit (JavaScript security)
- Safety (Python security)

## Workflow
1. Run security scanners
2. Analyze results
3. Create issues for vulnerabilities
4. Report to supervisor
EOF

# 2. Spawn the agent
bizzaroclaude agents spawn \
  --name sec-scan-1 \
  --class security-scanner \
  --prompt-file security-scanner.md \
  --task "Scan codebase for security issues"

# 3. Monitor
bizzaroclaude logs -f sec-scan-1
```

### Parallel Feature Development

**Scenario:** Multiple related features being developed simultaneously.

```bash
# Spawn workers for coordinated features
bizzaroclaude worker "Frontend: Add user profile page"
bizzaroclaude worker "Backend: Add user profile API endpoint"
bizzaroclaude worker "Database: Add user profile schema migration"

# Workers can message each other for coordination
# (via bizzaroclaude message send <recipient> <content>)

# Monitor all three
tmux attach -t mc-yourproject
# See all workers in separate windows
```

### Integration Testing Workflow

```bash
# 1. Create integration test worker
bizzaroclaude worker "Run full integration test suite"

# 2. If tests fail, spawn debugging worker
bizzaroclaude worker "Debug integration test failure in checkout flow"

# 3. Message between workers
bizzaroclaude attach test-worker
# In Claude:
bizzaroclaude message send debug-worker "Tests failing at checkout step 3"
```

## Productivity Tips

### Efficient Task Batching

```bash
# Start of day: Spawn all planned tasks
bizzaroclaude worker "Fix issue #123"
bizzaroclaude worker "Fix issue #124"
bizzaroclaude worker "Fix issue #125"
bizzaroclaude worker "Update changelog"

# Go get coffee while agents work
# Come back to PRs ready for review
```

### Using Workspaces for Exploration

```bash
# Attach to workspace for interactive work
bizzaroclaude attach workspace

# In workspace, you can:
# - Explore the codebase
# - Test commands
# - Spawn workers interactively
# - Review agent outputs
# - Send messages to agents
```

### Monitoring Without Interruption

```bash
# Terminal 1: Follow supervisor logs
bizzaroclaude logs -f supervisor

# Terminal 2: Follow specific worker
bizzaroclaude logs -f swift-eagle

# Terminal 3: Keep status display
watch -n 5 bizzaroclaude status
```

### History and Context

```bash
# Review what's been done
bizzaroclaude repo history

# See recent tasks
bizzaroclaude repo history -n 20

# Search for specific work
bizzaroclaude repo history --search "authentication"

# Filter by completion status
bizzaroclaude repo history --status completed
```

## Troubleshooting Workflows

### "I lost track of what's running"

```bash
# Quick overview
bizzaroclaude status

# Detailed worker list
bizzaroclaude worker list

# See all tmux windows
tmux list-windows -t mc-<repo>
```

### "Worker is stuck, not progressing"

```bash
# 1. Attach and observe
bizzaroclaude attach <worker-name>

# 2. Check recent logs
bizzaroclaude logs <worker-name> | tail -50

# 3. If truly stuck, restart
bizzaroclaude agent restart <worker-name>

# 4. If still stuck, check supervisor
bizzaroclaude attach supervisor
```

### "Daemon won't start"

```bash
# Check if already running
bizzaroclaude daemon status

# If stuck, force cleanup
pkill -f bizzaroclaude
rm ~/.bizzaroclaude/daemon.pid
rm ~/.bizzaroclaude/daemon.sock

# Repair and restart
bizzaroclaude repair
bizzaroclaude daemon start
```

### "Too many agents, system is slow"

```bash
# Check resource usage
bizzaroclaude diagnostics

# Clean up completed workers
bizzaroclaude worker list
# Remove completed ones:
bizzaroclaude worker rm <completed-worker>

# General cleanup
bizzaroclaude cleanup

# Consider working on fewer tasks at once
```

## Best Practices Summary

1. **Set a default repo** to avoid typing `--repo` every time
2. **Regular cleanup** - Weekly `bizzaroclaude cleanup`
3. **Monitor actively** - Use `logs -f` to watch progress
4. **Batch similar tasks** - Spawn multiple workers at once
5. **Use workspaces** for interactive exploration
6. **Remove completed workers** to reduce clutter
7. **Check status frequently** - `bizzaroclaude status` is fast
8. **Keep daemon logs** - They're crucial for debugging
9. **Use descriptive task descriptions** when spawning workers
10. **Review PRs promptly** - Don't let workers pile up waiting for merge

## See Also

- [Getting Started Guide](GETTING_STARTED.md)
- [Commands Reference](COMMANDS.md)
- [Agent Guide](AGENTS.md)
- [Architecture Overview](ARCHITECTURE.md)
