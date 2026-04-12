# internOS — Workstreams

## Workstreams Operating System

If `WORKSTREAMS.md` exists in the project root, read it at the start
of any session that involves a workstream.

Only load the workstream directory matching the active context.
Do not load all workstreams — keep context clean.

Projects live in: `projects/[project-name]/`
Each project has a TICK.md (task management), an optional AGENTS.md (project context), and workstreams/ directory.
Workstream directories live in: `projects/[project]/workstreams/[workstream-name]/`

## Resolution

Resolve the workstream by exact `thread_id` in BRIEF.md.
If no exact match exists, stop and ask — never guess.
Never resolve by fuzzy matching, keyword similarity, or path proximity.

## Before starting work

1. Resolve workstream by exact `thread_id`
2. Read project-level context: `projects/[project]/AGENTS.md` (if it exists)
3. Read the workstream's files (in the workstream directory, not your agent memory):
   - `BRIEF.md` — read in full (workstream identity + thread_id)
   - `STATUS.md` — read in full (must be ≤10 lines by design)
4. Escalate to other files only when the task requires it:
   - `MEMORY.md` — **last 80 lines only** (search on demand if more context needed)
   - `DECISIONS.md` — when task involves prior decisions
   - `STAKEHOLDERS.md` — when task involves people or relationships
   - `RESOURCES.md` — when task involves artifacts or deployments
5. Check tasks: `tick list --tag [workstream-name]`
6. Claim the task: `tick claim TASK-X @claude-code`

## Before ending any working session

1. Complete or release the task:
   - `tick done TASK-X @claude-code` (if complete)
   - `tick release TASK-X @claude-code` (if pausing)
2. Update STATUS.md with:
   - What was done this session
   - Current workstream phase
   - Any blockers
3. If the workstream's MEMORY.md exceeds 80 lines, consolidate — summary, not log

This is required even if nothing changed. A blank STATUS.md means
the workstream is invisible to the next agent or session.

## Recovery doctrine

If session is degraded, bloated, or reset: reconstruct from workstream files.
Do not trust transcript continuity. BRIEF.md + STATUS.md must be sufficient to restart.

## Isolation doctrine

Do not read another workstream's files by default.
Cross-workstream synthesis must be explicit and requested.

## Cross-workstream lookup

For operational overview, consult `projects/REGISTRY.md` (derived index).
Do not use it for single-workstream resolution — use BRIEF.md directly.

## Activating a new workstream

1. Add task: `tick add "Description" --tag workstream-name --priority high`
2. Scaffold directory from templates or manually:
   ```
   mkdir -p projects/[project]/workstreams/[name]/docs
   ```
3. Fill BRIEF.md with workstream identity (thread_id is mandatory)
4. Link everything in RESOURCES.md

## Workstream file structure

```
projects/[project]/workstreams/[name]/
├── BRIEF.md         ← Workstream identity + thread_id binding (mandatory)
├── STATUS.md        ← Operational heartbeat: phase, next, blockers
├── MEMORY.md        ← Durable context across sessions (≤80 lines)
├── DECISIONS.md     ← Key decisions log with date + rationale
├── STAKEHOLDERS.md  ← Relevant people and their role
├── RESOURCES.md     ← Artifact registry and where they live
└── docs/            ← Working artifacts
```

## References

- Framework: `references/en/FRAMEWORK.md`
- Playbook: `references/en/PLAYBOOK.md`
- Communication: `references/en/COMMUNICATION.md`
- tick.md integration: `references/en/TICK-INTEGRATION.md`
