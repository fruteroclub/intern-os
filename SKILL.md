---
name: intern-os
description: Install and operate the internOS Workstreams framework for OpenClaw agents. Use when setting up a new OpenClaw instance to use internOS, activating the workstreams system, or when an agent needs to understand how to work with workstreams in a Discord thread. Triggers on phrases like "install internOS", "set up workstreams", "configure internOS", "activate workstreams framework", or when operating in a Discord workstream thread and WORKSTREAMS.md does not yet exist in the workspace.
---

# internOS — Workstreams Module

internOS is a framework for humans and agents to collaborate on workstreams without losing context between sessions. Each workstream exists in two places simultaneously: a Discord forum thread (communication surface) and a filesystem directory (source of truth for agents).

## Installing internOS (first time setup)

Run these three steps:

**1. Copy WORKSTREAMS.md to workspace root**

Copy `assets/WORKSTREAMS.md` from this skill to `~/workspace/WORKSTREAMS.md`.

**2. Add the internOS block to AGENTS.md**

Add this section to `~/workspace/AGENTS.md`, after the "Every Session" block:

```markdown
## internOS — Workstreams

If `WORKSTREAMS.md` exists in the workspace root, read it at the start
of any session in a Discord thread that has a workstream context.

Only load the workstream directory matching the active thread.
Do not load all workstreams — keep context clean.

Workstream directories live in: `active-workstreams/[workstream-name]/`
Read: BRIEF.md, STATUS.md, MEMORY.md before doing any work.

Before ending any working session, update STATUS.md with:
1. What was done this session
2. Next concrete step
3. Any blockers

This is required even if nothing changed. A blank STATUS.md means
the workstream is invisible to the next agent or session.
```

**3. Create the workstreams directory**

```bash
mkdir -p ~/workspace/active-workstreams/
```

Restart the agent session for AGENTS.md changes to take effect.

## Operating a workstream

When in a Discord thread that has a workstream context:

1. Read `WORKSTREAMS.md` for the full operating guide
2. Find the matching directory in `active-workstreams/[name]/`
3. Read BRIEF.md → STATUS.md → MEMORY.md before doing any work
4. Update STATUS.md at the end of the session

## Activating a new workstream

Any team member can activate a workstream from any channel:

> Activate workstream: [name]
> Task: [task link or name] *(optional if already exists)*
> Discord: [forum or thread] *(optional if already exists)*

The agent creates what's missing: task in the management system, Discord post in the right forum, and directory scaffold in `active-workstreams/`.

**Directory scaffold:**
```bash
WS=workstream-name
mkdir -p ~/workspace/active-workstreams/$WS/docs
touch ~/workspace/active-workstreams/$WS/{BRIEF.md,STATUS.md,MEMORY.md,DECISIONS.md,STAKEHOLDERS.md,RESOURCES.md}
```

Immediately after creating the directory, add the thread ID to `BRIEF.md`:
```
discord_thread_id: [thread ID from Discord URL or metadata]
```

This is the canonical mapping between the Discord thread and the filesystem directory. Without it, the link is implicit and fragile.

**Discord post format:**
```
**[Workstream name]**

What: [one line]
Owner: [name]
Task: [URL or reference]
Directory: active-workstreams/[name]/
Status: [current phase — one line]
```

> The Discord post is injected in every thread message, including during context compaction. It is the most reliable context persistence mechanism — keep it updated.

## Workstream file structure

```
active-workstreams/[name]/
├── BRIEF.md         ← What, for whom, problem, appetite
├── STATUS.md        ← Current phase, next step, blockers
├── MEMORY.md        ← Accumulated context, insights, learnings
├── DECISIONS.md     ← Key decisions log with date + reason
├── STAKEHOLDERS.md  ← Relevant people and their role
├── RESOURCES.md     ← Artifacts index and where they live
└── docs/            ← Working artifacts
```

## Forum classification

Workstreams live exclusively in Discord forums, named `[area]-workstreams`. The forum is determined by who owns the workstream, not the topic.

## Full documentation

- `references/SETUP.md` — step-by-step setup guide for new instances
- `references/PLAYBOOK.md` — how to activate and operate workstreams day-to-day
- `references/FRAMEWORK.md` — full technical reference (architecture, lifecycle, roadmap)
