# Workstreams — internOS

*v1.0*

---

## What is this

internOS is a framework for humans and agents to collaborate on workstreams without losing context between sessions. This file applies to any agent operating in this workspace.

---

## The three layers

| Layer | Tool | Role |
|-------|------|------|
| Management | Team task system (tick.md, Notion, Trello, etc.) | Workstream origin |
| Communication | Discord (forum threads) | Team surface — humans and agents |
| Operation | `workstreams/` | Source of truth for agents |

---

## If you are in a Discord thread

1. **Check if the thread has a mirror directory** in `workstreams/`
2. **If it exists, read it before doing anything:**
   - `BRIEF.md` → what this workstream is
   - `STATUS.md` → where the work stands now
   - `MEMORY.md` → accumulated context and insights
3. **Load only that directory.** Do not load other workstreams.
4. **When done**, update `STATUS.md` with the current state.

---

## Workstream structure

```
workstreams/[name]/
├── BRIEF.md         ← What, for whom, problem, appetite
├── STATUS.md        ← Current phase, next step, blockers
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

```
Task created in task system
    → Thread opened in Discord forum
        → Directory created in workstreams/

Task marked complete/archived
    → STATUS.md updated with final state
        → Discord thread archived
            → Directory moved to workstreams/archived/
```

---

## Full reference

See `SETUP.md`, `PLAYBOOK.md`, and `FRAMEWORK.md` in the internOS workstream docs.
