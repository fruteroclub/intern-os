# TICK-INTEGRATION — tick.md as the Task Management Layer

*internOS v2.0 | 2026-03-30*

tick.md is the default task management layer for internOS. This document specifies how tick.md integrates with the project–workstream–task hierarchy.

> tick.md is a protocol and CLI for coordinating work through structured Markdown files. It is markdown-native, git-native, and requires zero infrastructure. [Full docs →](https://www.tick.md/docs)

---

## Overview

- **One TICK.md per project.** The file lives at the project root: `projects/[name]/TICK.md`
- **Tasks reference workstreams via tags.** A task tagged `feature-x` belongs to `workstreams/feature-x/`
- **A workstream can have 1 or N tasks.** Simple workstreams are one task. Complex ones have many.
- **tick.md owns task status.** STATUS.md owns workstream-level health.
- **tick.md owns coordination.** Claim/release, agent assignment, history.

---

## Hierarchy mapping

```
project/                     ← tick init here
├── TICK.md                  ← all tasks for this project
├── .tick/config.yml         ← tick-md configuration
└── workstreams/
    ├── feature-x/           ← workstream
    │   ├── BRIEF.md
    │   └── STATUS.md        ← workstream health
    └── bug-fix-y/
        ├── BRIEF.md
        └── STATUS.md
```

In TICK.md, tasks link to workstreams through tags:

```yaml
id: TASK-001
status: in_progress
priority: high
tags: [feature-x]
claimed_by: @duki
```

```yaml
id: TASK-002
status: todo
priority: medium
tags: [feature-x]
```

```yaml
id: TASK-003
status: in_progress
priority: high
tags: [bug-fix-y]
```

To see all tasks for a workstream: `tick list --tag feature-x`

---

## Agent workflow

### Setup (once per project)

```bash
cd projects/[project-name]
tick init
tick agent register @agent-name --type bot --role engineer
```

### Working a session

1. **Enter the workstream thread** (Discord or Slack)
2. **Load workstream context:** read BRIEF.md → STATUS.md → MEMORY.md
3. **Identify the task:** `tick list --tag [workstream-name] --status in_progress`
4. **Claim the task:**
   ```bash
   tick claim TASK-001 @agent-name
   ```
5. **Do the work**
6. **Add progress notes:**
   ```bash
   tick comment TASK-001 @agent-name --note "Implemented JWT middleware, refresh tokens next"
   ```
7. **Complete the task (if done):**
   ```bash
   tick done TASK-001 @agent-name
   ```
8. **Update STATUS.md** with:
   - What was done this session
   - Current workstream phase
   - Any blockers
9. **Release the task (if not done):**
   ```bash
   tick release TASK-001 @agent-name
   ```

### Creating a new task for an existing workstream

```bash
tick add "Implement refresh token rotation" --tag feature-x --priority medium
```

### Creating a new workstream

1. Add the first task: `tick add "Initial task" --tag new-workstream-name`
2. Open the communication thread
3. Scaffold the workstream directory (see PLAYBOOK.md)

---

## Coordination protocol

tick.md enforces a claim/release cycle so only one agent works a task at a time:

1. **Check availability:** `claimed_by` must be null, all dependencies must be done
2. **Claim:** `tick claim TASK-X @agent-name` — sets `claimed_by`, logs history entry
3. **Work:** Agent performs the task
4. **Release or complete:** `tick release` (if pausing) or `tick done` (if finished)

If an agent crashes or disconnects without releasing:
- The human manually releases: `tick release TASK-X @agent-name`
- Or another agent with appropriate trust level overrides the claim

### Dependencies

Tasks can depend on other tasks:

```yaml
id: TASK-005
depends_on: [TASK-003, TASK-004]
```

tick.md prevents claiming a task whose dependencies are not done.

---

## Task states

tick.md default workflow states, mapped to internOS usage:

| State | Meaning | Transition to |
|-------|---------|---------------|
| `backlog` | Identified but not prioritized | `todo` |
| `todo` | Ready to work | `in_progress`, `backlog` |
| `in_progress` | Actively being worked | `review`, `blocked` |
| `review` | Work complete, needs review | `done`, `in_progress` |
| `blocked` | Cannot proceed | `todo`, `in_progress` |
| `done` | Complete | `reopened` |

---

## STATUS.md vs TICK.md

These two files serve different purposes and should not duplicate information:

| Concern | STATUS.md (workstream) | TICK.md (tasks) |
|---------|----------------------|-----------------|
| **What it tracks** | Workstream phase, direction, blockers | Individual task status, priority, assignment |
| **Granularity** | Workstream-level | Task-level |
| **Updated by** | Agent at end of session | tick.md CLI on every action |
| **Format** | Free-form markdown | Structured YAML + markdown |
| **History** | Overwritten each session | Append-only audit log |

**Example STATUS.md** for a workstream with 3 tasks:

```markdown
## Status

Phase: Implementation — 2 of 3 tasks complete
Last session: 2026-03-30

## Current state

TASK-001 (JWT middleware) and TASK-002 (session storage) are done.
TASK-003 (refresh token rotation) is in progress — halfway through,
endpoint works but needs error handling.

## Blockers

None.

## Next

Finish TASK-003 error handling, then this workstream is ready for review.
```

---

## tick.md configuration for internOS

The project template includes a `.tick/config.yml` preset tuned for internOS:

```yaml
git:
  auto_commit: true
  commit_prefix: "[tick]"
  push_on_sync: false

locking:
  enabled: true
  timeout: 300

agents:
  default_trust: trusted
  require_registration: true
```

Key settings:
- **auto_commit: true** — every tick action creates a git commit, maintaining history
- **default_trust: trusted** — registered agents can create tasks, claim, and update status
- **require_registration: true** — agents must register before interacting with TICK.md

---

## Using other task systems

If the team uses Notion, Linear, Trello, or another task system instead of tick.md:

- The task system replaces TICK.md as the management layer
- Tasks are linked in RESOURCES.md instead of being tracked locally
- The agent cannot use `tick` CLI commands — task management happens in the external system
- The workstream lifecycle rules still apply (no task → no thread → no directory)
- STATUS.md becomes more important as it's the only local record of task state

tick.md is recommended because it's markdown-native, git-native, and agent-friendly. External systems require additional integration (API access, authentication) and break the zero-infrastructure principle.

---

## Commands reference

| Action | Command |
|--------|---------|
| Initialize project | `tick init` |
| Register agent | `tick agent register @name --type bot --role engineer` |
| Add task | `tick add "Title" --tag ws-name --priority high` |
| List all tasks | `tick list` |
| List workstream tasks | `tick list --tag ws-name` |
| View project status | `tick status` |
| Claim task | `tick claim TASK-X @name` |
| Release task | `tick release TASK-X @name` |
| Complete task | `tick done TASK-X @name` |
| Add comment | `tick comment TASK-X @name --note "Progress note"` |
| View dependencies | `tick graph` |
| Validate file | `tick validate` |
| Sync with git | `tick sync` |

> Full CLI reference: [tick.md/docs/cli](https://www.tick.md/docs/cli)
