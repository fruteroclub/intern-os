# Spec: Open Source Projects Library

version: 0.1
status: draft
created: 2026-05-28

## Purpose

A single Markdown file at `~/workspaces/LIBRARY.md` that records which external repos and packages have been cached by `opensrc` (and optionally indexed by gbrain) across all workspaces. It is the shared reference layer any agent or human loads to know what tools are available without re-discovering them.

## Location

```
~/workspaces/LIBRARY.md        ← primary, always present
~/workspaces/LIBRARY-<tag>.md  ← optional sibling files for large focused subsets (e.g. LIBRARY-agents.md)
```

One file per internOS installation. Sibling files are additive — the primary LIBRARY.md remains the canonical index.

## Format

```markdown
---
updated: YYYY-MM-DD
---

| name | version | path | purpose | gbrain | tags | fetched |
|------|---------|------|---------|--------|------|---------|
| org/repo | branch-or-version | repos/org/repo/branch | one-line description | yes/no | tag1, tag2 | YYYY-MM-DD |
```

### Fields

| field | required | notes |
|-------|----------|-------|
| `name` | yes | `org/repo` for repos; package name for npm/pip packages |
| `version` | yes | branch, tag, semver, or commit |
| `path` | yes | path relative to `~/.opensrc/` |
| `purpose` | yes | one line — what this is for, written for LLM context |
| `gbrain` | yes | `yes` / `no` — whether the content is indexed in gbrain |
| `tags` | no | comma-separated topic labels |
| `fetched` | yes | ISO date the cache was last refreshed |

## Agent usage

Load `~/workspaces/LIBRARY.md` as a single context block when a task asks "is X available?" or "what agent harnesses do we have cached?". The table is the full answer — no further file traversal needed.

## Maintenance

- Add a row when `opensrc` caches a new repo or package.
- Update `version`, `fetched`, and `gbrain` when re-fetching or after a gbrain re-index.
- Update the frontmatter `updated` date on every write.
- Keep `purpose` to one line — this file is loaded whole; verbose entries degrade LLM utility.

## Sibling files

Create `LIBRARY-<tag>.md` only when the primary file exceeds ~30 rows and a focused subset is frequently loaded together (e.g. all agent harnesses). A sibling file is a filtered view — every entry in a sibling must also appear in the primary LIBRARY.md.
