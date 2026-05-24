---
name: <TM_NAME>
description: "Use when loading, importing, or returning the <THING> internOS Transfer Module. Provides scoped <WORKSPACE> <TYPE> context, load order, contribution boundaries, and verification rules for receiver agents."
version: 1.0.0
author: <AUTHOR>
license: Proprietary
platforms: [linux, macos]
metadata:
  hermes:
    tags: [internOS, transfer-module, <THING>, <WORKSPACE>]
    related_skills: [intern-os]
  tm:
    tm_spec_version: 1.0
    type: internOS.<TYPE>            # project | workstream
    workspace: <WORKSPACE>
    project: <PROJECT>
    workstream: <WORKSTREAM_OR_NULL>
    canonical_path: workspaces/<WORKSPACE>/projects/<PROJECT><WORKSTREAM_PATH_SUFFIX>
    payload_path: payload/workspaces/<WORKSPACE>/projects/<PROJECT><WORKSTREAM_PATH_SUFFIX>
    created_at: "<ISO8601>"
---

# <THING> <TYPE>-Context TM

## Overview

This skill is an internOS Transfer Module (TM) for the **<THING>** <TYPE> inside the canonical **<WORKSPACE>** workspace.

It packages enough context for an authorized human or agent to load the <TYPE>, understand the operating boundary, work on its artifacts, and return changes — without receiving global agent identity, harness configuration, private runtime state, unrelated projects, or credentials.

## When to Use

Use this skill when:

- Exporting <THING> context to another authorized agent or operator.
- Importing <THING> context into a clean internOS-compatible environment.
- Asking a receiver to work inside the canonical_path declared above.
- Verifying that a returned branch, patch, or PR stayed inside the <TYPE> boundary.
- Rebuilding the TM after operating docs change materially.

Do not use this skill for:

- Granting access to global agent identity, memories, sessions, logs, or harness config.
- Exporting unrelated projects from the same workspace.
- Exporting nested code repositories under `code/` unless explicitly authorized as a separate transfer.
- Making external commitments without the author's approval.

## Package Layout

```
<TM_NAME>/
├── SKILL.md                ← this file
├── README.md
├── CHECKSUMS.sha256
├── references/
│   ├── TM.yml              ← machine-readable manifest
│   ├── IMPORT.md           ← receiver load protocol
│   ├── RETURN.md           ← return protocol
│   ├── REDACTION_REPORT.md ← what was checked / excluded
│   └── EXPORT_MANIFEST.md  ← export provenance
├── scripts/
│   └── verify_tm.sh
└── payload/
    └── <canonical_path>/
```

## Load Order

1. Read this `SKILL.md` first.
2. Read `references/TM.yml` for machine-readable scope and permissions.
3. Read `references/IMPORT.md` for receiver setup steps.
4. Read `references/RETURN.md` for contribution-return expectations.
5. Read `references/REDACTION_REPORT.md` before assuming any missing context is accidental.
6. Load payload context in internOS order:
   - For `internOS.project`: `PROJECT.md` → `AGENTS.md` → `POD.md` → `TICK.md` → active workstream files
   - For `internOS.workstream`: parent `PROJECT.md` (context header) → `AGENTS.md` (context header) → `BRIEF.md` → `STATUS.md` → escalate to `MEMORY.md`, `DECISIONS.md`, `STAKEHOLDERS.md`, `RESOURCES.md` as needed

## Contribution Boundary

Allowed read/write boundary is declared in `references/TM.yml` under `permissions.allowed_writes`. Forbidden writes are declared under `permissions.forbidden_writes`. The receiver must not modify anything outside the allowed paths.

## Verification

From the TM root:

```bash
bash scripts/verify_tm.sh
```

The script checks structural completeness, forbidden-pattern absence, and sha256 integrity. Expected output:

```
TM verification OK
```

## Common Pitfalls

1. **Treating the TM as global agent memory.** It is <TYPE>-scoped operating context, not an identity migration package.
2. **Including nested code repositories.** `code/**` is excluded by default; reference repository URLs via `RESOURCES.md` when code work is needed.
3. **Forgetting return boundaries.** A receiver must not modify global harness config, unrelated projects, logs, sessions, or memory files.
4. **Assuming missing private context is accidental.** Check `REDACTION_REPORT.md`; omissions are usually deliberate boundaries.
5. **Mutating files without verifying spec version.** If `metadata.tm.tm_spec_version` is newer than your toolchain supports, refuse the TM rather than guessing.

## Verification Checklist

- [ ] `metadata.tm.tm_spec_version` is set and matches the receiver's supported version.
- [ ] `scripts/verify_tm.sh` exits 0.
- [ ] `sha256sum -c CHECKSUMS.sha256` (or `shasum -a 256 -c`) passes.
- [ ] No forbidden files are present under `payload/`.
- [ ] Receiver instructions in `references/IMPORT.md` were followed.
- [ ] Return follows `references/RETURN.md`.
