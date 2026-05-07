# SETUP — Claude Code Adapter

*internOS Workstreams · Claude Code adapter*

This adapter lets Claude Code participate in internOS workstreams the same way Hermes (Discord/Slack) and OpenClaw do — but using the working directory as the thread binding instead of a chat-platform thread ID.

---

## How it works

A **thread** in Claude Code is the persistent conversation about a workstream. Each `/resume` continues the same thread; opening a fresh conversation in the same working directory also continues it. Individual sessions are *instances* of the thread.

Resolution is purely cwd-based:

1. Claude Code reads project-root `CLAUDE.md` automatically on every session.
2. `CLAUDE.md` tells Claude to run `~/.claude/skills/intern-os/scripts/resolve-thread.sh`.
3. The script walks up from `$PWD`, looks for `<workspace>/projects/<project>/workstreams/<name>`, and verifies BRIEF.md's `thread_id` is `claude-code:projects/<project>/workstreams/<name>`.
4. If a workstream is found, Claude loads BRIEF.md + STATUS.md and follows the standard internOS operating protocol. If not, the skill stays dormant — zero context cost.
5. (Optional) A `Stop` hook records the session in the workstream's `SESSIONS.md` so you can trace decisions back to specific `/resume` conversations.

The full skill is read on demand only when Claude Code's skill loader decides the description matches the current task — so the skill doesn't burn context for non-workstream work.

---

## Prerequisites

- Claude Code CLI installed
- `tick-md` installed globally: `npm install -g tick-md`
- A directory that will hold your projects — anything works (e.g. `~/workspace`, `~/code`). Inside it, projects live under a `projects/` subdirectory.

---

## Install (user-global)

This adapter installs into `~/.claude/skills/intern-os/` so it's available in every Claude Code session for the user. The skill activates only when Claude detects workstream context.

### 1. Install the skill

From this repo:

```bash
mkdir -p ~/.claude/skills/intern-os
cp adapters/claude-code/SKILL.md ~/.claude/skills/intern-os/SKILL.md
cp -R adapters/claude-code/scripts ~/.claude/skills/intern-os/scripts
chmod +x ~/.claude/skills/intern-os/scripts/*.sh
```

If you also want the deep references (`FRAMEWORK.md`, `PLAYBOOK.md`, etc.) accessible from the same install:

```bash
cp -R intern-os/references ~/.claude/skills/intern-os/references
```

### 2. Set the workspace path (required)

`INTERNOS_WORKSPACE` is required — there is no implicit default. Point it at the directory that contains your `projects/` directory:

```bash
echo 'export INTERNOS_WORKSPACE="$HOME/workspace"' >> ~/.zshrc
```

(Substitute whatever directory holds your `projects/` subdir — `~/workspace`, `~/code`, etc.) Both the skill instructions and the resolver script read this variable. No other configuration is needed.

If `INTERNOS_WORKSPACE` is unset when the resolver runs, it exits with code 3 and a clear error rather than guessing.

### 3. (Optional) Install the session-logging hook

The hook records each session's ID and timestamp in the active workstream's `SESSIONS.md` when the session ends. Sessions outside any workstream are silently ignored.

Merge `adapters/claude-code/hooks/settings.json` into `~/.claude/settings.json` — specifically the `hooks.Stop` array. If you don't already have a `hooks` block, you can copy the file as-is.

If you skip this step, you can still log sessions manually by calling `log-session.sh` from inside Claude.

### 4. Drop CLAUDE.md into projects that operate workstreams

This is per-project, not global. For each repo that should auto-resolve workstreams (typically your workspace repo itself, if you keep it under git):

```bash
cp adapters/claude-code/CLAUDE.md <your-project>/CLAUDE.md
```

If the project already has a `CLAUDE.md`, append the contents instead — Claude Code reads the whole file as project instructions.

---

## Verification

Run these from the repo root:

```bash
# 1. Skill is installed where Claude Code can find it
test -f ~/.claude/skills/intern-os/SKILL.md && echo "skill: ok"

# 2. Resolver runs (should exit 1 here unless this repo is your workspace)
~/.claude/skills/intern-os/scripts/resolve-thread.sh; echo "resolver exit: $?"

# 3. Resolver finds a real workstream when you cd into one
mkdir -p /tmp/internos-verify/projects/demo/workstreams/test
cat > /tmp/internos-verify/projects/demo/workstreams/test/BRIEF.md <<EOF
thread_id: claude-code:projects/demo/workstreams/test
EOF
( cd /tmp/internos-verify/projects/demo/workstreams/test \
  && INTERNOS_WORKSPACE=/tmp/internos-verify \
     ~/.claude/skills/intern-os/scripts/resolve-thread.sh )
rm -rf /tmp/internos-verify
```

The third command should print the workstream's absolute path.

---

## Daily use

Open Claude Code from inside a workstream directory:

```bash
cd $INTERNOS_WORKSPACE/projects/my-project/workstreams/feature-x
claude
```

Claude resolves the thread, loads BRIEF.md + STATUS.md, claims the tick.md task, and starts work. `/resume` later picks up the same thread because the cwd hasn't changed.

For an operational overview of all active workstreams, ask Claude to consult `$INTERNOS_WORKSPACE/projects/REGISTRY.md` (regenerate with `generate-registry.sh` from the framework-agnostic skill's scripts).

---

## Uninstall

```bash
# Remove the skill (preserves all workstream data)
rm -rf ~/.claude/skills/intern-os

# Remove project-level CLAUDE.md additions (manual — only if CLAUDE.md is internOS-only)
# Remove the Stop hook from ~/.claude/settings.json (manual)
```

Workstream data lives in your workspace and is untouched by uninstall.
