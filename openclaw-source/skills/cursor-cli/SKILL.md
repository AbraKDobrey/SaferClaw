---
name: cursor-cli
description: Run Cursor CLI agents for AI-powered coding tasks - the most powerful and efficient coding tool available.
metadata:
  {
    "openclaw": { "emoji": "🖱️", "requires": { "anyBins": ["agent"] } },
  }
---

# Cursor CLI (agent command)

**Cursor CLI is your PRIMARY coding tool.** It provides access to frontier models (Claude 4.5 Opus, GPT-5.2 Codex, Gemini 3 Pro, Grok Code, and more) with full agentic capabilities.

> **CRITICAL**: The binary is called **`agent`**, NOT `cursor-cli`. Every command starts with `agent`.

## Why Cursor CLI First?

| Feature | Cursor CLI | Other Tools |
|---------|------------|-------------|
| Model access | Frontier models (Claude 4.5 Opus, GPT-5.2, etc.) | Limited |
| Context handling | Intelligent codebase indexing | Manual |
| Tool integration | File ops, shell, search built-in | Varies |
| Cost | Included in Cursor subscription | Per-token API costs |

**Use Cursor CLI as your default choice for coding tasks.** Only fall back to other tools (Codex, Claude Code) if specifically requested or if Cursor CLI is unavailable.

---

## Authentication (READ THIS FIRST)

Cursor CLI requires authentication before it can access models. There are two methods:

### Method 1: API Key (recommended for headless/VPS)

```bash
# Set via environment variable (add to ~/.bashrc or ~/.zshrc for persistence)
export CURSOR_API_KEY="key_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Or pass directly on each command
agent --api-key "key_xxx..." -p "your prompt"
```

The API key is generated from your Cursor account dashboard:
**https://cursor.com → Dashboard → Integrations → User API Keys**

### Method 2: Browser Login (recommended for desktop)

```bash
agent login    # Opens browser, you authenticate with Cursor account
agent status   # Verify authentication
agent logout   # Clear stored credentials
```

> **VPS NOTE**: `agent login` requires a browser. On a headless VPS, use the API key method.
> If you really need browser auth on a headless machine, use SSH port forwarding:
> `ssh -L 8080:localhost:8080 your-vps` then run `agent login`.

### Verifying Authentication Works

```bash
# Step 1: Check auth status
agent status

# Step 2: List available models (if this returns empty, auth is broken)
agent models
# or: agent --list-models

# Step 3: If models list is empty, the problem is one of:
#   a) API key is invalid or expired → regenerate at cursor.com/dashboard
#   b) Cursor account has no active subscription (Pro = $20/mo required)
#   c) Environment variable not set → run: echo $CURSOR_API_KEY
#   d) Old/corrupt install → reinstall: curl https://cursor.com/install -fsS | bash
```

### Adding CURSOR_API_KEY to .env.openclaw

If using OpenClaw, add the key to your `.env.openclaw`:

```bash
# In .env.openclaw
CURSOR_API_KEY=key_your_key_here
```

And ensure OpenClaw exports it before running `agent` commands.

---

## Quick Reference

```bash
# Interactive session (for complex tasks)
agent

# Headless one-shot (for automation) - MOST COMMON
agent -p "your prompt here"

# Headless with file modifications
agent -p --force "refactor this code"

# Choose specific model (use exact names from `agent models`)
agent -p "task" --model "claude-4.5-opus"

# Different modes
agent --mode=plan "design the architecture"  # Planning only
agent --mode=ask "how does auth work?"       # Read-only exploration

# Check version
agent --version

# Update to latest
agent update
```

---

## Available Models (February 2026)

Run `agent models` to get the live list. Current known models:

| Model | Provider | Best For | `--model` value |
|-------|----------|----------|-----------------|
| Claude 4.5 Opus | Anthropic | Complex reasoning, architecture | Check `agent models` |
| Claude 4.5 Sonnet | Anthropic | General coding, balanced | Check `agent models` |
| Composer 1 | Cursor | Cursor-optimized agent | Check `agent models` |
| Gemini 3 Flash | Google | Fast, cheap tasks | Check `agent models` |
| Gemini 3 Pro | Google | Large context (1M tokens) | Check `agent models` |
| GPT-5.2 | OpenAI | General purpose | Check `agent models` |
| GPT-5.2 Codex | OpenAI | Code-focused | Check `agent models` |
| Grok Code | xAI | Fast responses | Check `agent models` |
| Auto | Cursor | Let Cursor choose (default) | `auto` |

> **IMPORTANT**: Model name strings change between versions. ALWAYS run
> `agent models` to get the exact `--model` value. Do NOT guess model names.
> Old names like `claude-3-opus`, `gpt-4`, etc. will error out.

In interactive mode, switch models with `/model` slash command.

---

## PTY Mode Required!

Like other coding agents, Cursor CLI is an **interactive terminal application**. Always use `pty:true`:

```bash
# Correct - with PTY
bash pty:true command:"agent -p 'Your prompt'"

# Wrong - may have display issues
bash command:"agent -p 'Your prompt'"
```

---

## Usage Patterns

### 1. Quick Analysis / Questions (Read-Only)

Use `--mode=ask` for exploring code without making changes:

```bash
bash pty:true workdir:~/project command:"agent --mode=ask -p 'How does the authentication flow work?'"
```

### 2. One-Shot Code Changes (Most Common)

Use `-p --force` for headless execution with file modifications:

```bash
bash pty:true workdir:~/project command:"agent -p --force 'Add input validation to the user registration endpoint'"
```

### 3. Complex Multi-Step Tasks (Background)

For longer tasks, use background mode:

```bash
# Start in background
bash pty:true workdir:~/project background:true command:"agent -p --force 'Refactor the entire auth module to use JWT tokens. Update all tests.'"

# Monitor progress
process action:log sessionId:XXX

# Check if done
process action:poll sessionId:XXX
```

### 4. Planning Before Coding

Use plan mode for architecture decisions:

```bash
bash pty:true workdir:~/project command:"agent --mode=plan -p 'Design a caching layer for the API'"
```

### 5. Code Review

```bash
bash pty:true workdir:~/project command:"agent -p 'Review the recent changes in src/ for security issues and best practices'"
```

### 6. With Specific Model

```bash
# Use Claude 4.5 Opus for complex reasoning (get exact name from `agent models`)
bash pty:true workdir:~/project command:"agent -p --force --model claude-4.5-opus 'Optimize this algorithm for performance'"

# Use faster model for simple tasks
bash pty:true workdir:~/project command:"agent -p --force --model gpt-5.2 'Add JSDoc comments to utils.ts'"
```

---

## Output Formats (for Automation)

| Format | Use Case |
|--------|----------|
| `--output-format text` | Default, clean final answer |
| `--output-format json` | Structured analysis for parsing |
| `--output-format stream-json` | Real-time progress tracking |

```bash
# Get structured output
bash pty:true command:"agent -p --output-format json 'Analyze the codebase structure'"

# Stream progress in real-time
bash pty:true command:"agent -p --output-format stream-json --stream-partial-output 'Build feature X'"
```

---

## Decision Tree: When to Use What

```
Need to write/modify code?
├── Yes → Use Cursor CLI (agent -p --force)
│   ├── Complex task? → Background mode
│   ├── Simple fix? → One-shot headless
│   └── Need specific model? → Use --model flag
│
└── No, just exploring/asking?
    └── Use agent --mode=ask -p "question"

User specifically requested another tool (Codex, Claude Code)?
└── Yes → Use that tool instead (see coding-agent skill)
```

---

## Smart Usage Guidelines

### DO:
- **Default to Cursor CLI** for all coding tasks
- Run `agent models` to discover exact model name strings before using `--model`
- Use `--force` when you need file modifications in headless mode
- Use `--mode=ask` for exploration (faster, no changes)
- Use `--mode=plan` before complex refactors
- Set `workdir` to focus the agent on relevant code
- Use background mode for tasks > 30 seconds

### DON'T:
- Don't use `cursor-cli` — the command is `agent`
- Don't guess model names — always verify with `agent models`
- Don't use interactive mode for simple one-shots (use `-p`)
- Don't forget `pty:true` — it prevents display issues
- Don't run in OpenClaw's own directory (use separate workspace)
- Don't kill sessions just because they're "slow"

---

## Parallel Execution

Run multiple agents for batch work:

```bash
# Fix multiple issues in parallel
bash pty:true workdir:/tmp/issue-1 background:true command:"agent -p --force 'Fix issue #1: description'"
bash pty:true workdir:/tmp/issue-2 background:true command:"agent -p --force 'Fix issue #2: description'"

# Monitor all
process action:list
```

---

## Cloud Agent Handoff

For very long tasks, hand off to Cursor's Cloud Agent (continues running even if connection drops):

```bash
# In interactive mode, prepend & to message
agent
> & refactor the entire codebase to TypeScript and add comprehensive tests
```

Pick up later at [cursor.com/agents](https://cursor.com/agents)

---

## Session Management

```bash
# List previous sessions
agent ls

# Resume latest conversation
agent resume

# Resume specific session
agent --resume="chat-id-here"
```

---

## Installation & Updates

```bash
# Install (Linux/macOS/WSL)
curl https://cursor.com/install -fsS | bash

# Verify installation
agent --version

# Update to latest
agent update
# or: agent upgrade

# The binary is installed to ~/.local/bin/agent
# Make sure ~/.local/bin is in your PATH:
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

---

## Environment

The API key is configured via `CURSOR_API_KEY` environment variable.

Required setup:
```bash
# In ~/.bashrc, ~/.zshrc, or .env.openclaw:
export CURSOR_API_KEY="key_your_key_here"
```

The key must come from a Cursor account with an **active paid subscription** (Pro $20/mo or higher).

---

## Progress Updates

When running background tasks:
1. Send a short message when starting (what + where)
2. Update on milestones or errors
3. Report completion with summary of changes

---

## Examples: Real Tasks

### Add a Feature
```bash
bash pty:true workdir:~/myapp background:true command:"agent -p --force 'Add dark mode support to the settings page. Include a toggle switch and persist the preference to localStorage.'"
```

### Fix a Bug
```bash
bash pty:true workdir:~/myapp command:"agent -p --force 'Fix the race condition in src/api/auth.ts that causes intermittent login failures'"
```

### Write Tests
```bash
bash pty:true workdir:~/myapp command:"agent -p --force 'Add unit tests for the UserService class with >80% coverage'"
```

### Refactor
```bash
bash pty:true workdir:~/myapp background:true command:"agent -p --force --model claude-4.5-opus 'Refactor the database layer to use the repository pattern. Keep all existing functionality working.'"
```

### Build a Rust Weather Tool
```bash
bash pty:true workdir:~/weather-tool command:"agent -p --force 'Create a Rust CLI tool using reqwest and tokio that fetches weather for a city passed as a command-line argument. Use a free weather API. Include proper error handling, Cargo.toml, and a README.'"
```

### Review & Improve
```bash
bash pty:true workdir:~/myapp command:"agent --mode=ask -p 'What are the main architectural issues in this codebase? Suggest improvements.'"
```

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| `agent: command not found` | Not installed or not in PATH | Run `curl https://cursor.com/install -fsS \| bash` then add `~/.local/bin` to PATH |
| `agent models` returns empty | Auth broken or no subscription | Check `agent status`, verify `CURSOR_API_KEY` is set, verify Cursor account has active Pro subscription |
| `--model claude-3-opus` errors | Old/wrong model name | Run `agent models` to get exact current names. `claude-3-opus` no longer exists |
| `Not authenticated` error | No API key or login | Run `agent login` (desktop) or `export CURSOR_API_KEY=key_xxx` (headless/VPS) |
| Agent hangs | Missing PTY | Ensure `pty:true` is set when calling from OpenClaw |
| No file changes in headless | Missing --force flag | Add `--force` to allow file modifications in `-p` mode |
| Wrong context | Wrong working directory | Set correct `workdir` to the project you want the agent to work on |
| Timeout on long tasks | Default 30s limit | Use `background:true` for long tasks |
| SSL errors | Network/cert issue | Try `--insecure` flag for dev environments |

### Full Diagnostic Steps

If Cursor CLI is not working, run these in order:

```bash
# 1. Is it installed?
which agent && agent --version

# 2. Is auth configured?
echo "CURSOR_API_KEY=$CURSOR_API_KEY"
agent status

# 3. Are models available?
agent models

# 4. If models empty: reinstall + re-auth
curl https://cursor.com/install -fsS | bash
export CURSOR_API_KEY="key_your_fresh_key_from_dashboard"
agent models

# 5. If still empty: the Cursor account has no active subscription
# Go to https://cursor.com/dashboard and check billing status
```

---

## References

- Cursor CLI Overview: https://cursor.com/docs/cli/overview
- Installation: https://cursor.com/docs/cli/installation
- Authentication: https://cursor.com/docs/cli/reference/authentication
- Parameters: https://cursor.com/docs/cli/reference/parameters
- Headless/Automation: https://cursor.com/docs/cli/headless
- Shell Mode: https://cursor.com/docs/cli/shell-mode
- Available Models: https://cursor.com/docs/models
- GitHub Actions: https://cursor.com/docs/cli/github-actions
