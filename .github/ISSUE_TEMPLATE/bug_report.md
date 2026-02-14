---
name: Bug Report
about: Report a bug or issue
title: '[BUG] '
labels: bug
assignees: ''
---

## Bug Description

<!-- A clear and concise description of the bug -->

## Steps to Reproduce

1. Run command: `bizzaroclaude ...`
2. ...
3. See error

## Expected Behavior

<!-- What you expected to happen -->

## Actual Behavior

<!-- What actually happened -->

## Environment

- OS: [e.g., Ubuntu 22.04, macOS 14]
- Go Version: [output of `go version`]
- bizzaroclaude Version: [output of `bizzaroclaude version`]
- tmux Version: [output of `tmux -V`]
- Docker Version: [output of `docker --version`] (if relevant)

## Logs

<!-- Include relevant logs. Use code blocks for formatting -->

<details>
<summary>Daemon Logs</summary>

```
# Output of: tail -100 ~/.bizzaroclaude/daemon.log

```
</details>

<details>
<summary>Agent Logs</summary>

```
# Output of: bizzaroclaude logs <agent-name>

```
</details>

<details>
<summary>State</summary>

```json
# Output of: cat ~/.bizzaroclaude/state.json (redact sensitive info)

```
</details>

## Additional Context

<!-- Any other context about the problem -->

## Possible Solution

<!-- If you have suggestions on how to fix this -->

## Checklist

- [ ] I have checked existing issues for duplicates
- [ ] I have included the output of `bizzaroclaude version`
- [ ] I have included relevant logs
- [ ] I can reproduce this consistently
