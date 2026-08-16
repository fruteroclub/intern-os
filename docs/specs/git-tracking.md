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

## Git worktrees

Parallel and agent-driven code work needs isolated checkouts — one branch per thread, per lane, or per subagent — so edits in one never touch another. internOS uses git worktrees for this, with one canonical location:

```
projects/<project>/code/.worktrees/<name>/
```

Each worktree is a **linked worktree of exactly one code repo** (`code/<repo>`), sharing that repo's single `.git`. They are all parked in one shared `code/.worktrees/` directory that sits *beside* the code repos, not inside any of them.

### Why here

- **Already ignored.** `code/.worktrees/` is matched by the existing `code/*` denial in the project `.gitignore` (below), so worktrees are invisible to the project repo with no extra rule.
- **Beside, not inside.** Because the parking dir is a sibling of the code repos rather than a subdirectory of one, no code repo's `git status` ever shows the worktree checkouts, and no code repo needs a `.worktrees/` line in *its* `.gitignore`. (A linked worktree never appears in its own parent repo's status regardless — placing them beside the repos also keeps IDE indexers and file-watchers from re-scanning nested checkouts.)
- **Self-contained.** Worktrees live inside the project tree, so a project directory remains a complete, portable unit.

### Naming

- **Worktree dir:** `code/.worktrees/<name>/` — `<name>` is kebab-case and unique within the project (git enforces path uniqueness).
- **Branch:** `<type>/<name>` — `feat/<name>` (features), `study/<name>` (study internals), `fix/<name>`, etc. The default is `feat/<name>`; override per worktree. Harness-native branch names (`hermes/…`, `worktree-…`) are accepted; the ledger records whatever branch a worktree is actually on.
- **Owning repo:** the shared dir does not encode which code repo a worktree belongs to. Ownership is recorded (a) in the workstream's `BRIEF.md` `worktrees:` block and (b) discovered at runtime via `git worktree list` per code repo. The tooling reconciles both.

### Compatibility with agent harnesses and IDEs

This location is a deliberate internOS convention, not where any single tool writes by default, so tools map onto it as follows:

| Tool | Native worktree location | How it uses `code/.worktrees/` |
| --- | --- | --- |
| internOS `worktree.sh` | — | Creates/lists/prunes here directly (primary path). |
| Claude Code | `<repo>/.claude/worktrees/` | Native `--worktree` forks the *project* repo (no code). Use the shipped `WorktreeCreate` hook to redirect creation here, or just `cd` into a worktree `worktree.sh` made. |
| Hermes / OpenClaw | `<repo>/.worktrees/` | Point their config at a `code/<repo>` and they write to `code/<repo>/.worktrees/`, not the shared dir — so prefer `worktree.sh` for the shared-dir convention, or accept the per-repo location. |
| Codex / Aider / Cline / Amp | none (operate in cwd) | `cd` into the worktree and run. **Codex caveat:** its sandbox can remount the gitdir read-only inside a linked worktree, breaking `git commit`; run Codex with `workspace-write` + a writable `.git`, or commit from the primary checkout. |

The tradeoff internOS accepts: worktrees are created by the `worktree.sh` helper (or the Claude Code hook) rather than by a harness's native flag. In exchange, every worktree lands in one predictable, already-ignored, self-contained place regardless of which tool is driving.

### Tooling

`intern-os/scripts/worktree.sh` is the single home for worktree logic:

```bash
# Create code/.worktrees/checkout-flow as a linked worktree of code/app-monorepo
worktree.sh create checkout-flow --repo app-monorepo --branch feat/checkout-flow

worktree.sh list            # all worktrees + owning repo, branch, state, workstream
worktree.sh ledger          # (re)write the derived code/WORKTREES.md
worktree.sh prune --dry-run # show worktrees safe to remove; --yes to remove
```

`generate-registry.sh` adds a per-project worktree count to `projects/REGISTRY.md`; the full per-project detail lives in the derived `code/WORKTREES.md` ledger.

### Fresh-worktree bootstrap

A new worktree is a fresh checkout that carries **tracked files only** — no `node_modules`, no gitignored env files. Two steps make it runnable:

1. **Install dependencies** in the worktree (`pnpm install`, etc.).
2. **Copy gitignored config** it needs (`.env.local`, secrets). Add a `.worktreeinclude` file (`.gitignore` syntax, one path/glob per line) at the code repo root listing the gitignored files to copy; `worktree.sh create` copies them into each new worktree automatically. This matches the Hermes / Claude Code `.worktreeinclude` convention. A missing env file is a common silent failure — e.g. an app that mounts a provider unconditionally will crash the whole route tree if its key is absent.

**Caches can lie across worktrees.** Build caches keyed on content (e.g. Turbo) may report a hit from another worktree; force a real run (`turbo run <task> --force`) when a number has to be trustworthy.

### Cleanup

Removal is gated on merge and is conservative by design:

- **Never remove a worktree with a dirty tree or unpushed commits.** `worktree.sh prune` keeps any worktree it cannot prove is clean *and* fully pushed (no upstream tracking counts as unprovable → kept).
- Prune only after the branch is merged and the work is reported. `worktree.sh prune --dry-run` classifies; `--yes` removes the safe set.
- When in doubt, leave it — an idle worktree costs disk, a wrongly-removed one costs work.

## Tradeoffs

**Maintenance cost.** Every new internOS file shape (e.g. if v0.5 adds `RISKS.md`) must be added to the allowlist, or it won't be tracked. The templates here are the single source of truth — update them when the framework evolves, then projects sync.

**Multiple `.git` directories on disk.** Several `.git` dirs per project tree (optionally workspace, definitely project, plus one per code repo), plus a `.git` *file* (a gitlink, not a dir) in each worktree under `code/.worktrees/`. `find` / globbing tools see them all. Some IDEs (notably JetBrains) get confused; VS Code and Cursor handle nested repos gracefully when the outer repo never touches the inner working trees, which the `code/*` denial guarantees (and it covers `code/.worktrees/` too).

**Project repo carries non-code concerns.** PROJECT.md, TICK.md, and `workstreams/` mean the project repo's history is dominated by internOS state changes rather than code commits (code lives in the nested repos). That's the right tradeoff — the project repo's *job* is to coordinate the project, not to ship code — but a reader expecting a traditional product repo will find it surprising. Document this in the project's `README.md`.

**Fresh-clone bootstrap.** A new contributor cloning the project repo gets the internOS state and an empty `code/` container. Bootstrapping a working tree requires cloning each code repo separately into the right `code/<repo>/` slot. A future `intern-os bootstrap` script can automate this from a list maintained in `code/README.md`.

## Open questions

- **Should the workspace tier ship as standard?** Or only adopt-on-need (current proposal)? Argues for: regularity. Argues against: most orgs won't need it, adoption friction.
- **`tmp/`, `node_modules/`, transient artifacts** in the templates as belt-and-suspenders. Allowlist style makes this unnecessary (anything not explicitly re-included is ignored), but explicit `node_modules/` lines reduce confusion for newcomers reading the file.
- **Does `sync-check.sh` need to learn about git tracking?** A workstream whose BRIEF.md isn't committed is implicitly different from one that is. INFO-level note when the project repo has uncommitted internOS files seems right but is scope creep against the current sync-check mandate.
- **A bootstrap script** that reads `code/README.md` (or a structured `code/repos.yml`) and clones each declared code repo into its slot. Solves the fresh-clone friction.

## Resolved

- **Worktrees (resolved).** Git worktrees for parallel/agent code work live at `code/.worktrees/<name>/` as linked worktrees of a code repo — see [Git worktrees](#git-worktrees) above. Managed by `intern-os/scripts/worktree.sh`; declared per workstream in `BRIEF.md`; tracked in the derived `code/WORKTREES.md` ledger and counted in `projects/REGISTRY.md`.
