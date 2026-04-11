# SETUP — OpenClaw Adapter

*internOS v0.3.0 | 2026-04-11*

OpenClaw-specific setup for the internOS Workstreams framework.

---

## Prerequisites

- OpenClaw installed and running on the instance
- Access to the agent workspace (`~/.openclaw/workspace/` by default)

---

## Install the skill

```
openclaw skills install https://github.com/fruteroclub/intern-os
```

---

## Configure the agent

### 1. Add the internOS block to AGENTS.md

Open `~/.openclaw/workspace/AGENTS.md` and add the following section after the "Every Session" block:

```markdown
## internOS — Workstreams

If `WORKSTREAMS.md` exists in the workspace root, read it at the start
of any session in a communication thread that has a workstream context.

### Resolution

Resolve the workstream by exact `thread_id` in BRIEF.md.
If no exact match exists, stop and ask — never guess.
Never resolve by fuzzy matching, keyword similarity, or path proximity.

### Loading order

1. Resolve workstream by exact `thread_id`
2. Read `projects/[project]/AGENTS.md` (project-level context, if exists)
3. Read `BRIEF.md` in full (workstream identity + thread_id)
4. Read `STATUS.md` in full (must be ≤10 lines by design)
5. Escalate to MEMORY.md, DECISIONS.md, STAKEHOLDERS.md, RESOURCES.md only when the task requires it
6. MEMORY.md: read last 80 lines only — search on demand if more context needed

Only load the workstream directory matching the active thread.
Do not load all workstreams — keep context clean.

Projects live in: `projects/[project-name]/`
Workstream directories live in: `projects/[project]/workstreams/[workstream-name]/`

### Platform startup protocol

**Always emit acknowledgment before any file reads.** Never let file reads block the first response token.

| Platform | Mode | Rule |
|----------|------|------|
| Discord | LIGHT | ACK → BRIEF + STATUS → escalate only if needed |
| Slack | LIGHT | ACK → BRIEF + STATUS → escalate only if needed |
| Telegram / CLI | FULL | BRIEF + STATUS + MEMORY before first response |

**MEMORY.md hygiene:** must stay ≤80 lines (target ≤50). Curated summary only — move detailed notes to `docs/`. Consolidate before ending the session if over threshold.

### Recovery doctrine

If session is degraded, bloated, or reset: reconstruct from workstream files.
Do not trust transcript continuity. BRIEF.md + STATUS.md must be sufficient to restart.

### Isolation doctrine

Do not read another workstream's files by default.
Cross-workstream synthesis must be explicit.

### Before starting work on a task
  tick claim TASK-X @agent-name

### Before ending any working session
1. Complete or release the task in tick.md
2. Update STATUS.md with:
   - What was done this session
   - Current workstream phase
   - Any blockers
3. If the workstream's MEMORY.md exceeds 80 lines (target ≤50), consolidate — summary, not log

This is required even if nothing changed. A blank STATUS.md means
the workstream is invisible to the next agent or session.
```

### 2. Copy WORKSTREAMS.md

```bash
cp ~/.openclaw/skills/intern-os/assets/WORKSTREAMS.md ~/.openclaw/workspace/WORKSTREAMS.md
```

### 3. Create the projects directory

```bash
mkdir -p ~/.openclaw/workspace/projects/
```

### 4. Initialize your first project

```bash
PROJECT=my-project
mkdir -p ~/.openclaw/workspace/projects/$PROJECT
cd ~/.openclaw/workspace/projects/$PROJECT
tick init
tick agent register @agent-name --type bot --role engineer
```

### 5. Restart the agent session

Changes to AGENTS.md take effect in the next session. Restart the agent or wait for the next session.

---

## Verification

- [ ] Skill installed via `openclaw skills install`
- [ ] AGENTS.md has the internOS block
- [ ] WORKSTREAMS.md exists at `~/.openclaw/workspace/WORKSTREAMS.md`
- [ ] `projects/` directory exists
- [ ] At least one project initialized with tick.md
- [ ] Agent restarted

---

## Next step

Follow **PLAYBOOK.md** to activate your first workstream.

---

## Uninstall

### 1. Remove the skill

```bash
openclaw skills uninstall intern-os
```

### 2. Remove the internOS block from AGENTS.md

Open `~/.openclaw/workspace/AGENTS.md` and remove the `## internOS — Workstreams` section.

### 3. Remove WORKSTREAMS.md from the workspace

```bash
rm ~/.openclaw/workspace/WORKSTREAMS.md
```

### 4. Restart the agent session

Changes take effect in the next session.

### 5. (Optional) Remove workspace data

The steps above remove the internOS framework but **preserve your project data** (projects, workstreams, TICK.md, task history). To remove everything:

```bash
rm -rf ~/.openclaw/workspace/projects/
```

> **Warning:** This deletes all project directories, workstream files, task history, and accumulated context. This cannot be undone.
