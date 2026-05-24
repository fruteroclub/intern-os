# Apply Protocol — <TM_NAME>

How a receiver applies this engagement-delivery TM to the target project. Replaces `RETURN.md` for snapshot TMs — engagement-delivery is one-way, there is no return.

## Modes

The `apply_protocol.preferred` field in `TM.yml` selects the mode:

| Mode | When to use | What happens |
| --- | --- | --- |
| `pr` | Target project has a git repo; you have push access | Script creates a branch (`branch_prefix`), applies updates, commits, pushes, opens PR via `gh pr create`. Receiver reviews + merges. |
| `branch` | Target has a git repo; you'll open the PR manually | Same as `pr` but stops at push. Receiver runs `gh pr create` separately. |
| `staging-dir` | Target has no git repo, OR you want to inspect before applying | Script writes proposed updates into `<target-canonical-path>/.tm-incoming/<TM_NAME>/`. Receiver reviews on the filesystem, then either copies into place or `git init`s the project. |

If `apply_protocol.preferred = pr` but `target.repo = null`, the script **automatically falls back to staging-dir mode** and prints a notice with a migration command (see `docs/specs/git-tracking.md` for git-tracking conventions).

## Pre-apply checklist

Before running `apply_to_target.sh`, verify:

1. `bash scripts/verify_tm.sh` exited 0.
2. You've read `references/TM.yml`'s `updates` block and understand what each operation does.
3. You've inspected `payload/updates/*` — the actual content that will be written.
4. The target project at `target.canonical_path` exists and looks right (`ls $TARGET/PROJECT.md`).
5. If applying in `pr` or `branch` mode: the target project has a clean working tree (`git status` is clean) so the TM's changes are isolated in their commit.

## Running

```bash
bash scripts/apply_to_target.sh
```

The script:

1. Resolves the target canonical path (from `TM.yml`'s `target.canonical_path`, relative to your `INTERNOS_WORKSPACE`).
2. Selects the apply mode (preferred, with fallback).
3. For `pr` / `branch` modes: creates a branch in the target repo (name follows `branch_prefix` + a timestamp).
4. Applies each `updates[]` entry:
   - `replace` — overwrite the target file with content.
   - `append-section` — append a new section (with `section_title`) to the target file.
   - `merge` — best-effort interpretive merge; the script applies as `append` and prints a notice that the receiver should hand-merge.
   - `create` — create the target file if it doesn't exist; refuse if it does.
5. For `pr` / `branch` modes: commits with a summary referencing this TM, pushes, optionally opens PR.
6. For `staging-dir` mode: writes everything to `<target>/.tm-incoming/<TM_NAME>/`, prints a tree of what was written, and exits.

## After applying

- **PR mode:** review the PR's diff. If the updates look right, merge. If something's off, request changes from the TM author rather than hand-editing the PR.
- **Branch mode:** open the PR yourself, then proceed as in PR mode.
- **Staging-dir mode:** review the proposed files in `.tm-incoming/<TM_NAME>/`. To accept, either:
  - Copy files into place manually (`cp .tm-incoming/<TM_NAME>/<path> <path>`), OR
  - `git init` the target project first (then re-run the script in `pr` mode), OR
  - Cherry-pick selectively (skip updates you disagree with).

Whichever mode applied: the receiver should update the target's `STATUS.md` to acknowledge ingestion (which active workstream now references the new deliverable, what's the new operational posture). That's a normal project edit, not a TM operation.

## If something goes wrong

- **Apply partially completed and failed mid-way** (e.g. one update applied, the next errored): the script does not roll back automatically. Inspect the working tree, decide whether to revert (`git checkout -- <files>`) or push forward.
- **Update content doesn't fit the target's current state** (e.g. STATUS.md schema changed between TM author's snapshot and receiver's current file): apply in staging-dir mode and hand-merge.
- **Runtime handles (REST/MCP) don't work** (`payload/runtime/mcp.json` points at an endpoint that's down): report to the TM author; the deliverable's repo issue tracker is the right place.

## What apply does **not** do

- Push to the deliverable's repo (the deliverable is unchanged by this TM).
- Modify the source project (engagement-delivery is one-way; source is untouched).
- Apply runtime/* files (those are operational handles, not state updates — they live alongside the TM for the receiver to wire up separately).
- Acknowledge the source — the source project doesn't learn from this TM that the target accepted it. That's an explicit communication step outside the TM.
