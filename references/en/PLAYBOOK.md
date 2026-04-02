# PLAYBOOK — Operating Workstreams Day to Day

*internOS v2.1 | 2026-03-31*

This guide explains how to use the internOS Workstreams system: how to create projects, activate workstreams, work sessions, and manage the lifecycle.

---

> **First time?** Before using this playbook, configure the instance by following **SETUP.md**.

---

## How to activate a workstream

Any team member can activate a workstream from any communication thread, talking to any agent. The agent creates what's missing: a task in tick.md, a communication thread, and a directory in the filesystem.

**Activation format (flexible):**

> Activate workstream: [name] in project: [project]
> Task: [task name or link] *(optional if already exists)*
> Thread: [channel/forum or thread] *(optional if already exists)*

Or simply describe what you want to do and the agent will ask for what it needs.

---

## Entry points

A workstream can be started from any of these situations:

### Entry A: From scratch

Nothing exists yet. The agent creates everything in order:
1. Task in tick.md: `tick add "Description" --tag workstream-name`
2. Communication thread in the appropriate `[area]-workstreams` channel/forum
3. Directory in `projects/[project]/workstreams/`
4. Requests BRIEF to be filled with the 6 questions

### Entry B: Task already exists in tick.md

The agent:
1. Identifies the existing task
2. Creates the communication thread
3. Creates the workstream directory
4. Links everything in RESOURCES.md

### Entry C: Communication thread already exists

The agent:
1. Reads the thread context
2. Creates or links the task in tick.md
3. Creates the workstream directory
4. Links everything in RESOURCES.md

### Entry D: Project exists, adding a new workstream

The agent:
1. Adds a task in the existing project's TICK.md
2. Creates the communication thread
3. Scaffolds the workstream directory
4. Links everything

### Entry E: New project (no project exists yet)

The agent:
1. Creates `projects/[name]/PROJECT.md` using the project template
2. Runs `tick init` and registers the agent
3. Opens a communication thread for the project
4. Asks the 4 discovery questions (domain, exclusions, owner, archive condition)
5. Once PROJECT.md is filled, the project is ready for workstreams

**Activation format:**

> Discover project: [name]

---

## What the agent creates at each step

### 1. Task in tick.md

```bash
cd projects/[project]
tick add "Workstream description" --tag workstream-name --priority high
```

### 2. Communication thread

The agent creates the thread in the appropriate `[area]-workstreams` channel/forum with this format:

```
**[Workstream name]**

What: [one line]
Owner: [name]
Task: TASK-001 (or external URL)
Directory: projects/[project]/workstreams/[name]/
Status: [current phase — one line]
```

> **Persistent context:** this message is the context anchor for the agent. Keep it updated as the workstream progresses. See COMMUNICATION.md for platform-specific details.

### 3. Workstream directory

```bash
PROJECT=project-name
WS=workstream-name

# Using templates (recommended)
cp -r [skill-path]/assets/templates/workstream/ projects/$PROJECT/workstreams/$WS/
mkdir -p projects/$PROJECT/workstreams/$WS/docs

# Or manually
mkdir -p projects/$PROJECT/workstreams/$WS/docs
touch projects/$PROJECT/workstreams/$WS/{BRIEF.md,STATUS.md,MEMORY.md,DECISIONS.md,STAKEHOLDERS.md,RESOURCES.md}
```

### 4. BRIEF.md — 6 questions

The agent asks them one by one, or the human answers them all at once:

1. What specific work is this? *(verb + object)*
2. What problem or situation triggers it?
3. Who needs it and for what purpose?
4. What does it deliver when done? *(outcome, not output)*
5. What is in scope? What is out of scope?
6. What is the appetite? *(maximum time or effort)*

After filling, add the thread mapping:

```yaml
thread_id: [platform]:[id]
```

### 5. RESOURCES.md — initial links

```markdown
## Links

- **Task:** TASK-001 in TICK.md (or external URL)
- **Thread:** [platform]:[thread URL]
- **Directory:** projects/[project]/workstreams/[name]/
```

---

## Working a session

When an agent enters a workstream thread, it follows this protocol:

### Starting work

1. Read `WORKSTREAMS.md` (agent runtime guide)
2. Identify the workstream from the thread context
3. Read the workstream files: BRIEF.md → STATUS.md → MEMORY.md
4. Check current tasks: `tick list --tag [workstream-name]`
5. Claim the task to work on: `tick claim TASK-X @agent-name`

### During work

- Do the work described in the task
- Add progress notes if useful: `tick comment TASK-X @agent-name --note "Progress"`

### Ending a session

1. **Complete the task** (if done): `tick done TASK-X @agent-name`
2. **Or release** (if pausing): `tick release TASK-X @agent-name`
3. **Update STATUS.md** with:
   - What was done this session
   - Current workstream phase
   - Any blockers
4. **Update MEMORY.md** if there are new insights or context worth preserving

> This is required even if nothing changed. A blank STATUS.md means the workstream is invisible to the next agent or session.

---

## Communication channel classification

Workstreams are created in dedicated channels/forums, classified by the area responsible for the workstream.

**Naming convention:** `[area]-workstreams` — applies to both Discord forums and Slack channels.

**Classification rule:** the channel is determined by who owns the workstream, not the topic.

**Thread rule:** workstreams live in threads (Discord forum posts or Slack threads). Regular channel messages are for direct agent interaction, not workstreams.

> Each project defines its own channels based on its active areas. See SETUP.md for creation guidance.

---

## Activation checklist

- [ ] Task created in tick.md and tagged with workstream name
- [ ] Communication thread created in the correct `[area]-workstreams` channel/forum
- [ ] Directory in `projects/[project]/workstreams/` with the 6 files
- [ ] BRIEF.md completed with 6 questions + thread_id
- [ ] RESOURCES.md with links to task and thread
- [ ] STATUS.md with initial state

✅ Workstream active. Work continues in the communication thread.

---

## Lifecycle management

### Pausing a workstream

- Release any claimed tasks: `tick release TASK-X @agent-name`
- Update STATUS.md with pause reason and blocker
- The communication thread stays open

### Resuming a workstream

- Read STATUS.md for context
- Check `tick list --tag [workstream-name]` for current task state
- Claim the next task and continue

### Archiving a workstream

When all tasks are complete:

1. Verify all tasks are done: `tick list --tag [workstream-name]` — all should be `done`
2. Update STATUS.md with final state and learnings
3. Archive the communication thread (Discord: archive thread, Slack: leave thread or note completion)
4. Move the directory:
   ```bash
   mv projects/[project]/workstreams/[name] projects/[project]/workstreams/archived/[name]
   ```
