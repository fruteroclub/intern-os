# SETUP — Generic Adapter (Any Agent Framework)

*internOS v2.0 | 2026-03-30*

Manual setup for agent frameworks without a dedicated adapter.

---

## Prerequisites

- An AI agent framework that supports custom instructions or system prompts
- Access to the agent's workspace or working directory

---

## Setup

### 1. Install tick.md

```bash
npm install -g tick-md
```

### 2. Add internOS instructions to your agent

Add the following to your agent's instruction file, system prompt, or configuration:

```markdown
## internOS — Workstreams

If `WORKSTREAMS.md` exists in the workspace root, read it at the start
of any session in a communication thread that has a workstream context.

Only load the workstream directory matching the active thread.
Do not load all workstreams — keep context clean.

Projects live in: `projects/[project-name]/`
Workstream directories live in: `projects/[project]/workstreams/[workstream-name]/`

Reading workstream files:
- BRIEF.md: read in full
- STATUS.md: read in full (must be ≤10 lines by design)
- MEMORY.md: read last 80 lines only — search on demand if more needed

On platforms with short response timeouts (Discord ~2min, Slack ACK ~3s):
Emit a brief acknowledgment BEFORE loading any context files.
Never let file reads block the first response token.

Before starting work on a task, claim it:
  tick claim TASK-X @agent-name

Before ending any working session:
1. Complete or release the task in tick.md
2. Update STATUS.md with:
   - What was done this session
   - Current workstream phase
   - Any blockers
3. If MEMORY.md exceeds 80 lines, consolidate — summary, not log

This is required even if nothing changed. A blank STATUS.md means
the workstream is invisible to the next agent or session.
```

### 3. Copy WORKSTREAMS.md to your workspace

```bash
cp [intern-os-repo]/assets/WORKSTREAMS.md [workspace]/WORKSTREAMS.md
```

### 4. Create the projects directory

```bash
mkdir -p [workspace]/projects/
```

### 5. Initialize your first project

```bash
PROJECT=my-project
mkdir -p [workspace]/projects/$PROJECT
cd [workspace]/projects/$PROJECT
tick init
tick agent register @agent-name --type bot --role engineer
```

### 6. Restart the agent

Apply instruction changes by restarting the agent session.

---

## Verification

- [ ] Agent instructions include the internOS block
- [ ] WORKSTREAMS.md exists in the workspace root
- [ ] `projects/` directory exists
- [ ] At least one project initialized with tick.md
- [ ] Agent registered: `cd projects/[project] && tick agent list`
- [ ] Agent restarted

---

## Next step

Follow **PLAYBOOK.md** to activate your first workstream.
