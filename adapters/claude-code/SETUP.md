# SETUP — Claude Code Adapter

*internOS Workstreams · Claude Code adapter*

This adapter lets Claude Code participate in internOS workstreams the same way Hermes (Discord/Slack) and OpenClaw do — but using the working directory as the thread binding instead of a chat-platform thread ID, plus lifecycle hooks that automate the housekeeping internOS doctrine prescribes.

---

## How it works

A **thread** in Claude Code is the persistent conversation about a workstream. Each `/resume` continues the same thread; opening a fresh conversation in the same working directory also continues it. Individual sessions are *instances* of the thread.

Three pieces work together:

1. **Resolver** (`resolve-thread.sh`) — walks up from `$PWD`, finds `<workspace>/projects/<project>/workstreams/<name>`, verifies BRIEF.md's `thread_id` matches `claude-code:projects/<project>/workstreams/<name>`. Exit codes: 0 resolved, 1 no workstream (silent), 2 binding broken (loud).
2. **SessionStart hook** — runs at the beginning of every Claude Code session. If the resolver finds a workstream, it injects a system reminder containing STATUS.md, the SESSIONS.md tail, open tick.md tasks, and any `.internos-warnings` from the previous session. Claude has the operating context before its first response token.
3. **SessionEnd hook** — runs at actual session end (not per-turn). Stamps `last_updated` on BRIEF.md, appends a SESSIONS.md entry, runs `sync-check.sh --workstream` and writes any findings to `.internos-warnings` for the next SessionStart to surface.

All three components silent-no-op outside any workstream subtree. Cost in non-workstream sessions: ~50ms total.

---

## Prerequisites

- Claude Code CLI installed
- `tick-md` installed globally: `npm install -g tick-md`
- A directory that will hold your projects — anything works (e.g. `~/workspace`, `~/code`). Inside it, projects live under a `projects/` subdirectory.

---

## Install (user-global)

The adapter installs into `~/.claude/skills/intern-os/`, available to every Claude Code session for the user.

### 1. Install the skill files

From this repo:

```bash
REPO=$(pwd)   # or wherever you've cloned intern-os
DEST=~/.claude/skills/intern-os

mkdir -p "$DEST"
cp "$REPO/adapters/claude-code/SKILL.md" "$DEST/SKILL.md"
cp -R "$REPO/adapters/claude-code/scripts" "$DEST/scripts"
# Bring sync-check along so SessionEnd can find it as a sibling to the
# adapter scripts. Shipped framework-agnostic; same code as the workspace
# sweep, just gains a --workstream mode.
cp "$REPO/intern-os/scripts/sync-check.sh" "$DEST/scripts/sync-check.sh"
chmod +x "$DEST/scripts/"*.sh
```

If you also want the deep references (`FRAMEWORK.md`, `PLAYBOOK.md`, etc.) accessible from the same install:

```bash
cp -R "$REPO/intern-os/references" "$DEST/references"
```

### 2. Set the workspace path (required)

`INTERNOS_WORKSPACE` is required — there is no implicit default. Point it at the directory that contains your `projects/` directory:

```bash
echo 'export INTERNOS_WORKSPACE="$HOME/workspace"' >> ~/.zshrc
```

(Substitute whatever directory holds your `projects/` subdir.) Both the skill instructions and the resolver script read this variable.

If `INTERNOS_WORKSPACE` is unset when the resolver runs, it exits with code 3 and a clear error rather than guessing.

### 3. Install the lifecycle hooks (strongly recommended)

The resolver alone gets you basic thread binding. The hooks give you the gstack-style "context save/restore" experience: every session starts with the right context already loaded, every session ends with the workstream stamped and checked. **Skip this step and you lose 80% of the value of this adapter.**

Merge `adapters/claude-code/hooks/settings.json` into `~/.claude/settings.json` — specifically the `hooks.SessionStart` and `hooks.SessionEnd` arrays. If you don't already have a `hooks` block in your settings, you can copy the file's `hooks` object as-is.

> ⚠️  Earlier versions of this adapter wired a `Stop` hook. Don't use `Stop` — it fires at the end of every agent turn, which would pollute SESSIONS.md. The right events are `SessionStart` and `SessionEnd`.

To verify the hooks are wired: open a fresh Claude Code session inside any workstream directory and check whether the conversation begins with an "internOS workstream resolved" system reminder. If you don't see it, the hook isn't firing — see Troubleshooting below.

### 4. Drop CLAUDE.md into projects that operate workstreams

Per-project, not global. For each repo that should auto-resolve workstreams (typically your workspace repo itself, if you keep it under git):

```bash
cp adapters/claude-code/CLAUDE.md <your-project>/CLAUDE.md
```

If the project already has a `CLAUDE.md`, append the contents instead — Claude Code reads the whole file as project instructions.

---

## Verification

```bash
# 1. Skill files in place
test -f ~/.claude/skills/intern-os/SKILL.md && echo "skill: ok"
test -x ~/.claude/skills/intern-os/scripts/resolve-thread.sh && echo "resolver: ok"
test -x ~/.claude/skills/intern-os/scripts/session-start.sh && echo "session-start: ok"
test -x ~/.claude/skills/intern-os/scripts/session-end.sh && echo "session-end: ok"
test -f ~/.claude/skills/intern-os/scripts/sync-check.sh && echo "sync-check: ok"

# 2. Resolver runs (should exit 1 here unless cwd is in a workstream)
~/.claude/skills/intern-os/scripts/resolve-thread.sh; echo "resolver exit: $?"

# 3. Resolver finds a real workstream when you cd into one
WS=$INTERNOS_WORKSPACE/projects/_verify/workstreams/install-check
mkdir -p "$WS"
cat > "$WS/BRIEF.md" <<EOF
thread_id: claude-code:projects/_verify/workstreams/install-check
EOF
( cd "$WS" && ~/.claude/skills/intern-os/scripts/resolve-thread.sh )
rm -rf "$INTERNOS_WORKSPACE/projects/_verify"
```

The third command should print the workstream's absolute path.

---

## Daily use

Open Claude Code from inside a workstream directory:

```bash
cd $INTERNOS_WORKSPACE/projects/my-project/workstreams/feature-x
claude
```

With the hooks installed: the session opens with STATUS, the SESSIONS tail, open tick tasks, and any prior-session warnings already in the conversation. You can dive straight into the work.

`/resume` later picks up the same thread because the cwd hasn't changed.

For an operational overview of all active workstreams: ask Claude to consult `$INTERNOS_WORKSPACE/projects/REGISTRY.md` (regenerate with `generate-registry.sh` from the framework-agnostic skill).

---

## Troubleshooting

**SessionStart system reminder doesn't appear.** Check that `~/.claude/settings.json` has a `hooks.SessionStart` block pointing at `~/.claude/skills/intern-os/scripts/session-start.sh`, and that the script is executable. Run `bash ~/.claude/skills/intern-os/scripts/session-start.sh` from inside the workstream directory with `INTERNOS_WORKSPACE` exported — if it prints valid JSON, the script works and the issue is hook wiring.

**SESSIONS.md gets a line on every Claude response.** You're using a `Stop` hook somewhere. `Stop` fires per turn — switch to `SessionEnd`.

**Resolver exits 2 with a thread_id mismatch.** Don't auto-fix BRIEF.md. The mismatch usually means the workstream was moved or copied; ask the human what the canonical path should be.

**Hooks fire but no warnings ever appear.** `sync-check.sh` may not be in the install dir. Re-run Step 1 — make sure `cp "$REPO/intern-os/scripts/sync-check.sh" "$DEST/scripts/sync-check.sh"` is included.

---

## Uninstall

```bash
# Remove the skill (preserves all workstream data)
rm -rf ~/.claude/skills/intern-os

# Remove SessionStart and SessionEnd hooks from ~/.claude/settings.json (manual)
# Remove project-level CLAUDE.md additions (manual — only if CLAUDE.md is internOS-only)
```

Workstream data lives in your workspace and is untouched by uninstall.
