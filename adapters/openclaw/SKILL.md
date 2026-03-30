---
name: intern-os
description: Install and operate the internOS Workstreams framework for OpenClaw agents. Use when setting up a new OpenClaw instance to use internOS, activating the workstreams system, or when an agent needs to understand how to work with workstreams. Triggers on phrases like "install internOS", "set up workstreams", "configure internOS", "activate workstreams framework", or when operating in a workstream thread and WORKSTREAMS.md does not yet exist in the workspace.
---

# internOS — Workstreams Module (OpenClaw Adapter)

internOS is a framework for humans and agents to collaborate on workstreams without losing context between sessions. Each workstream exists in three places simultaneously: a tick.md task (management), a communication thread (collaboration), and a filesystem directory (source of truth).

## Installing internOS (first time setup)

Run these steps:

**1. Install tick.md CLI**

```bash
npm install -g tick-md
```

**2. Copy WORKSTREAMS.md to workspace root**

Copy `assets/WORKSTREAMS.md` from this skill to `~/workspace/WORKSTREAMS.md`.

**3. Add the internOS block to AGENTS.md**

Add this section to `~/workspace/AGENTS.md`, after the "Every Session" block:

```markdown
## internOS — Workstreams

If `WORKSTREAMS.md` exists in the workspace root, read it at the start
of any session in a communication thread that has a workstream context.

Only load the workstream directory matching the active thread.
Do not load all workstreams — keep context clean.

Projects live in: `projects/[project-name]/`
Workstream directories live in: `projects/[project]/workstreams/[workstream-name]/`
Read: BRIEF.md, STATUS.md, MEMORY.md before doing any work.

Before starting work on a task, claim it:
  tick claim TASK-X @agent-name

Before ending any working session:
1. Complete or release the task in tick.md
2. Update STATUS.md with:
   - What was done this session
   - Current workstream phase
   - Any blockers

This is required even if nothing changed. A blank STATUS.md means
the workstream is invisible to the next agent or session.
```

**4. Create the projects directory**

```bash
mkdir -p ~/workspace/projects/
```

**5. Create your first project**

```bash
cd ~/workspace/projects/[project-name]
tick init
tick agent register @agent-name --type bot --role engineer
```

Restart the agent session for AGENTS.md changes to take effect.

## Operating a workstream

When in a communication thread that has a workstream context:

1. Read `WORKSTREAMS.md` for the full operating guide
2. Find the matching directory in `projects/[project]/workstreams/[name]/`
3. Read BRIEF.md → STATUS.md → MEMORY.md before doing any work
4. Check tasks: `tick list --tag [workstream-name]`
5. Claim the task: `tick claim TASK-X @agent-name`
6. Update STATUS.md at the end of the session
7. Complete or release the task in tick.md

## Activating a new workstream

Any team member can activate a workstream:

> Activate workstream: [name] in project: [project]
> Task: [task name or link] *(optional if already exists)*
> Thread: [channel/forum or thread] *(optional if already exists)*

The agent creates what's missing: task in tick.md, communication thread, and workstream directory scaffold.

**Directory scaffold:**
```bash
PROJECT=project-name
WS=workstream-name
mkdir -p ~/workspace/projects/$PROJECT/workstreams/$WS/docs
touch ~/workspace/projects/$PROJECT/workstreams/$WS/{BRIEF.md,STATUS.md,MEMORY.md,DECISIONS.md,STAKEHOLDERS.md,RESOURCES.md}
```

Immediately after creating the directory, add the thread ID to `BRIEF.md`:
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
├── BRIEF.md         ← What, for whom, problem, appetite
├── STATUS.md        ← Workstream phase, next step, blockers
├── MEMORY.md        ← Accumulated context, insights, learnings
├── DECISIONS.md     ← Key decisions log with date + reason
├── STAKEHOLDERS.md  ← Relevant people and their role
├── RESOURCES.md     ← Artifacts index and where they live
└── docs/            ← Working artifacts
```

## Full documentation

- Framework: `references/en/FRAMEWORK.md`
- Setup: `adapters/openclaw/SETUP.md`
- Playbook: `references/en/PLAYBOOK.md`
- Communication: `references/en/COMMUNICATION.md`
- tick.md integration: `references/en/TICK-INTEGRATION.md`
