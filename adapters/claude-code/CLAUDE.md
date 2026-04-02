# internOS — Workstreams

## Workstreams Operating System

If `WORKSTREAMS.md` exists in the project root, read it at the start
of any session that involves a workstream.

Only load the workstream directory matching the active context.
Do not load all workstreams — keep context clean.

Projects live in: `projects/[project-name]/`
Each project has a TICK.md (task management) and workstreams/ directory.
Workstream directories live in: `projects/[project]/workstreams/[workstream-name]/`

## Before starting work

1. Read the workstream's files (in the workstream directory, not your agent memory):
   - `BRIEF.md` — read in full
   - `STATUS.md` — read in full (must be ≤10 lines by design)
   - `MEMORY.md` — **last 80 lines only** (search on demand if more context needed)
2. Check tasks: `tick list --tag [workstream-name]`
3. Claim the task: `tick claim TASK-X @claude-code`

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

## Activating a new workstream

1. Add task: `tick add "Description" --tag workstream-name --priority high`
2. Scaffold directory from templates or manually:
   ```
   mkdir -p projects/[project]/workstreams/[name]/docs
   ```
3. Fill BRIEF.md with the 6 questions
4. Add thread_id to BRIEF.md if a communication thread exists
5. Link everything in RESOURCES.md

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

## References

- Framework: `references/en/FRAMEWORK.md`
- Playbook: `references/en/PLAYBOOK.md`
- Communication: `references/en/COMMUNICATION.md`
- tick.md integration: `references/en/TICK-INTEGRATION.md`
