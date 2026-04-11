# SETUP — Claude Code Adapter

*internOS v0.3.0 | 2026-04-11*

Claude Code-specific setup for the internOS Workstreams framework.

---

## Prerequisites

- Claude Code CLI installed
- A project directory where you work

---

## Setup

### 1. Install tick.md

```bash
npm install -g tick-md
```

### 2. Copy CLAUDE.md to your project

```bash
cp [intern-os-repo]/adapters/claude-code/CLAUDE.md [your-project]/CLAUDE.md
```

Claude Code automatically reads `CLAUDE.md` in the project root as project instructions.

### 3. Copy WORKSTREAMS.md

```bash
cp [intern-os-repo]/assets/WORKSTREAMS.md [your-project]/WORKSTREAMS.md
```

### 4. Create the projects directory

```bash
mkdir -p [your-project]/projects/
```

### 5. Initialize your first project

```bash
PROJECT=my-project
mkdir -p [your-project]/projects/$PROJECT
cd [your-project]/projects/$PROJECT
tick init
tick agent register @claude-code --type bot --role engineer
```

---

## How it works

Claude Code reads `CLAUDE.md` at the start of every session. The internOS instructions tell it to:

1. Check for `WORKSTREAMS.md`
2. Load the active workstream context
3. Claim tasks in tick.md before working
4. Update STATUS.md at session end

No skill installation, no restart needed — `CLAUDE.md` is loaded automatically.

---

## Verification

- [ ] `CLAUDE.md` exists in the project root with internOS instructions
- [ ] `WORKSTREAMS.md` exists in the project root
- [ ] `projects/` directory exists
- [ ] At least one project initialized with tick.md
- [ ] Agent registered: `cd projects/[project] && tick agent list`

---

## Next step

Follow **PLAYBOOK.md** to activate your first workstream.

---

## Uninstall

### 1. Remove CLAUDE.md (or the internOS section)

If CLAUDE.md contains only internOS instructions:

```bash
rm [your-project]/CLAUDE.md
```

If CLAUDE.md has other project instructions, edit it and remove the `## internOS — Workstreams` section.

### 2. Remove WORKSTREAMS.md

```bash
rm [your-project]/WORKSTREAMS.md
```

### 3. (Optional) Remove workspace data

The steps above remove the internOS framework but **preserve your project data** (projects, workstreams, TICK.md, task history). To remove everything:

```bash
rm -rf [your-project]/projects/
```

> **Warning:** This deletes all project directories, workstream files, task history, and accumulated context. This cannot be undone.
