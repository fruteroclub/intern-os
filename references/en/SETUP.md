# SETUP — Configure internOS on an OpenClaw Instance

*internOS v1.0 | 2026-03-26*

Guide for the admin or human configuring a new OpenClaw instance to use the Workstreams Operating System.

> **Current communication layer: Discord.** This setup assumes Discord as the communication surface. Other channels (Slack, Telegram, WhatsApp, etc.) are not yet defined for this system.

---

## Prerequisites

- OpenClaw installed and running on the instance
- Access to the agent workspace (`~/.openclaw/workspace/` by default)
- Discord bot configured on the project's server
- A task management system (see options below)

---

## Step 1: Add the internOS block to `AGENTS.md`

Open `~/workspace/AGENTS.md` and add this section:

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

---

## Step 2: Copy `WORKSTREAMS.md` to the workspace

The skill includes the file ready to use. Copy it to the workspace root:

```bash
cp ~/.openclaw/skills/intern-os/assets/WORKSTREAMS.md ~/workspace/WORKSTREAMS.md
```

> If the agent installed the skill via `openclaw skills install`, the file is at `~/.openclaw/skills/intern-os/assets/WORKSTREAMS.md`.

---

## Step 3: Create the `active-workstreams/` directory

```bash
mkdir -p ~/workspace/active-workstreams/
```

---

## Step 4: Create forums in Discord

Create forums in the project's Discord server. Naming convention: `[area]-workstreams`.

Minimum recommended forums by team size:

| Forum | When to create |
|-------|----------------|
| `ops-workstreams` | Always — for internal systems and setup |
| `ceo-workstreams` | If there is a CEO/founder operating workstreams |
| `tech-workstreams` | If there is product development |
| `[area]-workstreams` | Based on the project's active areas |

**Rule:** workstreams live exclusively in forums, never in regular text channels.

---

## Step 5: Restart the agent session

Changes to `AGENTS.md` take effect in the next session. Restart the agent or wait for the next session.

---

## Verification

Setup is complete when:

- [ ] `AGENTS.md` has the internOS block
- [ ] `WORKSTREAMS.md` exists in the workspace root
- [ ] `active-workstreams/` exists in the workspace
- [ ] At least one `[area]-workstreams` forum exists in Discord
- [ ] The agent has been restarted

---

## Task management system

Every workstream is born from a task. Choose the system that best fits the project:

| Option | When to use |
|--------|-------------|
| **tick.md** ⭐ *recommended* | Quick start, small teams, agent-first. Markdown + Git, zero infrastructure. [Docs](https://www.tick.md/docs) |
| **Notion** | If the team already uses Notion with a validated project and task kanban |
| **Trello / Asana / Linear** | If the team already has an established kanban |
| **Simple to-do list** | Todoist or similar — works for small teams with few workstreams |

**Key point:** any system works as long as it allows creating a task with a name, status, and owner. A workstream cannot exist without an associated task.

---

## Next step

With setup complete, activate the first workstream by following **PLAYBOOK.md**.
