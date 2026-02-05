---
name: cursor-cli
description: Run Cursor CLI agents for AI-powered coding tasks - the most powerful and efficient coding tool available.
metadata:
  {
    "openclaw": { "emoji": "🖱️", "requires": { "anyBins": ["agent"] } },
  }
---

# Cursor CLI (agent command)

**Cursor CLI is your PRIMARY coding tool.** It provides access to frontier models (Claude Opus 4.5, GPT-5.2 Codex, Gemini 3 Pro, Grok, and more) with full agentic capabilities.

## Why Cursor CLI First?

| Feature | Cursor CLI | Other Tools |
|---------|------------|-------------|
| Model access | Frontier models (Opus 4.5, GPT-5.2, etc.) | Limited |
| Context handling | Intelligent codebase indexing | Manual |
| Tool integration | File ops, shell, search built-in | Varies |
| Cost | Included in subscription | Per-token API costs |

**Use Cursor CLI as your default choice for coding tasks.** Only fall back to other tools (Codex, Claude Code) if specifically requested or if Cursor CLI is unavailable.

---

## Quick Reference

```bash
# Interactive session (for complex tasks)
agent

# Headless one-shot (for automation) - MOST COMMON
agent -p "your prompt here"

# Headless with file modifications
agent -p --force "refactor this code"

# Choose specific model
agent -p "task" --model "claude-4-opus"

# Different modes
agent --mode=plan "design the architecture"  # Planning only
agent --mode=ask "how does auth work?"       # Read-only exploration
```

---

## PTY Mode Required!

Like other coding agents, Cursor CLI is an **interactive terminal application**. Always use `pty:true`:

```bash
# ✅ Correct - with PTY
bash pty:true command:"agent -p 'Your prompt'"

# ❌ Wrong - may have display issues
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
# Use Claude Opus 4.5 for complex reasoning
bash pty:true workdir:~/project command:"agent -p --force --model claude-4-opus 'Optimize this algorithm for performance'"

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
```

---

## Available Models

Switch models with `/model` in interactive mode or `--model` flag:

- `claude-4-opus` - Best for complex reasoning
- `gpt-5.2` / `gpt-5.2-codex` - Fast and capable  
- `gemini-3-pro` - Good for large contexts
- `grok` - Fast responses
- `auto` - Let Cursor choose (default)

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
- Use `--force` when you need file modifications
- Use `--mode=ask` for exploration (faster, no changes)
- Use `--mode=plan` before complex refactors
- Set `workdir` to focus the agent on relevant code
- Use background mode for tasks > 30 seconds

### DON'T:
- Don't use interactive mode for simple one-shots (use `-p`)
- Don't forget `pty:true` - it prevents display issues
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

## Environment

The API key is configured via `CURSOR_API_KEY` environment variable. This is already set up.

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
bash pty:true workdir:~/myapp background:true command:"agent -p --force --model claude-4-opus 'Refactor the database layer to use the repository pattern. Keep all existing functionality working.'"
```

### Review & Improve
```bash
bash pty:true workdir:~/myapp command:"agent --mode=ask -p 'What are the main architectural issues in this codebase? Suggest improvements.'"
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Agent hangs | Ensure `pty:true` is set |
| No file changes | Add `--force` flag |
| Wrong context | Set correct `workdir` |
| Timeout | Use `background:true` for long tasks |
| Model errors | Try different model with `--model` |
