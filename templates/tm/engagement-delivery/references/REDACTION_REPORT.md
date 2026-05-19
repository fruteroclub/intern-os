# Redaction Report — <TM_NAME>

Type: engagement-delivery (one-way; source → target)

Source scope reviewed: `workspaces/<SOURCE_WORKSPACE>/projects/<SOURCE_PROJECT>/`
Target scope referenced: `workspaces/<TARGET_WORKSPACE>/projects/<TARGET_PROJECT>/`

Reviewer: <AUTHOR>
Date: <ISO8601>

## Checked

- Secrets and tokens (env files, auth.json, credentials) — none included.
- Source workstreams that produced the deliverable — only the named workstreams contributed updates; unrelated source workstreams are not referenced.
- Runtime handles — endpoints are referenced as env var names or public URLs; no embedded tokens.
- The deliverable's repo — pointed at by URL only; source code is NOT vendored into the TM.
- Generated runtime artifacts, caches, bytecode — none.

## Excluded by type policy

- Full source-project state (engagement-delivery TMs do not snapshot the source; see `internOS.project` if you need that).
- Code under `<source-project>/code/**` — same rationale as snapshot TMs.
- Global agent identity, harness config, memories, sessions, logs.

## Sensitive-adjacent content still present in updates

Document anything in `payload/updates/*` that a receiver should treat carefully. Common cases:

- Status text that names internal stakeholders or unreleased plans.
- Resource references to private repos / endpoints (receiver should already have access if this TM was sent to them).
- Decision entries citing internal commercial terms.

The receiver applies updates only after reviewing this content; the redaction discipline shifts to the target project after apply.

## Audience

This TM is intended for **<AUDIENCE>** — typically the target project's operating team, or an agent operating on behalf of that team.

## If you spot a leak

1. Stop the apply.
2. Notify the TM author with the file path and the kind of leak.
3. Author re-exports a fixed version of the TM.
4. You verify the new TM and resume.

Never silently scrub or modify `payload/` — that masks the source-side error and corrupts the audit trail.
