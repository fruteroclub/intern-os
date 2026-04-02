# Workstreams — internOS

*v2.1*

---

## What is this

internOS is a framework for humans and agents to collaborate on workstreams without losing context between sessions. This file applies to any agent operating in this workspace.

---

## The four layers

| Layer | Tool | Role |
|-------|------|------|
| Project | Filesystem (`projects/[name]/`) | Organizational container |
| Management | tick.md (`TICK.md` at project root) | Task origin and coordination |
| Communication | Discord forums · Slack threads | Team surface — humans and agents |
| Operation | `projects/[name]/workstreams/` | Source of truth for agents |

---

## If you are in a communication thread

1. **Check if the thread has a workstream directory** in `projects/[project]/workstreams/`
2. **If it exists, read it before doing anything:**
   - `BRIEF.md` → what this workstream is + thread_id mapping
   - `STATUS.md` → where the work stands now
   - `MEMORY.md` → accumulated context and insights
3. **Load only that directory.** Do not load other workstreams.
4. **Check tasks:** `tick list --tag [workstream-name]`
5. **Claim the task before working:** `tick claim TASK-X @agent-name`
6. **When done**, update `STATUS.md` with the current state and complete/release the task in tick.md.

---

## Project vs. workstream

> A **project** groups work of the same domain over time — it can contain multiple workstreams.
> A **workstream** is a concrete sprint of work with a start and end within that domain.

If the work needs multiple independent workstreams, or covers an area with its own identity (infra, product, ops, content) → **project**.
If it's scoped work inside an existing area → **workstream** in that project.

---

## Project discovery

To create a new project, any team member says:

> Discover project: [name]

The agent creates `projects/[name]/` with `PROJECT.md`, runs `tick init`, registers the agent, and opens a communication thread. It then asks:

1. What domain does this project group?
2. What does NOT belong in this project?
3. Who is the human owner?
4. When will this project be done or ready to archive?

Unanswered questions are marked `TBD` — the project proceeds.

---

## Project structure

```
projects/
├── project-alpha/
│   ├── PROJECT.md           ← Project brief: domain, owner, boundaries
│   ├── TICK.md              ← tick-md: all tasks for this project
│   ├── .tick/
│   └── workstreams/
│       └── [workstream-name]/
│           ├── BRIEF.md
│           ├── STATUS.md
│           ├── MEMORY.md
│           ├── DECISIONS.md
│           ├── STAKEHOLDERS.md
│           ├── RESOURCES.md
│           └── docs/
```

---

## Workstream structure

```
workstreams/[name]/
├── BRIEF.md         ← What, for whom, problem, appetite + thread_id
├── STATUS.md        ← Workstream phase, next step, blockers
├── MEMORY.md        ← Accumulated context, insights, learnings
├── DECISIONS.md     ← Key decisions log with date + reason
├── STAKEHOLDERS.md  ← Relevant people and their role
├── RESOURCES.md     ← Artifacts index and where they live
└── docs/            ← Working artifacts
```

---

## Write protocol

| Actor | Writes when... |
|-------|----------------|
| **Agent** | At the end of a working session in the thread |
| **Human** | Strategic decision, change of direction, new information |

**Golden rule:** If you cannot read `STATUS.md` and know where the workstream stands, it is outdated — update it.

---

## Lifecycle

### Project lifecycle

```
Discover project → PROJECT.md + tick init + thread
    → Workstreams activated within the project
        → All workstreams archived
            → PROJECT.md updated with final state
                → Project directory moved to projects/archived/
```

### Workstream lifecycle

```
Activate workstream → Task in TICK.md + thread + directory
    → Work sessions in thread
        → All tasks done in TICK.md
            → STATUS.md updated with final state
                → Thread archived
                    → Directory moved to workstreams/archived/
```

---

## Full reference

See `FRAMEWORK.md`, `SETUP.md`, `PLAYBOOK.md`, `COMMUNICATION.md`, and `TICK-INTEGRATION.md` in the internOS references.
