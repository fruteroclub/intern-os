# TM — Engagement Delivery: <SOURCE_PROJECT> → <TARGET_PROJECT>

This is an **engagement-delivery** internOS Transfer Module: a one-way capsule that flows the consequences of work done in **<SOURCE_PROJECT>** into the operational context of **<TARGET_PROJECT>**.

It carries:

1. **Update operations** — file changes to apply against the target project (status, resources, decisions).
2. **A runtime bundle** — MCP config and per-skill SKILL.md mirrors so a receiver agent can call the deliverable.

Nothing returns to the source. The deliverable itself lives in its own repo (`<DELIVERABLE_REPO>`), unchanged by this TM.

## Quick start for receivers

```bash
# 1. Verify integrity
bash scripts/verify_tm.sh

# 2. Read the manifest and apply protocol
cat references/TM.yml
cat references/APPLY.md

# 3. Inspect proposed updates before applying
ls payload/updates/

# 4. Apply (mode follows apply_protocol.preferred in TM.yml; falls back to staging-dir if target has no git repo)
bash scripts/apply_to_target.sh
```

## Wiring the runtime in Claude Code

```bash
# Copy the MCP config snippet into your Claude Code MCP config
cat payload/runtime/mcp.json

# Review per-skill SKILL.md files for tool semantics
ls payload/runtime/skills/

# Then in any Claude Code session, the engine's tools are available as mcp__<server-name>__<tool>
```

See `payload/runtime/USAGE.md` for full usage notes.

## Spec

This TM targets internOS Transfer Modules spec **v1.1**. See `docs/specs/transfer-modules.md` in `poktalabs/intern-os`.
