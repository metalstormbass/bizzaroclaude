# bizzaroclaude

[![CI](https://github.com/dlorenc/bizzaroclaude/actions/workflows/ci.yml/badge.svg)](https://github.com/dlorenc/bizzaroclaude/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> *Why test one way when you can test every way simultaneously?*

Multiple autonomous pentesting agents. Local containers. Coordinated chaos.

bizzaroclaude spawns autonomous security testing agents that coordinate, compete, and collaborate on container targets in your lab. Each agent gets its own tmux window and isolated workspace. You watch. They probe. Findings emerge.

**⚠️ LAB USE ONLY:** This tool is designed exclusively for authorized security research in controlled lab environments on infrastructure you own and operate.

**💡 Inspired by [multiclaude](https://github.com/dlorenc/multiclaude)** - A multi-agent GitHub repository orchestrator. bizzaroclaude adapts the parallel agent coordination concept for container security testing.

## The Philosophy: Parallel Discovery

Inspired by the [Brownian ratchet](https://en.wikipedia.org/wiki/Brownian_ratchet) - random exploration converted to validated findings through a verification mechanism.

Multiple agents work simultaneously using different approaches. They might duplicate effort. They might find different vulnerabilities. *This is fine.*

**Validation is the ratchet.** Every finding that can be verified gets reported. Progress is permanent. We never lose ground.

- 🎲 **Parallel Approaches** - Multiple techniques beat sequential testing
- 🔒 **Validation is King** - If you can reproduce it, report it. If not, investigate more.
- ⚡ **Coverage > Perfection** - Three validated findings beat one perfect report
- 👤 **Researcher Controls** - Agents discover. You validate and decide.

## Quick Start

```bash
# Install
go install github.com/dlorenc/bizzaroclaude/cmd/bizzaroclaude@latest

# Prerequisites: tmux, docker (for container targets)

# Fire it up
bizzaroclaude start
bizzaroclaude target init local-container-name

# Spawn a pentesting agent and watch the magic
bizzaroclaude agent create recon "Enumerate services and map attack surface"
tmux attach -t mc-target
```

That's it. You now have a supervisor, coordinator, and reconnaissance agent working. Detach with `Ctrl-b d` and they keep testing while you work.

## Two Modes

**Single Target** - Focus all agents on one container. Deep, thorough testing from multiple angles.

```bash
bizzaroclaude target init my-vulnerable-container
```

**Multi Target** - Coordinate testing across multiple containers. Network mapping, lateral movement testing.

```bash
bizzaroclaude target init container-1 container-2 container-3
```

## Built-in Agent Classes

```
┌─────────────────────────────────────────────────────────────┐
│                   tmux session: mc-target                    │
├───────────────┬───────────────┬───────────────┬─────────────┤
│  supervisor   │  coordinator  │  workspace    │ swift-eagle │
│               │               │               │             │
│ Coordinates   │ Validates &   │ Your personal │ Running     │
│ the testing   │ deduplicates  │ workspace     │ recon scan  │
└───────────────┴───────────────┴───────────────┴─────────────┘
```

| Agent Class | Role | Purpose |
|-------------|------|---------|
| **Supervisor** | Orchestration. Monitors agent progress. Answers "what's running?" | Coordinates testing workflow |
| **Coordinator** | Validation & deduplication. Verifies findings. Prevents duplicate work. | Quality control for results |
| **Workspace** | Your personal workspace. Spawn agents, check status, review findings. | Interactive control |
| **Recon** | Information gathering. Port scanning, service enumeration, fingerprinting. | Attack surface mapping |
| **Exploit** | Vulnerability testing. Attempts known exploits against identified services. | Exploitation verification |
| **Privilege** | Privilege escalation testing. Tests for container breakout, kernel exploits. | Post-compromise testing |

## Fully Extensible in Markdown

These are just the built-in agent classes. **Want more? Write markdown.**

Create `~/.bizzaroclaude/targets/<target>/agents/custom-fuzzer.md`:

```markdown
# Custom Fuzzer

You perform intelligent fuzzing against web services. Focus on:
- Input validation bypasses
- Buffer overflow conditions
- Injection vulnerabilities (SQL, command, etc.)

When you find potential vulnerabilities:
1. Document the exact payload that triggered the behavior
2. Attempt to verify the vulnerability is exploitable
3. Report to the coordinator for validation
```

Then spawn it:

```bash
bizzaroclaude agents spawn --name fuzzer-1 --class custom-fuzzer --prompt-file custom-fuzzer.md
```

## The Lab Testing Model

bizzaroclaude treats security testing like **coordinated research, not isolated scans**.

Your workspace is your command center. Agents are specialized tools you deploy. The supervisor orchestrates. The coordinator validates findings.

Walk away. Testing continues. Come back to results.

## Testing Workflow

```bash
# 1. Initialize target
bizzaroclaude target init vulnerable-container

# 2. Start with reconnaissance
bizzaroclaude agent create recon "Map all exposed services"

# 3. Based on findings, spawn exploitation agents
bizzaroclaude agent create exploit "Test nginx CVE-2021-23017"

# 4. If access gained, test privilege escalation
bizzaroclaude agent create privesc "Search for container escape vectors"

# 5. Review consolidated findings
bizzaroclaude findings list --validated
```

## Documentation

- **[Commands Reference](docs/COMMANDS.md)** - All the CLI commands
- **[Agent Guide](docs/AGENTS.md)** - How agents work and customization
- **[Architecture](docs/ARCHITECTURE.md)** - System design and internals
- **[Testing Workflows](docs/WORKFLOWS.md)** - Detailed examples and patterns
- **[Tool Integration](docs/TOOLS.md)** - Integrating nmap, metasploit, etc.

## Public Libraries

Two reusable Go packages:

- **[pkg/tmux](pkg/tmux/)** - Programmatic tmux control with multiline support
- **[pkg/claude](pkg/claude/)** - Launch and interact with Claude Code instances

## Building

```bash
go build ./cmd/bizzaroclaude    # Build
go test ./...                  # Test
go install ./cmd/bizzaroclaude  # Install
```

Requires: Go 1.21+, tmux, docker

## Security & Ethics

**CRITICAL REQUIREMENTS:**

1. **Authorization Required** - Only test infrastructure you own or have explicit written authorization to test
2. **Lab Environments Only** - This tool is designed for controlled lab environments
3. **No Production Systems** - Never point this at production infrastructure
4. **Responsible Disclosure** - If you discover vulnerabilities in third-party software, follow responsible disclosure practices
5. **Local Testing Only** - This version is designed for local container testing, not remote targets

**This tool is for security research and education. Misuse may violate laws including the Computer Fraud and Abuse Act (CFAA) and similar laws worldwide.**

## Acknowledgments

**bizzaroclaude** is inspired by [multiclaude](https://github.com/dlorenc/multiclaude) by Dan Lorenc (@dlorenc). The original multiclaude pioneered the concept of coordinating multiple autonomous Claude Code agents working in parallel on GitHub repositories.

bizzaroclaude adapts this innovative multi-agent orchestration pattern to a completely different domain: local container security testing and penetration testing research.

Key concepts borrowed from multiclaude:
- Multi-agent parallel coordination
- Tmux-based agent isolation
- Message passing between agents
- The "Brownian Ratchet" philosophy of productive chaos

Thank you to the multiclaude project for the inspiration and architectural foundation!

## License

MIT - Use responsibly and legally
