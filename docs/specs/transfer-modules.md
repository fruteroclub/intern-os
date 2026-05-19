# Transfer Modules (TM) for internOS

*Status: convention. Derived from lived practice (Hermes/Aibus TMs shipped in agencia, 2026-05). Spec version 1.0.*

## Concept

A **Transfer Module (TM)** is a portable, scoped, integrity-verified context capsule that packages a slice of internOS state for transfer across a trust boundary — agent ↔ agent, machine ↔ machine, or human ↔ agent. The Pokémon analogy: a single disc that teaches one specific move to a compatible recipient, with cartridge-level integrity guarantees so the receiver knows it's the right move.

TMs are a **packaging layer on top of internOS**, not part of the core resolution doctrine. internOS gives you workstreams + state files; TMs give you a vehicle to move a slice of that across systems without leaking global identity, secrets, unrelated projects, or runtime artifacts. A receiver can load a TM, work within an explicit boundary, and return changes for verification and ingestion — all without ever seeing the sender's full operating context.

This standard formalizes the practice already running in `<workspace>/.tms/` directories.

## Types (v1)

The standard ships with two TM types. Both follow the same package layout; they differ in scope and what gets included in the payload.

| Type | Scope | Payload contains | Typical use |
| --- | --- | --- | --- |
| `internOS.project` | One project | `PROJECT.md`, `AGENTS.md`, `POD.md`, `TICK.md`, `docs/`, all `workstreams/*/`, `.tick/config.yml` | Hand off a whole project to a collaborator or other agent harness. Most common. |
| `internOS.workstream` | One workstream inside a project | The workstream's files + a **read-only context header** (parent `PROJECT.md`, `AGENTS.md`, `POD.md`) so the receiver can orient | Hand off a single thread of work without exporting the whole project. Useful for narrow specialist handoffs (review, fixup, deep technical work). |

Workspace-tier and pod-tier TMs are out of scope for v1. Add them when the lived practice demands it.

## Package layout

A TM is a self-contained directory. The canonical shape:

```
<tm-name>/
├── SKILL.md                  ← entry point + load order (with `tm:` frontmatter block)
├── README.md                 ← human-facing overview, install instructions
├── CHECKSUMS.sha256          ← integrity manifest
├── references/
│   ├── TM.yml                ← machine-readable manifest (scope, permissions, return protocol)
│   ├── IMPORT.md             ← receiver-side load protocol
│   ├── RETURN.md             ← return-contributions protocol
│   ├── REDACTION_REPORT.md   ← what was checked, what was excluded, what remains
│   └── EXPORT_MANIFEST.md    ← export-time provenance
├── scripts/
│   └── verify_tm.sh          ← portable bash verification (zero deps)
└── payload/
    └── <canonical_path>/     ← mirrors the source path under workspaces/<ws>/projects/<p>/[workstreams/<w>/]
```

The payload **preserves the relative path** from `workspaces/` down so receivers can copy or overlay it into an internOS-compatible workspace root unchanged.

### Naming convention

`<thing>-<type>-context` — already in use:

- `method-lab-project-context` (project TM)
- `daily-pricing-pipeline-workstream-context` (workstream TM)
- `mi-pase-project-context` (project TM)

Where `<thing>` is the project or workstream name and `<type>` is `project` or `workstream`. The `-context` suffix differentiates TMs from other skills sharing the same skill loader.

### Canonical home

`<workspace>/.tms/<tm-name>/`. The `.tms/` directory at the workspace root is where exports land and where local TMs live before distribution. Workspace-tier TMs (when added) would live at the same path despite being scoped to the workspace itself.

## SKILL.md frontmatter

Every TM's `SKILL.md` declares its identity in YAML frontmatter:

```yaml
---
name: <tm-name>
description: "Use when loading, importing, or returning the <thing> internOS Transfer Module..."
version: 1.0.0                      # this TM's version (semver)
author: <agent or human identity>
license: <as appropriate>
platforms: [linux, macos]
metadata:
  tm:
    tm_spec_version: 1.0            # which version of THIS standard the TM targets
    type: internOS.project          # or internOS.workstream
    workspace: <workspace-name>
    project: <project-name>
    workstream: <name | null>       # null for project TMs
    canonical_path: workspaces/<workspace>/projects/<project>[/workstreams/<ws>]
    payload_path: payload/<canonical_path>
    created_at: <ISO 8601>
---
```

Two distinct versions:

- `version` — semver of *this particular TM* (1.0.0, 1.1.0 if you re-export with changes, 2.0.0 if scope changes meaningfully).
- `metadata.tm.tm_spec_version` — which version of this standard the TM was authored against. Lets future receivers refuse TMs that target a spec they can't load.

## TM.yml — machine-readable manifest

```yaml
tm_version: 1.0                     # spec version, mirrors tm_spec_version in SKILL.md
name: <tm-name>
type: internOS.project              # or internOS.workstream
created_at: <ISO 8601>

source:
  workspace: <workspace>
  project: <project>
  workstream: <name | null>
  canonical_path: workspaces/<workspace>/projects/<project>[/workstreams/<ws>]

scope:
  primary: project | workstream
  includes:
    - <glob patterns relative to canonical_path>
  excludes:
    - <glob patterns>

permissions:
  default: read
  allowed_writes:
    - <abs path globs under canonical_path>
  forbidden_writes:
    - <abs path globs the receiver must NOT modify>

return_protocol:
  preferred: pull_request | branch | patch
  target_repo: <git-remote or "private">
  target_path: workspaces/<workspace>/projects/<project>[/workstreams/<ws>]
  branch_prefix: tm/<tm-name>/
  require_summary: true
  require_diff_review: true
  require_sync_check: true

verification:
  internos_sync_check: <command to run sync-check.sh against the receiver's workspace>
  checksum_file: CHECKSUMS.sha256
```

## Default scope per type

Authors should treat these as the **baseline** — TMs may extend `excludes` for sensitive cases but should not narrow the canonical `includes`.

### `internOS.project` — includes
- `PROJECT.md`, `AGENTS.md`, `POD.md`, `TICK.md`
- `.tick/config.yml`
- `docs/**/*.md`, `docs/**/*.pdf`
- `workstreams/**/BRIEF.md`
- `workstreams/**/STATUS.md`
- `workstreams/**/MEMORY.md`
- `workstreams/**/DECISIONS.md`
- `workstreams/**/STAKEHOLDERS.md`
- `workstreams/**/RESOURCES.md`
- `workstreams/**/SESSIONS.md`
- `workstreams/**/ONBOARDING.md`
- `workstreams/**/README.md`
- `workstreams/**/docs/**/*.md`
- `workstreams/**/docs/**/*.pdf`

### `internOS.workstream` — includes
- The workstream's full set of internOS files (BRIEF, STATUS, MEMORY, DECISIONS, STAKEHOLDERS, RESOURCES, SESSIONS, ONBOARDING, README)
- The workstream's `docs/**`
- A **read-only context header** copied from the parent project — `PROJECT.md`, `AGENTS.md`, `POD.md`. The receiver loads these for orientation but has `forbidden_writes` over them.

### Default `excludes` (both types)

These are baseline forbidden patterns the verification script enforces:

- `code/**` — nested code repos are independent artifacts with their own remotes; see `docs/specs/git-tracking.md`. If a receiver needs to work on code, reference repository URLs via `RESOURCES.md` rather than vendoring.
- `.tick/lock`, `.tick/session.json` — tick runtime state
- `**/__pycache__/**`, `**/*.pyc` — Python bytecode
- `**/.env`, `**/.env.*` — secret-bearing
- `**/auth.json` — secret-bearing
- `**/*.lock`, `**/*.pid` — runtime state
- `**/.internos-warnings` — local warning state; meaningless to a receiver
- `SOUL.md`, `config.yaml`, `memories/**`, `sessions/**`, `logs/**` — global agent/harness identity (Hermes-specific shapes, but the pattern generalizes: anything outside the canonical path that represents the *sender's* identity is excluded by definition)

## Lifecycle

```
[author/sender]
    1. Decide scope, type, name.
    2. Stage payload under .tms/<tm-name>/payload/<canonical_path>/.
    3. Author SKILL.md, TM.yml, IMPORT.md, RETURN.md.
    4. Run scripts/verify_tm.sh — fails if forbidden files present or required files missing.
    5. Generate CHECKSUMS.sha256 over the package (excluding itself).
    6. Author REDACTION_REPORT.md — what was checked, what's excluded, what sensitive-adjacent content remains.
    7. Distribute (git push to a private repo, tar+sign, etc.).

[receiver]
    8. Acquire the TM directory.
    9. Read SKILL.md first, then TM.yml.
   10. Run scripts/verify_tm.sh && sha256sum -c CHECKSUMS.sha256. Refuse if either fails.
   11. Follow IMPORT.md: load order, copy payload into an internOS-compatible root, observe forbidden_writes.
   12. Work within the boundary. Never modify outside allowed_writes.
   13. Return contributions per RETURN.md (PR, branch, or patch with required notes).

[author/sender, on return]
   14. Run sync-check.sh against own workspace after merging.
   15. Update STATUS.md, DECISIONS.md, RESOURCES.md in the canonical workspace to reflect ingested work.
   16. If material change to source: re-export the TM (new version, new CHECKSUMS).
```

## Verification

`scripts/verify_tm.sh` is portable bash with zero runtime dependencies beyond standard POSIX utilities + `sha256sum` (Linux) or `shasum -a 256` (macOS). It checks:

1. **Structural completeness** — required files present (`SKILL.md`, `references/TM.yml`, `references/IMPORT.md`, `references/RETURN.md`, `references/REDACTION_REPORT.md`).
2. **Payload required files** — based on the declared `type`:
   - `internOS.project`: `payload/<canonical_path>/PROJECT.md`, `AGENTS.md`, `TICK.md`
   - `internOS.workstream`: `payload/<canonical_path>/BRIEF.md`, `STATUS.md`
3. **Forbidden patterns absent** — no file inside `payload/` matches the default exclude globs.
4. **Checksums** — `sha256sum -c CHECKSUMS.sha256` (or `shasum -a 256 -c` on macOS) passes.

The reference implementation is in `templates/tm/scripts/verify_tm.sh`.

## Cross-harness compatibility

A well-formed TM is **harness-agnostic**. It can be loaded by:

- **Hermes** — install to `~/.hermes/skills/intern-os/<tm-name>/`, load via `skill_view(name="<tm-name>")`.
- **Claude Code** — drop the TM directory anywhere the agent can read; the SKILL.md frontmatter + IMPORT.md tell the agent how to proceed. No native skill-loader integration required.
- **Codex / OpenCode / OpenClaw / any LLM agent** — same as Claude Code; the SKILL.md is plain markdown.
- **Humans** — read the README and follow IMPORT.md.

Harness-specific install paths and skill-loader hooks belong in the TM's own `README.md`, not in this standard. The standard guarantees only the *shape*.

## Author identity

The `author:` field in SKILL.md can be a human identity (`Mel`, `mel@innvertir.com`), an agent identity (`Aibus Dumbleclaw`), or a hybrid (`Aibus Dumbleclaw on behalf of Mel`). The convention is to name whoever (or whatever) is accountable for the redaction decisions and the boundary contract — that's the entity a receiver should trust or distrust.

## Open questions

- **Cross-workstream TMs.** A project may have workstreams that depend on each other (one's RESOURCES.md references another's outputs). The current spec treats workstream TMs as standalone. If dependency tracking matters in practice, add a `depends_on:` block to TM.yml pointing to other TM names or workstream canonical paths.
- **Receiver capability negotiation.** When a TM targets `tm_spec_version: 1.0` and the receiver only supports `0.x`, what happens? Currently: refuse. A `min_spec_version` and `max_spec_version` field could allow gentler compatibility windows.
- **Signed TMs.** REDACTION_REPORT.md is author-attested but unsigned. For higher-trust transfers (client deliverables, paid handoffs), GPG-signing the CHECKSUMS file may be worth adding.
- **Bootstrap from REGISTRY.** A `tm export <workspace>/<project>` command that reads `projects/REGISTRY.md` (when the git-tracking spec lands) and produces a fully-formed TM directory automatically. The lived practice today is manual.
- **`code/` exception.** The default exclude is firm. A future TM type `internOS.code-bundle` could authorize selective inclusion of `code/<repo>/` for narrow use cases (review handoffs, security audits) with explicit `permissions.allowed_writes` carving in code-side. Out of scope for v1.

## Compatibility with the git-tracking spec

TMs and git-tracked project repos solve related but distinct problems:

| Concern | Git-tracking spec | Transfer Modules |
| --- | --- | --- |
| Audit history of state changes | Yes (project repo commits) | No (snapshot only) |
| Move state across trust boundaries | No (assumes shared repo access) | Yes (self-contained, redacted, integrity-verified) |
| Track code repos alongside state | Yes (via `code/` container, gitignored subdirs) | No (excludes `code/**` by default) |
| Receiver can work offline | Requires clone | Yes (payload is everything) |

The two coexist: a project repo accumulates *committed* state over time; a TM captures a *snapshot* of that state for a specific receiver at a specific moment. They share the same default exclude on `code/**` — same reason, same precedent.
