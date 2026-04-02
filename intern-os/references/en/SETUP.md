# SETUP — Configure internOS on an Agent Instance

*internOS v2.0 | 2026-03-30*

Guide for the admin or human configuring an agent instance to use the internOS Workstreams framework.

---

## Prerequisites

- An AI agent framework installed and running (OpenClaw, Hermes Agent, Claude Code, or other)
- Access to the agent's workspace directory
- A communication platform configured (Discord or Slack — see COMMUNICATION.md)
- Node.js installed (for tick.md CLI)

---

## Step 1: Install tick.md

```bash
npm install -g tick-md
tick --version
```

Or use without global install:

```bash
npx tick-md --version
```

---

## Step 2: Configure your agent framework

Each agent framework has its own setup mechanism. Follow the guide for your framework:

| Framework | Adapter | Setup guide |
|-----------|---------|-------------|
| OpenClaw | `adapters/openclaw/` | `adapters/openclaw/SETUP.md` |
| Hermes Agent | `adapters/hermes/` | `adapters/hermes/SETUP.md` |
| Claude Code | `adapters/claude-code/` | `adapters/claude-code/SETUP.md` |
| Other | `adapters/generic/` | `adapters/generic/SETUP.md` |

This step configures the agent to read `WORKSTREAMS.md` and follow the internOS protocol.

---

## Step 3: Copy `WORKSTREAMS.md` to the workspace

Copy the agent runtime guide to the workspace root:

```bash
cp [skill-path]/assets/WORKSTREAMS.md [workspace]/WORKSTREAMS.md
```

The exact paths depend on your agent framework — see the adapter setup guide.

---

## Step 4: Create the `projects/` directory

```bash
mkdir -p [workspace]/projects/
```

---

## Step 5: Create your first project

```bash
PROJECT=my-project
mkdir -p [workspace]/projects/$PROJECT
cd [workspace]/projects/$PROJECT

# Initialize tick.md
tick init

# Register the agent
tick agent register @agent-name --type bot --role engineer
```

Or use the project template (includes pre-configured TICK.md and .tick/config.yml):

```bash
PROJECT=my-project
cp -r [skill-path]/assets/templates/project/ [workspace]/projects/$PROJECT
cd [workspace]/projects/$PROJECT
tick agent register @agent-name --type bot --role engineer
```

---

## Step 6: Set up communication channels

Create channels or forums for your workstream areas. See COMMUNICATION.md for the full specification.

### Discord

Create forums in the project's Discord server. Naming convention: `[area]-workstreams`.

| Forum | When to create |
|-------|----------------|
| `ops-workstreams` | Always — for internal systems and setup |
| `ceo-workstreams` | If there is a CEO/founder operating workstreams |
| `tech-workstreams` | If there is product development |
| `[area]-workstreams` | Based on the project's active areas |

**Rule:** workstreams live exclusively in forums, never in regular text channels.

### Slack

Create channels in the project's Slack workspace. Same naming convention: `[area]-workstreams`.

| Channel | When to create |
|---------|----------------|
| `ops-workstreams` | Always — for internal systems and setup |
| `ceo-workstreams` | If there is a CEO/founder operating workstreams |
| `tech-workstreams` | If there is product development |
| `[area]-workstreams` | Based on the project's active areas |

**Rule:** workstreams use threads within these channels. The channel root is only for creating new workstream threads.

---

## Step 7: Restart the agent session

Agent instruction changes take effect in the next session. Restart the agent or wait for the next session.

---

## Verification

Setup is complete when:

- [ ] tick.md CLI is installed and working
- [ ] Agent framework is configured with internOS instructions (via adapter)
- [ ] `WORKSTREAMS.md` exists in the workspace root
- [ ] `projects/` directory exists
- [ ] At least one project is initialized with `tick init`
- [ ] Agent is registered in tick.md: `tick agent list`
- [ ] At least one `[area]-workstreams` channel/forum exists
- [ ] Agent has been restarted

---

## Task management system

tick.md is the default and recommended task system for internOS. It is deeply integrated into the framework — the project template, agent workflow, and coordination protocol are built around it.

| Option | When to use |
|--------|-------------|
| **tick.md** ⭐ *default* | Agent-first, markdown + Git, zero infrastructure. [Docs](https://www.tick.md/docs) |
| **Notion** | If the team already uses Notion with a validated project and task kanban |
| **Trello / Asana / Linear** | If the team already has an established kanban |
| **Simple to-do list** | Todoist or similar — works for small teams with few workstreams |

If using a system other than tick.md, the task system provides the management layer but the agent cannot use `tick` CLI commands. See TICK-INTEGRATION.md for details on what changes.

---

## Next step

With setup complete, activate the first workstream by following **PLAYBOOK.md**.
