# SETUP — Generic Adapter (Any Agent Framework)

*internOS v0.3.0 | 2026-04-11*

Manual setup for agent frameworks without a dedicated adapter.

---

## Prerequisites

- An AI agent framework that supports custom instructions or system prompts
- Access to the agent's workspace or working directory

---

## Setup

### 1. Install tick.md

```bash
npm install -g tick-md
```

### 2. Add internOS instructions to your agent

Add the following to your agent's instruction file, system prompt, or configuration:

```markdown
## internOS — Workstreams

If `WORKSTREAMS.md` exists in the workspace root, read it at the start
of any session in a communication thread that has a workstream context.

### Resolution

Resolve the workstream by exact `thread_id` in BRIEF.md.
If no exact match exists, stop and ask — never guess.

### Loading order

1. Resolve workstream by exact `thread_id`
2. Read `projects/[project]/AGENTS.md` (project-level context, if exists)
3. Read `BRIEF.md` in full (workstream identity + thread_id)
4. Read `STATUS.md` in full (must be ≤10 lines by design)
5. Escalate to MEMORY.md, DECISIONS.md, STAKEHOLDERS.md, RESOURCES.md only when needed
6. MEMORY.md: read last 80 lines only — search on demand if more needed

Only load the workstream directory matching the active thread.
Do not load all workstreams — keep context clean.

Projects live in: `projects/[project-name]/`
Workstream directories live in: `projects/[project]/workstreams/[workstream-name]/`

Always emit acknowledgment BEFORE loading any context files. Never let file reads block the first response token.

Platform startup modes:
- Discord / Slack (LIGHT): ACK → BRIEF + STATUS → escalate only if needed
- Telegram / CLI (FULL): BRIEF + STATUS + MEMORY before first response

Recovery: if session is degraded, reconstruct from workstream files — not transcript.
Isolation: do not read other workstream files by default.

Before starting work on a task, claim it:
  tick claim TASK-X @agent-name

Before ending any working session:
1. Complete or release the task in tick.md
2. Update STATUS.md with:
   - What was done this session
   - Current workstream phase
   - Any blockers
3. If the workstream's MEMORY.md exceeds 80 lines (target ≤50), consolidate — summary, not log

This is required even if nothing changed. A blank STATUS.md means
the workstream is invisible to the next agent or session.
```

### 3. Copy WORKSTREAMS.md to your workspace

```bash
cp [intern-os-repo]/assets/WORKSTREAMS.md [workspace]/WORKSTREAMS.md
```

### 4. Create the projects directory

```bash
mkdir -p [workspace]/projects/
```

### 5. Initialize your first project

```bash
PROJECT=my-project
mkdir -p [workspace]/projects/$PROJECT
cd [workspace]/projects/$PROJECT
tick init
tick agent register @agent-name --type bot --role engineer
```

### 6. Restart the agent

Apply instruction changes by restarting the agent session.

---

## Verification

- [ ] Agent instructions include the internOS block
- [ ] WORKSTREAMS.md exists in the workspace root
- [ ] `projects/` directory exists
- [ ] At least one project initialized with tick.md
- [ ] Agent registered: `cd projects/[project] && tick agent list`
- [ ] Agent restarted

---

## Next step

Follow **PLAYBOOK.md** to activate your first workstream.

---

## Uninstall

### 1. Remove the internOS instructions from your agent

Remove the `## internOS — Workstreams` section from your agent's instruction file or system prompt.

### 2. Remove WORKSTREAMS.md from the workspace

```bash
rm [workspace]/WORKSTREAMS.md
```

### 3. Restart the agent

Apply changes by restarting the agent session.

### 4. (Optional) Remove workspace data

The steps above remove the internOS framework but **preserve your project data** (projects, workstreams, TICK.md, task history). To remove everything:

```bash
rm -rf [workspace]/projects/
```

> **Warning:** This deletes all project directories, workstream files, task history, and accumulated context. This cannot be undone.
