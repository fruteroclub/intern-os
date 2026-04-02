---
name: intern-os
description: internOS Workstreams framework. Coordinates work across projects, tick.md tasks, communication threads, and filesystem workstreams. Load this skill when operating in a workstream thread or when setting up internOS.
version: 2.1.0
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

> A **project** groups work of the same domain over time — it can contain multiple workstreams.
> A **workstream** is a concrete sprint of work with a start and end within that domain.

**Rule of thumb:**
- If the work requires more than one independent workstream, or involves an operational area with its own identity (infra, product, ops, content, etc.) → it's a **project**.
- If it's a scoped piece of work inside an existing area → it's a **workstream** within that project.

## Discovering a new project

Any team member can create a new project:

> Discover project: [name]

The agent:

1. Creates `projects/[name]/PROJECT.md` using the project template
2. Runs `tick init` and registers the agent
3. Opens a communication thread (Slack or Discord) for the project
4. Asks the discovery questions:
   - **What domain or area does this project group?** *(one line)*
   - **What does NOT belong in this project?** *(explicit boundary)*
   - **Who is the human owner?**
   - **When will we know this project is done or ready to archive?**

If the human doesn't have an answer for any question, it's marked as `TBD` in `PROJECT.md` — the project can still be created.

## Project lifecycle

```
Discover project → PROJECT.md + tick init + thread
    → Workstreams activated within the project
        → All workstreams archived
            → PROJECT.md updated with final state
                → Project directory moved to projects/archived/
```

## Operating a workstream

When in a communication thread that has a workstream context:

1. Read `WORKSTREAMS.md` for the operating guide
2. Find the matching directory in `projects/[project]/workstreams/[name]/`
3. Read the workstream's files before doing any work (these are in the workstream directory, not your agent memory):
   - `BRIEF.md` — read in full
   - `STATUS.md` — read in full (must be ≤10 lines by design)
   - `MEMORY.md` — **last 80 lines only** (search on demand if more context needed)
4. Check tasks: `tick list --tag [workstream-name]`
5. Claim the task: `tick claim TASK-X @agent-name`
6. Do the work
7. Update STATUS.md at the end of the session
8. If the workstream's MEMORY.md exceeds 80 lines, consolidate — summary, not log
9. Complete or release the task: `tick done TASK-X @agent-name`

### Platform timeout protocol

On platforms with short response timeouts (Discord ~2min, Slack ACK ~3s):
Emit a brief acknowledgment BEFORE loading any context files. Never let file reads block the first response token.

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

Add the thread ID to BRIEF.md:
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
├── BRIEF.md         ← What, for whom, problem, appetite + thread_id
├── STATUS.md        ← Workstream phase, next step, blockers
├── MEMORY.md        ← Accumulated context, insights, learnings
├── DECISIONS.md     ← Key decisions log with date + reason
├── STAKEHOLDERS.md  ← Relevant people and their role
├── RESOURCES.md     ← Artifacts index and where they live
└── docs/            ← Working artifacts
```

## Full documentation

- Framework: `references/en/FRAMEWORK.md`
- Playbook: `references/en/PLAYBOOK.md`
- Communication: `references/en/COMMUNICATION.md`
- tick.md integration: `references/en/TICK-INTEGRATION.md`
- Framework-specific setup: `adapters/[framework]/SETUP.md`
