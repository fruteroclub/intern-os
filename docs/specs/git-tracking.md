# Git tracking for internOS workspaces

*Status: convention proposal. Not yet enforced by tooling.*

## Problem

internOS workstreams live at `<workspace>/projects/<project>/workstreams/<name>/` and accumulate state over time — BRIEF.md, STATUS.md, MEMORY.md, DECISIONS.md, TICK.md, etc. This state is operationally valuable, but the framework today treats it as "files on disk" with no version history. Meanwhile, each project also contains real code that must be tracked in its own repo (often multiple repos per project — engine, skills, channels, landing, etc.).

The question is how to introduce git tracking for internOS state without colliding with code repos that are already (or will be) git-tracked at deeper paths.

## Model: three-tier containment, one repo per tier

The filesystem hierarchy mirrors how teams organize repos under a GitHub organization. Each tier is its own git repo; they nest on disk because internOS uses filesystem containment to express conceptual containment that GitHub orgs only express in their admin layer.

| Tier | Path | Maps to | Tracks |
| --- | --- | --- | --- |
| Workspace | `<workspace>/` | The GitHub organization itself | Org-level state: README, workspace-level AGENTS.md, POD.md, `projects/REGISTRY.md`, cross-project docs |
| Project | `<workspace>/projects/<project>/` | One repo per project on GitHub (`<org>/<project>`) | Project-level state: PROJECT.md, AGENTS.md, POD.md, TICK.md, `workstreams/<name>/*.md`, `docs/`, **and the `code/` container** (its README, but never the nested repos inside it) |
| Code | `<workspace>/projects/<project>/code/<repo>/` | Independent code repos on GitHub (`<org>/<repo>`) | Source code — one repo per deployable layer or service |

Two important shape rules:

1. **The project repo is the project repo.** There is no separate `<project>-os` for internOS state. PROJECT.md, TICK.md, workstreams, and the `code/` container all live in the same repo (`<org>/<project>`) — the one that already exists for the product. This matches the "one product, one repo in the org" instinct and keeps state co-located with its container.
2. **`code/` is a container, not a tier in itself.** It's a deliberate subdirectory inside the project repo that houses the project's actual code repositories — one per layer or service. The container itself is tracked (with a `README.md` that documents the layout); its subdirectories are independent git repos and are gitignored from the project's perspective.

### Worked example — PyME Companion (Agencia)

```
workspaces/agencia/                               (workspace; org = agencia-frutero)
├── (optional) .git/                              ← workspace-state repo, if used
├── AGENTS.md, POD.md, README.md, docs/           ← tracked at workspace tier
└── projects/
    ├── REGISTRY.md                                ← tracked at workspace tier
    └── pyme-companion/                          clone of agencia-frutero/pyme-companion   (project repo)
        ├── .git/
        ├── PROJECT.md, AGENTS.md, POD.md, TICK.md
        ├── workstreams/<name>/*.md               ← tracked here
        ├── docs/                                  ← tracked here
        └── code/
            ├── README.md                          ← tracked here (declares the layer layout)
            ├── engine/                .git/      clone of agencia-frutero/engine
            ├── skills/                .git/      clone of agencia-frutero/skills
            ├── workflows/             .git/      clone of agencia-frutero/workflows
            ├── channels/              .git/      clone of agencia-frutero/channels
            ├── platform/              .git/      clone of agencia-frutero/platform
            └── companion-worklab-poc/ .git/      clone of agencia-frutero/Companion
```

This is the layout used by `agencia/projects/pyme-companion/` today; the templates and `.gitignore` rules in this doc are derived from that lived practice.

## The clash, and why nested repos still work

Naïvely, nested git repos are a footgun: the parent repo "sees" the child's working tree, which leads to ambiguous commits, accidental gitlink entries, and submodule-style headaches.

This convention sidesteps the clash with each parent repo's `.gitignore`:

- **Project repo:** denies `code/*/` (the subdirectories that are themselves repos) while allowing `code/` (the container) and `code/README.md`. Combined with an allowlist over project-level files, the project repo never sees inside any code subdirectory.
- **Workspace repo (if used):** ignores everything under `projects/*/` except `projects/REGISTRY.md`. Each project repo is opaque to the workspace.

Result: `git status` at any tier shows only that tier's changes — no spurious untracked entries from below, no risk of accidentally creating a gitlink with a stray `git add`.

## Canonical .gitignore templates

The framework ships templates as starting points:

- `templates/git/workspace.gitignore` — workspace-level allowlist (optional; only needed if the org wants a dedicated workspace-state repo)
- `templates/git/project.gitignore` — project-level allowlist, including workstream files and the `code/` container rules

Copy on `git init` (or into an existing repo without a `.gitignore`):

```bash
# Project-level — covers all three: state, workstreams, code/ container
cp <intern-os-checkout>/templates/git/project.gitignore <workspace>/projects/<project>/.gitignore

# Workspace-level — only if you want an org-state repo at the workspace root
cp <intern-os-checkout>/templates/git/workspace.gitignore <workspace>/.gitignore
```

Symlinking instead of copying keeps the file in sync with framework updates, at the cost of making the project repo's `.gitignore` non-standalone (a fresh clone needs the framework installed to resolve the symlink). Copy is the safer default.

## When to enable the workspace tier

The workspace tier is **optional**. Enable it if any of these are true:

- Your org has cross-project state worth versioning (workspace-level `AGENTS.md`, shared `docs/`, an authoritative `REGISTRY.md`).
- Multiple humans need to bootstrap the same workspace skeleton from a clone.
- You want auditability of how the org's internOS state evolves over time.

Skip it if the workspace is just a directory of independent projects with no shared state to track. In that case, each project repo stands alone and the workspace tier adds no value.

## Migrating an existing project

For a project whose repo already exists (like `pyme-companion`) and has code subdirectories with their own `.git`:

1. `cd <workspace>/projects/<project>`
2. If no `.gitignore` exists: `cp <intern-os-checkout>/templates/git/project.gitignore .gitignore`
3. If a `.gitignore` already exists: merge in the `code/*/` ignore plus the `code/README.md` re-include. (The allowlist template is opinionated; for an established repo, the minimal change is the `code/*/` denial.)
4. `git add .gitignore && git commit -m "chore: ignore nested code/ subdirectories"`
5. `git status` should now be clean — any nested code repos disappear from the untracked list.

The code subdirectories are unaffected — their `.git/` and remote bindings remain. The project repo simply cannot see them.

## Tradeoffs

**Maintenance cost.** Every new internOS file shape (e.g. if v0.5 adds `RISKS.md`) must be added to the allowlist, or it won't be tracked. The templates here are the single source of truth — update them when the framework evolves, then projects sync.

**Multiple `.git` directories on disk.** Several `.git` dirs per project tree (optionally workspace, definitely project, plus one per code repo). `find` / globbing tools see them all. Some IDEs (notably JetBrains) get confused; VS Code and Cursor handle nested repos gracefully when the outer repo never touches the inner working trees, which the `code/*/` denial guarantees.

**Project repo carries non-code concerns.** PROJECT.md, TICK.md, and `workstreams/` mean the project repo's history is dominated by internOS state changes rather than code commits (code lives in the nested repos). That's the right tradeoff — the project repo's *job* is to coordinate the project, not to ship code — but a reader expecting a traditional product repo will find it surprising. Document this in the project's `README.md`.

**Fresh-clone bootstrap.** A new contributor cloning the project repo gets the internOS state and an empty `code/` container. Bootstrapping a working tree requires cloning each code repo separately into the right `code/<repo>/` slot. A future `intern-os bootstrap` script can automate this from a list maintained in `code/README.md`.

## Open questions

- **Should the workspace tier ship as standard?** Or only adopt-on-need (current proposal)? Argues for: regularity. Argues against: most orgs won't need it, adoption friction.
- **`tmp/`, `node_modules/`, transient artifacts** in the templates as belt-and-suspenders. Allowlist style makes this unnecessary (anything not explicitly re-included is ignored), but explicit `node_modules/` lines reduce confusion for newcomers reading the file.
- **Does `sync-check.sh` need to learn about git tracking?** A workstream whose BRIEF.md isn't committed is implicitly different from one that is. INFO-level note when the project repo has uncommitted internOS files seems right but is scope creep against the current sync-check mandate.
- **A bootstrap script** that reads `code/README.md` (or a structured `code/repos.yml`) and clones each declared code repo into its slot. Solves the fresh-clone friction.
