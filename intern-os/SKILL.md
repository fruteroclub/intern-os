---
name: intern-os
description: internOS Workstreams framework. Coordinates work across projects, tick.md tasks, communication threads, and filesystem workstreams. Load this skill when operating in a workstream thread or when setting up internOS.
version: 0.3.0
metadata:
  hermes:
    tags: [Workstreams, Project Management, Coordination]
    related_skills: []
---

# internOS — Workstreams

internOS is a framework for humans and agents to collaborate on workstreams without losing context between sessions. Each workstream exists in three places simultaneously: a tick.md task (management), a communication thread (collaboration), and a filesystem directory (source of truth).

## Install

| Framework | Command |
|-----------|---------|
| **Hermes Agent** | `hermes skills install fruteroclub/intern-os/intern-os` |
| **OpenClaw** | `openclaw skills install https://github.com/fruteroclub/intern-os` |
| **Claude Code** | Copy `adapters/claude-code/CLAUDE.md` to your project root |
| **Other** | See `adapters/generic/SETUP.md` |

After installing, follow your adapter's SETUP.md for framework-specific configuration.

## Project vs. workstream — when to use which

> A **project** is the top-level operating container in internOS.
> A **workstream** is a bounded unit of execution inside a project.

**Rule of thumb:**
- If the work requires more than one independent workstream, or involves an operational area with its own identity (infra, product, ops, content, etc.) → it's a **project**.
- If it's a scoped piece of work inside an existing area → it's a **workstream** within that project.

Projects are not thread-bound. Workstreams are thread-bound.

## Discovering a new project

Any team member can create a new project:

> Discover project: [name]

The agent:

1. Creates `projects/[name]/PROJECT.md` using the project template
2. Creates `projects/[name]/AGENTS.md` using the project agents template
3. Runs `tick init` and registers the agent
4. Opens a communication thread for the project

**Discovery questions:**
- **Who is the human owner?**
- **What is the main objective?**
- **What is the success criteria?**
- **When should this project be archived?**

If the human does not have an answer for a non-critical field, mark it as `TBD` in `PROJECT.md`.

## Project lifecycle

```
Discover project → PROJECT.md + AGENTS.md + tick init + thread
    → Workstreams activated within the project
        → All workstreams archived
            → PROJECT.md updated with final state
                → Project directory moved to projects/archived/
```

## The three layers

internOS operates across three explicit layers.

### Storage layer

The workstream files are the authoritative operational state. Not the transcript, not agent memory.

```text
projects/
  [project-name]/
    PROJECT.md
    AGENTS.md
    TICK.md
    workstreams/
      [workstream-name]/
        BRIEF.md
        STATUS.md
        MEMORY.md
        DECISIONS.md
        STAKEHOLDERS.md
        RESOURCES.md
        docs/
```

### Resolution layer

Resolution must be exact, deterministic, and non-heuristic.

1. Resolve by exact `thread_id` in `BRIEF.md`
2. If exact match exists, load that workstream
3. If no exact match exists, stop and ask — never guess
4. Never resolve by fuzzy matching, keyword similarity, or path proximity

`BRIEF.md` is the source of truth for thread-to-workstream binding.

### Runtime layer

Load only what is needed for the current turn.

**Default loading policy (Tier 1):**
- `BRIEF.md`
- `STATUS.md`

**On-demand (Tier 2) — when task requires relationship or decision context:**
- `DECISIONS.md`
- `STAKEHOLDERS.md`

**On-demand (Tier 3) — when task requires accumulated or detailed context:**
- `MEMORY.md`
- `RESOURCES.md`
- `docs/*`

**Runtime rules:**
- No cross-workstream reads by default
- No broad scanning across `projects/`
- No heuristic fallback if binding is missing
- If session degrades, reconstruct from files — not from transcript continuity

## Operating a workstream

When in a communication thread that has a workstream context:

1. Resolve the workstream by exact `thread_id` match
2. Load `AGENTS.md` from the project directory (if it exists)
3. Read the workstream's files:
   - `BRIEF.md` — read in full (includes thread_id, project, identity)
   - `STATUS.md` — read in full (must be ≤10 lines by design)
4. Escalate to `MEMORY.md` (last 80 lines only), `DECISIONS.md`, `STAKEHOLDERS.md`, or `RESOURCES.md` only when the task requires it
5. Check tasks: `tick list --tag [workstream-name]`
6. Claim the task: `tick claim TASK-X @agent-name`
7. Do the work
8. Update STATUS.md at the end of the session
9. If MEMORY.md exceeds 80 lines, consolidate — summary, not log. Target ≤50 lines.
10. Complete or release the task: `tick done TASK-X @agent-name`

### Platform startup protocol

**Rule: always emit acknowledgment before any file reads.** Never let file reads block the first response token.

| Platform | Startup mode | Rule |
|----------|-------------|------|
| Discord | **LIGHT** | ACK immediately → load BRIEF + STATUS → escalate only if needed |
| Slack | **LIGHT** | ACK immediately → load BRIEF + STATUS → escalate only if needed |
| Telegram / CLI | **FULL** | Load BRIEF + STATUS + MEMORY before first response |

**LIGHT mode startup contract:**
1. Emit ACK first (e.g. "on it, loading context...")
2. Load `BRIEF.md` (in full — includes thread_id and workstream identity)
3. Load `STATUS.md` (in full, ≤10 lines)
4. Load `MEMORY.md` only if the request requires prior context
5. If `MEMORY.md` exceeds threshold, load last 80 lines and note it was truncated

**MEMORY.md hygiene:**
- Hard limit: 80 lines; target: ≤50 lines
- Must be a curated summary — not a raw session log
- Detailed chronology goes in `docs/` notes, not MEMORY.md
- If size grows beyond threshold: consolidate before ending the session, not after
- `sync-check.sh` validates line count; agents are expected to self-enforce during sessions

### Recovery doctrine

If a session is degraded, bloated, reset, or unhealthy:
- Reconstruct from workstream files
- Do not trust transcript continuity as source of truth
- `BRIEF.md` and `STATUS.md` must be sufficient to restart the workstream safely

### Isolation doctrine

By default:
- Do not read another workstream's files
- Do not search broadly across projects
- Do not infer from similar names

Cross-workstream synthesis must be explicit and requested by the human.

## Activating a new workstream

Any team member can activate a workstream from any thread:

> Activate workstream: [name] in project: [project]

The agent creates what's missing: task in tick.md, communication thread, and workstream directory scaffold.

**Directory scaffold:**
```bash
PROJECT=project-name
WS=workstream-name
mkdir -p [workspace]/projects/$PROJECT/workstreams/$WS/docs
touch [workspace]/projects/$PROJECT/workstreams/$WS/{BRIEF.md,STATUS.md,MEMORY.md,DECISIONS.md,STAKEHOLDERS.md,RESOURCES.md}
```

Add the thread ID to BRIEF.md (mandatory):
```
thread_id: [platform]:[thread ID]
```

**Communication thread format:**
```
**[Workstream name]**

What: [one line]
Owner: [name]
Task: TASK-001
Directory: projects/[project]/workstreams/[name]/
Status: [current phase — one line]
```

## Workstream file structure

```
projects/[project]/workstreams/[name]/
├── BRIEF.md         ← Workstream identity + thread_id binding (mandatory)
├── STATUS.md        ← Operational heartbeat: phase, next, blockers
├── MEMORY.md        ← Durable context across sessions (≤80 lines)
├── DECISIONS.md     ← Key decisions log with date + rationale
├── STAKEHOLDERS.md  ← Relevant people and their role
├── RESOURCES.md     ← Artifact registry and where they live
└── docs/            ← Working artifacts
```

## Project file structure

```
projects/[project]/
├── PROJECT.md       ← Project identity: purpose, scope, direction
├── AGENTS.md        ← Project-level agent context (optional)
├── TICK.md          ← Task management (tick.md)
├── .tick/
│   └── config.yml   ← tick.md configuration
└── workstreams/
```

## Tooling vs. doctrine

The resolution, runtime, recovery, and isolation rules above are **doctrine for agents to follow** — they depend on agents reading and respecting these instructions. They are not mechanically enforced by tooling in v0.3.0.

What **is** validated by shipped tooling:
- `sync-check.sh` — validates file presence, `thread_id` format and uniqueness, BRIEF.md identity fields, STATUS.md / MEMORY.md size limits
- `checkpoint-reminder.sh` — detects stale STATUS.md files
- `tick.md` — enforces task claim/release coordination

See FRAMEWORK.md for the full breakdown of what is validated vs. what is doctrine.

## Full documentation

- Framework: `references/en/FRAMEWORK.md`
- Playbook: `references/en/PLAYBOOK.md`
- Communication: `references/en/COMMUNICATION.md`
- tick.md integration: `references/en/TICK-INTEGRATION.md`
- Framework-specific setup: `adapters/[framework]/SETUP.md`
