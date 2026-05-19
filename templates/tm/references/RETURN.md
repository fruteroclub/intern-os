# Return Protocol — <TM_NAME>

How a receiver returns contributions to the author for verification and ingestion.

Accepted return forms (in order of preference):

1. **Pull request** against the target_repo declared in `TM.yml`. Branch name follows `branch_prefix` (e.g. `tm/<TM_NAME>/<short-description>`).
2. **Git branch** pushed to a mutually accessible remote, with explicit head SHA in the return summary.
3. **Patch bundle** rooted at the canonical_path (e.g. `git format-patch` or `git diff > return.patch`).

## Required return notes

Every return includes:

- **Intent summary** — what was the contribution trying to accomplish?
- **Files changed** — explicit list, paths relative to canonical_path.
- **Decisions made** — anything that required judgment beyond the TM's stated scope.
- **Resources added or referenced** — new entries that belong in `RESOURCES.md`.
- **Human review needed** — flag anything the author should make a call on before ingestion.
- **Verification result** — output of `sync-check.sh` if available, otherwise note any verification skipped and why.

## Forbidden in returns

- Generated runtime state (`.tick/lock`, `.tick/session.json`, logs, caches).
- Credentials of any kind.
- Session transcripts.
- Changes to files outside `permissions.allowed_writes`.
- Modifications to `code/**` paths (even if the receiver also worked on the code repos — return those via the code repos' own PR flow, not this TM).

## Author-side ingestion checklist

When accepting a return:

```bash
# Run internOS sync-check against the author's canonical workspace
bash <intern-os-checkout>/intern-os/scripts/sync-check.sh <workspace-path>

# Review the diff scoped to the canonical_path
git diff -- <canonical_path>
```

After accepting material contributions, update:

- `STATUS.md` — reflect the new operational state
- `DECISIONS.md` — record any decisions captured in the return summary
- `RESOURCES.md` — register new resources surfaced by the receiver

If the source state changed materially as a result of ingestion, **re-export the TM** with a bumped version and fresh CHECKSUMS.
