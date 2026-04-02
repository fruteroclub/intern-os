# SETUP — OpenClaw Adapter

*internOS v2.1 | 2026-04-02*

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

Only load the workstream directory matching the active thread.
Do not load all workstreams — keep context clean.

Projects live in: `projects/[project-name]/`
Workstream directories live in: `projects/[project]/workstreams/[workstream-name]/`

### Reading workstream files (in the workstream directory, not your agent memory)
- BRIEF.md: read in full
- STATUS.md: read in full (must be ≤10 lines by design)
- MEMORY.md: read last 80 lines only — search on demand if more context needed

### Platform timeout protocol
On platforms with short response timeouts (Discord ~2min, Slack ACK ~3s):
Emit a brief acknowledgment BEFORE loading any context files.
Never let file reads block the first response token.

### Before starting work on a task
  tick claim TASK-X @agent-name

### Before ending any working session
1. Complete or release the task in tick.md
2. Update STATUS.md with:
   - What was done this session
   - Current workstream phase
   - Any blockers
3. If the workstream's MEMORY.md exceeds 80 lines, consolidate it — summary, not log

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
