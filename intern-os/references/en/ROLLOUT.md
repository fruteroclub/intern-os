# ROLLOUT — Bringing a Workspace to internOS Spec

*internOS v0.3.1 | 2026-04-12*

---

## When to use this

Use this protocol when:
- Rolling out internOS to a workspace with existing projects
- Upgrading a workspace to a new internOS version
- Auditing workspace health before a milestone
- Onboarding a new team to an existing workspace

---

## Prerequisites

- internOS skill installed (see SETUP.md for your adapter)
- `WORKSTREAMS.md` placed at workspace root
- Access to the workspace filesystem

---

## Phase 1: Assess current state

Generate the registry to see what exists:

```bash
bash intern-os/scripts/generate-registry.sh <workspace-path>
```

Review `projects/REGISTRY.md`. The summary table shows:
- How many workstreams exist
- How many are healthy, incomplete, or unbound
- Which ones need attention

Run sync-check in rollout mode for a prioritized action list:

```bash
bash intern-os/scripts/sync-check.sh <workspace-path> --rollout
```

This produces a focused report: unbound workstreams, incomplete identity fields, and missing TICK.md tags — ordered by severity.

---

## Phase 2: Normalize active workstreams

**Focus on active workstreams first.** Do not try to normalize everything at once.

An active workstream is one with ongoing work — open communication thread, in-progress tasks, team members actively contributing.

### Priority order

1. **Bind active threads** — For each workstream with an active communication thread, add the correct `thread_id` to BRIEF.md:
   ```
   thread_id: discord:1491150845675438110
   ```
   or:
   ```
   thread_id: slack:C07ABC123/1234567890.123456
   ```

2. **Complete identity fields** — Fill in `project`, `workstream`, `owner`, `created` in BRIEF.md.

3. **Update STATUS.md** — Ensure Phase, Next, Owner, Blockers, Updated are current. Target: ≤10 lines.

4. **Tag in TICK.md** — Ensure each active workstream has at least one tagged task:
   ```bash
   tick add "Description" --tag workstream-name --priority high
   ```

5. **Create missing files** — If any of the 6 workstream files are missing, create them from templates:
   ```bash
   cp intern-os/assets/templates/workstream/MISSING_FILE.md projects/[project]/workstreams/[name]/
   ```

---

## Phase 3: Classify legacy content

For directories that are not active workstreams:

| Situation | Action |
|-----------|--------|
| Work is done | Move to `workstreams/archived/` |
| Work is paused but may resume | Keep in place, set STATUS.md phase to `Paused` |
| Directory is orphan/legacy | Move to `workstreams/archived/` with a note in STATUS.md |
| Not sure | Keep in place, mark as `Paused` — revisit later |

```bash
# Archive a completed workstream
mv projects/[project]/workstreams/[name] projects/[project]/workstreams/archived/[name]
```

---

## Phase 4: Validate

Re-run both tools to confirm the workspace is clean:

```bash
# Health check (should report 0 issues for active workstreams)
bash intern-os/scripts/sync-check.sh <workspace-path>

# Regenerate registry (should show all active workstreams as healthy)
bash intern-os/scripts/generate-registry.sh <workspace-path>
```

Review `projects/REGISTRY.md` — all active workstreams should show as `healthy`.

---

## Phase 5: Ongoing maintenance

- Re-run `generate-registry.sh` after activating or archiving workstreams
- Run `sync-check.sh` periodically or after major changes
- Use `checkpoint-reminder.sh` to catch stale STATUS.md files:
  ```bash
  bash intern-os/scripts/checkpoint-reminder.sh <workspace-path> 3
  ```
- The registry is a snapshot — it reflects the state at generation time, not real-time

---

## Rollout checklist

- [ ] `generate-registry.sh` run — `projects/REGISTRY.md` generated
- [ ] `sync-check.sh --rollout` run and reviewed
- [ ] All active workstreams have `thread_id` in BRIEF.md
- [ ] All active workstreams have identity fields in BRIEF.md
- [ ] All active workstreams have current STATUS.md
- [ ] All active workstreams have task tags in TICK.md
- [ ] Legacy directories classified (archived or paused)
- [ ] Registry regenerated — all active workstreams show as `healthy`
- [ ] `sync-check.sh` (normal mode) passes clean

---

## Tools reference

| Tool | Purpose | Command |
|------|---------|---------|
| `generate-registry.sh` | Generate workstream registry | `bash generate-registry.sh <workspace-path>` |
| `sync-check.sh` | Workspace health validation | `bash sync-check.sh <workspace-path>` |
| `sync-check.sh --rollout` | Rollout-focused validation | `bash sync-check.sh <workspace-path> --rollout` |
| `checkpoint-reminder.sh` | Detect stale STATUS.md | `bash checkpoint-reminder.sh <workspace-path> [days]` |
