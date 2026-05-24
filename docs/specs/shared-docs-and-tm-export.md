# Spec: Shared Docs + TM Export Contract

- **Spec ID:** shared-docs-and-tm-export
- **Targeted version:** v0.5
- **Status:** DRAFT (stub)
- **Author:** Mel
- **Created:** 2026-05-23
- **Related branches:** `feat/shared-docs-and-tm-export` (this spec)
- **Related specs:** `transfer-modules.md` (v1.0 + v1.1), `git-tracking.md`

## Motivation

internOS today specifies project-level state (`PROJECT.md`, `TICK.md`, `AGENTS.md`) and per-workstream state (`BRIEF`, `STATUS`, `DECISIONS`, `MEMORY`, `RESOURCES`, `STAKEHOLDERS`). It does not specify a home for **shared documents** — artifacts that are referenced from multiple workstreams, that need to travel when a workstream is exported, or that should be indexable as project knowledge by external tools (LLM-Wiki, gbrain, etc.).

Three concrete cases this spec exists to handle:

1. **Authored artifacts shared across workstreams** — e.g. a market research prompt used by both a `pitch-prep` workstream (running the prompt) and a future `market-positioning` workstream (re-running with new scope). Duplicating into each workstream's dir creates two sources of truth.
2. **External-system artifacts that drove project state** — e.g. a gstack `/office-hours` design doc that scaffolded new workstreams. The canonical home is the external tool; the project loses context when the external doc is unavailable (offline, transferred, archived).
3. **LLM-Wiki / knowledge-index integration** — Mel's planned setup (Obsidian vault + Karpathy-style LLM index, https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) requires predictable structure and rich frontmatter to index across the workspace. State files are well-shaped; arbitrary referenced documents are not.

This spec adds a `docs/` directory at project level, defines the snapshot contract for external-system artifacts, and extends the Transfer Module export contract to resolve workstream `RESOURCES.md` references into `<workstream>/docs/` at TM export time.

## Specification

### 1. Project structure addition

Canonical project template gains one new directory:

```
<project>/
├── PROJECT.md
├── AGENTS.md
├── TICK.md
├── code/                  # source repo container (per git-tracking spec)
│   └── README.md
├── docs/                  # ← NEW: project-level shared documents
│   └── README.md          # documents the convention + index
└── workstreams/
    └── <workstream>/
        ├── BRIEF.md
        ├── STATUS.md
        ├── DECISIONS.md
        ├── MEMORY.md
        ├── RESOURCES.md
        ├── STAKEHOLDERS.md
        └── docs/          # ← populated at TM-export time only (not committed in normal use)
```

`docs/` at workstream level is **not** committed in normal use. It is populated by the TM export process from the workstream's `RESOURCES.md` references. The workstream's live filesystem references `../../docs/<filename>` to reach the project-level source.

`PROJECT.md` gains a `docs_dir: docs/` line in its `## Operational links` section.

### 2. What goes in `docs/`

Two kinds of documents:

- **Authored shared artifacts.** Markdown documents authored inside the project (or pasted from elsewhere with permission), intended to be referenced from multiple workstreams or stable over time. Examples: research prompts, deck drafts, transcripts, vetted templates.
- **Snapshots of external-system artifacts** that produced project or workstream state. Examples: gstack `/office-hours` design docs that scaffolded workstreams; Notion strategy docs that drove a TICK task; voice memo transcripts that informed a DECISION.

Not every external artifact should be snapshotted. The threshold: **did this artifact produce tracked work?** If yes, snapshot. If it's reference material that lives outside the project's causal graph (e.g., a competitor's pricing page, an industry report), reference by URL or external path in the relevant `RESOURCES.md` and leave it external.

### 3. Frontmatter contract

Every file in `docs/` has YAML frontmatter. Minimum fields:

```yaml
---
title: "..."
project: <project-slug>
type: <design-doc | prompt | report | transcript | template | other>
tags: [...]
---
```

Snapshots of external artifacts add:

```yaml
source:
  system: <gstack | notion | linear | slack | voice | other>
  path: "<canonical-path-or-url>"
  generated_by: "<tool-or-process>"
  generated_on: "<ISO-date>"
snapshot:
  taken_on: "<ISO-date>"
  taken_by: <human | claude-code | other-agent>
  reason: "<one-line why this was snapshotted>"
```

Design docs that generated workstreams add:

```yaml
generated_workstreams:
  - <workstream-name>
  - ...
```

Reports authored against a prompt add:

```yaml
prompt_source: "../<prompt-file>.md"
```

### 4. Snapshot freshness

Snapshots are point-in-time copies, not live mirrors. Each snapshot includes a `> Snapshot notice` block immediately under the frontmatter that names the canonical source path and the snapshot date. If the canonical source updates, the snapshot becomes stale until re-imported.

Three policies for staleness handling (project-level choice, declared in `docs/README.md`):

- **`canonical`** (default): canonical source remains authoritative. Snapshot is for portability + indexing only. Workstreams reading the snapshot should consult the canonical when in doubt.
- **`promoted`**: the snapshot has been promoted to the in-tree source of truth. Canonical may diverge; snapshot wins. Declared per-file in the snapshot block: `promoted: true`.
- **`pinned`**: the snapshot is the version of record for a specific decision (e.g. "the design doc as it was when we scaffolded the project"). Future iterations of the canonical are tracked as separate files (`design-rev3.2.md`, etc.), not by overwriting.

### 5. Workstream references

Workstream `RESOURCES.md` files reference shared docs with relative paths from the workstream directory back to `docs/`. From `<project>/workstreams/<workstream>/RESOURCES.md`, the relative path to `docs/foo.md` is `../../docs/foo.md`.

External canonical sources (when a snapshot exists in `docs/`) should be listed in the same RESOURCES.md row, in the Notes column, so the canonical path is discoverable without leaving the workstream context.

### 6. TM export contract extension

This spec extends `transfer-modules.md` (v1.1, engagement-delivery type) and the workstream-type TM:

At TM export time, the export process MUST:

1. Parse the workstream's `RESOURCES.md`.
2. Identify rows whose `Location` field starts with `../../docs/` (the project-level docs convention).
3. Copy each referenced file from `<project>/docs/<filename>` into `<workstream>/docs/<filename>` inside the exported TM.
4. Rewrite the workstream's `RESOURCES.md` (in the exported TM only — the live workstream copy is untouched) to point at the now-local `docs/<filename>`.
5. Preserve frontmatter `source` and `snapshot` blocks verbatim — these are the provenance record for the receiving project.

This makes exported workstream TMs self-contained — the receiving project / agent has all referenced docs available without needing access to the source project's filesystem.

### 6a. Heavy-asset pointer convention

Workstream `RESOURCES.md` has two tables: the canonical resource table (text-shaped artifacts) and a **heavy-asset table** for binary / non-text content — images, audio, video, large PDFs (>~5MB), datasets, ML model weights, archives.

Heavy assets are *referenced*, not *embedded*:

- They live in `<workstream>/docs/assets/<kind>/<file>` (preferred) or in external storage (Drive, S3, Git LFS).
- The RESOURCES.md heavy-asset row records: name, kind, location (relative path or external URL), size, notes.
- The bytes do not enter `docs/*.md` and they are not inlined as base64.

At TM export time:

1. Heavy-asset rows are carried through verbatim in the exported `RESOURCES.md`.
2. The bytes of heavy assets **do not travel with the TM**. The receiving agent follows the pointer if and when it needs the asset.
3. If the heavy asset's `Location` is a relative path (`docs/assets/...`) and the source brain is accessible to the receiver (auth handshake outside this spec), the receiver may fetch on demand. Otherwise the receiver must coordinate with the source brain owner.

Rationale: keeps TM payloads small + portable, avoids byte-duplication across exports, and matches how human collaborators already treat linked vs. embedded content. A 24-line markdown referencing a 5MB PDF becomes a 24-line markdown + a 1-line pointer in RESOURCES.md, not a 5MB TM payload bloat.

Schema: see `intern-os/assets/templates/workstream/RESOURCES.md` for the canonical two-table layout.

### 7. LLM-Wiki indexing

The shared-docs convention is designed to be consumed by an LLM-Wiki indexer (Obsidian + LLM-powered semantic search). Implementers of indexers can rely on:

- Every file in any project's `docs/` has YAML frontmatter with at minimum `title`, `project`, `type`, `tags`.
- Snapshots are marked by the presence of a `source` block.
- Cross-project queries ("show me everything about Nubia") work by matching the `project` frontmatter field across the workspace.
- Workstream-scoping ("show me what fed the hackathon-mvp workstream") works via the `generated_workstreams` frontmatter on design-doc snapshots, plus the workstream's RESOURCES.md.

The indexer is out of scope for this spec; the convention exists to make implementation tractable.

## Migration

For existing internOS projects upgrading to v0.5:

- `mkdir docs/` at project root if not present.
- Move any shared artifacts currently sitting at project root or duplicated across workstreams into `docs/`. Add frontmatter.
- Update `PROJECT.md` operational links to include `docs_dir: docs/`.
- Update workstream `RESOURCES.md` references to use `../../docs/` paths.
- No retroactive snapshotting of external artifacts required — snapshot when next they drive project state.

## Backwards compatibility

Projects without `docs/` continue to work — the directory is optional but recommended. TM export tooling MUST handle the absence gracefully (no `docs/` to resolve = empty `<workstream>/docs/` in the exported TM, no error).

## Open questions

- **Non-markdown artifacts (PDFs, images, audio):** should they live in `docs/` with markdown sidecar files carrying the frontmatter, or in a sibling `docs/assets/` with a different addressing scheme? Current proposal: `docs/assets/` for binaries, markdown sidecars at `docs/<asset-name>.md` carrying frontmatter. Defer to v0.6.
- **Snapshot refresh tooling:** should `intern-os snapshot refresh <file>` be a CLI verb that re-pulls from canonical when the canonical has updated? Defer to v0.6.
- **gstack integration:** should `/office-hours` (and other gstack skills that produce project-state-driving artifacts) gain a "register snapshot in target project" step, or is the snapshot-on-import flow purely consumer-side in internOS? Probably consumer-side is simpler, but worth a conversation with gstack maintainers. Defer.
- **TM apply contract:** when a TM is applied to a receiving project, should the embedded `docs/` files be merged into the receiving project's `docs/` (potentially overwriting), staged in `.tms/<tm-name>/docs/` (per existing TM convention), or both? Current proposal: stage in `.tms/<tm-name>/docs/` only; promotion to `docs/` is an explicit step. Aligns with how TMs currently stage other files.
- **Multi-project shared docs:** what if a doc is genuinely shared across multiple *projects* (e.g. a workspace-level style guide)? Likely out of scope here — workspace-level docs is a separate spec.

## Verification

Acceptance criteria for v0.5 landing:

- [ ] Canonical project template (`code/intern-os/intern-os/assets/templates/project/`) includes `docs/` with a starter `README.md`.
- [ ] `PROJECT.md` template has `docs_dir: docs/` in its operational links section.
- [ ] `templates/git/project.gitignore` allowlists `docs/` (per git-tracking spec).
- [ ] At least one example project (e.g. nubia) demonstrates a working snapshot with frontmatter contract.
- [ ] TM export tooling (workstream + engagement-delivery types) honors the resolve-and-copy contract from §6.
- [ ] `docs/specs/transfer-modules.md` is amended to reference this spec for the docs/ export contract.
- [ ] Migration notes added to v0.5 release notes.

## References

- `transfer-modules.md` — TM spec v1.0 + v1.1.
- `git-tracking.md` — three-tier git-tracking convention.
- Nubia project (`poktalabs/projects/nubia/`) — first project applying this convention live; `docs/design-nubia-rev3.1.md` is the first snapshot under the contract.
- Karpathy's LLM-Wiki gist: https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
