# Spec: Resource Hub

version: 0.2
status: draft
created: 2026-05-28
updated: 2026-05-29
supersedes: n/a
related: open-source-projects-library.md

## Purpose

The Resource Hub is a dedicated `~/workspaces/resources/` workspace that gives any agent or human a single-load reference for what tools, skills, and knowledge sources are available across all workspaces. The `resources/` directory is itself an internOS workspace — it has its own `AGENTS.md` and is indexed by gbrain. Each registry file covers one resource type. Loading the relevant file(s) is enough to answer "what do we have?" without traversing workspace trees.

## Canonical location

The `resources/` workspace lives at `~/workspaces/resources/` — always at the internOS home root level, sibling to the other workspaces. It is not project-specific.

```
~/workspaces/
  resources/
    AGENTS.md      ← workspace identity + usage guide
    LIBRARY.md     ← opensrc cache registry
    SKILLS.md      ← agent skills registry
    VAULTS.md      ← knowledge vaults registry
```

## Registry files

| file | covers |
|------|--------|
| `LIBRARY.md` | repos and packages cached by `opensrc` |
| `SKILLS.md` | agent skills installed on this machine |
| `VAULTS.md` | knowledge vaults and gbrain indexes |

Each file is independent. Load only what the current task needs.

Sibling files (`LIBRARY-agents.md`, `SKILLS-medical.md`, etc.) are supported for focused subsets when a primary file exceeds ~30 rows. Every entry in a sibling must also appear in the primary file.

## Shared format

All registry files use the same pattern:

```markdown
---
updated: YYYY-MM-DD
---

| <fields> |
```

Frontmatter carries only `updated`. The table is the content. One row per resource. Keep `purpose` / `description` to one line — these files are loaded whole into agent context.

## File specs

### LIBRARY.md — opensrc cache

Fields: `name` · `version` · `path` · `purpose` · `gbrain` · `tags` · `fetched`

Full field definitions in [open-source-projects-library.md](open-source-projects-library.md).

### SKILLS.md — agent skills

Fields: `name` · `version` · `install_path` · `harness` · `purpose` · `status` · `tags`

| field | notes |
|-------|-------|
| `name` | skill name as invoked (e.g. `browse`, `intern-os`) |
| `version` | semver or `n/a` |
| `install_path` | path relative to `~` (e.g. `.claude/skills/browse`) |
| `harness` | `claude-code` / `hermes` / `openclaw` / `codex` / `cursor` |
| `purpose` | one-line description written for LLM context |
| `status` | `installed` / `needs-review` / `deprecated` |
| `tags` | comma-separated |

### VAULTS.md — knowledge vaults

Fields: `name` · `type` · `path` · `covers` · `engine` · `status` · `tags`

| field | notes |
|-------|-------|
| `name` | vault or brain identifier |
| `type` | `gbrain` / `obsidian` / `notion` / `custom` |
| `path` | local path or remote URL |
| `covers` | one-line: which workspace(s) or corpus this indexes |
| `engine` | storage backend (e.g. `postgres/pgvector`, `pglite`, `local`) |
| `status` | `active` / `stale` / `offline` |
| `tags` | comma-separated |

## Agent usage

Load only the file(s) relevant to the current task:
- "Is X cached?" → read `LIBRARY.md`
- "What skills are available?" → read `SKILLS.md`
- "Can I semantic-search this topic?" → read `VAULTS.md`

These files are meant to be loaded whole. Keep rows short enough that the full file stays under ~60 lines. Use sibling files when a category grows large.

## Maintenance

Update `updated` in frontmatter on every write. Add rows when a resource is added; update `status` when it changes; remove rows when a resource is permanently gone.
