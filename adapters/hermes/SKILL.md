---
name: intern-os
description: internOS Workstreams framework for Hermes Agent. Coordinates work across projects, tick.md tasks, communication threads, and filesystem workstreams. Load this skill when operating in a workstream thread or when setting up internOS.
version: 2.1.0
metadata:
  hermes:
    tags: [Workstreams, Project Management, Coordination]
    related_skills: []
---

# internOS — Workstreams Module (Hermes Adapter)

internOS is a framework for humans and agents to collaborate on workstreams without losing context between sessions. Each workstream exists in three places simultaneously: a tick.md task (management), a communication thread (collaboration), and a filesystem directory (source of truth).

## Installing internOS (first time setup)

**1. Install tick.md CLI**

```bash
npm install -g tick-md
```

**2. Copy WORKSTREAMS.md to the Hermes workspace**

```bash
cp ~/.hermes/skills/intern-os/assets/WORKSTREAMS.md ~/.hermes/workspace/WORKSTREAMS.md
```

**3. Create the projects directory**

```bash
mkdir -p ~/.hermes/workspace/projects/
```

**4. Create your first project**

```bash
PROJECT=my-project
mkdir -p ~/.hermes/workspace/projects/$PROJECT
cd ~/.hermes/workspace/projects/$PROJECT
tick init
tick agent register @hermes-agent --type bot --role engineer
```

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
3. Opens a communication thread in Slack (or Discord) for the project
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

When in a communication thread (Slack thread or Discord forum post) that has a workstream context:

1. Read `WORKSTREAMS.md` for the operating guide
2. Find the matching directory in `projects/[project]/workstreams/[name]/`
3. Read BRIEF.md → STATUS.md → MEMORY.md before doing any work
4. Check tasks: `tick list --tag [workstream-name]`
5. Claim the task: `tick claim TASK-X @hermes-agent`
6. Do the work
7. Update STATUS.md at the end of the session
8. Complete or release the task: `tick done TASK-X @hermes-agent`

## Activating a new workstream

Any team member can activate a workstream from any thread:

> Activate workstream: [name] in project: [project]

The agent creates what's missing: task in tick.md, communication thread, and workstream directory scaffold.

**Directory scaffold:**
```bash
PROJECT=project-name
WS=workstream-name
mkdir -p ~/.hermes/workspace/projects/$PROJECT/workstreams/$WS/docs
touch ~/.hermes/workspace/projects/$PROJECT/workstreams/$WS/{BRIEF.md,STATUS.md,MEMORY.md,DECISIONS.md,STAKEHOLDERS.md,RESOURCES.md}
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

## Slack thread-only mode

When operating in Slack, the Hermes agent:
- Responds **only inside threads**, never in channel root
- Reads the thread root message for workstream context on entry
- Maps the thread to a workstream via `thread_id: slack:[channel_id]/[thread_ts]` in BRIEF.md

Configure thread-only mode in the Hermes gateway config (see `adapters/hermes/SETUP.md`).

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
- Setup: `adapters/hermes/SETUP.md`
- Playbook: `references/en/PLAYBOOK.md`
- Communication: `references/en/COMMUNICATION.md`
- tick.md integration: `references/en/TICK-INTEGRATION.md`
