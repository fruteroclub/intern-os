# internOS — Workstreams Framework

*Version: 1.0 | Date: 2026-03-24 | Status: v1 — just ship*

---

## The system in one line

Every team workstream exists in three simultaneous layers. Coherence between layers eliminates coordination friction.

---

## The three layers

| Layer | Tool | Role |
|-------|------|------|
| **Management** | Team task system (tick.md, Notion, Trello, etc.) | Workstream origin |
| **Communication** | Discord (forum threads) | Team work surface — humans and agents |
| **Operation** | Filesystem (`active-workstreams/`) | Source of truth for agents — context persists across sessions |

> **Current communication layer: Discord.** Other channels (Slack, Telegram, WhatsApp, etc.) are not yet defined for this system.

**On artifacts:** there is no single repository. `docs/` inside each workstream is one of N possible repositories (Notion, Google Drive, S3, R2, etc.). `RESOURCES.md` is the index that tracks all resources and where they live.

---

## 1. File structure

Each workstream has a mirror directory in the filesystem with 6 standard files:

```
active-workstreams/
└── [workstream-name]/
    ├── BRIEF.md         ← What, for whom, problem, appetite
    ├── STATUS.md        ← Phase, where we are, next step, blockers
    ├── MEMORY.md        ← Accumulated context, insights, learnings
    ├── DECISIONS.md     ← Key decisions log with date + reason
    ├── STAKEHOLDERS.md  ← Relevant people and their role
    ├── RESOURCES.md     ← Artifact inventory and where they live
    └── docs/            ← Working artifacts
```

**Convention:** All system markdown files in UPPERCASE.

---

## 2. Write protocol

**Who writes what:**

| Actor | Writes when... | Files |
|-------|----------------|-------|
| **Agent** | At the end of a working session in the thread | STATUS.md, MEMORY.md, DECISIONS.md |
| **Human** | Strategic decision, change of direction, or new information | Any file |
| **Both** | Creating a new workstream | BRIEF.md, STAKEHOLDERS.md, RESOURCES.md |

**Golden rule:** If the agent cannot answer "where does this workstream stand?" by reading STATUS.md, the file is outdated.

**Checkpoints (v1):** The human explicitly requests "save state" and the agent updates STATUS.md + MEMORY.md. No context reset required.

> **Roadmap:** Create a `/checkpoint` command in OpenClaw that saves the active workstream state without closing the session or losing agent context.

---

## 3. Lifecycle

A workstream **is born** when:
1. A task is created in the team's task management system
2. A thread is opened in the corresponding Discord forum
3. The directory is created in `active-workstreams/` with the 6 files

**No task, no thread. No thread, no directory.**

A workstream **dies** when:
1. The task is marked complete or archived in the task system
2. STATUS.md is updated with final state and learnings
3. The Discord thread is archived
4. The directory is moved from `active-workstreams/` to `archived-workstreams/`

**Possible states:**

| State | Directory | Discord Thread | Task |
|-------|-----------|----------------|------|
| Active | `active-workstreams/` | Open | In progress |
| Paused | `active-workstreams/` | Open | Blocked |
| Archived | `archived-workstreams/` | Archived | Complete/Archived |

---

## 4. Agent bootstrap

**Principle:** The agent loads only the workstream for the thread it is operating in — not all of them.

**Mechanism:**
- Each Discord thread has a unique ID
- That ID maps to a specific directory in `active-workstreams/`
- When entering a workstream thread, the agent reads **only** that subdirectory

**What goes in `AGENTS.md`:**
```
## internOS — Workstreams

If `WORKSTREAMS.md` exists in the workspace root, read it at the start
of any session in a Discord thread that has a workstream context.

Only load the workstream directory matching the active thread.
Do not load all workstreams — keep context clean.

Workstream directories live in: `active-workstreams/[workstream-name]/`
Read: BRIEF.md, STATUS.md, MEMORY.md before doing any work.

Before ending any working session, update STATUS.md with:
1. What was done this session
2. Next concrete step
3. Any blockers

This is required even if nothing changed. A blank STATUS.md means
the workstream is invisible to the next agent or session.
```

**Thread ↔ directory mapping:** The `discord_thread_id` field in BRIEF.md is the canonical record. The agent writes it when creating the directory, using the `topic_id` from Discord metadata.

---

## 5. Discord forums by workstream type

Workstreams live exclusively in forums, classified by the responsible area. Naming convention: `[area]-workstreams`.

Examples: `ceo-workstreams`, `tech-workstreams`, `ops-workstreams`, `mkt-workstreams`.

Each project defines its own forums based on its active areas.

---

## How to create a new workstream

1. Create a task in the team's task management system
2. Open a thread in the Discord forum for the responsible area
3. Create the directory in `active-workstreams/[name]/` with the 6 files
4. Fill BRIEF.md using the 6 questions:
   - What specific work is this? *(verb + object)*
   - What problem or situation triggers it?
   - Who needs it and for what purpose?
   - What does it deliver when done? *(outcome, not output)*
   - What is in scope? What is out of scope?
   - What is the appetite? *(maximum time or effort)*
5. Link the Discord thread in RESOURCES.md
6. Link the task in RESOURCES.md

---

## What this framework is not

- Does not replace the team's task management system
- Is not a ticketing or sprint system
- Does not require additional tools to function

---

## Roadmap

> This framework is in active development. v1 is fully manual — automations will be implemented as the system is proven in real use.

### v1.1 — Low-effort automations

**Sync check** *(~1h)*
Script that compares active threads in Discord `-workstreams` forums vs directories in `active-workstreams/`. Detects mismatches: thread without directory, directory without thread.

**Checkpoint reminder** *(~1h)*
Cron job that checks whether `STATUS.md` was updated during an active working session. If not, the agent receives a reminder. Prevents workstreams from going stale.

### v1.2 — Medium-effort automations

**Auto-scaffold on thread creation** *(~3h)*
Discord webhook detects a new post in a `-workstreams` forum → automatically creates the directory + 6 files in `active-workstreams/`. Eliminates the most repetitive step in activation.

### v2.0 — High-effort automations

**Archive workflow** *(~6-8h)*
Detects a status change in the task management system → moves the directory to `archived-workstreams/` → archives the Discord thread. Requires coordinating three systems.

---

*Iterated from learnings of each workstream.*

---

## References

- Agent operational guide: `workspace/WORKSTREAMS.md`
- Workstream directory: `workspace/active-workstreams/`
- New instance setup: `references/en/SETUP.md`
- Operational playbook: `references/en/PLAYBOOK.md`
