# internOS — Workstreams Framework

*Version: 2.0 | Date: 2026-03-30 | Status: v2 — projects, tick-md, multi-platform*

---

## The system in one line

Every project organizes work across four synchronized layers. Coherence between layers eliminates coordination friction.

---

## The four layers

| Layer | Tool | Role |
|-------|------|------|
| **Project** | Filesystem (`projects/[name]/`) | Organizational container — groups workstreams and tasks |
| **Management** | tick.md (`TICK.md` at project root) | Task origin — what needs to be done, who's doing it |
| **Communication** | Discord forums · Slack threads | Team work surface — humans and agents collaborate |
| **Operation** | Filesystem (`projects/[name]/workstreams/`) | Source of truth for agents — context persists across sessions |

> tick.md is the default task management layer. Other systems (Notion, Linear, Trello, etc.) can be used instead — see the task management section in SETUP.md.

**On artifacts:** there is no single repository. `docs/` inside each workstream is one of N possible repositories (Notion, Google Drive, S3, R2, etc.). `RESOURCES.md` is the index that tracks all resources and where they live.

---

## 1. Project structure

Each project is a self-contained directory with a tick.md task file and a `workstreams/` directory:

```
projects/
├── project-alpha/
│   ├── TICK.md              ← tick-md: all tasks for this project
│   ├── .tick/
│   │   └── config.yml       ← tick-md configuration
│   ├── workstreams/
│   │   ├── feature-x/
│   │   │   ├── BRIEF.md
│   │   │   ├── STATUS.md
│   │   │   ├── MEMORY.md
│   │   │   ├── DECISIONS.md
│   │   │   ├── STAKEHOLDERS.md
│   │   │   ├── RESOURCES.md
│   │   │   └── docs/
│   │   └── bug-fix-y/
│   │       └── ...
│   └── docs/                ← project-level artifacts
└── project-beta/
    ├── TICK.md
    ├── .tick/
    └── workstreams/
```

### Workstream file structure

Each workstream has a directory with 6 standard files:

```
workstreams/[name]/
├── BRIEF.md         ← What, for whom, problem, appetite
├── STATUS.md        ← Workstream phase, where we are, blockers
├── MEMORY.md        ← Accumulated context, insights, learnings
├── DECISIONS.md     ← Key decisions log with date + reason
├── STAKEHOLDERS.md  ← Relevant people and their role
├── RESOURCES.md     ← Artifact inventory and where they live
└── docs/            ← Working artifacts
```

**Convention:** All system markdown files in UPPERCASE.

---

## 2. Task–workstream relationship

Tasks live in `TICK.md` at the project root. Workstreams live in `workstreams/`. They connect through tags:

- Each task in TICK.md is tagged with its workstream name (e.g., `tags: [feature-x]`)
- A workstream can have **1 or N tasks** — some workstreams are a single task, others have many
- `tick list --tag feature-x` shows all tasks for that workstream
- `tick status` shows all tasks across the project

**STATUS.md is workstream-level health** — aggregated progress, direction, blockers. It does not track individual task status. tick.md owns task status.

**TICK.md is the task-level source of truth** — status, priority, assignment, claim/release, history. It does not describe the workstream's purpose or context. intern-os workstream files own that.

---

## 3. Write protocol

**Who writes what:**

| Actor | Writes when... | Files |
|-------|----------------|-------|
| **Agent** | At the end of a working session in the thread | STATUS.md, MEMORY.md, DECISIONS.md |
| **Human** | Strategic decision, change of direction, or new information | Any file |
| **Both** | Creating a new workstream | BRIEF.md, STAKEHOLDERS.md, RESOURCES.md |

**Golden rule:** If the agent cannot answer "where does this workstream stand?" by reading STATUS.md, the file is outdated.

**Task claiming:** Before starting work on a task, the agent claims it in tick.md:

```bash
tick claim TASK-001 @agent-name
```

After completing a task:

```bash
tick done TASK-001 @agent-name
```

See TICK-INTEGRATION.md for the full coordination protocol.

**Checkpoints (v1 carry-forward):** The human explicitly requests "save state" and the agent updates STATUS.md + MEMORY.md. No context reset required.

---

## 4. Lifecycle

### Project lifecycle

A project is created when:
1. A new directory is created under `projects/`
2. `tick init` is run inside the project directory
3. The agent is registered: `tick agent register @agent-name`

A project is archived when all its workstreams are archived.

### Workstream lifecycle

A workstream **is born** when:
1. A project exists (or is created)
2. A task is added to TICK.md: `tick add "Task name" --tag workstream-name`
3. A communication thread is opened (Discord forum post or Slack thread)
4. The workstream directory is created in `projects/[project]/workstreams/` with the 6 files

**No task, no thread. No thread, no directory.**

A workstream **dies** when:
1. All tasks for the workstream are marked done in TICK.md
2. STATUS.md is updated with final state and learnings
3. The communication thread is archived
4. The directory is moved from `workstreams/` to `workstreams/archived/`

**Possible states:**

| State | Directory | Communication Thread | Tasks |
|-------|-----------|---------------------|-------|
| Active | `workstreams/` | Open | In progress |
| Paused | `workstreams/` | Open | Blocked |
| Archived | `workstreams/archived/` | Archived | Complete/Archived |

---

## 5. Agent bootstrap

**Principle:** The agent loads only the workstream for the thread it is operating in — not all of them.

**Mechanism:**
- Each communication thread (Discord or Slack) maps to a workstream directory
- The `thread_id` field in BRIEF.md is the canonical mapping
- When entering a workstream thread, the agent reads **only** that workstream's directory

**Thread ↔ directory mapping:** The `thread_id` field in BRIEF.md uses the format `[platform]:[id]`:

```
thread_id: discord:123456789
```
```
thread_id: slack:C07ABC123/1234567890.123456
```

The agent writes this field when creating the workstream directory, using the thread ID from platform metadata.

**Agent instructions:** Each agent framework has its own mechanism for loading instructions. See `adapters/` for framework-specific configuration:

- **OpenClaw:** SKILL.md + AGENTS.md block → `adapters/openclaw/`
- **Hermes Agent:** Skill definition → `adapters/hermes/`
- **Claude Code:** CLAUDE.md project instructions → `adapters/claude-code/`
- **Other agents:** Manual setup → `adapters/generic/`

The instruction contract is the same regardless of framework:
1. Read `WORKSTREAMS.md` at the start of any session in a workstream thread
2. Load only the workstream directory matching the active thread
3. Read BRIEF.md → STATUS.md → MEMORY.md before doing any work
4. Claim the task in tick.md before starting work
5. Update STATUS.md at the end of every working session

---

## 6. Communication platforms

Workstreams use communication threads as the collaboration surface. The framework supports multiple platforms — see COMMUNICATION.md for the full specification.

**Summary:**

| Platform | Container | Workstream surface | Thread ID format |
|----------|-----------|-------------------|------------------|
| Discord | Forum (`[area]-workstreams`) | Forum post (thread) | `discord:[thread_id]` |
| Slack | Channel (`[area]-workstreams`) | Thread in channel | `slack:[channel_id]/[thread_ts]` |

**Naming convention:** `[area]-workstreams` — applies to both Discord forums and Slack channels. Examples: `ceo-workstreams`, `tech-workstreams`, `ops-workstreams`.

**Persistent context mechanism:** The thread starter message (Discord forum post or Slack thread root) is the most reliable context anchor. It survives context compaction and tells the agent which workstream it's operating in. Keep it updated.

---

## 7. tick.md integration

tick.md is the default task management layer. TICK.md lives at the project root and contains all tasks for that project. See TICK-INTEGRATION.md for the full specification.

**Quick reference:**

| Action | Command |
|--------|---------|
| Initialize project | `tick init` |
| Register agent | `tick agent register @agent-name` |
| Add task | `tick add "Task name" --tag workstream-name --priority high` |
| Claim task | `tick claim TASK-001 @agent-name` |
| Complete task | `tick done TASK-001 @agent-name` |
| View project status | `tick status` |
| List workstream tasks | `tick list --tag workstream-name` |

---

## How to create a new project

1. Create the project directory: `mkdir -p projects/[project-name]`
2. Initialize tick.md: `cd projects/[project-name] && tick init`
3. Register the agent: `tick agent register @agent-name`
4. The project is ready for workstreams

## How to create a new workstream

1. Add a task in tick.md: `tick add "Description" --tag workstream-name`
2. Open a communication thread (Discord forum post or Slack thread) in the `[area]-workstreams` channel
3. Create the workstream directory with the 6 files:
   ```bash
   WS=workstream-name
   PROJECT=project-name
   cp -r assets/templates/workstream/ projects/$PROJECT/workstreams/$WS/
   mkdir -p projects/$PROJECT/workstreams/$WS/docs
   ```
4. Fill BRIEF.md using the 6 questions:
   - What specific work is this? *(verb + object)*
   - What problem or situation triggers it?
   - Who needs it and for what purpose?
   - What does it deliver when done? *(outcome, not output)*
   - What is in scope? What is out of scope?
   - What is the appetite? *(maximum time or effort)*
5. Add thread_id to BRIEF.md: `thread_id: [platform]:[id]`
6. Link the communication thread and task in RESOURCES.md

---

## What this framework is not

- Does not replace tick.md or any task management system — it complements them
- Is not a ticketing or sprint system
- Does not require infrastructure beyond a filesystem and Git

---

## Roadmap

> v2 ships projects, tick.md integration, and multi-platform communication. Automations will be implemented as the system is proven in real use.

### v2.1 — Low-effort automations

**Sync check** *(~1h)*
Script that compares active communication threads vs directories in `workstreams/`. Detects mismatches: thread without directory, directory without thread. Platform-agnostic.

**Checkpoint reminder** *(~1h)*
Cron job that checks whether STATUS.md was updated during an active working session. If not, the agent receives a reminder.

### v2.2 — Medium-effort automations

**Auto-scaffold on thread creation** *(~3h)*
Platform webhook detects a new thread in a `-workstreams` channel/forum → automatically creates the directory + 6 files and adds the tick.md task.

### v3.0 — High-effort automations

**Archive workflow** *(~6-8h)*
Detects all tasks for a workstream marked done in tick.md → moves the directory to `workstreams/archived/` → archives the communication thread.

**Cross-project dashboard** *(~4h)*
Aggregator that reads all `projects/*/TICK.md` files and produces a unified view across projects.

---

*Iterated from learnings of each workstream.*

---

## References

- Agent runtime guide: `WORKSTREAMS.md` (copied to workspace root)
- Workstream templates: `assets/templates/workstream/`
- Project template: `assets/templates/project/`
- Agent adapters: `adapters/`
- Communication spec: `references/en/COMMUNICATION.md`
- tick.md integration: `references/en/TICK-INTEGRATION.md`
- New instance setup: `references/en/SETUP.md`
- Operational playbook: `references/en/PLAYBOOK.md`
