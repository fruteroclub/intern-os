# internOS v0.5.0-alpha — Testing Registry

status: active
version: 0.5.0-alpha.0
tracking_since: 2026-05-28
maintained_by: Mel

## Purpose

Track every user, device, and workspace running internOS v0.5.0-alpha so we can:
- Know who to notify when alpha.1 or v0.5.0 stable ships
- Collect daily findings and surface regressions before stable release
- Record which features each tester is exercising (TM spec, LIBRARY convention, shared-docs, etc.)

## Testers

| handle | workspace | device / OS | internOS path | features under test | first_seen | last_report |
|--------|-----------|-------------|---------------|---------------------|------------|-------------|
| mel | poktalabs | macOS 26.3 (darwin) | ~/workspaces/poktalabs | TM spec v1.0+v1.1, heavy-asset RESOURCES, shared-docs, resource-hub (LIBRARY+SKILLS+VAULTS) | 2026-05-24 | 2026-05-28 |

## Daily report format

Each session that touches an alpha feature should append one entry here (or in the workstream MEMORY.md, with a pointer added here):

```
YYYY-MM-DD · <handle> · <feature> · <finding> [ok | gap | bug | regression]
```

## Findings log

| date | handle | feature | finding | status |
|------|--------|---------|---------|--------|
| 2026-05-24 | mel | TM spec v1.0 | verifier rejects custom types — no extensibility mechanism | open (IOS-7) |
| 2026-05-24 | mel | heavy-asset RESOURCES | v1.0 includes template silently filters binary files — 23 MB media lost | fixed (feat/resources-heavy-asset-convention) |
| 2026-05-28 | mel | open-source-projects-library | LIBRARY.md location should be `~/workspaces/LIBRARY.md` not `~/.opensrc/` | fixed |
| 2026-05-28 | mel | resource-hub | scope expanded OSPL → Resource Hub (LIBRARY+SKILLS+VAULTS); template applied to poktalabs device; 3 live files in place | ok |
| 2026-05-28 | mel | resource-hub | prior-art audit surfaced 3 parallel implementations (aibus-os resources-hub, dnai-brain OSPL, dnai-brain skills-tracking-system) — all independent, no shared standard; internOS Resource Hub is the canonical fix | ok |

## Notify list (for alpha.1 + stable ship)

- mel — all channels
