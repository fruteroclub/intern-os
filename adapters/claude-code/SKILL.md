---
name: intern-os
description: internOS Workstreams framework for Claude Code. Use this skill whenever the user is operating inside an internOS workstream (their working directory is under `<workspace>/projects/<project>/workstreams/<name>/`), or when they mention workstreams, BRIEF.md, STATUS.md, MEMORY.md, tick.md tasks, or activating/discovering a project. Resolves the active thread from the working directory, loads the right context files in the right order, and enforces the resolution, runtime, recovery, and isolation doctrines so context survives across sessions and `/resume`. Trigger this even when the user doesn't say "internOS" or "workstream" by name — if pwd is inside a `projects/*/workstreams/*` subtree, this skill applies.
---

# internOS — Workstreams (Claude Code)

internOS is a framework for humans and agents to collaborate on long-running workstreams without losing context between sessions. Each workstream exists in three places at once: a tick.md task (management), a communication thread (collaboration), and a filesystem directory (source of truth).

This skill is the **Claude Code adapter**. The framework-agnostic doctrine lives in `intern-os/SKILL.md` — read it when you need the full FRAMEWORK / PLAYBOOK / COMMUNICATION reference. This file covers what's specific to Claude Code: how a thread is resolved, how sessions relate to threads, and the operating protocol.

## What "thread" means in Claude Code

On Discord and Slack, a thread is a platform-native conversation thread. In Claude Code, a **thread is the persistent conversation about a workstream** — surfaced as one or more *sessions* over time:

- Each `/resume` continues the same thread.
- Opening a fresh conversation in the same working directory continues the same thread.
- Sessions are *instances* of the thread; the thread is the unit of work.

The `thread_id` in BRIEF.md uses the canonical form:

```
thread_id: claude-code:projects/<project>/workstreams/<name>
```

This is the working-directory-relative path under the configured workspace. It's the cheapest, most deterministic binding Claude Code can offer: no inference, no fuzzy matching.

## Resolution: pwd → workstream

Claude Code thread resolution is fully delegated to a small script. Always use it — never resolve a workstream by reading directory listings or guessing from path fragments.

```bash
# Returns workstream absolute path on stdout (exit 0), or:
#   exit 1 — no active workstream (pwd not inside a workstream subtree). Silent, expected.
#   exit 2 — workstream dir found but BRIEF.md missing or thread_id mismatched. STOP and ask.
~/.claude/skills/intern-os/scripts/resolve-thread.sh
```

The script:
1. Walks up from `$PWD` looking for `<workspace>/projects/<project>/workstreams/<name>`.
2. Reads BRIEF.md and verifies `thread_id` exactly equals `claude-code:projects/<project>/workstreams/<name>`.
3. Prints the workstream path on success, or fails loudly on mismatch.

`<workspace>` is set via the `INTERNOS_WORKSPACE` environment variable — required, no implicit default. Point it at the directory that contains your `projects/` directory.

**Mismatch handling.** If the script exits 2, do not proceed and do not patch the file silently. Tell the human what was expected vs. found, and ask whether the workstream was moved, copied, or scaffolded by hand. Quietly fixing thread_id values is exactly the kind of "helpful guess" that corrupts the binding model.

## Operating protocol

When `resolve-thread.sh` returns a workstream path, follow the same protocol as any other internOS adapter:

1. Read `BRIEF.md` in full (workstream identity + thread_id).
2. Read `STATUS.md` in full (operational heartbeat, ≤10 lines by design).
3. Read project-level `AGENTS.md` from `<workspace>/projects/<project>/AGENTS.md` if it exists.
4. Escalate to the on-demand files only when the task actually needs them:
   - `MEMORY.md` — last 80 lines (search on demand for older context).
   - `DECISIONS.md` — when the task touches a prior decision.
   - `STAKEHOLDERS.md` — when the task involves people.
   - `RESOURCES.md` — when the task involves artifacts or deployments.
5. Check tasks: `tick list --tag <workstream-name>`.
6. Claim before working: `tick claim TASK-X @claude-code`.

Before ending the session:

1. Complete or release the task: `tick done TASK-X @claude-code` or `tick release TASK-X @claude-code`.
2. Update `STATUS.md` (what was done, current phase, blockers). A blank STATUS.md makes the workstream invisible to the next session.
3. If `MEMORY.md` exceeds 80 lines, consolidate — summary, not log. Target ≤50 lines.
4. Append a one-line summary entry to `SESSIONS.md` (see below).

This is required even if nothing changed. STATUS.md and SESSIONS.md being current is what makes `/resume` actually useful.

## Sessions vs. threads (SESSIONS.md)

Sessions are individual Claude Code conversations. The thread is the workstream. `SESSIONS.md` lives inside the workstream directory and is an append-only log of which sessions touched this thread:

```
2026-05-07 09:14 · 8c1a4d9e-... · resolved STATUS.md staleness, drafted plan for resource-binding bug
2026-05-07 14:03 · 1f2b9e77-... · implemented resource-binding fix and updated DECISIONS.md
```

Entries are written automatically when the lifecycle hooks are installed (see below). Manual writes are still possible via `log-session.sh "<session-id>" "<summary>"`, but you usually won't need them.

If the user `/resume`s a session and continues work, no new entry is needed unless meaningful new work happened — judgment call. Don't pad SESSIONS.md with empty resume markers.

## Lifecycle hooks (strongly recommended)

The adapter ships two hooks that do work the doctrine previously relied on Claude remembering. Install them once and the workstream is kept honest automatically.

### SessionStart — pre-load context before the first response token

When a session starts inside a workstream, `session-start.sh` injects a system reminder containing:

- BRIEF.md identity header (thread_id, project, owner, created, last_updated)
- STATUS.md in full
- The last 3 SESSIONS.md entries
- Open tick.md tasks tagged with this workstream
- Any `.internos-warnings` written by the previous SessionEnd

This means: by the time you read your first user message inside a workstream, the operating context is already in your conversation. **Do not re-read STATUS.md or SESSIONS.md just because you'd "normally" load them at the start of a workstream session — they're already there.** Read BRIEF.md fully, MEMORY.md, DECISIONS.md, etc. only when a specific turn requires them.

If `session-start.sh` exited 2 (binding broken), the system reminder will say so explicitly. Stop and ask the human; don't start work blind.

### SessionEnd — stamp, append, check

When the session ends, `session-end.sh`:

1. Stamps `last_updated: <today>` in BRIEF.md (creating the field if missing). This makes staleness visible to `sync-check.sh` and to humans skimming the file.
2. Appends a `<timestamp> · <session-id>` line to SESSIONS.md. The summary is your job — append it during the end-of-session protocol *before* the hook fires (the hook only adds the timestamp + id; you add the summary text on the same line).
3. Runs `sync-check.sh --workstream <path>` and writes findings to `<workstream>/.internos-warnings`. The next SessionStart will surface them.
4. Does **not** auto-release tick tasks. Claimed-but-not-completed tasks just persist into the next session — that's usually what the human wants ("I'll come back tomorrow"). The findings file will note the unreleased claim.

The hook returns immediately on workstreams it can't resolve, so it costs ~50ms in non-workstream sessions.

## Doctrines (recap)

These come from the framework-agnostic `intern-os/SKILL.md`. They apply unchanged in Claude Code:

- **Resolution doctrine.** Exact, deterministic, non-heuristic. If `resolve-thread.sh` says no thread, there is no thread. Don't infer one from a similar path.
- **Runtime doctrine.** Load only what the current turn needs. Tier 1 = BRIEF + STATUS. Tier 2 = DECISIONS, STAKEHOLDERS. Tier 3 = MEMORY, RESOURCES, docs/. No cross-workstream reads by default. No broad scans across `projects/`.
- **Recovery doctrine.** If the session is degraded, bloated, or reset, reconstruct from workstream files — not from transcript continuity. BRIEF + STATUS must be sufficient to restart.
- **Isolation doctrine.** Don't read another workstream's files. Don't search across projects. Cross-workstream synthesis must be explicit and human-requested.

## Discovering a project / activating a workstream

When the human says "discover project: X" or "activate workstream: X in project Y", follow the discovery / activation flows in `intern-os/SKILL.md`. The Claude Code specifics:

- The new workstream directory must live at `<workspace>/projects/<project>/workstreams/<name>/`.
- BRIEF.md `thread_id` must be `claude-code:projects/<project>/workstreams/<name>` — anything else will fail resolution.
- After scaffolding, verify by `cd`ing into the workstream and running `resolve-thread.sh` — it should print the path on the first try. If not, the binding is wrong; fix it before claiming any task.

## When NOT to load this skill

- The user is doing general coding outside any workstream subtree. `resolve-thread.sh` exits 1 silently — that's the signal to stand down.
- The user explicitly asks for cross-project synthesis or a workspace-wide overview. That's a `sync-check.sh` / `generate-registry.sh` job, not workstream operation.
- The user is troubleshooting tick.md, the resolver script, or the workspace structure itself. That's tooling work, not workstream work — read this file for context but don't enter the operating protocol.

## Pointers into the framework-agnostic skill

For deeper reference, read these from the canonical skill (one repo up from this adapter, or wherever it's installed):

- `intern-os/SKILL.md` — full framework, doctrine, project lifecycle
- `intern-os/references/en/FRAMEWORK.md` — what's validated by tooling vs. what's doctrine
- `intern-os/references/en/PLAYBOOK.md` — concrete workflows
- `intern-os/references/en/COMMUNICATION.md` — thread format, message conventions
- `intern-os/references/en/TICK-INTEGRATION.md` — tick.md commands and tags
- `intern-os/references/en/ROLLOUT.md` — rolling out internOS to an existing workspace

Load these only when the current turn actually needs them. Defaulting to "read everything" is exactly the runtime-doctrine violation this skill is designed to prevent.
