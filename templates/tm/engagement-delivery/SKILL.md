---
name: <TM_NAME>
description: "Engagement-delivery TM — flows deliverables from <SOURCE_PROJECT> into <TARGET_PROJECT>'s operational context. Loads runtime handles (REST/MCP) and proposes state updates to apply via PR or staging directory."
version: 1.0.0
author: <AUTHOR>
license: Proprietary
platforms: [linux, macos]
metadata:
  tm:
    tm_spec_version: 1.1
    type: internOS.engagement-delivery
    source_workspace: <SOURCE_WORKSPACE>
    source_project: <SOURCE_PROJECT>
    target_workspace: <TARGET_WORKSPACE>
    target_project: <TARGET_PROJECT>
    created_at: "<ISO8601>"
---

# <TM_NAME> — Engagement Delivery TM

## Overview

This TM is a **directed-flow** capsule: work done in **<SOURCE_WORKSPACE>/<SOURCE_PROJECT>** produced a deliverable (the named code artifact, runtime, or service) that the **<TARGET_WORKSPACE>/<TARGET_PROJECT>** engagement needs to reflect and consume.

When loaded, the TM gives a receiver two things:

1. **Update operations** — file-level changes to apply against the target project (status updates, resource references, decision entries). Applied via PR, branch, or staging-directory mode per `references/TM.yml`.
2. **Runtime bundle** — operational handles for using the deliverable: MCP server config, per-skill SKILL.md mirrors, REST endpoint reference, usage notes.

Nothing flows back to the source. The source project's state is unchanged by this TM. The deliverable itself (the code, the runtime) lives where it lives; the TM is a pointer + state-update package for the target.

## When to Use

Use this TM when:

- A spin-off project shipped a deliverable that a commercial / engagement project needs to reference and use.
- You need the target project's `PROJECT.md` / `STATUS.md` / `RESOURCES.md` to reflect the delivery.
- A receiver agent operating on behalf of the target needs to call the deliverable's REST/MCP endpoints.

Do not use this TM for:

- Returning work to the source project (use `internOS.project` or `internOS.workstream` snapshot TMs with the return protocol).
- Distributing source code (the deliverable lives in its own git repo; this TM points at it).
- Granting credentials or secrets to the receiver (auth is referenced via env vars, never embedded).

## Package Layout

```
<TM_NAME>/
├── SKILL.md                ← this file
├── README.md
├── CHECKSUMS.sha256
├── references/
│   ├── TM.yml              ← machine-readable manifest (source+target+deliverables+updates+apply_protocol)
│   ├── IMPORT.md           ← receiver load protocol
│   ├── APPLY.md            ← how to apply updates against target (replaces RETURN.md for this type)
│   ├── REDACTION_REPORT.md
│   └── EXPORT_MANIFEST.md
├── scripts/
│   ├── verify_tm.sh
│   └── apply_to_target.sh  ← implements pr | branch | staging-dir per TM.yml
└── payload/
    ├── updates/            ← file changes to apply against target project
    │   └── <target-relative-path>.<op>   (replace | append-section | merge | create)
    ├── runtime/            ← operational handles
    │   ├── mcp.json
    │   ├── skills/<name>/SKILL.md
    │   ├── USAGE.md
    │   └── ENGINE_REFERENCE.md
    └── source-snapshot/    ← OPTIONAL provenance snippets
```

## Load Order

1. Read this `SKILL.md` first.
2. Read `references/TM.yml` — source, target, deliverables, updates, apply_protocol.
3. Read `references/APPLY.md` — how to apply updates safely (PR / branch / staging-dir).
4. Read `references/REDACTION_REPORT.md` before assuming missing context is accidental.
5. Read `payload/runtime/USAGE.md` if you'll be calling the deliverable.
6. Inspect `payload/updates/*` — these are the proposed file changes; review before applying.
7. Apply when ready: `bash scripts/apply_to_target.sh`.

## Contribution Boundary

Engagement-delivery TMs are one-way: there is no return path. If the receiver wants to push back changes to the source project, that's a separate workflow (a normal PR against the source repo, or a separate `internOS.project` TM).

The TM author is responsible for:

- The accuracy of update operations (do they describe the work truthfully?)
- The integrity of runtime handles (does the MCP endpoint actually serve the listed skills?)
- The redaction discipline (no secrets, no global identity, no unrelated state)

The receiver is responsible for:

- Reviewing every update before applying (no auto-apply by policy)
- Acknowledging successful ingestion in their own STATUS.md update (not via this TM)
- Reporting integrity issues back to the author

## Verification

```bash
bash scripts/verify_tm.sh
```

For this type, the verifier also checks:

- `payload/updates/` and `payload/runtime/` both present
- Every `content_path` in `TM.yml`'s `updates` block resolves to an existing file under `payload/updates/`
- `payload/runtime/mcp.json` is valid JSON (if present)
- No secrets in update content (best-effort pattern check; not a substitute for human review)

## Apply

```bash
bash scripts/apply_to_target.sh
```

Mode follows `apply_protocol.preferred` in `TM.yml`. If the target project lacks a git repo and the requested mode is `pr` or `branch`, the script falls back to `staging-dir` mode and writes proposed changes into `<target-canonical-path>/.tm-incoming/<TM_NAME>/`.

## Common Pitfalls

1. **Treating updates as authoritative.** The TM author proposed them; the receiver reviews. Apply ≠ accept.
2. **Embedding the deliverable in the TM.** The deliverable lives in its own repo (named in `deliverables[].repo`); the TM is a pointer + state-update package, not a vendored copy.
3. **Skipping `payload/runtime/USAGE.md`.** Tells you how to call REST / MCP / what env vars are needed. Don't reverse-engineer.
4. **Confusing apply with return.** This TM doesn't return anything. If you found a bug in the deliverable, that's a separate PR against the deliverable's repo.
5. **Forgetting that engagement-delivery TMs supersede each other.** If a newer delivery TM ships, treat older ones as historical. Don't re-apply old updates.
