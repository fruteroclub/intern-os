# PLAYBOOK — Workstreams Operating System

*internOS v1.0 | 2026-03-24*

This guide explains how to use the internOS Workstreams system: how to activate and operate a workstream day to day.

> **Current communication layer: Discord.** The persistent context mechanism described in this playbook (thread starter as context anchor) currently applies to Discord only. Other channels (Slack, Telegram, WhatsApp, etc.) are not yet defined or configured for this system.

---

> **First time?** Before using this playbook, configure the instance by following **SETUP.md**.

---

## How to activate a workstream

Any team member can activate a workstream from any Discord channel, talking to any agent. The agent takes care of creating what's missing: a task in the management system, a post in Discord, and a directory in the filesystem.

**Activation format (flexible):**

> Activate workstream: [name]
> Task: [task name or link] *(optional if already exists)*
> Discord: [forum or thread] *(optional if already exists)*

Or simply describe what you want to do and the agent will ask for what it needs.

---

## Three entry points

A workstream can be started from any of these situations:

### Entry A: From scratch

Nothing exists yet. The agent creates everything in order:
1. Task in the team's task management system
2. Post in the corresponding Discord forum
3. Directory in `active-workstreams/`
4. Requests BRIEF to be filled with the 6 questions

### Entry B: Task already exists

The agent:
1. Asks for the task link or name
2. Creates the post in the corresponding Discord forum
3. Creates the directory in `active-workstreams/`
4. Links everything in RESOURCES.md

### Entry C: Discord post already exists

The agent:
1. Asks for the Discord post link or name
2. Creates or links the task in the management system if it doesn't exist
3. Creates the directory in `active-workstreams/`
4. Links everything in RESOURCES.md

---

## Discord forum classification

Discord workstreams are created **exclusively in forums**, classified by the area responsible for the workstream. Naming convention: `[area]-workstreams`.

**Classification rule:** the forum is determined by who owns the workstream, not the topic.

**Channel rule:** no workstream lives in a regular text channel. Those channels are for direct agent interaction, not workstreams.

> Each project defines its own forums based on its active areas. See SETUP.md for creation guidance.

---

## What the agent creates at each step

### 1. Task in the task management system

Create a task in whatever system the team uses.

Minimum fields: **Name**, **Status** (in progress), **Owner**, **One-line description**

> tick.md is the recommended option for quick start — Markdown + Git, no additional infrastructure. See [tick.md/docs](https://www.tick.md/docs)

### 2. Discord post

The agent creates the post in the corresponding forum with this format:

```
**[Workstream name]**

What: [one line]
Owner: [name]
Task: [URL or reference in the task system]
Directory: active-workstreams/[kebab-name]/
Status: [current phase — one line]
```

> **Persistent context mechanism (Discord):** the thread's original post is injected in every channel message, including during context compaction. This is the most reliable way for the agent to always know which workstream it's in and where to read more. This mechanism currently applies to Discord only.

### 3. Filesystem directory

```bash
WS=workstream-name

mkdir -p ~/workspace/active-workstreams/$WS/docs
touch ~/workspace/active-workstreams/$WS/BRIEF.md
touch ~/workspace/active-workstreams/$WS/STATUS.md
touch ~/workspace/active-workstreams/$WS/MEMORY.md
touch ~/workspace/active-workstreams/$WS/DECISIONS.md
touch ~/workspace/active-workstreams/$WS/STAKEHOLDERS.md
touch ~/workspace/active-workstreams/$WS/RESOURCES.md
```

### 4. BRIEF.md — 6 questions

The agent asks them one by one, or the human answers them all at once:

1. What specific work is this? *(verb + object)*
2. What problem or situation triggers it?
3. Who needs it and for what purpose?
4. What does it deliver when done? *(outcome, not output)*
5. What is in scope? What is out of scope?
6. What is the appetite? *(maximum time or effort)*

### 5. RESOURCES.md — initial links

```markdown
## Links

- **Task:** [URL or reference in the task system]
- **Discord:** [post URL]
- **Directory:** active-workstreams/[name]/
```

---

## Activation checklist

- [ ] Task created in the task system and linked
- [ ] Post created in the correct Discord forum
- [ ] Directory in `active-workstreams/` with the 6 files
- [ ] BRIEF.md completed
- [ ] RESOURCES.md with links to task and Discord
- [ ] STATUS.md with initial state

✅ Workstream active. Work continues in the Discord post.
