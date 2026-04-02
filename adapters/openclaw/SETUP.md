# SETUP — OpenClaw Adapter

*internOS v2.0 | 2026-03-30*

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

Open `~/.openclaw/workspace/AGENTS.md` and add the internOS section. The full block is in `adapters/openclaw/SKILL.md` under "Add the internOS block to AGENTS.md".

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
