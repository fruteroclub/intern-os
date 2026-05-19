# TM — <THING> <TYPE> Context

This directory is a portable internOS Transfer Module (TM) — a self-contained context capsule for the **<THING>** <TYPE> inside the **<WORKSPACE>** workspace.

Use it to load context into an authorized human or agent system, contribute within the declared boundary, and return changes for verification and ingestion.

## What this is

A scoped export of:

```
workspaces/<WORKSPACE>/projects/<PROJECT>[/workstreams/<WORKSTREAM>]/
```

with global identity, secrets, runtime state, and nested code repositories deliberately excluded. See `references/REDACTION_REPORT.md` for the full list of what was checked and omitted.

## Harness-agnostic by design

This TM is internOS-first and works with any agent harness that can read its directory:

- **Hermes:** install at `~/.hermes/skills/intern-os/<TM_NAME>/`, load with `skill_view(name="<TM_NAME>")`.
- **Claude Code:** drop the directory anywhere the agent can read; `SKILL.md` is the entry point. No special install required.
- **Codex / OpenCode / OpenClaw / other:** same as Claude Code.
- **Humans:** read this file, then follow `references/IMPORT.md`.

## Verification

From the TM root:

```bash
bash scripts/verify_tm.sh
```

Expected output: `TM verification OK`.

## Quick start for receivers

1. Verify: `bash scripts/verify_tm.sh`
2. Read: `SKILL.md`, then `references/TM.yml`, then `references/IMPORT.md`.
3. Import: copy `payload/workspaces/...` into your internOS-compatible workspace root.
4. Work within `permissions.allowed_writes` from `references/TM.yml`.
5. Return: follow `references/RETURN.md`.

## Spec

This TM targets internOS Transfer Modules spec version 1.0. See `docs/specs/transfer-modules.md` in the `fruteroclub/intern-os` repo.
